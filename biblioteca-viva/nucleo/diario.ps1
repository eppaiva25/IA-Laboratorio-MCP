if (-not (Get-Command Get-BvConfig -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'config.ps1')
}

function Get-BvArquivoDiario {
    $cfg = Get-BvConfig
    return (Join-Path $cfg.PastaDados $cfg.NomeArquivoDiario)
}

function Add-BvRegistroDiario {
    param(
        [Parameter(Mandatory)][string]$Evento,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Id,
        [hashtable]$Detalhe = @{}
    )

    $arquivo = Get-BvArquivoDiario
    $pasta = Split-Path -Parent $arquivo
    if (-not (Test-Path -LiteralPath $pasta)) {
        New-Item -ItemType Directory -Path $pasta -Force | Out-Null
    }

    $registro = [ordered]@{
        quando = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        evento = $Evento
        id     = $Id
    }
    foreach ($chave in $Detalhe.Keys) { $registro[$chave] = $Detalhe[$chave] }

    ($registro | ConvertTo-Json -Compress) | Add-Content -LiteralPath $arquivo -Encoding utf8
    return $arquivo
}

function Get-BvDiario {
    $arquivo = Get-BvArquivoDiario
    if (-not (Test-Path -LiteralPath $arquivo)) { return @() }
    $linhas = @(Get-Content -LiteralPath $arquivo | Where-Object { $_.Trim() })
    if ($linhas.Count -eq 0) { return @() }
    return @($linhas | ForEach-Object { $_ | ConvertFrom-Json })
}
