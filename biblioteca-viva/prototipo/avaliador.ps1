# PROTÓTIPO — Biblioteca V1 (avaliador isolado, sem dependência do núcleo)
# NÃO integrar a nucleo/. NÃO executa operações físicas. Somente avaliação em memória.

$script:CamposPermitidos = @('categoria', 'confianca', 'tipo', 'nome_original', 'pasta_original', 'status')
$script:OperadoresPermitidos = @('igual', 'diferente', 'contem', 'em', 'vazio', 'nao_vazio', 'maior_igual', 'menor_igual')
$script:OperadoresDeConteudo = @('igual', 'diferente', 'contem', 'em', 'maior_igual', 'menor_igual')

function Get-BvProtoCampo {
    param($Linha, [Parameter(Mandatory)][string]$Campo)

    if ($Campo -match '^detalhes\.') {
        $chave = $Campo.Substring('detalhes.'.Length)
        $prop = $Linha.PSObject.Properties['detalhes']
        if (-not $prop -or $null -eq $prop.Value) { return $null }
        $interna = $prop.Value.PSObject.Properties[$chave]
        if (-not $interna) { return $null }
        return $interna.Value
    }

    $prop = $Linha.PSObject.Properties[$Campo]
    if (-not $prop) { return $null }
    return $prop.Value
}

function Test-BvProtoPredicado {
    param($Valor, [Parameter(Mandatory)][string]$Operador, $Esperado)

    $texto = if ($null -eq $Valor) { '' } else { [string]$Valor }
    $eVazio = ($null -eq $Valor -or $texto.Trim() -eq '')

    if (($script:OperadoresDeConteudo -contains $Operador) -and $eVazio) { return $false }

    switch ($Operador) {
        'vazio'       { return $eVazio }
        'nao_vazio'   { return (-not $eVazio) }
        'igual'       { return ($texto.ToLowerInvariant() -eq ([string]$Esperado).ToLowerInvariant()) }
        'diferente'   { return ($texto.ToLowerInvariant() -ne ([string]$Esperado).ToLowerInvariant()) }
        'contem'      { return $texto.ToLowerInvariant().Contains(([string]$Esperado).ToLowerInvariant()) }
        'em'          {
            $lista = @($Esperado | ForEach-Object { ([string]$_).ToLowerInvariant() })
            return ($lista -contains $texto.ToLowerInvariant())
        }
        'maior_igual' {
            $n = 0.0
            if (-not [double]::TryParse($texto, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$n)) { return $false }
            $m = 0.0
            if (-not [double]::TryParse([string]$Esperado, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$m)) { throw "valor esperado nao numerico para maior_igual: $Esperado" }
            return ($n -ge $m)
        }
        'menor_igual' {
            $n = 0.0
            if (-not [double]::TryParse($texto, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$n)) { return $false }
            $m = 0.0
            if (-not [double]::TryParse([string]$Esperado, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$m)) { throw "valor esperado nao numerico para menor_igual: $Esperado" }
            return ($n -le $m)
        }
        default { throw "operador nao permitido: $Operador" }
    }
}

function Test-BvProtoEstrutura {
    param([Parameter(Mandatory)][pscustomobject]$Bib)

    if (-not $Bib.meta) { throw 'bloco meta ausente' }
    foreach ($campoMeta in @('nome', 'versao', 'status')) {
        $prop = $Bib.meta.PSObject.Properties[$campoMeta]
        if (-not $prop -or [string]::IsNullOrWhiteSpace([string]$prop.Value)) { throw "meta.$campoMeta ausente ou vazio" }
    }
    if (-not $Bib.taxonomia -or [string]$Bib.taxonomia.origem -ne 'config') { throw 'taxonomia invalida: origem config esperada' }

    $idsNos = @{}
    foreach ($no in @($Bib.nos)) {
        if (-not $no.id -or -not $no.caminho) { throw 'no invalido: id e caminho obrigatorios' }
        $idNo = [string]$no.id
        if ($idsNos.ContainsKey($idNo)) { throw "no duplicado: $idNo" }
        $idsNos[$idNo] = $true
    }
    if ($idsNos.Count -eq 0) { throw 'nenhum no declarado na arvore logica' }

    $idsRegras = @{}
    $indice = 0
    foreach ($regra in @($Bib.regras)) {
        $indice++
        if (-not $regra.id) { throw "regra $indice sem id" }
        $idRegra = [string]$regra.id
        if ($idsRegras.ContainsKey($idRegra)) { throw "regra duplicada: $idRegra" }
        $idsRegras[$idRegra] = $true

        if (-not $regra.quando -or @($regra.quando.todos).Count -eq 0) { throw "regra ${idRegra}: condicao vazia" }
        foreach ($predicado in @($regra.quando.todos)) {
            $campo = [string]$predicado.campo
            if (($campo -notmatch '^detalhes\..+') -and ($script:CamposPermitidos -notcontains $campo)) {
                throw "regra ${idRegra}: campo fora da whitelist: '$campo'"
            }
            if ($script:OperadoresPermitidos -notcontains [string]$predicado.operador) {
                throw "regra ${idRegra}: operador nao permitido: '$($predicado.operador)'"
            }
        }

        $destino = [string]$regra.entao.destino
        if (-not $destino) { throw "regra ${idRegra}: destino ausente" }
        if (-not $idsNos.ContainsKey($destino)) { throw "regra ${idRegra}: destino inexistente '$destino'" }
    }

    if ($Bib.fallback -and $Bib.fallback.sem_regra -and -not $Bib.fallback.sem_regra.acao) {
        throw 'fallback.sem_regra presente sem acao'
    }

    return $true
}

