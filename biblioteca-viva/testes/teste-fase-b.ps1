$ErrorActionPreference = 'Stop'

$pastaNucleo = Join-Path $PSScriptRoot '..\nucleo'
. (Join-Path $pastaNucleo 'config.ps1')
. (Join-Path $pastaNucleo 'catalogo.ps1')
. (Join-Path $pastaNucleo 'identificador.ps1')
. (Join-Path $pastaNucleo 'diario.ps1')
. (Join-Path $pastaNucleo 'roteador.ps1')
. (Join-Path $pastaNucleo 'descobridor.ps1')
. (Join-Path $pastaNucleo 'reconciliacao.ps1')
. (Join-Path $pastaNucleo '..\modulos\modulo_pdf.ps1')

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

function New-BvPdfProva {
    param(
        [string]$Produtor = 'ProdutorDeTeste',
        [bool]$Criptografado = $false
    )
    $texto = @(
        '%PDF-1.4'
        '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj'
        '2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj'
        '3 0 obj << /Type /Page /Parent 2 0 R /Resources << /Font << /F1 4 0 R >> >> >> endobj'
        '4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj'
        'trailer << /Size 5 /Root 1 0 R /Producer (' + $Produtor + ') >>'
        '%%EOF'
    ) -join "`n"
    if ($Criptografado) {
        $texto = $texto.Replace('%%EOF', "/Encrypt 9 0 R`n%%EOF")
    }
    return [Text.Encoding]::ASCII.GetBytes($texto)
}

Write-Host '=== Biblioteca Viva - Testes da Fase B ==='
Write-Host ''

$pastaRaiz = Join-Path ([IO.Path]::GetTempPath()) 'bv-teste-fase-b'
$pastaLib = Join-Path $pastaRaiz 'lib'

if (Test-Path -LiteralPath $pastaRaiz) { Remove-Item -LiteralPath $pastaRaiz -Recurse -Force }
New-Item -ItemType Directory -Path $pastaLib -Force | Out-Null

$arquivoCatalogo = Get-BvArquivoCatalogo
if (Test-Path -LiteralPath $arquivoCatalogo) { Remove-Item -LiteralPath $arquivoCatalogo -Force }
$arquivoDiario = Get-BvArquivoDiario
if (Test-Path -LiteralPath $arquivoDiario) { Remove-Item -LiteralPath $arquivoDiario -Force }

$caminhoProva = Join-Path $pastaLib 'prova.pdf'

Test-BvVerificacao -Nome '01 Roteador classifica os tres estados e normaliza caixa alta' -Bloco {
    $rotaPdf = Get-BvRota -Tipo '.pdf'
    if ($rotaPdf.Estado -ne 'ComModulo') { throw '.pdf deveria ser ComModulo' }
    if (-not (Test-Path -LiteralPath $rotaPdf.ScriptModulo)) { throw 'script do modulo pdf nao existe' }
    $rotaDocx = Get-BvRota -Tipo '.docx'
    if ($rotaDocx.Estado -ne 'ConhecidoSemModulo') { throw '.docx deveria ser ConhecidoSemModulo' }
    $rotaXyz = Get-BvRota -Tipo '.xyz'
    if ($rotaXyz.Estado -ne 'Desconhecido') { throw '.xyz deveria ser Desconhecido' }
    $rotaMaiuscula = Get-BvRota -Tipo '.PDF'
    if ($rotaMaiuscula.Estado -ne 'ComModulo' -or $rotaMaiuscula.Tipo -ne '.pdf') { throw 'caixa alta nao foi normalizada' }
    if (-not (Test-BvRegistroModulosValido)) { throw 'registro de modulos inconsistente com a config' }
}

Test-BvVerificacao -Nome '02 Modulo PDF analisa PDF valido sem alertas' -Bloco {
    [IO.File]::WriteAllBytes($caminhoProva, (New-BvPdfProva))
    $ficha = Invoke-BvAnalise -Caminho $caminhoProva
    if (-not $ficha.Legivel) { throw 'deveria ser legivel' }
    if (@($ficha.Alertas).Count -ne 0) { throw "nao deveria ter alertas: $($ficha.Alertas -join ',')" }
    $detalhes = $ficha.DetalhesJson | ConvertFrom-Json
    if ([int]$detalhes.paginas -ne 1) { throw "paginas deveria ser 1" }
    if ($detalhes.produtor -ne 'ProdutorDeTeste') { throw 'produtor nao capturado' }
    if ($ficha.AmostraConteudo -ne '') { throw 'amostra deveria ser vazia na V0.1' }
    if ($ficha.Tipo -ne '.pdf') { throw 'tipo incorreto' }
}

