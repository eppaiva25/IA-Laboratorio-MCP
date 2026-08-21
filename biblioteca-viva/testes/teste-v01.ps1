$ErrorActionPreference = 'Stop'

$pastaNucleo = Join-Path $PSScriptRoot '..\nucleo'
. (Join-Path $pastaNucleo 'config.ps1')
. (Join-Path $pastaNucleo 'catalogo.ps1')
. (Join-Path $pastaNucleo 'identificador.ps1')

$script:aprovados = 0
$script:falhados = 0

function Test-BvVerificacao {
    param(
        [Parameter(Mandatory)][string]$Nome,
        [Parameter(Mandatory)][scriptblock]$Bloco
    )
    try {
        & $Bloco
        Write-Host "[PASSOU] $Nome"
        $script:aprovados++
    }
    catch {
        Write-Host "[FALHOU] $Nome -> $($_.Exception.Message)"
        $script:falhados++
    }
}

Write-Host '=== Biblioteca Viva - Testes da Fase A ==='
Write-Host ''

Test-BvVerificacao -Nome '01 Config carrega com valores essenciais dos dois modos' -Bloco {
    $cfg = Get-BvConfig
    if ([int]$cfg.VersaoEsquema -ne 1) { throw 'VersaoEsquema deveria ser 1' }
    if ($cfg.ModosValidos.Count -ne 2) { throw 'devem existir exatamente dois modos' }
    if ($cfg.ModosValidos -notcontains $cfg.ModoPadrao) { throw 'ModoPadrao fora dos modos validos' }
    if ($cfg.StatusValidos -notcontains 'desaparecido') { throw 'vocabulario sem desaparecido' }
    if ($cfg.StatusValidos -notcontains 'aguardando_hash') { throw 'vocabulario sem aguardando_hash' }
    if ($cfg.ExtensoesComModulo -notcontains '.pdf') { throw 'modulo pdf ausente nas extensoes' }
    if ($cfg.PastasMigracao.Count -lt 1) { throw 'PastasMigracao vazia' }
}

Test-BvVerificacao -Nome '02 Initialize cria catalogo.csv com cabecalho exato de 26 colunas' -Bloco {
    $arquivo = Initialize-BvCatalogo
    if (-not (Test-Path -LiteralPath $arquivo)) { throw 'catalogo.csv nao foi criado' }
    $obtida = Get-Content -LiteralPath $arquivo -TotalCount 1
    $esperada = '"' + (@(Get-BvColunasCatalogo) -join '","') + '"'
    if ($obtida -ne $esperada) { throw "Cabecalho diverge. Obtida: $obtida" }
    if (@(Get-BvColunasCatalogo).Count -ne 26) { throw 'numero de colunas deveria ser 26' }
}

Test-BvVerificacao -Nome '03 esquema.json registra a versao 1 do esquema' -Bloco {
    $cfg = Get-BvConfig
    $arquivoEsquema = Join-Path $cfg.PastaDados $cfg.NomeArquivoEsquema
    if (-not (Test-Path -LiteralPath $arquivoEsquema)) { throw 'esquema.json ausente' }
    $esquema = Get-Content -LiteralPath $arquivoEsquema -Raw | ConvertFrom-Json
    if ([int]$esquema.versao_esquema -ne 1) { throw 'versao divergente entre arquivo e codigo' }
}

Test-BvVerificacao -Nome '04 Initialize e seguro: segunda execucao nao reescreve o catalogo' -Bloco {
    $arquivo = Initialize-BvCatalogo
    $antes = (Get-Item -LiteralPath $arquivo).LastWriteTimeUtc.Ticks
    Start-Sleep -Milliseconds 50
    Initialize-BvCatalogo | Out-Null
    $depois = (Get-Item -LiteralPath $arquivo).LastWriteTimeUtc.Ticks
    if ($antes -ne $depois) { throw 'arquivo foi reescrito na segunda inicializacao' }
}

Test-BvVerificacao -Nome '05 Get-BvCatalogo em catalogo vazio retorna zero linhas sem erro' -Bloco {
    $linhas = @(Get-BvCatalogo)
    if ($linhas.Count -ne 0) { throw "esperava 0 linhas, obtive $($linhas.Count)" }
}

$pastaProva = Join-Path ([IO.Path]::GetTempPath()) 'bv-teste-fase-a'

