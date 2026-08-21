if (-not (Get-Command Get-BvConfig -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'config.ps1')
}
if (-not (Get-Command Get-BvRota -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'roteador.ps1')
}

function Get-BvPastaExtracoes {
    $cfg = Get-BvConfig
    $pasta = Join-Path $cfg.PastaDados $cfg.PastaExtracoes
    if (-not (Test-Path -LiteralPath $pasta)) {
        New-Item -ItemType Directory -Path $pasta -Force | Out-Null
    }
    return $pasta
}

function Invoke-BvExtracaoDeLinha {
    param([Parameter(Mandatory)][psobject]$Linha)

    $cfg = Get-BvConfig
    $pasta = Get-BvPastaExtracoes
    $caminhoTxt = Join-Path $pasta "$($Linha.id).txt"
    $caminhoJson = Join-Path $pasta "$($Linha.id).json"

    if ((Test-Path -LiteralPath $caminhoTxt) -and (Test-Path -LiteralPath $caminhoJson)) {
        try {
            $meta = Get-Content -LiteralPath $caminhoJson -Raw | ConvertFrom-Json
            if ($meta.sha256 -eq $Linha.sha256) {
                return [pscustomobject]@{
                    Ok          = $true
                    DoCache     = $true
                    CaminhoTexto = $caminhoTxt
                    Texto       = (Get-Content -LiteralPath $caminhoTxt -Raw)
                    Caracteres  = [int]$meta.caracteres
                    Paginas     = [int]$meta.paginas
                    PrecisaOcr  = ([bool]$meta.precisa_ocr)
                    PrecisaSenha = ([bool]$meta.precisa_senha)
                    Observacoes = @($meta.observacoes)
                }
            }
        }
        catch {
        }
    }

    $rota = Get-BvRota -Tipo $Linha.tipo
    if ($rota.Estado -ne 'ComModulo') {
        return [pscustomobject]@{
            Ok = $false; DoCache = $false; CaminhoTexto = ''; Texto = ''
            Caracteres = 0; Paginas = 0; PrecisaOcr = $false; PrecisaSenha = $false
            Observacoes = @("rota:$($rota.Estado)")
        }
    }

    . $rota.ScriptModulo
    $fichaModulo = Invoke-BvExtracao -Caminho $Linha.caminho_atual

    if ($fichaModulo.Ok) {
        Set-Content -LiteralPath $caminhoTxt -Value $fichaModulo.Texto -Encoding utf8 -NoNewline
        $meta = [ordered]@{
            sha256       = $Linha.sha256
            quando       = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            paginas      = $fichaModulo.Paginas
            caracteres   = $fichaModulo.Caracteres
            precisa_ocr  = $fichaModulo.PrecisaOcr
            precisa_senha = $fichaModulo.PrecisaSenha
            observacoes  = @($fichaModulo.Observacoes)
        }
        ($meta | ConvertTo-Json -Compress) | Set-Content -LiteralPath $caminhoJson -Encoding utf8
    }

    return [pscustomobject]@{
        Ok           = $fichaModulo.Ok
        DoCache      = $false
        CaminhoTexto = $(if ($fichaModulo.Ok) { $caminhoTxt } else { '' })
        Texto        = $fichaModulo.Texto
        Caracteres   = $fichaModulo.Caracteres
        Paginas      = $fichaModulo.Paginas
        PrecisaOcr   = $fichaModulo.PrecisaOcr
        PrecisaSenha = $fichaModulo.PrecisaSenha
        Observacoes  = @($fichaModulo.Observacoes)
    }
}