Test-BvVerificacao -Nome '03 Modulo PDF detecta arquivo falso como malformado' -Bloco {
    $falso = Join-Path $pastaRaiz 'falso-isolado.pdf'
    Set-Content -LiteralPath $falso -Value 'isto nao e um pdf' -Encoding utf8
    $ficha = Invoke-BvAnalise -Caminho $falso
    if ($ficha.Legivel) { throw 'deveria ser ilegivel' }
    if (@($ficha.Alertas) -notcontains 'malformado') { throw 'alerta malformado ausente' }
}

Test-BvVerificacao -Nome '04 Modulo PDF detecta marcador de criptografia' -Bloco {
    $protegido = Join-Path $pastaRaiz 'protegido.pdf'
    [IO.File]::WriteAllBytes($protegido, (New-BvPdfProva -Criptografado $true))
    $ficha = Invoke-BvAnalise -Caminho $protegido
    if (-not $ficha.Legivel) { throw 'estrutura basica deveria continuar legivel' }
    if (@($ficha.Alertas) -notcontains 'criptografado') { throw 'alerta criptografado ausente' }
    $detalhes = $ficha.DetalhesJson | ConvertFrom-Json
    if (-not $detalhes.criptografado) { throw 'flag criptografado ausente nos detalhes' }
}

Test-BvVerificacao -Nome '05 Descobridor encontra os tres arquivos como novos' -Bloco {
    Set-Content -LiteralPath (Join-Path $pastaLib 'falso.pdf') -Value 'isto nao e um pdf' -Encoding utf8
    Set-Content -LiteralPath (Join-Path $pastaLib 'documento.txt') -Value 'texto simples de prova' -Encoding utf8
    $d = Get-BvDescobertas -Modo 'migracao' -Pastas @($pastaLib)
    if (@($d.NovosCandidatos).Count -ne 3) { throw "esperava 3 novos, obtive $(@($d.NovosCandidatos).Count)" }
    if (@($d.Suspeitos).Count -ne 0) { throw 'suspeitos deveria ser 0' }
    if (@($d.AusentesDoDisco).Count -ne 0) { throw 'ausentes deveria ser 0' }
}

Test-BvVerificacao -Nome '06 Reconciliacao inventaria os tres com status corretos' -Bloco {
    $d = Get-BvDescobertas -Modo 'migracao' -Pastas @($pastaLib)
    $r = Invoke-BvReconciliacao -Descobertas $d -CheckpointACada 1
    if ($r.Novos -ne 3) { throw "novos deveria ser 3, obtive $($r.Novos)" }
    $linhas = @(Get-BvCatalogo)
    if ($linhas.Count -ne 3) { throw "catalogo deveria ter 3 linhas, tem $($linhas.Count)" }
    $linhaProva = Get-BvLinhaPorCaminho -Caminho $caminhoProva
    if ($linhaProva.status -ne 'inventariado') { throw "prova deveria estar inventariada, esta $($linhaProva.status)" }
    $detalhes = $linhaProva.detalhes | ConvertFrom-Json
    if ([int]$detalhes.paginas -ne 1) { throw 'detalhes do pdf nao persistiram' }
    $linhaFalsa = Get-BvLinhaPorCaminho -Caminho (Join-Path $pastaLib 'falso.pdf')
    if ($linhaFalsa.status -ne '_PROBLEMAS') { throw "falso deveria ser _PROBLEMAS, esta $($linhaFalsa.status)" }
    $linhaTxt = Get-BvLinhaPorCaminho -Caminho (Join-Path $pastaLib 'documento.txt')
    if ($linhaTxt.status -ne '_REVISAR') { throw "txt deveria ser _REVISAR, esta $($linhaTxt.status)" }
    $eventos = @(Get-BvDiario | Where-Object { $_.evento -eq 'arquivo_novo' })
    if ($eventos.Count -lt 3) { throw 'diario deveria ter pelo menos 3 arquivo_novo' }
}

Test-BvVerificacao -Nome '07 Segunda varredura sem mudancas nao reprocessa nada' -Bloco {
    $d = Get-BvDescobertas -Modo 'migracao' -Pastas @($pastaLib)
    if (@($d.NovosCandidatos).Count -ne 0) { throw 'novos deveria ser 0' }
    if (@($d.Inalterados).Count -ne 3) { throw "inalterados deveria ser 3, obtive $(@($d.Inalterados).Count)" }
    $r = Invoke-BvReconciliacao -Descobertas $d
    if ($r.Novos -ne 0 -or $r.Substituidos -ne 0 -or $r.Movidos -ne 0 -or $r.Duplicatas -ne 0) { throw 'reconciliacao alterou o que nao devia' }
    if (@(Get-BvCatalogo).Count -ne 3) { throw 'catalogo deveria continuar com 3 linhas' }
}

