if (-not (Get-Command Get-BvConfig -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'config.ps1')
}
if (-not (Get-Command Get-BvCatalogo -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'catalogo.ps1')
}
if (-not (Get-Command Get-BvIdentidade -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'identificador.ps1')
}
if (-not (Get-Command Get-BvRota -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'roteador.ps1')
}
if (-not (Get-Command Add-BvRegistroDiario -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'diario.ps1')
}

function New-BvLinhaDeIdentidade {
    param(
        [Parameter(Mandatory)][pscustomobject]$Identidade,
        [string]$Observacoes = ''
    )

    $agora = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $rota = Get-BvRota -Tipo $Identidade.tipo

    $status = '_REVISAR'
    $detalhesJson = ''
    $anotacoes = @()
    if ($Observacoes) { $anotacoes += $Observacoes }

    if ($rota.Estado -eq 'ComModulo') {
        . $rota.ScriptModulo
        $ficha = Invoke-BvAnalise -Caminho $Identidade.caminho_atual
        $detalhesJson = $ficha.DetalhesJson
        if (-not $ficha.Legivel) {
            $status = '_PROBLEMAS'
            $anotacoes += (@($ficha.Alertas) -join ', ')
        }
        elseif (@($ficha.Alertas).Count -gt 0) {
            $status = '_REVISAR'
            $anotacoes += (@($ficha.Alertas) -join ', ')
        }
        else {
            $status = 'inventariado'
        }
    }
    else {
        $anotacoes += "rota:$($rota.Estado)"
    }

    $linha = New-BvLinhaCatalogo
    $linha.id             = $Identidade.id
    $linha.sha256         = $Identidade.sha256
    $linha.nome_original  = $Identidade.nome_original
    $linha.pasta_original = $Identidade.pasta_original
    $linha.caminho_atual  = $Identidade.caminho_atual
    $linha.tamanho_bytes  = $Identidade.tamanho_bytes
    $linha.modificado_em  = $Identidade.modificado_em
    $linha.visto_em       = $agora
    $linha.tipo           = $Identidade.tipo
    $linha.status         = $status
    $linha.detalhes       = $detalhesJson
    $linha.observacoes    = ($anotacoes -join '; ')
    return $linha
}