Test-BvVerificacao -Nome '06 Get-BvStatLeve extrai metadados sem calcular hash' -Bloco {
    if (Test-Path -LiteralPath $pastaProva) { Remove-Item -LiteralPath $pastaProva -Recurse -Force }
    New-Item -ItemType Directory -Path $pastaProva -Force | Out-Null
    $prova = Join-Path $pastaProva 'prova.txt'
    Set-Content -LiteralPath $prova -Value 'conteudo de prova biblioteca viva' -Encoding utf8

    $stat = Get-BvStatLeve -Caminho $prova
    $item = Get-Item -LiteralPath $prova
    if ($stat.caminho_atual -ne $item.FullName) { throw 'caminho_atual diverge do caminho completo real' }
    if ($stat.tamanho_bytes -ne $item.Length) { throw 'tamanho_bytes nao bate byte a byte' }
    if ($stat.tipo -ne '.txt') { throw "tipo inesperado: $($stat.tipo)" }
    if ($stat.PSObject.Properties.Name -contains 'sha256') { throw 'stat leve nao deveria conter hash' }
}

Test-BvVerificacao -Nome '07 Get-BvStatLeve recusa caminho inexistente com erro claro' -Bloco {
    $fantasma = Join-Path $pastaProva 'nao-existe.txt'
    $erroCapturado = $null
    try { Get-BvStatLeve -Caminho $fantasma | Out-Null }
    catch { $erroCapturado = $_.Exception.Message }
    if ($null -eq $erroCapturado) { throw 'deveria ter lancado erro para arquivo inexistente' }
}