Test-BvVerificacao -Nome '08 Alteracao de conteudo gera versao nova com historico' -Bloco {
    [IO.File]::WriteAllBytes($caminhoProva, (New-BvPdfProva -Produtor 'ProdutorV2'))
    $d = Get-BvDescobertas -Modo 'migracao' -Pastas @($pastaLib)
    if (@($d.Suspeitos).Count -ne 1) { throw "esperava 1 suspeito, obtive $(@($d.Suspeitos).Count)" }
    $r = Invoke-BvReconciliacao -Descobertas $d
    if ($r.Substituidos -ne 1) { throw "substituidos deveria ser 1, obtive $($r.Substituidos)" }
    $linhas = @(Get-BvCatalogo)
    if ($linhas.Count -ne 4) { throw "catalogo deveria ter 4 linhas, tem $($linhas.Count)" }
    $ativa = Get-BvLinhaPorCaminho -Caminho $caminhoProva
    $antiga = $linhas | Where-Object { $_.substituido_por -eq $ativa.id }
    if (-not $antiga) { throw 'ligacao substituido_por ausente' }
    $eventos = @(Get-BvDiario | Where-Object { $_.evento -eq 'conteudo_substituido' })
    if ($eventos.Count -ne 1) { throw 'diario deveria registrar exatamente 1 substituicao' }
}

Test-BvVerificacao -Nome '09 Renomeacao externa move a mesma linha sem duplicar' -Bloco {
    Rename-Item -LiteralPath (Join-Path $pastaLib 'documento.txt') -NewName 'documento2.txt'
    $d = Get-BvDescobertas -Modo 'migracao' -Pastas @($pastaLib)
    if (@($d.NovosCandidatos).Count -ne 1) { throw "esperava 1 novo candidato, obtive $(@($d.NovosCandidatos).Count)" }
    if (@($d.AusentesDoDisco).Count -ne 1) { throw "esperava 1 ausente, obtive $(@($d.AusentesDoDisco).Count)" }
    $r = Invoke-BvReconciliacao -Descobertas $d
    if ($r.Movidos -ne 1) { throw "movidos deveria ser 1, obtive $($r.Movidos)" }
    if ($r.Novos -ne 0) { throw 'nao deveria criar linha nova' }
    if (@(Get-BvCatalogo).Count -ne 4) { throw 'catalogo deveria continuar com 4 linhas' }
    $linhaMovida = Get-BvLinhaPorCaminho -Caminho (Join-Path $pastaLib 'documento2.txt')
    if ($null -eq $linhaMovida) { throw 'linha nao atualizada para o novo caminho' }
    if ($linhaMovida.tipo -ne '.txt') { throw 'linha movida com tipo errado' }
    $eventos = @(Get-BvDiario | Where-Object { $_.evento -eq 'movido_externamente' })
    if ($eventos.Count -ne 1) { throw 'diario deveria registrar exatamente 1 movimento' }
}

Test-BvVerificacao -Nome '10 Copia do mesmo conteudo vira segunda ocorrencia' -Bloco {
    Copy-Item -LiteralPath $caminhoProva -Destination (Join-Path $pastaLib 'copia.pdf')
    $d = Get-BvDescobertas -Modo 'migracao' -Pastas @($pastaLib)
    if (@($d.NovosCandidatos).Count -ne 1) { throw "esperava 1 novo candidato, obtive $(@($d.NovosCandidatos).Count)" }
    $r = Invoke-BvReconciliacao -Descobertas $d
    if ($r.Duplicatas -ne 1) { throw "duplicatas deveria ser 1, obtive $($r.Duplicatas)" }
    if (@(Get-BvCatalogo).Count -ne 5) { throw "catalogo deveria ter 5 linhas, tem $(@(Get-BvCatalogo).Count)" }
    $hashCopia = (Get-BvIdentidade -Caminho (Join-Path $pastaLib 'copia.pdf')).sha256
    $ocorrencias = @(Get-BvLinhasPorHash -Sha256 $hashCopia)
    if ($ocorrencias.Count -ne 2) { throw "esperava 2 ocorrencias do mesmo hash, obtive $($ocorrencias.Count)" }
}

