$ErrorActionPreference = 'Stop'

if (-not (Get-Command Get-BvCatalogo -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot '..\nucleo\catalogo.ps1')
}
if (-not (Get-Command Invoke-BvChamadaOpencode -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot '..\nucleo\classificador.ps1')
}

# ----------------------------------------------------------------------------
# Utilitários de formatação (somente leitura)
# ----------------------------------------------------------------------------

function Format-BvCliTamanho {
    param([Parameter(Mandatory)]$Bytes)
    if ($null -eq $Bytes -or [string]::IsNullOrWhiteSpace([string]$Bytes)) { return '-' }
    $n = 0L
    if (-not [long]::TryParse([string]$Bytes, [ref]$n)) { return '-' }
    if ($n -lt 1024) { return "$n B" }
    if ($n -lt 1048576) { return ('{0:N1} KB' -f ($n / 1024.0)) }
    if ($n -lt 1073741824) { return ('{0:N1} MB' -f ($n / 1048576.0)) }
    return ('{0:N2} GB' -f ($n / 1073741824.0))
}

function Format-BvCliData {
    param($Valor)
    if ($null -eq $Valor) { return '-' }
    $s = [string]$Valor
    if ([string]::IsNullOrWhiteSpace($s)) { return '-' }
    $d = $null
    if ([DateTime]::TryParse($s, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeLocal -or [Globalization.DateTimeStyles]::None, [ref]$d)) {
        return $d.ToString('yyyy-MM-dd HH:mm')
    }
    return $s
}

function Format-BvCliConfianca {
    param($Valor)
    if ($null -eq $Valor) { return '-' }
    $s = [string]$Valor
    if ([string]::IsNullOrWhiteSpace($s)) { return '-' }
    $n = 0.0
    if (-not [double]::TryParse($s, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$n)) { return $s }
    return ('{0:N2}' -f $n)
}

function Format-BvCliTruncar {
    param([Parameter(Mandatory)][string]$Texto, [Parameter(Mandatory)][int]$Largura)
    if ($Largura -lt 3) { $Largura = 3 }
    if ($Texto.Length -le $Largura) { return $Texto }
    return $Texto.Substring(0, $Largura - 1) + '…'
}

function Format-BvCliCaminho {
    param($Caminho, [int]$Largura = 60)
    if ($null -eq $Caminho) { return '-' }
    $s = [string]$Caminho
    if ([string]::IsNullOrWhiteSpace($s)) { return '-' }
    if ($s.Length -le $Largura) { return $s }
    return '…' + $s.Substring($s.Length - ($Largura - 1))
}

# ----------------------------------------------------------------------------
# Consulta (somente leitura)
# ----------------------------------------------------------------------------

function Get-BvCliLinhasFiltradas {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Linhas,
        [string]$Status,
        [string]$Categoria,
        [string]$Tipo
    )
    $resultado = foreach ($l in @($Linhas)) {
        if ($Status -and ([string]$l.status -ne $Status)) { continue }
        if ($Categoria -and ([string]$l.categoria -ne $Categoria)) { continue }
        if ($Tipo -and ([string]$l.tipo -ne $Tipo)) { continue }
        $l
    }
    return @($resultado)
}

function Get-BvCliLinhasEncontradas {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Linhas,
        [string]$Termo
    )
    $alvo = $Termo.ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($alvo)) { return @() }
    $resultado = foreach ($l in @($Linhas)) {
        $id = [string]$l.id
        $nome = [string]$l.nome_original
        $caminho = [string]$l.caminho_atual
        if ($id.ToLowerInvariant().Contains($alvo)) { $l; continue }
        if ($nome.ToLowerInvariant().Contains($alvo)) { $l; continue }
        if ($caminho.ToLowerInvariant().Contains($alvo)) { $l; continue }
    }
    return @($resultado)
}

function Get-BvCliLinhaPorId {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Linhas,
        [Parameter(Mandatory)][string]$Id
    )
    $alvo = $Id.Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($alvo)) { return $null }
    foreach ($l in @($Linhas)) {
        if ([string]$l.id -and ([string]$l.id).ToLowerInvariant() -eq $alvo) { return $l }
    }
    return $null
}