Test-BvVerificacao -Nome '08 Get-BvIdentidade produz hash confiavel e campos completos' -Bloco {
    $prova = Join-Path $pastaProva 'prova.txt'
    $identidade = Get-BvIdentidade -Caminho $prova
    $hashDireto = (Get-FileHash -LiteralPath $prova -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($identidade.sha256 -ne $hashDireto) { throw 'sha256 diverge do calculo direto' }
    if ($identidade.id -ne $hashDireto.Substring(0, 12)) { throw 'id nao corresponde aos primeiros 12 caracteres' }
    if ($identidade.nome_original -ne 'prova.txt') { throw 'nome_original incorreto' }
    if ($identidade.caminho_atual -ne (Get-Item -LiteralPath $prova).FullName) { throw 'caminho_atual incorreto' }
    if ([long]$identidade.tamanho_bytes -le 0) { throw 'tamanho_bytes deveria ser positivo' }
    if ($identidade.pasta_original -ne (Split-Path -Parent (Get-Item -LiteralPath $prova).FullName)) { throw 'pasta_original incorreta' }
}

$hashA = 'a' * 64
$caminhoP1 = 'C:\provas-ficticias\documento.txt'
$caminhoP2 = 'C:\outras-provas\copia-documento.txt'

Test-BvVerificacao -Nome '09 Roundtrip New+Save+Get preserva valores e ordem das 26 colunas' -Bloco {
    $linha = New-BvLinhaCatalogo
    $linha.id = $hashA.Substring(0, 12)
    $linha.sha256 = $hashA
    $linha.nome_original = 'documento.txt'
    $linha.pasta_original = 'C:\provas-ficticias'
    $linha.caminho_atual = $caminhoP1
    $linha.tamanho_bytes = '1234'
    $linha.status = 'novo'
    $linha.detalhes = '{"paginas":1}'
    Save-BvCatalogo -Linhas @($linha) | Out-Null

    $linhas = @(Get-BvCatalogo)
    if ($linhas.Count -ne 1) { throw "esperava 1 linha, obtive $($linhas.Count)" }
    $r = $linhas[0]
    if ($r.id -ne $hashA.Substring(0, 12)) { throw 'campo id nao persistiu' }
    if ($r.caminho_atual -ne $caminhoP1) { throw 'campo caminho_atual nao persistiu' }
    if ($r.tamanho_bytes -ne '1234') { throw 'campo tamanho_bytes nao persistiu' }
    if ($r.detalhes -ne '{"paginas":1}') { throw 'campo detalhes nao persistiu' }

    $obtido = Get-Content -LiteralPath (Get-BvArquivoCatalogo) -TotalCount 1
    $esperado = '"' + (@(Get-BvColunasCatalogo) -join '","') + '"'
    if ($obtido -ne $esperado) { throw 'ordem das colunas mudou apos gravacao' }
}

Test-BvVerificacao -Nome '10 Porta unica recusa ocorrencia duplicada (mesmo sha256 e mesmo caminho)' -Bloco {
    $a1 = New-BvLinhaCatalogo
    $a1.sha256 = $hashA
    $a1.caminho_atual = $caminhoP1
    $a1.status = 'novo'
    $a2 = New-BvLinhaCatalogo
    $a2.sha256 = $hashA.ToUpperInvariant()
    $a2.caminho_atual = $caminhoP1.ToUpperInvariant()
    $a2.status = 'novo'
    $erroCapturado = $null
    try { Save-BvCatalogo -Linhas @($a1, $a2) | Out-Null }
    catch { $erroCapturado = $_.Exception.Message }
    if ($null -eq $erroCapturado) { throw 'deveria ter recusado a duplicata' }
    if (@(Get-BvCatalogo).Count -ne 1) { throw 'catalogo foi alterado apesar da recusa' }
}

Test-BvVerificacao -Nome '11 Mesmo conteudo em dois caminhos e aceito como duas ocorrencias' -Bloco {
    $a = New-BvLinhaCatalogo
    $a.sha256 = $hashA
    $a.caminho_atual = $caminhoP1
    $a.status = 'novo'
    $b = New-BvLinhaCatalogo
    $b.sha256 = $hashA
    $b.caminho_atual = $caminhoP2
    $b.status = 'novo'
    Save-BvCatalogo -Linhas @($a, $b) | Out-Null
    if (@(Get-BvCatalogo).Count -ne 2) { throw "esperava 2 linhas, obtive $(@(Get-BvCatalogo).Count)" }
}

Test-BvVerificacao -Nome '12 Consultas por caminho e por hash localizam as ocorrencias' -Bloco {
    $porCaminho = Get-BvLinhaPorCaminho -Caminho $caminhoP2
    if ($null -eq $porCaminho) { throw 'consulta por caminho nao encontrou a linha' }
    if ($porCaminho.caminho_atual -ne $caminhoP2) { throw 'linha errada retornada por caminho' }
    $porHash = @(Get-BvLinhasPorHash -Sha256 $hashA)
    if ($porHash.Count -ne 2) { throw "esperava 2 ocorrencias do mesmo hash, obtive $($porHash.Count)" }
}

Test-BvVerificacao -Nome '13 Versao substituida sai da consulta padrao mas permanece no historico' -Bloco {
    $hashB = 'b' * 64
    $idNovo = $hashB.Substring(0, 12)

    $nova = New-BvLinhaCatalogo
    $nova.id = $idNovo
    $nova.sha256 = $hashB
    $nova.caminho_atual = $caminhoP1
    $nova.status = 'novo'

    $antiga = Get-BvLinhaPorCaminho -Caminho $caminhoP1
    $antiga.substituido_por = $idNovo

    $outra = Get-BvLinhaPorCaminho -Caminho $caminhoP2
    Save-BvCatalogo -Linhas @($nova, $antiga, $outra) | Out-Null

    $ativa = Get-BvLinhaPorCaminho -Caminho $caminhoP1
    if ($ativa.sha256 -ne $hashB) { throw 'consulta padrao deveria retornar a versao nova' }
    $historico = @(Get-BvLinhasPorHash -Sha256 $hashA)
    if ($historico.Count -ne 2) { throw "esperava 2 linhas com o hash antigo, obtive $($historico.Count)" }
    $substituida = $historico | Where-Object { $_.substituido_por -eq $idNovo }
    if (-not $substituida) { throw 'ligacao de substituicao ausente' }
}

Test-BvVerificacao -Nome '14 Porta unica recusa status fora do vocabulario' -Bloco {
    $x = New-BvLinhaCatalogo
    $x.sha256 = 'c' * 64
    $x.caminho_atual = 'C:\qualquer\arquivo.bin'
    $x.status = 'processando-aleatorio'
    $erroCapturado = $null
    try { Save-BvCatalogo -Linhas @($x) | Out-Null }
    catch { $erroCapturado = $_.Exception.Message }
    if ($null -eq $erroCapturado) { throw 'status invalido deveria ser rejeitado' }
}

Test-BvVerificacao -Nome '15 Save com lista vazia preserva apenas o cabecalho' -Bloco {
    Save-BvCatalogo -Linhas @() | Out-Null
    $linhas = @(Get-BvCatalogo)
    if ($linhas.Count -ne 0) { throw 'catalogo deveria ficar vazio' }
    $obtido = Get-Content -LiteralPath (Get-BvArquivoCatalogo) -TotalCount 1
    $esperado = '"' + (@(Get-BvColunasCatalogo) -join '","') + '"'
    if ($obtido -ne $esperado) { throw 'cabecalho perdido ao salvar lista vazia' }
}

if (Test-Path -LiteralPath $pastaProva) {
    Remove-Item -LiteralPath $pastaProva -Recurse -Force
}

Write-Host ''
Write-Host "Resultado: $script:aprovados passaram, $script:falhados falharam"

exit ($script:falhados -gt 0 ? 1 : 0)