Test-BvVerificacao -Nome '11 Arquivo removido fica desaparecido sem sair do catalogo' -Bloco {
    Remove-Item -LiteralPath (Join-Path $pastaLib 'copia.pdf') -Force
    $d = Get-BvDescobertas -Modo 'migracao' -Pastas @($pastaLib)
    if (@($d.AusentesDoDisco).Count -ne 1) { throw "esperava 1 ausente, obtive $(@($d.AusentesDoDisco).Count)" }
    $r = Invoke-BvReconciliacao -Descobertas $d
    if ($r.Desaparecidos -ne 1) { throw "desaparecidos deveria ser 1, obtive $($r.Desaparecidos)" }
    if (@(Get-BvCatalogo).Count -ne 5) { throw 'linha desaparecida deve permanecer no catalogo' }
    $linhaCopia = @(Get-BvCatalogo) | Where-Object { $_.nome_original -eq 'copia.pdf' }
    if ($linhaCopia.status -ne 'desaparecido') { throw "status deveria ser desaparecido, esta $($linhaCopia.status)" }
}

Test-BvVerificacao -Nome '12 Varredura parcial nao marca ausentes fora do escopo' -Bloco {
    $pastaVazia = Join-Path $pastaRaiz 'vazio'
    New-Item -ItemType Directory -Path $pastaVazia -Force | Out-Null
    $dParcial = Get-BvDescobertas -Modo 'manutencao' -Pastas @($pastaVazia)
    if (@($dParcial.NovosCandidatos).Count -ne 0) { throw 'novos deveria ser 0' }
    if (@($dParcial.AusentesDoDisco).Count -ne 0) { throw 'ausentes fora do escopo nao deveriam aparecer' }
    $dCompleta = Get-BvDescobertas -Modo 'manutencao' -Pastas @($pastaLib)
    if (@($dCompleta.AusentesDoDisco).Count -ne 0) { throw 'varredura completa nao deveria ter ausentes' }
    if (@($dCompleta.Inalterados).Count -ne 3) { throw "inalterados deveria ser 3, obtive $(@($dCompleta.Inalterados).Count)" }
}

Test-BvVerificacao -Nome '13 Diario registra JSONL valido com todos os eventos' -Bloco {
    $registros = @(Get-BvDiario)
    if ($registros.Count -lt 7) { throw "diario com poucos registros: $($registros.Count)" }
    foreach ($registro in $registros) {
        if (-not $registro.quando -or -not $registro.evento) { throw 'registro incompleto no diario' }
    }
    foreach ($tipo in @('arquivo_novo', 'conteudo_substituido', 'movido_externamente', 'duplicata_detectada', 'desaparecido')) {
        $achou = @(Get-BvDiario | Where-Object { $_.evento -eq $tipo })
        if ($achou.Count -eq 0) { throw "evento ausente no diario: $tipo" }
    }
}

Test-BvVerificacao -Nome '14 Porta unica mantem unicidade e vocabulario (regressao)' -Bloco {
    $l1 = New-BvLinhaCatalogo
    $l1.sha256 = 'f' * 64
    $l1.caminho_atual = 'C:\qualquer\x.pdf'
    $l1.status = 'novo'
    $l2 = New-BvLinhaCatalogo
    $l2.sha256 = 'f' * 64
    $l2.caminho_atual = 'C:\qualquer\x.pdf'
    $l2.status = 'novo'
    $erroDuplicata = $null
    try { Save-BvCatalogo -Linhas @($l1, $l2) | Out-Null } catch { $erroDuplicata = $_.Exception.Message }
    if ($null -eq $erroDuplicata) { throw 'duplicata deveria ser recusada' }
    $l3 = New-BvLinhaCatalogo
    $l3.sha256 = 'e' * 64
    $l3.caminho_atual = 'C:\qualquer\y.pdf'
    $l3.status = 'status-inventado'
    $erroStatus = $null
    try { Save-BvCatalogo -Linhas @($l3) | Out-Null } catch { $erroStatus = $_.Exception.Message }
    if ($null -eq $erroStatus) { throw 'status invalido deveria ser recusado' }
    if (@(Get-BvCatalogo).Count -ne 5) { throw 'tentativas invalidas nao devem alterar o catalogo' }
}

if (Test-Path -LiteralPath $pastaRaiz) {
    Remove-Item -LiteralPath $pastaRaiz -Recurse -Force
}

if (Test-Path -LiteralPath $arquivoCatalogo) { Remove-Item -LiteralPath $arquivoCatalogo -Force }
if (Test-Path -LiteralPath $arquivoDiario) { Remove-Item -LiteralPath $arquivoDiario -Force }

Write-Host ''
Write-Host "Resultado: $script:aprovados passaram, $script:falhados falharam"
Write-Host 'dados\ local resetado apos os testes'

exit ($script:falhados -gt 0 ? 1 : 0)