function Get-BvCliValoresUnicos {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Linhas,
        [Parameter(Mandatory)][string]$Campo
    )
    $vals = @{}
    foreach ($l in @($Linhas)) {
        $v = [string]$l.$Campo
        if ([string]::IsNullOrWhiteSpace($v)) { continue }
        if (-not $vals.ContainsKey($v)) { $vals[$v] = $true }
    }
    return @($vals.Keys | Sort-Object)
}

function Format-BvCliResumo {
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Linhas)
    $linhas = @()
    $porStatus = @{}
    foreach ($l in @($Linhas)) {
        $k = if ([string]::IsNullOrWhiteSpace([string]$l.status)) { '(vazio)' } else { [string]$l.status }
        if (-not $porStatus.ContainsKey($k)) { $porStatus[$k] = 0 }
        $porStatus[$k]++
    }
    $linhas += 'Por status:'
    foreach ($k in @($porStatus.Keys | Sort-Object)) { $linhas += ('  {0,-18} {1}' -f $k, $porStatus[$k]) }

    $porCat = @{}
    foreach ($l in @($Linhas)) {
        $k = if ([string]::IsNullOrWhiteSpace([string]$l.categoria)) { '(vazio)' } else { [string]$l.categoria }
        if (-not $porCat.ContainsKey($k)) { $porCat[$k] = 0 }
        $porCat[$k]++
    }
    $linhas += ''
    $linhas += 'Por categoria:'
    foreach ($k in @($porCat.Keys | Sort-Object)) { $linhas += ('  {0,-24} {1}' -f $k, $porCat[$k]) }
    return ,$linhas
}

function Format-BvCliDetalhes {
    param([Parameter(Mandatory)]$Linha, [Parameter(Mandatory)][string[]]$Colunas)
    $saida = @()
    foreach ($c in $Colunas) {
        $v = $Linha.$c
        $texto = if ($null -eq $v) { '' } else { [string]$v }
        if ($c -eq 'detalhes' -and -not [string]::IsNullOrWhiteSpace($texto)) {
            $saida += ("{0}: {1}" -f $c, $texto)
            try {
                $obj = $texto | ConvertFrom-Json -ErrorAction Stop
                $saida += '  (detalhes decodificado:'
                foreach ($p in @($obj.PSObject.Properties)) {
                    $saida += ('    {0}: {1}' -f $p.Name, $p.Value)
                }
                $saida += '  )'
            } catch {
                $saida += '  (detalhes nao e JSON valido)'
            }
        }
        else {
            $saida += ("{0}: {1}" -f $c, $texto)
        }
    }
    return ,$saida
}

# ----------------------------------------------------------------------------
# Apresentação do catálogo (tabela ampliada)
# ----------------------------------------------------------------------------

function Get-BvCliTabelaCatalogo {
    param([AllowEmptyCollection()][object[]]$Linhas)
    $saida = @('{0,-12} {1,-40} {2,-14} {3,-22} {4,-6} {5,-8} {6}' -f 'ID', 'NOME', 'STATUS', 'CATEGORIA', 'CONF', 'TAMANHO', 'CAMINHO')
    foreach ($l in @($Linhas)) {
        $id = [string]$l.id
        $nome = Format-BvCliTruncar -Texto ([string]$l.nome_original) -Largura 40
        $status = if ([string]::IsNullOrWhiteSpace([string]$l.status)) { '-' } else { [string]$l.status }
        $categoria = if ([string]::IsNullOrWhiteSpace([string]$l.categoria)) { '-' } else { [string]$l.categoria }
        $categoria = Format-BvCliTruncar -Texto $categoria -Largura 22
        $conf = Format-BvCliConfianca $l.confianca
        $tam = Format-BvCliTamanho $l.tamanho_bytes
        $caminho = Format-BvCliCaminho -Caminho $l.caminho_atual -Largura 60
        $saida += '{0,-12} {1,-40} {2,-14} {3,-22} {4,-6} {5,-8} {6}' -f $id, $nome, $status, $categoria, $conf, $tam, $caminho
    }
    return ,$saida
}

# ----------------------------------------------------------------------------
# Pergunta à IA sobre um documento (fluxo mínimo: texto -> modelo -> resposta)
# ----------------------------------------------------------------------------

