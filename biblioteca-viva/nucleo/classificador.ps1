if (-not (Get-Command Get-BvConfig -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'config.ps1')
}
if (-not (Get-Command Get-BvCatalogo -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'catalogo.ps1')
}
if (-not (Get-Command Add-BvRegistroDiario -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'diario.ps1')
}
if (-not (Get-Command Invoke-BvExtracaoDeLinha -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'extrator.ps1')
}

function Get-BvPastaClassificacoes {
    $cfg = Get-BvConfig
    $pasta = Join-Path $cfg.PastaDados $cfg.PastaClassificacoes
    if (-not (Test-Path -LiteralPath $pasta)) {
        New-Item -ItemType Directory -Path $pasta -Force | Out-Null
    }
    return $pasta
}

function New-BvPromptSistema {
    $cfg = Get-BvConfig
    $linhasTaxonomia = foreach ($categoria in $cfg.Taxonomia) {
        "- $categoria : $($cfg.DescricoesTaxonomia[$categoria])"
    }

    return @"
Voce e um classificador de documentos. Analise o texto recebido e responda APENAS com um JSON valido, sem nenhuma palavra fora dele, no formato exato:
{"categoria":"<categoria>","confianca":<numero de 0.0 a 1.0>,"motivo":"<ate 200 caracteres, citando um trecho do texto>","palavras_chave":["ate 6 termos"],"resumo":"<1 frase, ate 150 caracteres>"}
Categorias permitidas (escolha EXATAMENTE uma, nunca invente outra):
$($linhasTaxonomia -join "`n")
Regras: se o tema for obscuro ou misto, use digitalizado_diverso; se nao houver como julgar, use outro; a confianca deve refletir sua certeza real.
"@
}

function Invoke-BvChamadaIA {
    param(
        [Parameter(Mandatory)][string]$PromptSistema,
        [Parameter(Mandatory)][string]$PromptUsuario
    )

    $chave = $env:OPENROUTER_API_KEY
    if (-not $chave) { throw 'Variavel de ambiente OPENROUTER_API_KEY nao definida' }

    $cfg = Get-BvConfig
    $corpo = @{
        model       = $cfg.ModeloIA
        temperature = 0
        messages    = @(
            @{ role = 'system'; content = $PromptSistema },
            @{ role = 'user'; content = $PromptUsuario }
        )
    } | ConvertTo-Json -Depth 5

    $resposta = Invoke-RestMethod -Uri $cfg.UrlOpenRouter -Method Post -Headers @{
        Authorization = "Bearer $chave"
        'HTTP-Referer' = 'https://localhost'
        'X-Title'      = 'BibliotecaViva'
    } -ContentType 'application/json; charset=utf-8' -Body $corpo

    return [string]$resposta.choices[0].message.content
}

function Invoke-BvChamadaOpencode {
    param(
        [Parameter(Mandatory)][string]$PromptSistema,
        [Parameter(Mandatory)][string]$PromptUsuario
    )

    $exe = (Get-Command opencode -ErrorAction SilentlyContinue).Source
    if (-not $exe) { throw 'opencode nao encontrado no PATH' }

    $cfg = Get-BvConfig
    $mensagem = "$PromptSistema`n`n---`n`n$PromptUsuario"

    function ExtrairTextos([object]$No, [System.Collections.Generic.List[string]]$Lista) {
        if ($null -eq $No -or $No -is [string]) { return }
        if ($No -is [pscustomobject]) {
            foreach ($p in $No.PSObject.Properties) {
                if ($p.Name -eq 'text' -and $p.Value -is [string] -and $p.Value.Trim()) { $Lista.Add($p.Value) }
                else { ExtrairTextos $p.Value $Lista }
            }
        }
        elseif ($No -is [System.Collections.IEnumerable]) {
            foreach ($i in $No) { ExtrairTextos $i $Lista }
        }
    }

    $saida = ''
    $erroExec = ''
    $arqStderr = Join-Path ([IO.Path]::GetTempPath()) ("bv-oc-stderr-{0}.tmp" -f [IO.Path]::GetRandomFileName())
    try {
        $job = Start-Job -ScriptBlock {
            param($CaminhoExe, $Modelo, $Dir, $Mensagem, $ArqErro)
            & $CaminhoExe run -m $Modelo --format json --dir $Dir $Mensagem 2>$ArqErro
        } -ArgumentList $exe, $cfg.ModeloIA, $cfg.RaizCodigo, $mensagem, $arqStderr

        if (Wait-Job $job -Timeout 180) { $saida = @(Receive-Job $job) -join "`n" }
        else { Stop-Job $job; $erroExec = 'timeout de 180 s na chamada opencode' }
        Remove-Job $job -Force -ErrorAction SilentlyContinue
    }
    catch { $erroExec = $_.Exception.Message }
    finally {
        if (Test-Path -LiteralPath $arqStderr) { Remove-Item -LiteralPath $arqStderr -Force -ErrorAction SilentlyContinue }
    }

    if ($erroExec) { throw $erroExec }

    $textos = [System.Collections.Generic.List[string]]::new()
    foreach ($ln in ($saida -split "`n")) {
        $t = $ln.Trim()
        if (-not $t) { continue }
        try { ExtrairTextos ($t | ConvertFrom-Json) $textos } catch { }
    }
    $extraido = (@($textos) | Select-Object -Unique) -join "`n"
    if (-not $extraido.Trim()) {
        $extraido = (($saida -join "`n") -replace "\x1b\[[0-9;]*m", '')
    }
    if (-not $extraido.Trim()) { throw 'opencode devolveu saida vazia' }

    return $extraido.Trim()
}

