$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\cli\cli.ps1')

# ----------------------------------------------------------------------------
# Fixture inline: catalogo ficticio usado pelos testes
# Mantem-se isolado do catalogo real (sandbox).
# ----------------------------------------------------------------------------
function New-BvCliLinhaFixture {
    param(
        [string]$Id, [string]$Nome, [string]$Status, [string]$Categoria,
        [string]$Tipo = '.pdf', [string]$Caminho = 'G:\Documentos_Todos\PDFs\Projeto PDFs\x.pdf',
        [string]$Tamanho = '1024', [string]$Confianca = ''
    )
    $linha = [ordered]@{}
    foreach ($c in @(Get-BvColunasCatalogo)) { $linha[$c] = '' }
    $linha['id']             = $Id
    $linha['nome_original']  = $Nome
    $linha['caminho_atual']  = $Caminho
    $linha['tamanho_bytes']  = $Tamanho
    $linha['tipo']           = $Tipo
    $linha['status']         = $Status
    $linha['categoria']      = $Categoria
    $linha['confianca']      = $Confianca
    return [pscustomobject]$linha
}

$script:fixture = @(
    (New-BvCliLinhaFixture -Id 'ecd9dca366af' -Nome 'TesePolimeros.pdf'   -Status 'classificado' -Categoria 'academico_tecnico' -Confianca '0.98' -Caminho 'G:\Documentos_Todos\PDFs\Projeto PDFs\TesePolimeros.pdf'),
    (New-BvCliLinhaFixture -Id 'aabbcc112233' -Nome 'ArtigoIA.pdf'        -Status 'classificado' -Categoria 'academico_tecnico' -Confianca '0.90' -Caminho 'G:\Documentos_Todos\PDFs\Projeto PDFs\ArtigoIA.pdf'),
    (New-BvCliLinhaFixture -Id 'ffddee998877' -Nome 'ExtratoBanco.pdf'    -Status 'classificado' -Categoria 'financeiro'        -Confianca '0.85' -Caminho 'G:\Documentos_Todos\PDFs\Projeto PDFs\ExtratoBanco.pdf'),
    (New-BvCliLinhaFixture -Id '998877665544' -Nome 'Contrato.docx'       -Status 'inventariado' -Categoria 'documento_pessoal' -Tipo '.docx'      -Caminho 'G:\Documentos_Todos\PDFs\Projeto PDFs\Contrato.docx'),
    (New-BvCliLinhaFixture -Id '665544332211' -Nome 'Multa.pdf'           -Status 'inventariado' -Categoria 'automotivo'        -Caminho 'G:\Documentos_Todos\PDFs\Projeto PDFs\Multa.pdf')
)

$script:aprovados = 0
$script:falhados  = 0

function Test-BvVerificacao {
    param([Parameter(Mandatory)][string]$Nome, [Parameter(Mandatory)][scriptblock]$Bloco)
    try { & $Bloco; Write-Host "[PASSOU] $Nome"; $script:aprovados++ }
    catch { Write-Host "[FALHOU] $Nome -> $($_.Exception.Message)"; $script:falhados++ }
}

Write-Host '=== CLI - Testes (sandbox, fixture ficticia) ==='

# 01 - carregamento: CLI deve carregar sem erro e a fixture deve estar disponivel
Test-BvVerificacao -Nome '01 Carregamento da CLI e fixture disponivel' -Bloco {
    if (-not (Get-Command Invoke-BvCli -ErrorAction SilentlyContinue)) { throw 'Invoke-BvCli nao carregada' }
    if (-not (Get-Command Get-BvColunasCatalogo -ErrorAction SilentlyContinue)) { throw 'Get-BvColunasCatalogo nao carregada' }
    if ($script:fixture.Count -lt 1) { throw 'fixture vazia' }
}

# 02 - menu principal imprime 4 opcoes reais
Test-BvVerificacao -Nome '02 Menu principal imprime as 4 opcoes atuais' -Bloco {
    $r = Invoke-BvCli -Entradas @('4') -Linhas $script:fixture
    foreach ($m in '1. Listar documentos','2. Pesquisar documento','3. Perguntar à IA sobre um documento','4. Sair') {
        if (-not ($r.Transcript -contains $m)) { throw "linha de menu ausente: $m" }
    }
}

