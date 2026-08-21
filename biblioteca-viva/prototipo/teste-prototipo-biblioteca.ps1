$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'avaliador.ps1')

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

function New-BvProtoLinha {
    param([string]$Nome, [string]$Categoria, [double]$Confianca)
    return [pscustomobject]@{
        nome_original = $Nome; tipo = '.pdf'; categoria = $Categoria
        confianca = $Confianca; lote = 'lote-ficticio'
    }
}

Write-Host '=== Prototipo Biblioteca V1 - Testes ==='
Write-Host ''

$pastaTemp = Join-Path ([IO.Path]::GetTempPath()) 'bv-proto-teste'
if (Test-Path -LiteralPath $pastaTemp) { Remove-Item -LiteralPath $pastaTemp -Recurse -Force }
New-Item -ItemType Directory -Path $pastaTemp -Force | Out-Null

$bibliotecaExemplo = Read-BvProtoBiblioteca -Caminho (Join-Path $PSScriptRoot 'bibliotecas\biblioteca-exemplo\v1.json')

Test-BvVerificacao -Nome '01 Biblioteca exemplo carrega e passa na validacao' -Bloco {
    if ($bibliotecaExemplo.Documento.meta.nome -ne 'biblioteca-exemplo') { throw 'nome inesperado' }
    if (@($bibliotecaExemplo.Documento.regras).Count -ne 4) { throw 'deveria ter 4 regras' }
    if ($bibliotecaExemplo.CaminhoNo['n_fin_extratos'] -ne 'Financeiro/Extratos') { throw 'indice de nos incorreto' }
}

Test-BvVerificacao -Nome '02 Regra especifica vence a generica pela ordem' -Bloco {
    $linha = New-BvProtoLinha -Nome 'extrato-banco-exemplo-2026.pdf' -Categoria 'financeiro' -Confianca 0.92
    $r = Invoke-BvProtoAvaliacao -Biblioteca $bibliotecaExemplo -Linhas @($linha)
    if ($r.Count -ne 1) { throw "esperava 1 resultado, obtive $($r.Count)" }
    if ($r[0].regra -ne 'r_001') { throw "regra errada: $($r[0].regra)" }
    if ($r[0].destino -ne 'Financeiro/Extratos') { throw "destino errado: $($r[0].destino)" }
    if ($r[0].resultado -ne 'PROPOSTO') { throw "resultado errado: $($r[0].resultado)" }
}

Test-BvVerificacao -Nome '03 Regra generica aplica quando a especifica nao casa' -Bloco {
    $linha = New-BvProtoLinha -Nome 'fatura-cartao-exemplo.pdf' -Categoria 'financeiro' -Confianca 0.85
    $r = Invoke-BvProtoAvaliacao -Biblioteca $bibliotecaExemplo -Linhas @($linha)
    if ($r[0].regra -ne 'r_002') { throw "regra errada: $($r[0].regra)" }
    if ($r[0].destino -ne 'Financeiro/Geral') { throw "destino errado: $($r[0].destino)" }
}

Test-BvVerificacao -Nome '04 Condicao composta aceita com confianca alta' -Bloco {
    $linha = New-BvProtoLinha -Nome 'certidao-exemplo.pdf' -Categoria 'documento_pessoal' -Confianca 0.90
    $r = Invoke-BvProtoAvaliacao -Biblioteca $bibliotecaExemplo -Linhas @($linha)
    if ($r[0].regra -ne 'r_003') { throw "regra errada: $($r[0].regra)" }
    if ($r[0].destino -ne 'Documentos Pessoais') { throw "destino errado: $($r[0].destino)" }
}

Test-BvVerificacao -Nome '05 Condicao composta abaixo do limiar cai no fallback' -Bloco {
    $linha = New-BvProtoLinha -Nome 'documento-pessoal-generico.pdf' -Categoria 'documento_pessoal' -Confianca 0.50
    $r = Invoke-BvProtoAvaliacao -Biblioteca $bibliotecaExemplo -Linhas @($linha)
    if ($r[0].regra -ne '-') { throw "deveria ser fallback, foi $($r[0].regra)" }
    if ($r[0].resultado -ne 'PENDENTE_DE_REGRA') { throw "resultado errado: $($r[0].resultado)" }
    if ($r[0].destino -ne '') { throw 'fallback nao deveria propor destino' }
}

Test-BvVerificacao -Nome '06 Categoria sem regra vai para o fallback' -Bloco {
    $linha = New-BvProtoLinha -Nome 'receita-de-bolo-exemplo.txt' -Categoria 'religioso' -Confianca 0.70
    $r = Invoke-BvProtoAvaliacao -Biblioteca $bibliotecaExemplo -Linhas @($linha)
    if ($r[0].resultado -ne 'PENDENTE_DE_REGRA') { throw "resultado errado: $($r[0].resultado)" }
    if ($r[0].acao -ne 'nenhuma') { throw "acao do fallback deveria ser nenhuma" }
}

function New-BvProtoJsonInvalido {
    param([string]$Conteudo, [string]$Arquivo)
    $caminho = Join-Path $pastaTemp $Arquivo
    Set-Content -LiteralPath $caminho -Value $Conteudo -Encoding utf8
    return $caminho
}

