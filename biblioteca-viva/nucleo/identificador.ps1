if (-not (Get-Command Get-BvConfig -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'config.ps1')
}

function Get-BvStatLeve {
    param([Parameter(Mandatory)][string]$Caminho)

    if (-not (Test-Path -LiteralPath $Caminho -PathType Leaf)) {
        throw "Arquivo nao encontrado: $Caminho"
    }
    $item = Get-Item -LiteralPath $Caminho
    return [pscustomobject]@{
        caminho_atual = $item.FullName
        nome          = $item.Name
        tamanho_bytes = $item.Length
        modificado_em = $item.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
        tipo          = $item.Extension.ToLowerInvariant()
    }
}

function Get-BvIdentidade {
    param([Parameter(Mandatory)][string]$Caminho)

    $stat = Get-BvStatLeve -Caminho $Caminho
    $hash = (Get-FileHash -LiteralPath $Caminho -Algorithm SHA256).Hash.ToLowerInvariant()
    $cfg = Get-BvConfig
    return [pscustomobject]@{
        id             = $hash.Substring(0, [Math]::Min($cfg.TamanhoId, $hash.Length))
        sha256         = $hash
        nome_original  = $stat.nome
        pasta_original = Split-Path -Parent $stat.caminho_atual
        caminho_atual  = $stat.caminho_atual
        tamanho_bytes  = $stat.tamanho_bytes
        modificado_em  = $stat.modificado_em
        tipo           = $stat.tipo
    }
}
