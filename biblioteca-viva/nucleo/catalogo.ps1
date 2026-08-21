if (-not (Get-Command Get-BvConfig -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'config.ps1')
}

function Get-BvColunasCatalogo {
    return @(
        'id',
        'sha256',
        'nome_original',
        'pasta_original',
        'caminho_atual',
        'tamanho_bytes',
        'modificado_em',
        'visto_em',
        'tipo',
        'status',
        'categoria',
        'confianca',
        'nome_sugerido',
        'motivo',
        'classificado_por',
        'modelo',
        'lote',
        'processado_em',
        'acao_proposta',
        'destino_proposto',
        'aprovado',
        'executado_em',
        'verificado',
        'observacoes',
        'detalhes',
        'substituido_por'
    )
}

function Get-BvArquivoCatalogo {
    $cfg = Get-BvConfig
    return (Join-Path $cfg.PastaDados $cfg.NomeArquivoCatalogo)
}

function Initialize-BvCatalogo {
    $cfg = Get-BvConfig
    if (-not (Test-Path -LiteralPath $cfg.PastaDados)) {
        New-Item -ItemType Directory -Path $cfg.PastaDados -Force | Out-Null
    }
    $arquivoEsquema = Join-Path $cfg.PastaDados $cfg.NomeArquivoEsquema
    if (-not (Test-Path -LiteralPath $arquivoEsquema)) {
        [pscustomobject]@{
            versao_esquema = $cfg.VersaoEsquema
            criado_em      = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        } | ConvertTo-Json | Set-Content -LiteralPath $arquivoEsquema -Encoding utf8
    }
    else {
        $esquemaAtual = Get-Content -LiteralPath $arquivoEsquema -Raw | ConvertFrom-Json
        if ([int]$esquemaAtual.versao_esquema -ne [int]$cfg.VersaoEsquema) {
            throw "Versao do esquema no disco ($($esquemaAtual.versao_esquema)) difere da esperada pelo codigo ($($cfg.VersaoEsquema)). Execute a migracao correspondente antes de continuar."
        }
    }
    $arquivo = Get-BvArquivoCatalogo
    if (-not (Test-Path -LiteralPath $arquivo)) {
        Set-Content -LiteralPath $arquivo -Value ('"' + (@(Get-BvColunasCatalogo) -join '","') + '"') -Encoding utf8
    }
    return $arquivo
}

function Get-BvCatalogo {
    $arquivo = Initialize-BvCatalogo
    $esperadas = @(Get-BvColunasCatalogo)
    $objetos = Import-Csv -LiteralPath $arquivo
    $linhas = if ($null -eq $objetos) { @() } else { @($objetos) }
    if ($linhas.Count -gt 0) {
        $recebidas = @($linhas[0].PSObject.Properties.Name)
        $diferencas = @(Compare-Object -ReferenceObject $esperadas -DifferenceObject $recebidas)
        if ($diferencas.Count -gt 0) {
            throw "Cabecalho do catalogo diverge do esquema esperado. Divergencias: $(($diferencas | ForEach-Object { $_.InputObject }) -join ', ')"
        }
    }
    return $linhas
}

function New-BvLinhaCatalogo {
    $registro = [ordered]@{}
    foreach ($coluna in @(Get-BvColunasCatalogo)) { $registro[$coluna] = '' }
    return [pscustomobject]$registro
}

function Save-BvCatalogo {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Linhas
    )

    $cfg = Get-BvConfig
    $esperadas = @(Get-BvColunasCatalogo)

    $normalizadas = foreach ($linha in @($Linhas)) {
        $registro = [ordered]@{}
        foreach ($coluna in $esperadas) {
            $valor = $linha.$coluna
            $registro[$coluna] = if ($null -ne $valor) { [string]$valor } else { '' }
        }
        [pscustomobject]$registro
    }
    $normalizadas = @($normalizadas)

    foreach ($linha in $normalizadas) {
        if ($linha.status -and ($cfg.StatusValidos -notcontains $linha.status)) {
            throw "Status desconhecido: '$($linha.status)'. Status validos: $($cfg.StatusValidos -join ', ')"
        }
    }

    $ocupados = @{}
    foreach ($linha in $normalizadas) {
        if ($linha.sha256 -and $linha.caminho_atual -and -not $linha.substituido_por) {
            $chave = "$($linha.sha256)|$($linha.caminho_atual)".ToLowerInvariant()
            if ($ocupados.ContainsKey($chave)) {
                throw "Ocorrencia duplicada (sha256 + caminho_atual): $($linha.caminho_atual)"
            }
            $ocupados[$chave] = $true
        }
    }

    $arquivo = Initialize-BvCatalogo
    $temporario = "$arquivo.tmp"
    if ($normalizadas.Count -eq 0) {
        Set-Content -LiteralPath $temporario -Value ('"' + ($esperadas -join '","') + '"') -Encoding utf8
    }
    else {
        $normalizadas | Export-Csv -LiteralPath $temporario -NoTypeInformation -Encoding utf8
    }
    Move-Item -LiteralPath $temporario -Destination $arquivo -Force
    return $arquivo
}

function Get-BvLinhaPorCaminho {
    param(
        [Parameter(Mandatory)][string]$Caminho,
        [switch]$IncluirSubstituidas
    )
    $alvo = $Caminho.ToLowerInvariant()
    foreach ($linha in @(Get-BvCatalogo)) {
        if ($linha.caminho_atual -and ($linha.caminho_atual.ToLowerInvariant() -eq $alvo)) {
            if (-not $IncluirSubstituidas -and $linha.substituido_por) { continue }
            return $linha
        }
    }
    return $null
}

function Get-BvLinhasPorHash {
    param([Parameter(Mandatory)][string]$Sha256)
    $alvo = $Sha256.ToLowerInvariant()
    $encontradas = @( @(Get-BvCatalogo) | Where-Object { $_.sha256 -eq $alvo } )
    return $encontradas
}