Test-BvVerificacao -Nome '07 Destino inexistente e recusado na validacao' -Bloco {
    $caminho = New-BvProtoJsonInvalido -Arquivo 'destino-fantasma.json' -Conteudo @'
{
  "meta": { "nome": "x", "versao": 1, "status": "aprovada" },
  "taxonomia": { "origem": "config", "versao_esquema": 1 },
  "nos": [ { "id": "n_a", "caminho": "A", "descricao": "" } ],
  "regras": [ { "id": "r_x", "descricao": "", "quando": { "todos": [ { "campo": "categoria", "operador": "igual", "valor": "outro" } ] }, "entao": { "destino": "n_fantasma" } } ]
}
'@
    $erro = $null
    try { Read-BvProtoBiblioteca -Caminho $caminho | Out-Null } catch { $erro = $_.Exception.Message }
    if (-not $erro) { throw 'validacao deveria ter recusado' }
    if ($erro -notmatch 'destino inexistente') { throw "erro inesperado: $erro" }
}

Test-BvVerificacao -Nome '08 Operador fora da whitelist e recusado' -Bloco {
    $caminho = New-BvProtoJsonInvalido -Arquivo 'operador-invalido.json' -Conteudo @'
{
  "meta": { "nome": "x", "versao": 1, "status": "aprovada" },
  "taxonomia": { "origem": "config", "versao_esquema": 1 },
  "nos": [ { "id": "n_a", "caminho": "A", "descricao": "" } ],
  "regras": [ { "id": "r_x", "descricao": "", "quando": { "todos": [ { "campo": "categoria", "operador": "parecido", "valor": "a" } ] }, "entao": { "destino": "n_a" } } ]
}
'@
    $erro = $null
    try { Read-BvProtoBiblioteca -Caminho $caminho | Out-Null } catch { $erro = $_.Exception.Message }
    if (-not $erro) { throw 'validacao deveria ter recusado' }
    if ($erro -notmatch 'operador nao permitido') { throw "erro inesperado: $erro" }
}

Test-BvVerificacao -Nome '09 Campo fora da whitelist e recusado' -Bloco {
    $caminho = New-BvProtoJsonInvalido -Arquivo 'campo-invalido.json' -Conteudo @'
{
  "meta": { "nome": "x", "versao": 1, "status": "aprovada" },
  "taxonomia": { "origem": "config", "versao_esquema": 1 },
  "nos": [ { "id": "n_a", "caminho": "A", "descricao": "" } ],
  "regras": [ { "id": "r_x", "descricao": "", "quando": { "todos": [ { "campo": "segredo_interno", "operador": "igual", "valor": "a" } ] }, "entao": { "destino": "n_a" } } ]
}
'@
    $erro = $null
    try { Read-BvProtoBiblioteca -Caminho $caminho | Out-Null } catch { $erro = $_.Exception.Message }
    if (-not $erro) { throw 'validacao deveria ter recusado' }
    if ($erro -notmatch 'campo fora da whitelist') { throw "erro inesperado: $erro" }
}

Test-BvVerificacao -Nome '10 Ordem das regras define prioridade (inverter muda o resultado)' -Bloco {
    $jsonInvertida = @'
{
  "meta": { "nome": "invertida", "versao": 1, "status": "aprovada" },
  "taxonomia": { "origem": "config", "versao_esquema": 1 },
  "nos": [
    { "id": "n_extratos", "caminho": "Financeiro/Extratos", "descricao": "" },
    { "id": "n_geral", "caminho": "Financeiro/Geral", "descricao": "" }
  ],
  "regras": [
    { "id": "r_generica", "descricao": "", "quando": { "todos": [ { "campo": "categoria", "operador": "igual", "valor": "financeiro" } ] }, "entao": { "destino": "n_geral" } },
    { "id": "r_especifica", "descricao": "", "quando": { "todos": [ { "campo": "categoria", "operador": "igual", "valor": "financeiro" }, { "campo": "nome_original", "operador": "contem", "valor": "extrato" } ] }, "entao": { "destino": "n_extratos" } }
  ]
}
'@
    $caminho = New-BvProtoJsonInvalido -Arquivo 'ordem-invertida.json' -Conteudo $jsonInvertida
    $invertida = Read-BvProtoBiblioteca -Caminho $caminho
    $linha = New-BvProtoLinha -Nome 'extrato-banco-exemplo-2026.pdf' -Categoria 'financeiro' -Confianca 0.92
    $r = Invoke-BvProtoAvaliacao -Biblioteca $invertida -Linhas @($linha)
    if ($r[0].regra -ne 'r_generica') { throw "deveria casar a generica primeiro, foi $($r[0].regra)" }
    if ($r[0].destino -ne 'Financeiro/Geral') { throw "destino deveria ser Geral, foi $($r[0].destino)" }
}

Test-BvVerificacao -Nome '11 Operador em aceita valor dentro da lista' -Bloco {
    if (-not (Test-BvProtoPredicado -Valor 'financeiro' -Operador 'em' -Esperado @('financeiro', 'tributario'))) { throw 'deveria casar' }
}