function Invoke-BvReconciliacao {
    param(
        [Parameter(Mandatory)][pscustomobject]$Descobertas,
        [int]$CheckpointACada = 0
    )

    $agora = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

    $resumo = [ordered]@{
        Novos                = 0
        Movidos              = 0
        Duplicatas           = 0
        MetadadosAtualizados = 0
        Substituidos         = 0
        Desaparecidos        = 0
        Inalterados          = @($Descobertas.Inalterados).Count
        Erros                = 0
    }

    $linhas = @(Get-BvCatalogo)

    $porCaminho = @{}
    $porHash = @{}
    foreach ($linha in $linhas) {
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

    $ausentesPendentes = @{}
    foreach ($linhaAusente in @($Descobertas.AusentesDoDisco)) {
        $ausentesPendentes[$linhaAusente.caminho_atual.ToLowerInvariant()] = $true
    }

    $contadorProcessados = 0

    foreach ($candidato in @($Descobertas.NovosCandidatos)) {
        try {
            $identidade = Get-BvIdentidade -Caminho $candidato.caminho_atual
        }
        catch {
            $resumo.Erros++
            $null = Add-BvRegistroDiario -Evento 'erro_identificacao' -Id '' -Detalhe @{ caminho = $candidato.caminho_atual; erro = $_.Exception.Message }
            continue
        }

        $chaveHash = $identidade.sha256.ToLowerInvariant()
        $ativos = @()
        if ($porHash.ContainsKey($chaveHash)) {
            $ativos = @($porHash[$chaveHash] | Where-Object { (-not $_.substituido_por) -and ($_.status -ne 'desaparecido') })
        }
        $candidatosMovimento = @($ativos | Where-Object { $ausentesPendentes.ContainsKey($_.caminho_atual.ToLowerInvariant()) })

        if ($ativos.Count -eq 1 -and $candidatosMovimento.Count -eq 1) {
            $linhaOriginal = $candidatosMovimento[0]
            $caminhoAnterior = $linhaOriginal.caminho_atual
            $linhaOriginal.caminho_atual = $identidade.caminho_atual
            $linhaOriginal.tamanho_bytes = $identidade.tamanho_bytes
            $linhaOriginal.modificado_em = $identidade.modificado_em
            $linhaOriginal.visto_em      = $agora
            $null = $ausentesPendentes.Remove($caminhoAnterior.ToLowerInvariant())
            $null = $porCaminho.Remove($caminhoAnterior.ToLowerInvariant())
            $porCaminho[$identidade.caminho_atual.ToLowerInvariant()] = $linhaOriginal
            $resumo.Movidos++
            $null = Add-BvRegistroDiario -Evento 'movido_externamente' -Id $linhaOriginal.id -Detalhe @{ de = $caminhoAnterior; para = $identidade.caminho_atual }
        }
        elseif ($ativos.Count -eq 0) {
            $novaLinha = New-BvLinhaDeIdentidade -Identidade $identidade
            $linhas += $novaLinha
            $porCaminho[$identidade.caminho_atual.ToLowerInvariant()] = $novaLinha
            if (-not $porHash.ContainsKey($chaveHash)) { $porHash[$chaveHash] = @() }
            $porHash[$chaveHash] += $novaLinha
            $resumo.Novos++
            $null = Add-BvRegistroDiario -Evento 'arquivo_novo' -Id $novaLinha.id -Detalhe @{ caminho = $identidade.caminho_atual; status = $novaLinha.status }
        }
        else {
            $original = $ativos[0]
            $novaLinha = New-BvLinhaDeIdentidade -Identidade $identidade -Observacoes "copia de $($original.id)"
            $linhas += $novaLinha
            $porCaminho[$identidade.caminho_atual.ToLowerInvariant()] = $novaLinha
            $porHash[$chaveHash] += $novaLinha
            $resumo.Duplicatas++
            $null = Add-BvRegistroDiario -Evento 'duplicata_detectada' -Id $novaLinha.id -Detalhe @{ original = $original.id; caminho = $identidade.caminho_atual }
        }

        $contadorProcessados++
        if ($CheckpointACada -gt 0 -and ($contadorProcessados % $CheckpointACada) -eq 0) {
            Save-BvCatalogo -Linhas $linhas | Out-Null
        }
    }

    foreach ($suspeito in @($Descobertas.Suspeitos)) {
        try {
            $identidade = Get-BvIdentidade -Caminho $suspeito.caminho_atual
        }
        catch {
            $resumo.Erros++
            $null = Add-BvRegistroDiario -Evento 'erro_identificacao' -Id '' -Detalhe @{ caminho = $suspeito.caminho_atual; erro = $_.Exception.Message }
            continue
        }

        $linha = $porCaminho[$suspeito.caminho_atual.ToLowerInvariant()]
        if ($null -eq $linha) {
            $novaLinha = New-BvLinhaDeIdentidade -Identidade $identidade
            $linhas += $novaLinha
            $porCaminho[$identidade.caminho_atual.ToLowerInvariant()] = $novaLinha
            $chaveHashNova = $identidade.sha256.ToLowerInvariant()
            if (-not $porHash.ContainsKey($chaveHashNova)) { $porHash[$chaveHashNova] = @() }
            $porHash[$chaveHashNova] += $novaLinha
            $resumo.Novos++
            $null = Add-BvRegistroDiario -Evento 'arquivo_novo' -Id $novaLinha.id -Detalhe @{ caminho = $identidade.caminho_atual; status = $novaLinha.status }
        }
        elseif ($identidade.sha256.ToLowerInvariant() -eq $linha.sha256.ToLowerInvariant()) {
            $linha.tamanho_bytes = $identidade.tamanho_bytes
            $linha.modificado_em = $identidade.modificado_em
            $linha.visto_em      = $agora
            $resumo.MetadadosAtualizados++
            $null = Add-BvRegistroDiario -Evento 'metadados_atualizados' -Id $linha.id -Detalhe @{ caminho = $linha.caminho_atual }
        }
        else {
            $novaLinha = New-BvLinhaDeIdentidade -Identidade $identidade
            $linhas += $novaLinha
            $linha.substituido_por = $novaLinha.id
            $chaveHashNova = $identidade.sha256.ToLowerInvariant()
            if (-not $porHash.ContainsKey($chaveHashNova)) { $porHash[$chaveHashNova] = @() }
            $porHash[$chaveHashNova] += $novaLinha
            $resumo.Substituidos++
            $null = Add-BvRegistroDiario -Evento 'conteudo_substituido' -Id $novaLinha.id -Detalhe @{ anterior = $linha.id; caminho = $identidade.caminho_atual }
        }

        $contadorProcessados++
        if ($CheckpointACada -gt 0 -and ($contadorProcessados % $CheckpointACada) -eq 0) {
            Save-BvCatalogo -Linhas $linhas | Out-Null
        }
    }

    foreach ($inalterado in @($Descobertas.Inalterados)) {
        $linha = $porCaminho[$inalterado.caminho_atual.ToLowerInvariant()]
        if ($linha) { $linha.visto_em = $agora }
    }

    foreach ($chaveAusente in @($ausentesPendentes.Keys)) {
        $linha = $porCaminho[$chaveAusente]
        if ($null -eq $linha) { continue }
        $linha.status   = 'desaparecido'
        $linha.visto_em = $agora
        $resumo.Desaparecidos++
        $null = Add-BvRegistroDiario -Evento 'desaparecido' -Id $linha.id -Detalhe @{ caminho = $linha.caminho_atual }
    }

    Save-BvCatalogo -Linhas $linhas | Out-Null

    return [pscustomobject]$resumo
}