# 03 - opcao 1 lista o catalogo
Test-BvVerificacao -Nome '03 Opcao 1 lista o catalogo' -Bloco {
    $r = Invoke-BvCli -Entradas @('1','4') -Linhas $script:fixture
    if (-not ($r.Transcript -contains 'BIBLIOTECA VIVA')) { throw 'cabecalho ausente' }
    $linhas = @($r.Transcript | Where-Object { $_ -match '^ecd9dca366af ' })
    if ($linhas.Count -ne 1) { throw 'linha TesePolimeros nao encontrada na listagem' }
}

# 04 - opcao 2 pesquisa por termo existente
Test-BvVerificacao -Nome '04 Opcao 2 pesquisa por termo existente' -Bloco {
    $r = Invoke-BvCli -Entradas @('2','TesePolimeros','4') -Linhas $script:fixture
    $linhas = @($r.Transcript | Where-Object { $_ -match '^ecd9dca366af ' })
    if ($linhas.Count -lt 1) { throw 'pesquisa nao retornou a TesePolimeros' }
}

# 05 - opcao 2 pesquisa por termo inexistente
Test-BvVerificacao -Nome '05 Opcao 2 pesquisa por termo inexistente' -Bloco {
    $r = Invoke-BvCli -Entradas @('2','zzznaoexiste','4') -Linhas $script:fixture
    if (-not ($r.Transcript | Where-Object { $_ -match 'Nenhuma ocorr' })) { throw 'mensagem de nao encontrado ausente' }
}

# 06 - opcao 3 selecao por termo unico
Test-BvVerificacao -Nome '06 Opcao 3 seleciona documento por termo' -Bloco {
    $r = Invoke-BvCli -Entradas @('3','TesePolimeros','qual e o tema geral?','3','4') -Linhas $script:fixture
    if (-not ($r.Transcript -contains 'Documento selecionado: TesePolimeros.pdf (ecd9dca366af)')) { throw 'documento nao selecionado por termo' }
}

# 07 - opcao 3 selecao por ID exato
Test-BvVerificacao -Nome '07 Opcao 3 seleciona documento por ID' -Bloco {
    $r = Invoke-BvCli -Entradas @('3','aabbcc112233','qual o tema?','3','4') -Linhas $script:fixture
    if (-not ($r.Transcript -contains 'Documento selecionado: ArtigoIA.pdf (aabbcc112233)')) { throw 'documento nao selecionado por ID' }
}

# 08 - opcao 3 selecao por numero
Test-BvVerificacao -Nome '08 Opcao 3 seleciona documento por numero' -Bloco {
    $r = Invoke-BvCli -Entradas @('3','1','qual o tema?','3','4') -Linhas $script:fixture
    if (-not ($r.Transcript | Where-Object { $_ -match 'Documento selecionado: TesePolimeros\.pdf' })) { throw 'documento nao selecionado por numero 1' }
}

# 09 - opcao 3 termo inexistente mostra mensagem
Test-BvVerificacao -Nome '09 Opcao 3 termo inexistente nao quebra' -Bloco {
    $r = Invoke-BvCli -Entradas @('3','zzz_nao_existe','4') -Linhas $script:fixture
    if (-not ($r.Transcript | Where-Object { $_ -match 'Nenhum documento encontrado' })) { throw 'mensagem de nao encontrado ausente' }
    if ($r.Opcoes[-1] -ne '4') { throw 'CLI deveria encerrar na opcao 4' }
}

# 10 - opcao 3: catalogo vazio
Test-BvVerificacao -Nome '10 Opcao 3 com catalogo vazio' -Bloco {
    $r = Invoke-BvCli -Entradas @('3','4') -Linhas @()
    if (-not ($r.Transcript -contains 'Catálogo vazio — nada para perguntar.')) { throw 'mensagem de catalogo vazio ausente' }
    if ($r.Opcoes[-1] -ne '4') { throw 'CLI deveria encerrar na opcao 4' }
}

# 11 - opcao 3 chama a IA e imprime "=== RESPOSTA ==="
Test-BvVerificacao -Nome '11 Opcao 3 chama IA e imprime resposta' -Bloco {
    $r = Invoke-BvCli -Entradas @('3','TesePolimeros','qual o tema?','3','4') -Linhas $script:fixture
    if (-not ($r.Transcript -contains 'Consultando a IA...')) { throw 'linha de consulta ausente' }
    if (-not ($r.Transcript -contains '=== RESPOSTA ===')) { throw 'cabecalho de resposta ausente' }
}

