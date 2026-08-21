if (-not (Get-Command Get-BvConfig -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot '..\nucleo\config.ps1')
}

function Get-BvPdfJanela {
    param(
        [Parameter(Mandatory)][string]$Caminho,
        [Parameter(Mandatory)][bool]$DoInicio,
        [Parameter(Mandatory)][int]$Tamanho
    )

    $fluxo = [IO.File]::OpenRead($Caminho)
    try {
        if (-not $DoInicio) {
            $posicao = [Math]::Max(0, $fluxo.Length - $Tamanho)
            $null = $fluxo.Seek($posicao, [IO.SeekOrigin]::Begin)
        }
        $disponivel = [int][Math]::Min($Tamanho, $fluxo.Length - $fluxo.Position)
        if ($disponivel -le 0) { return [byte[]]@() }
        $buffer = New-Object byte[] $disponivel
        $lidos = 0
        while ($lidos -lt $disponivel) {
            $parcial = $fluxo.Read($buffer, $lidos, $disponivel - $lidos)
            if ($parcial -le 0) { break }
            $lidos += $parcial
        }
        if ($lidos -eq $disponivel) { return $buffer }
        if ($lidos -le 0) { return [byte[]]@() }
        return $buffer[0..($lidos - 1)]
    }
    finally {
        $fluxo.Dispose()
    }
}

function Invoke-BvAnalise {
    param([Parameter(Mandatory)][string]$Caminho)

    if (-not (Test-Path -LiteralPath $Caminho -PathType Leaf)) {
        throw "Arquivo nao encontrado: $Caminho"
    }

    $cfg = Get-BvConfig
    $item = Get-Item -LiteralPath $Caminho
    $analiseLeve = $item.Length -gt ([long]$cfg.LimiteAnaliseLeveMb * 1MB)

    $janelaBytes = 64KB
    $cabecalho = [Text.Encoding]::ASCII.GetString((Get-BvPdfJanela -Caminho $Caminho -DoInicio $true -Tamanho $janelaBytes))
    $rodape = [Text.Encoding]::ASCII.GetString((Get-BvPdfJanela -Caminho $Caminho -DoInicio $false -Tamanho $janelaBytes))

    $alertas = @()
    $legivel = $cabecalho.StartsWith('%PDF-') -and $rodape.Contains('%%EOF')
    if (-not $legivel) { $alertas += 'malformado' }

    $versaoPdf = ''
    $casamentoVersao = [regex]::Match($cabecalho, '%PDF-(\d\.\d)')
    if ($casamentoVersao.Success) { $versaoPdf = $casamentoVersao.Groups[1].Value }

    if ($analiseLeve) {
        $corpoBusca = $cabecalho + "`r`n" + $rodape
    }
    else {
        $corpoBusca = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($Caminho))
    }

    $criptografado = [regex]::IsMatch($corpoBusca, '/Encrypt(?![A-Za-z])')
    if ($criptografado) { $alertas += 'criptografado' }

    $paginas = [regex]::Matches($corpoBusca, '/Type\s*/Page(?![A-Za-z])').Count

    $temFonte = $corpoBusca.Contains('/Font')

    $produtor = ''
    $casamentoProdutor = [regex]::Match($corpoBusca, '/Producer\s*\(([^)]*)\)')
    if ($casamentoProdutor.Success) {
        $produtor = $casamentoProdutor.Groups[1].Value.Trim()
        if ($produtor.Length -gt 100) { $produtor = $produtor.Substring(0, 100) }
    }

    if ($legivel -and -not $temFonte) { $alertas += 'provavel_scan' }
    if ($legivel -and $paginas -eq 0) { $alertas += 'estrutura_comprimida' }
    if ($analiseLeve) { $alertas += 'analise_leve' }

    $detalhes = [ordered]@{
        versao_pdf    = $versaoPdf
        paginas       = $paginas
        tem_fonte     = $temFonte
        criptografado = $criptografado
        produtor      = $produtor
        analise_leve  = $analiseLeve
        tamanho_bytes = $item.Length
    }

    return [pscustomobject]@{
        Tipo            = '.pdf'
        Legivel         = $legivel
        Alertas         = @($alertas)
        DetalhesJson    = ($detalhes | ConvertTo-Json -Compress)
        AmostraConteudo = ''
    }
}

function Invoke-BvExtracao {
    param([Parameter(Mandatory)][string]$Caminho)

    if (-not (Test-Path -LiteralPath $Caminho -PathType Leaf)) {
        throw "Arquivo nao encontrado: $Caminho"
    }

    $scriptPonte = Join-Path $PSScriptRoot '..\externo\extrator_pdf.py'
    $arquivoTemp = [IO.Path]::GetTempFileName()

    try {
        $saidaBruta = & python $scriptPonte $Caminho $arquivoTemp 2>&1
        $json = $null
        try { $json = ($saidaBruta | Out-String).Trim() | ConvertFrom-Json } catch { }

        if ($null -eq $json) {
            return [pscustomobject]@{
                Ok = $false; Texto = ''; Caracteres = 0; Paginas = 0
                PrecisaOcr = $false; PrecisaSenha = $false
                Observacoes = @('ponte_python_falhou')
            }
        }

        $observacoes = @($json.observacoes)
        $texto = ''
        if ($json.ok -and (Test-Path -LiteralPath $arquivoTemp)) {
            $texto = Get-Content -LiteralPath $arquivoTemp -Raw
        }

        return [pscustomobject]@{
            Ok           = [bool]$json.ok
            Texto        = $texto
            Caracteres   = [int]$json.caracteres
            Paginas      = [int]$json.paginas
            PrecisaOcr   = ($observacoes -contains 'texto_insuficiente')
            PrecisaSenha = ($observacoes -contains 'precisa_senha')
            Observacoes  = $observacoes
        }
    }
    catch {
        return [pscustomobject]@{
            Ok = $false; Texto = ''; Caracteres = 0; Paginas = 0
            PrecisaOcr = $false; PrecisaSenha = $false
            Observacoes = @("erro:$($_.Exception.Message)")
        }
    }
    finally {
        if (Test-Path -LiteralPath $arquivoTemp) {
            Remove-Item -LiteralPath $arquivoTemp -Force -ErrorAction SilentlyContinue
        }
    }
}
