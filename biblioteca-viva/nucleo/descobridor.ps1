if (-not (Get-Command Get-BvConfig -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'config.ps1')
}
if (-not (Get-Command Get-BvCatalogo -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'catalogo.ps1')
}

function Get-BvIndiceCatalogo {
    $porCaminho = @{}
    $porHash = @{}
    foreach ($linha in @(Get-BvCatalogo)) {
        $ativa = (-not $linha.substituido_por) -and ($linha.status -ne 'desaparecido')
        if ($ativa -and $linha.caminho_atual) {
            $porCaminho[$linha.caminho_atual.ToLowerInvariant()] = $linha
        }
        if ($linha.sha256) {
            $chaveHash = $linha.sha256.ToLowerInvariant()
            if (-not $porHash.ContainsKey($chaveHash)) { $porHash[$chaveHash] = @() }
            $porHash[$chaveHash] += $linha
        }
    }
    return [pscustomobject]@{ PorCaminho = $porCaminho; PorHash = $porHash }
}

function Get-BvArquivosDisco {
    param([Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Pastas)

    $encontrados = @()
    foreach ($pasta in $Pastas) {
        if (-not (Test-Path -LiteralPath $pasta -PathType Container)) { continue }
        $encontrados += @(Get-ChildItem -LiteralPath $pasta -Recurse -File -Force |
            Where-Object { $_.FullName -notmatch '\\dados(\\|$)' -and $_.Extension -ne '.tmp' } |
            ForEach-Object {
                [pscustomobject]@{
                    caminho_atual = $_.FullName
                    nome          = $_.Name
                    tamanho_bytes = $_.Length
                    modificado_em = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
                    tipo          = $_.Extension.ToLowerInvariant()
                }
            })
    }
    return $encontrados
}

function Get-BvDescobertas {
    param(
        [string]$Modo = '',
        [string[]]$Pastas = @()
    )

    $cfg = Get-BvConfig
    if (-not $Modo) { $Modo = $cfg.ModoPadrao }
    if ($cfg.ModosValidos -notcontains $Modo) {
        throw "Modo invalido: '$Modo'. Modos validos: $($cfg.ModosValidos -join ', ')"
    }

    $aviso = ''
    if (@($Pastas).Count -eq 0) {
        if ($Modo -eq 'migracao') { $Pastas = @($cfg.PastasMigracao) }
        else { $Pastas = @($cfg.PastasManutencao) }
    }
    if (@($Pastas).Count -eq 0) {
        $aviso = "Nenhuma pasta configurada para o modo '$Modo'."
    }

    $indice = Get-BvIndiceCatalogo
    $noDisco = @(Get-BvArquivosDisco -Pastas $Pastas)

    $novos = @()
    $suspeitos = @()
    $inalterados = @()
    $caminhosVistos = @{}

    foreach ($arquivo in $noDisco) {
        $chave = $arquivo.caminho_atual.ToLowerInvariant()
        $caminhosVistos[$chave] = $true
        $linha = $indice.PorCaminho[$chave]
        if (-not $linha) {
            $novos += $arquivo
        }
        elseif ([string]$linha.tamanho_bytes -eq [string]$arquivo.tamanho_bytes -and $linha.modificado_em -eq $arquivo.modificado_em) {
            $inalterados += $arquivo
        }
        else {
            $suspeitos += $arquivo
        }
    }

    $raizes = @($Pastas | ForEach-Object { $_.TrimEnd('\').ToLowerInvariant() })
    $ausentes = @(
        $indice.PorCaminho.Values | Where-Object {
            $caminhoLinha = $_.caminho_atual.ToLowerInvariant()
            $dentroEscopo = $false
            foreach ($raiz in $raizes) {
                if ($caminhoLinha -eq $raiz -or $caminhoLinha.StartsWith("$raiz\")) {
                    $dentroEscopo = $true
                    break
                }
            }
            $dentroEscopo -and (-not $caminhosVistos.ContainsKey($caminhoLinha))
        }
    )

    return [pscustomobject]@{
        Modo            = $Modo
        Pastas          = @($Pastas)
        NovosCandidatos = @($novos)
        Suspeitos       = @($suspeitos)
        Inalterados     = @($inalterados)
        AusentesDoDisco = @($ausentes)
        Aviso           = $aviso
    }
}