function Get-BvCliTextoDocumento {
    param([Parameter(Mandatory)]$Linha)

    $cfg = Get-BvConfig
    $arquivoTexto = Join-Path (Join-Path $cfg.PastaDados $cfg.PastaExtracoes) ("{0}.txt" -f $Linha.id)
    if (-not (Test-Path -LiteralPath $arquivoTexto)) {
        $null = Invoke-BvExtracaoDeLinha -Linha $Linha
    }
    if (-not (Test-Path -LiteralPath $arquivoTexto)) { throw "extracao nao disponivel para $($Linha.id)" }
    return (Get-Content -LiteralPath $arquivoTexto -Raw)
}

function Invoke-BvCliPergunta {
    param(
        [Parameter(Mandatory)]$Linha,
        [Parameter(Mandatory)][string]$Pergunta
    )

    $texto = Get-BvCliTextoDocumento -Linha $Linha
    $cfg = Get-BvConfig
    if ($texto.Length -gt $cfg.LimiteCaracteresIA) {
        $texto = $texto.Substring(0, $cfg.LimiteCaracteresIA)
    }

    $resposta = Invoke-BvChamadaOpencode `
        -PromptSistema 'Voce e um assistente da Biblioteca Viva. Responda em portugues, de forma objetiva, com base apenas no contexto fornecido.' `
        -PromptUsuario "Contexto do documento:`n$texto`n`nPergunta: $Pergunta"

    return [string]$resposta
}

function Resolve-BvCliDocumento {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Linhas,
        [Parameter(Mandatory)][string]$Escolha
    )
    $e = $Escolha.Trim()
    if (-not $e) { return $null }
    $n = 0
    if ([int]::TryParse($e, [ref]$n) -and $n -ge 1 -and $n -le $Linhas.Count) { return $Linhas[$n - 1] }
    $porId = Get-BvCliLinhaPorId -Linhas $Linhas -Id $e
    if ($porId) { return $porId }
    $achados = @(Get-BvCliLinhasEncontradas -Linhas $Linhas -Termo $e)
    if ($achados.Count -eq 1) { return $achados[0] }
    return $achados
}

# ----------------------------------------------------------------------------
# Menu
# ----------------------------------------------------------------------------

function Get-BvCliOpcao {
    param([string[]]$Fila, [ref]$Indice)
    if ($Fila -and $Indice.Value -lt $Fila.Count) {
        $opcao = $Fila[$Indice.Value]
        $Indice.Value++
        if ($null -eq $opcao) { return '' }
        return ([string]$opcao)
    }
    return (Read-Host 'Opção')
}