function Convert-BvRespostaParaFicha {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Bruta)

    if (-not $Bruta.Trim()) { throw 'resposta vazia' }

    $limpa = $Bruta.Trim() -replace '^```(json)?\s*', '' -replace '\s*```$', ''
    $dados = $limpa | ConvertFrom-Json

    $cfg = Get-BvConfig
    if (-not $dados.categoria -or @($cfg.Taxonomia) -notcontains [string]$dados.categoria) {
        throw "categoria invalida: '$($dados.categoria)'"
    }

    $confianca = 0.0
    if (-not [double]::TryParse([string]$dados.confianca, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$confianca)) {
        throw "confianca invalida: '$($dados.confianca)'"
    }
    if ($confianca -lt 0 -or $confianca -gt 1) { throw "confianca fora do intervalo: $confianca" }

    $motivo = ([string]$dados.motivo).Trim()
    if (-not $motivo) { throw 'motivo ausente' }
    if ($motivo.Length -gt 200) { $motivo = $motivo.Substring(0, 200) }

    $palavras = @()
    if ($dados.palavras_chave) { $palavras = @($dados.palavras_chave | ForEach-Object { [string]$_ }) }
    $resumo = ([string]$dados.resumo).Trim()
    if ($resumo.Length -gt 150) { $resumo = $resumo.Substring(0, 150) }

    return [pscustomobject]@{
        Categoria     = [string]$dados.categoria
        Confianca     = $confianca
        Motivo        = ($motivo -replace '\s+', ' ')
        PalavrasChave = $palavras
        Resumo        = ($resumo -replace '\s+', ' ')
    }
}

function Add-BvRegistroHistorico {
    param(
        [Parameter(Mandatory)][hashtable]$Registro
    )

    $cfg = Get-BvConfig
    $pasta = Get-BvPastaClassificacoes
    $arquivo = Join-Path $pasta ("lote-{0}.jsonl" -f $Registro.lote)
    $ordenado = [ordered]@{}
    foreach ($chave in @('quando', 'lote', 'id', 'modelo', 'valido', 'categoria', 'confianca', 'erro', 'resposta_bruta')) {
        if ($Registro.ContainsKey($chave)) { $ordenado[$chave] = $Registro[$chave] }
    }
    ($ordenado | ConvertTo-Json -Compress) | Add-Content -LiteralPath $arquivo -Encoding utf8
    return $arquivo
}