# 12 - opcao 3: duas perguntas consecutivas sobre o mesmo documento
Test-BvVerificacao -Nome '12 Opcao 3 permite duas perguntas consecutivas' -Bloco {
    $r = Invoke-BvCli -Entradas @('3','TesePolimeros','pergunta 1','1','pergunta 2','3','4') -Linhas $script:fixture
    $respostas = @($r.Transcript | Where-Object { $_ -eq '=== RESPOSTA ===' })
    if ($respostas.Count -ne 2) { throw "esperava 2 respostas, encontrei $($respostas.Count)" }
}

# 13 - submenu aparece apos a resposta
Test-BvVerificacao -Nome '13 Submenu aparece apos a resposta' -Bloco {
    $r = Invoke-BvCli -Entradas @('3','TesePolimeros','pergunta','3','4') -Linhas $script:fixture
    if (-not ($r.Transcript | Where-Object { $_ -match 'Nova pergunta sobre este documento' })) { throw 'submenu nao apareceu' }
    if (-not ($r.Transcript | Where-Object { $_ -match 'Escolher outro documento' })) { throw 'opcao "Escolher outro" ausente' }
    if (-not ($r.Transcript | Where-Object { $_ -match 'Voltar ao menu' })) { throw 'opcao "Voltar ao menu" ausente' }
}

# 14 - sub-opcao 3 volta ao menu principal
Test-BvVerificacao -Nome '14 Sub-opcao 3 (voltar) retorna ao menu principal' -Bloco {
    $r = Invoke-BvCli -Entradas @('3','TesePolimeros','pergunta','3','4') -Linhas $script:fixture
    # Depois do "voltar", o menu principal deve reaparecer
    $cabec = @($r.Transcript | Where-Object { $_ -eq 'BIBLIOTECA VIVA' })
    if ($cabec.Count -lt 2) { throw "esperava 2 cabecalhos (entrada + retorno), achei $($cabec.Count)" }
}

# 15 - opcao invalida no menu principal nao encerra
Test-BvVerificacao -Nome '15 Opcao invalida no menu principal nao encerra' -Bloco {
    $r = Invoke-BvCli -Entradas @('x','9','','4') -Linhas $script:fixture
    if (-not ($r.Transcript | Where-Object { $_ -match "Opção inválida: 'x'" })) { throw 'mensagem de invalida ausente' }
    if ($r.Opcoes.Count -ne 4) { throw 'loop deveria continuar apos invalidas' }
}

# 16 - sub-opcao invalida dentro da sessao
Test-BvVerificacao -Nome '16 Sub-opcao invalida dentro da sessao nao quebra' -Bloco {
    $r = Invoke-BvCli -Entradas @('3','TesePolimeros','pergunta','9','3','4') -Linhas $script:fixture
    if (-not ($r.Transcript | Where-Object { $_ -match "Opção inválida: '9'" })) { throw 'mensagem de sub-invalida ausente' }
    if ($r.Opcoes[-1] -ne '4') { throw 'CLI deveria encerrar na opcao 4' }
}

# 17 - IA nao eh fixada: a CLI so consome Invoke-BvChamadaOpencode
Test-BvVerificacao -Nome '17 CLI NAO fixa provedor/modelo' -Bloco {
    $corpo = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\cli\cli.ps1') -Raw
    if ($corpo -match 'nemotron|gemma|llama|minimax|sonnet|haiku|opus|gpt-') {
        throw 'CLI contem referencia textual a um modelo especifico'
    }
    if (-not ($corpo -match 'Invoke-BvCliPergunta')) { throw 'CLI nao delega para Invoke-BvCliPergunta' }
}

# 18 - pergunta vazia nao quebra a CLI
Test-BvVerificacao -Nome '18 Pergunta vazia nao quebra a CLI' -Bloco {
    $r = Invoke-BvCli -Entradas @('3','TesePolimeros','','4') -Linhas $script:fixture
    if (-not ($r.Transcript -contains 'Pergunta vazia.')) { throw 'mensagem de pergunta vazia ausente' }
    if ($r.Opcoes[-1] -ne '4') { throw 'CLI deveria encerrar na opcao 4' }
}

# 19 - sair pela opcao 4 termina limpo
Test-BvVerificacao -Nome '19 Sair pela opcao 4 termina limpo' -Bloco {
    $r = Invoke-BvCli -Entradas @('4') -Linhas $script:fixture
    if (-not ($r.Transcript -contains 'Encerrando.')) { throw 'mensagem de encerramento ausente' }
    if ($r.Opcoes[-1] -ne '4') { throw 'ultima opcao deveria ser 4' }
}

Write-Host ''
Write-Host "Resultado: $script:aprovados passaram, $script:falhados falharam"
exit ($script:falhados -gt 0 ? 1 : 0)