Test-BvVerificacao -Nome '12 Operador em recusa valor fora da lista' -Bloco {
    if (Test-BvProtoPredicado -Valor 'contabil' -Operador 'em' -Esperado @('financeiro', 'tributario')) { throw 'nao deveria casar' }
}

Test-BvVerificacao -Nome '13 Operadores vazio e nao_vazio tratam campo ausente' -Bloco {
    if (-not (Test-BvProtoPredicado -Valor $null -Operador 'vazio' -Esperado $null)) { throw 'nulo deveria ser vazio' }
    if (-not (Test-BvProtoPredicado -Valor '' -Operador 'vazio' -Esperado $null)) { throw 'branco deveria ser vazio' }
    if (Test-BvProtoPredicado -Valor $null -Operador 'nao_vazio' -Esperado $null) { throw 'nao_vazio deveria ser falso para nulo' }
}

Test-BvVerificacao -Nome '14 menor_igual converte string numerica com cultura invariante' -Bloco {
    if (-not (Test-BvProtoPredicado -Valor '0.45' -Operador 'menor_igual' -Esperado '0.5')) { throw '0.45 deveria ser <= 0.5' }
    if (Test-BvProtoPredicado -Valor '0.9' -Operador 'menor_igual' -Esperado '0.5') { throw '0.9 nao deveria ser <= 0.5' }
}

Test-BvVerificacao -Nome '15 Operador diferente compara textos sem case' -Bloco {
    if (-not (Test-BvProtoPredicado -Valor 'PDF' -Operador 'diferente' -Esperado 'txt')) { throw 'PDF deveria diferir de txt' }
    if (Test-BvProtoPredicado -Valor 'pdf' -Operador 'diferente' -Esperado 'PDF') { throw 'case-insensivel: pdf nao deveria diferir de PDF' }
}

Test-BvVerificacao -Nome '16 Campo detalhes.chave e lido quando presente' -Bloco {
    $linha = [pscustomobject]@{ nome_original = 'x.pdf'; detalhes = [pscustomobject]@{ paginas = 12 } }
    $valor = Get-BvProtoCampo -Linha $linha -Campo 'detalhes.paginas'
    if ([string]$valor -ne '12') { throw "esperava 12, obtive '$valor'" }
}

Test-BvVerificacao -Nome '17 Campo detalhes ausente e tratado como vazio' -Bloco {
    $linha = [pscustomobject]@{ nome_original = 'y.pdf' }
    $valor = Get-BvProtoCampo -Linha $linha -Campo 'detalhes.paginas'
    if ($null -ne $valor) { throw 'deveria retornar nulo' }
    if (-not (Test-BvProtoPredicado -Valor $valor -Operador 'vazio' -Esperado $null)) { throw 'ausencia deveria contar como vazio' }
}

Test-BvVerificacao -Nome '18 Biblioteca em rascunho e recusada pelo carregador (D5)' -Bloco {
    $caminho = New-BvProtoJsonInvalido -Arquivo 'rascunho.json' -Conteudo @'
{
  "meta": { "nome": "em-rascunho", "versao": 1, "status": "rascunho" },
  "taxonomia": { "origem": "config", "versao_esquema": 1 },
  "nos": [ { "id": "n_a", "caminho": "A", "descricao": "" } ],
  "regras": [ { "id": "r_x", "descricao": "", "quando": { "todos": [ { "campo": "categoria", "operador": "igual", "valor": "a" } ] }, "entao": { "destino": "n_a" } } ]
}
'@
    $erro = $null
    try { Read-BvProtoBiblioteca -Caminho $caminho | Out-Null } catch { $erro = $_.Exception.Message }
    if (-not $erro) { throw 'carregamento deveria ter recusado o rascunho' }
    if ($erro -notmatch "nao e 'aprovada'") { throw "erro inesperado: $erro" }
}

Test-BvVerificacao -Nome '19 Campo ausente so casa com vazio (D3)' -Bloco {
    foreach ($op in @('igual', 'diferente', 'contem', 'em')) {
        if (Test-BvProtoPredicado -Valor $null -Operador $op -Esperado 'qualquer') { throw "$op deveria ser falso para campo ausente" }
    }
    if (Test-BvProtoPredicado -Valor $null -Operador 'maior_igual' -Esperado 0) { throw 'maior_igual deveria ser falso para campo ausente' }
    if (-not (Test-BvProtoPredicado -Valor $null -Operador 'vazio' -Esperado $null)) { throw 'vazio deveria ser verdadeiro para campo ausente' }
    if (Test-BvProtoPredicado -Valor $null -Operador 'nao_vazio' -Esperado $null) { throw 'nao_vazio deveria ser falso para campo ausente' }
}

if (Test-Path -LiteralPath $pastaTemp) { Remove-Item -LiteralPath $pastaTemp -Recurse -Force }

Write-Host ''
Write-Host "Resultado: $script:aprovados passaram, $script:falhados falharam"

exit ($script:falhados -gt 0 ? 1 : 0)