function Read-BvProtoBiblioteca {
    param([Parameter(Mandatory)][string]$Caminho)

    $bruto = Get-Content -LiteralPath $Caminho -Raw -Encoding utf8
    $documento = $bruto | ConvertFrom-Json
    $null = Test-BvProtoEstrutura -Bib $documento

    if ([string]$documento.meta.status -ne 'aprovada') {
        throw "biblioteca '$($documento.meta.nome)' v$($documento.meta.versao) recusada: status '$($documento.meta.status)' nao e 'aprovada'"
    }

    $caminhosPorNo = @{}
    foreach ($no in @($documento.nos)) { $caminhosPorNo[[string]$no.id] = [string]$no.caminho }

    return [pscustomobject]@{ Documento = $documento; CaminhoNo = $caminhosPorNo }
}

function Invoke-BvProtoAvaliacao {
    param(
        [Parameter(Mandatory)]$Biblioteca,
        [Parameter(Mandatory)][AllowEmptyCollection()]$Linhas
    )

    $semRegra = $null
    if ($Biblioteca.Documento.fallback -and $Biblioteca.Documento.fallback.sem_regra) {
        $semRegra = $Biblioteca.Documento.fallback.sem_regra
    }

    $resultados = foreach ($linha in @($Linhas)) {
        $regraCasada = $null
        foreach ($regra in @($Biblioteca.Documento.regras)) {
            $todosOk = $true
            foreach ($predicado in @($regra.quando.todos)) {
                $valor = Get-BvProtoCampo -Linha $linha -Campo ([string]$predicado.campo)
                if (-not (Test-BvProtoPredicado -Valor $valor -Operador ([string]$predicado.operador) -Esperado $predicado.valor)) {
                    $todosOk = $false
                    break
                }
            }
            if ($todosOk) { $regraCasada = $regra; break }
        }

        if ($regraCasada) {
            [pscustomobject]@{
                arquivo   = [string]$linha.nome_original
                categoria = [string]$linha.categoria
                regra     = [string]$regraCasada.id
                destino   = [string]$Biblioteca.CaminhoNo[[string]$regraCasada.entao.destino]
                resultado = 'PROPOSTO'
                acao      = 'mover'
            }
        }
        else {
            [pscustomobject]@{
                arquivo   = [string]$linha.nome_original
                categoria = [string]$linha.categoria
                regra     = '-'
                destino   = ''
                resultado = $(if ($semRegra) { ([string]$semRegra.registrar_como).ToUpperInvariant() } else { 'PENDENTE_DE_REGRA' })
                acao      = $(if ($semRegra) { [string]$semRegra.acao } else { 'nenhuma' })
            }
        }
    }

    return @($resultados)
}

function Show-BvProtoRelatorio {
    param([Parameter(Mandatory)][AllowEmptyCollection()]$Resultados)

    Write-Host '=== RELATORIO DO PROTOTIPO (somente proposta, nada e executado) ==='
    foreach ($r in $Resultados) {
        $destinoExibicao = if ($r.destino) { $r.destino } else { '(nenhum)' }
        '{0,-40} | {1,-18} | {2,-6} | {3,-22} | {4}' -f $r.arquivo, $r.categoria, $r.regra, $destinoExibicao, $r.resultado
    }
    $propostos = @($Resultados | Where-Object { $_.resultado -eq 'PROPOSTO' }).Count
    $pendentes = @($Resultados | Where-Object { $_.resultado -ne 'PROPOSTO' }).Count
    Write-Host ''
    Write-Host "Resumo: $propostos propostos, $pendentes pendentes, $($Resultados.Count) avaliados"
}