function Invoke-BvCli {
    param(
        [string[]]$Entradas = @(),
        [AllowEmptyCollection()][object[]]$Linhas
    )

    $indice = 0
    $transcript = [System.Collections.Generic.List[string]]::new()
    $opcoesUsadas = [System.Collections.Generic.List[string]]::new()
    if ($PSBoundParameters.ContainsKey('Linhas') -and $null -ne $Linhas) {
        $linhas = @($Linhas)
    }
    else {
        $linhas = @(Get-BvCatalogo)
    }
    $colunas = @(Get-BvColunasCatalogo)

    function Escrever { param($Texto) foreach ($t in @($Texto)) { Write-Host $t; $transcript.Add([string]$t) } }

    :principal while ($true) {
        Escrever ''
        Escrever 'BIBLIOTECA VIVA'
        Escrever '----------------'
        Escrever ("Catálogo: {0} arquivos" -f $linhas.Count)
        Escrever ''
        Escrever '1. Listar documentos'
        Escrever '2. Pesquisar documento'
        Escrever '3. Perguntar à IA sobre um documento'
        Escrever '4. Sair'
        Escrever ''

        $opcaoRaw = Get-BvCliOpcao -Fila $Entradas -Indice ([ref]$indice)
        $opcao = if ($null -eq $opcaoRaw) { '' } else { ([string]$opcaoRaw).Trim() }
        $opcoesUsadas.Add($opcao)
        Escrever ''

        switch ($opcao) {
            '1' {
                Escrever (Get-BvCliTabelaCatalogo -Linhas $linhas)
                Escrever ''
                Escrever ("Total: {0}" -f $linhas.Count)
            }
            '2' {
                $termo = (Get-BvCliOpcao -Fila $Entradas -Indice ([ref]$indice))
                $encontradas = Get-BvCliLinhasEncontradas -Linhas $linhas -Termo $termo
                if ($encontradas.Count -eq 0) {
                    Escrever ("Nenhuma ocorrência para '{0}'." -f $termo)
                }
                else {
                    Escrever (Get-BvCliTabelaCatalogo -Linhas $encontradas)
                    Escrever ''
                    Escrever ("Encontradas: {0}" -f $encontradas.Count)
                }
            }
            '3' {
                if ($linhas.Count -eq 0) { Escrever 'Catálogo vazio — nada para perguntar.'; continue principal }
                Escrever ("Selecione o documento (número de 1-{0}, ID ou termo de busca):" -f $linhas.Count)
                $escolha = (Get-BvCliOpcao -Fila $Entradas -Indice ([ref]$indice)).Trim()
                $cands = @(Resolve-BvCliDocumento -Linhas $linhas -Escolha $escolha)
                if ($cands.Count -eq 0) {
                    Escrever ("Nenhum documento encontrado para '{0}'." -f $escolha)
                    continue principal
                }
                if ($cands.Count -gt 1) {
                    Escrever 'Vários documentos encontrados:'
                    Escrever (Get-BvCliTabelaCatalogo -Linhas $cands)
                    Escrever ("Digite o número (1-{0}):" -f $cands.Count)
                    $num = (Get-BvCliOpcao -Fila $Entradas -Indice ([ref]$indice)).Trim()
                    $n = 0
                    if (-not [int]::TryParse($num, [ref]$n) -or $n -lt 1 -or $n -gt $cands.Count) {
                        Escrever 'Seleção inválida.'
                        continue principal
                    }
                    $doc = $cands[$n - 1]
                }
                else {
                    $doc = $cands[0]
                }
                Escrever ("Documento selecionado: {0} ({1})" -f $doc.nome_original, $doc.id)
                Escrever 'Digite sua pergunta:'
                $perguntaRaw = Get-BvCliOpcao -Fila $Entradas -Indice ([ref]$indice)
                $pergunta = if ($null -eq $perguntaRaw) { '' } else { ([string]$perguntaRaw).Trim() }
                if (-not $pergunta) {
                    Escrever 'Pergunta vazia.'
                    continue principal
                }

                function Perguntar-BvCliDoc { param($Doc, $Perg)
                    Escrever 'Consultando a IA...'
                    try {
                        $r = Invoke-BvCliPergunta -Linha $Doc -Pergunta $Perg
                        Escrever ''
                        Escrever '=== RESPOSTA ==='
                        Escrever ([string]$r)
                    } catch {
                        Escrever ("Falha ao consultar a IA: {0}" -f $_.Exception.Message)
                    }
                }

                Perguntar-BvCliDoc -Doc $doc -Perg $pergunta

                :sub while ($true) {
                    Escrever ''
                    Escrever ("--- Documento: {0} ({1}) ---" -f $doc.nome_original, $doc.id)
                    Escrever '1. Nova pergunta sobre este documento'
                    Escrever '2. Escolher outro documento'
                    Escrever '3. Voltar ao menu'
                    Escrever '4. Sair'
                    $sub = (Get-BvCliOpcao -Fila $Entradas -Indice ([ref]$indice)).Trim()
                    switch ($sub) {
                        '1' {
                            Escrever 'Digite sua pergunta:'
                            $proximaRaw = Get-BvCliOpcao -Fila $Entradas -Indice ([ref]$indice)
                            $proxima = if ($null -eq $proximaRaw) { '' } else { ([string]$proximaRaw).Trim() }
                            if (-not $proxima) { Escrever 'Pergunta vazia.'; continue sub }
                            Perguntar-BvCliDoc -Doc $doc -Perg $proxima
                        }
                        '2' { continue principal }
                        '3' { break sub }
                        '4' { Escrever 'Encerrando.'; break principal }
                        default { Escrever "Opção inválida: '$sub'" }
                    }
                }
            }
            '4' { Escrever 'Encerrando.'; break principal }
            default { Escrever "Opção inválida: '$opcao'" }
        }
    }

    return [pscustomobject]@{
        Opcoes     = $opcoesUsadas.ToArray()
        Transcript = $transcript.ToArray()
        Arquivos   = $linhas.Count
    }
}

if ($MyInvocation.InvocationName -ne '.') { Invoke-BvCli }
