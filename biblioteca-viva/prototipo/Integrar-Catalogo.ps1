#!/usr/bin/env pwsh
# Wrapper de integração Biblioteca V1 mínima - apenas leitura
# Este script conecta o avaliador do protótipo V1 às linhas reais do catálogo
# sem misturar os dois conceitos e sem alterar nenhum arquivo do núcleo.

$ErrorActionPreference = 'Stop'

# Configurar caminho para o núcleo
$pastaNucleo = Join-Path $PSScriptRoot '..\nucleo'

# ----------------------------------------------------------
# 1) Carregar núcleo para Get-BvCatalogo (se não já carregado)
# ----------------------------------------------------------
if (-not (Get-Command Get-BvConfig -ErrorAction SilentlyContinue)) {
    . (Join-Path $pastaNucleo 'config.ps1')
}
if (-not (Get-Command Get-BvCatalogo -ErrorAction SilentlyContinue)) {
    . (Join-Path $pastaNucleo 'catalogo.ps1')
}

# ----------------------------------------------------------
# 2) Carregar avaliador (isolado do núcleo)
# ----------------------------------------------------------
. (Join-Path $PSScriptRoot 'avaliador.ps1')

# ----------------------------------------------------------
# 3) Carregar biblioteca JSON de exemplo (já aprovada)
# ----------------------------------------------------------
$bibliotecaJsonPath = Join-Path $PSScriptRoot 'bibliotecas\biblioteca-exemplo\v1.json'
$biblioteca = Read-BvProtoBiblioteca -Caminho $bibliotecaJsonPath

# ----------------------------------------------------------
# 4) Obter linhas reais do catálogo (somente leitura)
# ----------------------------------------------------------
$linhasReais = Get-BvCatalogo
"Linhas reais do catálogo carregadas: $($linhasReais.Count)"

# ----------------------------------------------------------
# 5) Avaliar usando o avaliador isolado (mantendo Biblioteca e Catálogo separados)
# ----------------------------------------------------------
if ($linhasReais.Count -gt 0) {
    $resultados = Invoke-BvProtoAvaliacao -Biblioteca $biblioteca -Linhas $linhasReais
    "Resultados produzidos: $($resultados.Count)"

    # ----------------------------------------------------------
    # 6) Mostrar relatório
    # ----------------------------------------------------------
    Show-BvProtoRelatorio -Resultados $resultados
}
else {
    Write-Host 'Nenhuma linha no catálogo — nada a avaliar.'
}

# ----------------------------------------------------------
# 7) CONCLUÍDO: O wrapper executou SOMENTE leitura e avaliação,
#    sem modificar o núcleo, a Biblioteca ou o catálogo.
# ----------------------------------------------------------
"Wrapper Integrar-Catalogo concluído."