function Invoke-BvClassificacaoDeLinha {
    param(
        [scriptblock]$FuncaoChamada,
        [string[]]$Ids = @(),
        [switch]$Reprocessar,
        [string]$IdLote = (Get-Date -Format 'yyyyMMdd-HHmmss'),
        [int]$CheckpointACada = 0
    )

    $cfg = Get-BvConfig
    $agora = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $promptSistema = New-BvPromptSistema

    $resumo = [ordered]@{
        Elegiveis               = 0
        Classificados           = 0
        SemTexto                = 0
        PrecisamSenha           = 0
        ErrosExtracao           = 0
        Recusadas               = 0
        BaixaConfianca          = 0
    }

    $linhas = @(Get-BvCatalogo)
    $statusElegiveis = @('inventariado', '_REVISAR')
    if ($Reprocessar) { $statusElegiveis += 'classificado' }

    $elegiveis = @($linhas | Where-Object {
            (-not $_.substituido_por) -and ($_.status -ne 'desaparecido') -and ($statusElegiveis -contains $_.status)
        })
    if (@($Ids).Count -gt 0) {
        $elegiveis = @($elegiveis | Where-Object { @($Ids) -contains $_.id })
    }
    $resumo.Elegiveis = $elegiveis.Count

    $contadorProcessados = 0

    foreach ($linha in $elegiveis) {

        $assinaturaAntes = "$($linha.id)|$($linha.sha256)|$($linha.caminho_atual)|$($linha.tamanho_bytes)|$($linha.modificado_em)|$($linha.tipo)|$($linha.substituido_por)"

        $ficha = Invoke-BvExtracaoDeLinha -Linha $linha

        if (-not $ficha.Ok) {
            $resumo.ErrosExtracao++
            $null = Add-BvRegistroDiario -Evento 'erro_extracao' -Id $linha.id -Detalhe @{ caminho = $linha.caminho_atual; observacoes = ($ficha.Observacoes -join ', ') }
            continue
        }

        if ($ficha.PrecisaSenha) {
            $resumo.PrecisamSenha++
            if ($linha.observacoes -notmatch 'precisa_senha') {
                $linha.observacoes = ($linha.observacoes ? "$($linha.observacoes); precisa_senha" : 'precisa_senha')
            }
            $null = Add-BvRegistroDiario -Evento 'classificacao_precisa_senha' -Id $linha.id -Detalhe @{ caminho = $linha.caminho_atual }
            continue
        }

        if ($ficha.Caracteres -lt $cfg.MinimoCaracteresTexto) {
            $resumo.SemTexto++
            if ($linha.observacoes -notmatch 'sem_texto_para_classificar') {
                $linha.observacoes = ($linha.observacoes ? "$($linha.observacoes); sem_texto_para_classificar" : 'sem_texto_para_classificar')
            }
            $null = Add-BvRegistroDiario -Evento 'classificacao_sem_texto' -Id $linha.id -Detalhe @{ caracteres = $ficha.Caracteres }
            continue
        }

        $truncado = $ficha.Texto.Length -gt $cfg.LimiteCaracteresIA
        $amostra = if ($truncado) { $ficha.Texto.Substring(0, $cfg.LimiteCaracteresIA) } else { $ficha.Texto }
        $promptUsuario = "Arquivo: $($linha.nome_original)`n`nTexto:`n$amostra"

        $fichaIA = $null
        $ultimoErro = ''
        $bruta = ''
        foreach ($tentativa in 1..2) {
            try {
                if ($FuncaoChamada) {
                    $bruta = & $FuncaoChamada $promptSistema $promptUsuario
                }
                elseif ($cfg.ProvedorIA -eq 'opencode') {
                    $bruta = Invoke-BvChamadaOpencode -PromptSistema $promptSistema -PromptUsuario $promptUsuario
                }
                else {
                    $bruta = Invoke-BvChamadaIA -PromptSistema $promptSistema -PromptUsuario $promptUsuario
                }
                $fichaIA = Convert-BvRespostaParaFicha -Bruta ([string]$bruta)
                break
            }
            catch {
                $ultimoErro = $_.Exception.Message
                $fichaIA = $null
            }
        }

        if ($null -eq $fichaIA) {
            $resumo.Recusadas++
            $null = Add-BvRegistroHistorico -Registro @{
                quando = $agora; lote = $IdLote; id = $linha.id; modelo = $cfg.ModeloIA
                valido = $false; erro = $ultimoErro; resposta_bruta = $bruta
            }
            $null = Add-BvRegistroDiario -Evento 'classificacao_recusada' -Id $linha.id -Detalhe @{ erro = $ultimoErro }
            continue
        }

        $linha.categoria        = $fichaIA.Categoria
        $linha.confianca        = $fichaIA.Confianca.ToString('0.00', [Globalization.CultureInfo]::InvariantCulture)
        $linha.motivo           = $fichaIA.Motivo
        $linha.classificado_por = 'ia'
        $linha.modelo           = $cfg.ModeloIA
        $linha.lote             = $IdLote
        $linha.processado_em    = $agora
        $linha.status           = 'classificado'
        $resumo.Classificados++

        try { $detalhes = $linha.detalhes | ConvertFrom-Json } catch { $detalhes = New-Object PSObject }
        if (-not $detalhes) { $detalhes = New-Object PSObject }
        Add-Member -InputObject $detalhes -NotePropertyName 'ia' -NotePropertyValue ([pscustomobject]@{
            quando      = $agora
            modelo      = $cfg.ModeloIA
            palavras_chave = ($fichaIA.PalavrasChave -join ', ')
            resumo      = $fichaIA.Resumo
            caracteres_extracao = $ficha.Caracteres
            truncado    = $truncado
        }) -Force
        $linha.detalhes = $detalhes | ConvertTo-Json -Compress -Depth 4

        if ($fichaIA.Confianca -lt $cfg.ConfiancaMinima) { $resumo.BaixaConfianca++ }

        $assinaturaDepois = "$($linha.id)|$($linha.sha256)|$($linha.caminho_atual)|$($linha.tamanho_bytes)|$($linha.modificado_em)|$($linha.tipo)|$($linha.substituido_por)"
        if ($assinaturaAntes -ne $assinaturaDepois) {
            throw "VIOLACAO: colunas tecnicas alteradas durante classificacao do id $($linha.id)"
        }

        $null = Add-BvRegistroHistorico -Registro @{
            quando = $agora; lote = $IdLote; id = $linha.id; modelo = $cfg.ModeloIA
            valido = $true; categoria = $fichaIA.Categoria; confianca = $linha.confianca
            resposta_bruta = $(if ($bruta.Length -gt 1000) { $bruta.Substring(0, 1000) } else { $bruta })
        }
        $null = Add-BvRegistroDiario -Evento 'classificado' -Id $linha.id -Detalhe @{ categoria = $fichaIA.Categoria; confianca = $linha.confianca }

        $contadorProcessados++
        if ($CheckpointACada -gt 0 -and ($contadorProcessados % $CheckpointACada) -eq 0) {
            Save-BvCatalogo -Linhas $linhas | Out-Null
        }
    }

    Save-BvCatalogo -Linhas $linhas | Out-Null

    return [pscustomobject]$resumo
}
