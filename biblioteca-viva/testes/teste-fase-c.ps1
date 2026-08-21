$ErrorActionPreference = 'Stop'

$pastaNucleo = Join-Path $PSScriptRoot '..\nucleo'
. (Join-Path $pastaNucleo 'config.ps1')
. (Join-Path $pastaNucleo 'catalogo.ps1')
. (Join-Path $pastaNucleo 'identificador.ps1')
. (Join-Path $pastaNucleo 'diario.ps1')
. (Join-Path $pastaNucleo 'roteador.ps1')
. (Join-Path $pastaNucleo 'descobridor.ps1')
. (Join-Path $pastaNucleo 'reconciliacao.ps1')
. (Join-Path $pastaNucleo 'extrator.ps1')
. (Join-Path $pastaNucleo 'classificador.ps1')

$script:aprovados = 0
$script:falhados = 0
$script:chamadasIA = 0

function Test-BvVerificacao {
    param(
        [Parameter(Mandatory)][string]$Nome,
        [Parameter(Mandatory)][scriptblock]$Bloco
    )
    try {
        & $Bloco
        Write-Host "[PASSOU] $Nome"
        $script:aprovados++
    }
    catch {
        Write-Host "[FALHOU] $Nome -> $($_.Exception.Message)"
        $script:falhados++
    }
}

function New-BvPdfProvaC {
    param([Parameter(Mandatory)][string]$Destino, [string]$Frase = '', [switch]$SemTexto)
    $null = & python (Join-Path $pastaRaiz 'gera_pdf.py') $Destino $Frase $(if ($SemTexto) { '0' } else { '1' }) 2>&1
    if ($LASTEXITCODE -ne 0) { throw "falha ao gerar pdf de prova: $Destino" }
}

function New-BvLinhaDeTeste {
    param([Parameter(Mandatory)][string]$Caminho)
    $identidade = Get-BvIdentidade -Caminho $Caminho
    return [pscustomobject]@{
        id = $identidade.id; sha256 = $identidade.sha256
        caminho_atual = $identidade.caminho_atual; tipo = '.pdf'
    }
}

function Remove-BvDadosLocais {
    foreach ($arquivo in @((Get-BvArquivoCatalogo), (Get-BvArquivoDiario))) {
        if (Test-Path -LiteralPath $arquivo) { Remove-Item -LiteralPath $arquivo -Force }
    }
    $cfg = Get-BvConfig
    foreach ($sub in @($cfg.PastaExtracoes, $cfg.PastaClassificacoes)) {
        $pasta = Join-Path $cfg.PastaDados $sub
        if (Test-Path -LiteralPath $pasta) { Remove-Item -LiteralPath $pasta -Recurse -Force }
    }
}

Write-Host '=== Biblioteca Viva - Testes da Fase C ==='
Write-Host ''

$pastaRaiz = Join-Path ([IO.Path]::GetTempPath()) 'bv-teste-fase-c'
$pastaLib = Join-Path $pastaRaiz 'lib'

if (Test-Path -LiteralPath $pastaRaiz) { Remove-Item -LiteralPath $pastaRaiz -Recurse -Force }
New-Item -ItemType Directory -Path $pastaLib -Force | Out-Null

Remove-BvDadosLocais

Set-Content -LiteralPath (Join-Path $pastaRaiz 'gera_pdf.py') -Encoding utf8 -Value @'
import sys

def build(destino, texto, com_fonte):
    conteudo = f"BT /F1 12 Tf 72 720 Td ({texto}) Tj ET".encode("ascii") if com_fonte else b"% pagina sem conteudo de texto %"
    recursos = b"<< /Font << /F1 4 0 R >> >>" if com_fonte else b"<< >>"
    objs = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /Resources " + recursos + b" /Contents 5 0 R >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>" if com_fonte else b"<< >>",
        b"<< /Length " + str(len(conteudo)).encode() + b" >>\nstream\n" + conteudo + b"\nendstream",
    ]
    buf = bytearray(b"%PDF-1.4\n")
    offsets = []
    for i, corpo in enumerate(objs, start=1):
        offsets.append(len(buf))
        buf += f"{i} 0 obj\n".encode() + corpo + b"\nendobj\n"
    xref_pos = len(buf)
    n = len(objs) + 1
    buf += f"xref\n0 {n}\n".encode()
    buf += b"0000000000 65535 f \n"
    for off in offsets:
        buf += f"{off:010d} 00000 n \n".encode()
    buf += f"trailer << /Size {n} /Root 1 0 R /Producer (ProdutorTesteC) >>\nstartxref\n{xref_pos}\n%%EOF\n".encode()
    with open(destino, "wb") as saida:
        saida.write(bytes(buf))

build(sys.argv[1], sys.argv[2], sys.argv[3] == "1")
'@

$fraseFinanceira = ('EXTRATO BANCARIO CONTA 12345 AGENCIA 0001 SALDO ANTERIOR R$ 1500,00 PAGAMENTO RECEBIDO DE CLIENTE DEPOSITO EM ESPECIE TARIFA BANCARIA ZERO SALDO FINAL R$ 2345,67 EMITIDO PELO BANCO EXEMPLO SA ' * 3).Trim()
$fraseReligiosa = ('SERMAO PREGADO NA CATEDRAL SOBRE A CARIDADE E O PROXIMO TEXTO SACRO REFLEXAO PASTAL PARA A COMUNIDADE REUNIDA NA CELEBRACAO DOMINICAL ' * 3).Trim()
$fraseAcademica = ('TESE SOBRE POLIMEROS CONDUTORES ESTRUTURA MOLECULAR APLICACOES INDUSTRIAIS REVISAO BIBLIOGRAFICA METODOLOGIA EXPERIMENTAL RESULTADOS OBTIDOS EM LABORATORIO CONCLUSOES FINAIS ' * 3).Trim()
$fraseBaixa = ('DOCUMENTO DE TESTE COM CONTEUDO GENERICO PARA AVALIAR CLASSIFICACAO DE BAIXA CONFIANCA NO PIPELINE DA BIBLIOTECA VIVA FASE C ' * 3).Trim()

$caminhoExtrato = Join-Path $pastaLib 'extrato.pdf'
$caminhoSermao = Join-Path $pastaLib 'sermao.pdf'
$caminhoScan = Join-Path $pastaLib 'scan.pdf'

New-BvPdfProvaC -Destino $caminhoExtrato -Frase $fraseFinanceira
New-BvPdfProvaC -Destino $caminhoSermao -Frase $fraseReligiosa

$script:mockValido = {
    param($ps, $pu)
    $script:chamadasIA++
    '{"categoria":"financeiro","confianca":0.90,"motivo":"texto menciona extrato bancario e saldo","palavras_chave":["extrato","saldo"],"resumo":"Documento financeiro bancario."}'
}
$script:mockInvalido = {
    param($ps, $pu)
    $script:chamadasIA++
    '{"categoria":"categoria_inventada","confianca":0.90,"motivo":"teste de recusa"}'
}
$script:mockBaixa = {
    param($ps, $pu)
    $script:chamadasIA++
    '{"categoria":"academico_tecnico","confianca":0.30,"motivo":"conteudo generico tecnico"}'
}

Test-BvVerificacao -Nome '01 Config da Fase C completa (taxonomia, modelo, limites)' -Bloco {
    $cfg = Get-BvConfig
    if (@($cfg.Taxonomia).Count -ne 9) { throw "taxonomia deveria ter 9 categorias, tem $(@($cfg.Taxonomia).Count)" }
    if (-not $cfg.ModeloIA) { throw 'ModeloIA vazio' }
    if (-not $cfg.UrlOpenRouter) { throw 'UrlOpenRouter vazia' }
    if ($cfg.LimiteCaracteresIA -le 0 -or $cfg.MinimoCaracteresTexto -le 0) { throw 'limites invalidos' }
    foreach ($cat in $cfg.Taxonomia) { if (-not $cfg.DescricoesTaxonomia[$cat]) { throw "descricao ausente para $cat" } }
}

Test-BvVerificacao -Nome '02 Ponte Python disponivel com pypdf importavel' -Bloco {
    & python --version *> $null
    if ($LASTEXITCODE -ne 0) { throw 'python indisponivel' }
    & python -c 'import pypdf' *> $null
    if ($LASTEXITCODE -ne 0) { throw 'pypdf nao importavel' }
}

Test-BvVerificacao -Nome '03 Extrator processa PDF com texto e cria sidecars' -Bloco {
    $linha = New-BvLinhaDeTeste -Caminho $caminhoExtrato
    $ficha = Invoke-BvExtracaoDeLinha -Linha $linha
    if (-not $ficha.Ok) { throw "extracao falhou: $($ficha.Observacoes -join ',')" }
    if ($ficha.DoCache) { throw 'primeira extracao nao deveria vir do cache' }
    if ($ficha.Caracteres -lt 200) { throw "caracteres insuficientes: $($ficha.Caracteres)" }
    if (-not (Test-Path -LiteralPath $ficha.CaminhoTexto)) { throw 'sidecar txt ausente' }
    $metaEsperado = Join-Path (Get-BvPastaExtracoes) "$($linha.id).json"
    if (-not (Test-Path -LiteralPath $metaEsperado)) { throw 'sidecar json ausente' }
}

Test-BvVerificacao -Nome '04 Cache da extracao funciona na segunda chamada' -Bloco {
    $linha = New-BvLinhaDeTeste -Caminho $caminhoExtrato
    $ficha = Invoke-BvExtracaoDeLinha -Linha $linha
    if (-not $ficha.DoCache) { throw 'segunda extracao deveria vir do cache' }
    if ($ficha.Caracteres -lt 200) { throw 'cache com conteudo errado' }
}

Test-BvVerificacao -Nome '05 PDF criptografado com senha vazia abre e extrai' -Bloco {
    $auxiliar = Join-Path $pastaRaiz 'criptografa.py'
    Set-Content -LiteralPath $auxiliar -Encoding utf8 -Value @'
import sys
from pypdf import PdfReader, PdfWriter
origem, destino, senha = sys.argv[1], sys.argv[2], sys.argv[3]
r = PdfReader(origem)
w = PdfWriter()
for p in r.pages:
    w.add_page(p)
w.encrypt(user_password=senha, owner_password='dono')
with open(destino, 'wb') as f:
    w.write(f)
print('ok')
'@
    $protegidoVazio = Join-Path $pastaRaiz 'protegido-vazio.pdf'
    $null = & python $auxiliar $caminhoExtrato $protegidoVazio '' 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'falha ao gerar pdf criptografado com senha vazia' }
    $linha = New-BvLinhaDeTeste -Caminho $protegidoVazio
    $ficha = Invoke-BvExtracaoDeLinha -Linha $linha
    if (-not $ficha.Ok) { throw "deveria abrir com senha vazia: $($ficha.Observacoes -join ',')" }
    if (@($ficha.Observacoes) -notcontains 'aberto_com_senha_vazia') { throw 'observacao aberto_com_senha_vazia ausente' }
}

Test-BvVerificacao -Nome '06 PDF criptografado com senha real marca PrecisaSenha' -Bloco {
    $auxiliar = Join-Path $pastaRaiz 'criptografa.py'
    $protegidoReal = Join-Path $pastaRaiz 'protegido-real.pdf'
    $null = & python $auxiliar $caminhoExtrato $protegidoReal 'segredo123' 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'falha ao gerar pdf criptografado com senha real' }
    $linha = New-BvLinhaDeTeste -Caminho $protegidoReal
    $ficha = Invoke-BvExtracaoDeLinha -Linha $linha
    if ($ficha.Ok) { throw 'nao deveria conseguir extrair' }
    if (-not $ficha.PrecisaSenha) { throw 'flag PrecisaSenha ausente' }
}

Test-BvVerificacao -Nome '07 PDF sem texto marca PrecisaOcr e texto insuficiente' -Bloco {
    New-BvPdfProvaC -Destino $caminhoScan -SemTexto
    $linha = New-BvLinhaDeTeste -Caminho $caminhoScan
    $ficha = Invoke-BvExtracaoDeLinha -Linha $linha
    if (-not $ficha.Ok) { throw "extracao deveria suceder sem texto: $($ficha.Observacoes -join ',')" }
    if (-not $ficha.PrecisaOcr) { throw 'flag PrecisaOcr ausente' }
    if ($ficha.Caracteres -ge (Get-BvConfig).MinimoCaracteresTexto) { throw 'deveria ter texto insuficiente' }
}

Test-BvVerificacao -Nome '08 Arquivo malformado falha de forma limpa' -Bloco {
    $lixo = Join-Path $pastaRaiz 'lixo.pdf'
    Set-Content -LiteralPath $lixo -Value 'isto nao e um pdf' -Encoding utf8
    $linha = New-BvLinhaDeTeste -Caminho $lixo
    $ficha = Invoke-BvExtracaoDeLinha -Linha $linha
    if ($ficha.Ok) { throw 'malformado nao deveria extrair' }
    if ($ficha.Caracteres -ne 0) { throw 'malformado nao deveria ter texto' }
}

Test-BvVerificacao -Nome '09 Pipeline integrado classifica 2 e marca 1 sem texto' -Bloco {
    $d = Get-BvDescobertas -Modo 'migracao' -Pastas @($pastaLib)
    $null = Invoke-BvReconciliacao -Descobertas $d
    $antes = @(Get-BvCatalogo)
    if ($antes.Count -ne 3) { throw "catalogo deveria ter 3 linhas, tem $($antes.Count)" }

    $script:chamadasIA = 0
    $r = Invoke-BvClassificacaoDeLinha -FuncaoChamada $script:mockValido -IdLote 'lote-teste-09'
    if ($r.Elegiveis -ne 3) { throw "elegiveis deveria ser 3, foi $($r.Elegiveis)" }
    if ($r.Classificados -ne 2) { throw "classificados deveria ser 2, foi $($r.Classificados)" }
    if ($r.SemTexto -ne 1) { throw "semtexto deveria ser 1, foi $($r.SemTexto)" }
    if ($script:chamadasIA -ne 2) { throw "IA deveria ser chamada 2 vezes, foi $($script:chamadasIA)" }

    $linhaOk = Get-BvLinhaPorCaminho -Caminho $caminhoExtrato
    if ($linhaOk.status -ne 'classificado') { throw "extrato deveria estar classificado, esta $($linhaOk.status)" }
    if ($linhaOk.categoria -ne 'financeiro') { throw "categoria incorreta: $($linhaOk.categoria)" }
    if ($linhaOk.classificado_por -ne 'ia') { throw 'classificado_por deveria ser ia' }
    if ($linhaOk.lote -ne 'lote-teste-09') { throw 'lote nao registrado' }
    $detalhes = $linhaOk.detalhes | ConvertFrom-Json
    if (-not $detalhes.ia) { throw 'bloco ia ausente nos detalhes' }

    $linhaScan = @(Get-BvCatalogo) | Where-Object { $_.nome_original -eq 'scan.pdf' }
    if ($linhaScan.status -eq 'classificado') { throw 'scan sem texto nao deveria ser classificado' }
    if ($linhaScan.observacoes -notmatch 'sem_texto_para_classificar') { throw 'marcador sem_texto ausente' }

    $eventos = @(Get-BvDiario | Where-Object { $_.evento -eq 'classificado' })
    if ($eventos.Count -lt 2) { throw 'diario deveria registrar 2 classificacoes' }
    $eventosSemTexto = @(Get-BvDiario | Where-Object { $_.evento -eq 'classificacao_sem_texto' })
    if ($eventosSemTexto.Count -lt 1) { throw 'diario deveria registrar o caso sem texto' }

    $historicos = @(Get-ChildItem (Get-BvPastaClassificacoes) -Filter 'lote-*.jsonl')
    if ($historicos.Count -lt 1) { throw 'arquivo de historico ausente' }
    $registros = @(Get-Content $historicos[0].FullName | ForEach-Object { $_ | ConvertFrom-Json })
    $validos = @($registros | Where-Object { $_.valido })
    if ($validos.Count -lt 2) { throw 'historico deveria ter 2 registros validos' }
    if (-not $validos[0].resposta_bruta) { throw 'resposta bruta nao registrada no historico' }
}

Test-BvVerificacao -Nome '10 Resposta fora da taxonomia e recusada sem tocar o catalogo' -Bloco {
    New-BvPdfProvaC -Destino (Join-Path $pastaLib 'tese.pdf') -Frase $fraseAcademica
    $d = Get-BvDescobertas -Modo 'migracao' -Pastas @($pastaLib)
    $null = Invoke-BvReconciliacao -Descobertas $d

    $script:chamadasIA = 0
    $r = Invoke-BvClassificacaoDeLinha -FuncaoChamada $script:mockInvalido -IdLote 'lote-teste-10'
    if ($r.Recusadas -ne 1) { throw "recusadas deveria ser 1, foi $($r.Recusadas)" }
    if ($script:chamadasIA -ne 2) { throw "deveria haver retry (2 chamadas), houve $($script:chamadasIA)" }

    $linhaTese = Get-BvLinhaPorCaminho -Caminho (Join-Path $pastaLib 'tese.pdf')
    if ($linhaTese.status -eq 'classificado') { throw 'recusada nao deveria ser classificada' }
    if ($linhaTese.categoria) { throw 'categoria nao deveria ser gravada em recusa' }

    $historico = Get-ChildItem (Get-BvPastaClassificacoes) -Filter '*teste-10*'
    $registros = @(Get-Content $historico.FullName | ForEach-Object { $_ | ConvertFrom-Json })
    $invalidos = @($registros | Where-Object { -not $_.valido })
    if ($invalidos.Count -ne 1) { throw 'historico deveria registrar a recusa' }
    $evento = @(Get-BvDiario | Where-Object { $_.evento -eq 'classificacao_recusada' })
    if ($evento.Count -lt 1) { throw 'diario deveria registrar classificacao_recusada' }

    $r2 = Invoke-BvClassificacaoDeLinha -FuncaoChamada $script:mockValido -IdLote 'lote-teste-10b'
    if ($r2.Classificados -ne 1) { throw "reclassificacao apos recusa deveria funcionar, foi $($r2.Classificados)" }
    $linhaTese2 = Get-BvLinhaPorCaminho -Caminho (Join-Path $pastaLib 'tese.pdf')
    if ($linhaTese2.status -ne 'classificado') { throw 'tese deveria ser classificada na segunda passada' }
}

Test-BvVerificacao -Nome '11 Colunas tecnicas permanecem intactas apos classificacoes' -Bloco {
    foreach ($linha in @(Get-BvCatalogo)) {
        if (-not $linha.sha256 -or $linha.sha256.Length -ne 64) { throw "sha256 corrompido no id $($linha.id)" }
        if (-not (Test-Path -LiteralPath $linha.caminho_atual)) { throw "caminho tecnico alterado no id $($linha.id)" }
        if ([int]$linha.tamanho_bytes -le 0) { throw "tamanho corrompido no id $($linha.id)" }
    }
    $classificadas = @(@(Get-BvCatalogo) | Where-Object { $_.status -eq 'classificado' })
    foreach ($linha in $classificadas) {
        if ($linha.classificado_por -ne 'ia' -or -not $linha.processado_em) { throw "metadados semanticos incompletos no id $($linha.id)" }
    }
}

Test-BvVerificacao -Nome '12 Segunda execucao sem mudancas nao chama a IA' -Bloco {
    $script:chamadasIA = 0
    $r = Invoke-BvClassificacaoDeLinha -FuncaoChamada $script:mockValido -IdLote 'lote-teste-12'
    if ($r.Classificados -ne 0) { throw "nenhum deveria ser reprocessado, foram $($r.Classificados)" }
    if ($script:chamadasIA -ne 0) { throw "IA nao deveria ser chamada, foi chamada $($script:chamadasIA) vezes" }
}

Test-BvVerificacao -Nome '13 Baixa confianca e classificada mas sinalizada' -Bloco {
    New-BvPdfProvaC -Destino (Join-Path $pastaLib 'generico.pdf') -Frase $fraseBaixa
    $d = Get-BvDescobertas -Modo 'migracao' -Pastas @($pastaLib)
    $null = Invoke-BvReconciliacao -Descobertas $d

    $r = Invoke-BvClassificacaoDeLinha -FuncaoChamada $script:mockBaixa -IdLote 'lote-teste-13'
    if ($r.BaixaConfianca -ne 1) { throw "baixa confianca deveria ser 1, foi $($r.BaixaConfianca)" }
    $linhaGenerica = Get-BvLinhaPorCaminho -Caminho (Join-Path $pastaLib 'generico.pdf')
    if ($linhaGenerica.status -ne 'classificado') { throw 'baixa confianca ainda deve ser classificada' }
    if ([double]$linhaGenerica.confianca -ge (Get-BvConfig).ConfiancaMinima) { throw 'confianca deveria estar abaixo do minimo' }
}

Test-BvVerificacao -Nome '14 Porta unica aceita status classificado e rejeita invalidos' -Bloco {
    $total = @(Get-BvCatalogo).Count
    $linha = @(Get-BvCatalogo) | Select-Object -First 1
    $salvoStatus = $linha.status
    $linha.status = 'classificado'
    Save-BvCatalogo -Linhas @(Get-BvCatalogo) | Out-Null
    $linha.status = $salvoStatus
    Save-BvCatalogo -Linhas @(Get-BvCatalogo) | Out-Null

    $linhaRuim = New-BvLinhaCatalogo
    $linhaRuim.sha256 = 'a' * 64
    $linhaRuim.caminho_atual = 'C:\inexistente\z.pdf'
    $linhaRuim.status = 'status-fantasma'
    $erro = $null
    try { Save-BvCatalogo -Linhas @($linhaRuim) | Out-Null } catch { $erro = $_.Exception.Message }
    if ($null -eq $erro) { throw 'status invalido deveria ser recusado' }
    if (@(Get-BvCatalogo).Count -ne $total) { throw 'catalogo nao deveria mudar de tamanho' }
}

$script:chamadasRota = 0
function Invoke-BvChamadaOpencode {
    param([string]$PromptSistema, [string]$PromptUsuario)
    $script:chamadasRota++
    '{"categoria":"financeiro","confianca":0.88,"motivo":"mock da rota opencode","palavras_chave":["rota"],"resumo":"Teste de roteamento."}'
}

Test-BvVerificacao -Nome '15 Roteamento ProvedorIA=opencode usa Invoke-BvChamadaOpencode sem rede' -Bloco {
    New-BvPdfProvaC -Destino (Join-Path $pastaLib 'rota.pdf') -Frase $fraseFinanceira
    $d = Get-BvDescobertas -Modo 'migracao' -Pastas @($pastaLib)
    $null = Invoke-BvReconciliacao -Descobertas $d
    if ((Get-BvConfig).ProvedorIA -ne 'opencode') { throw 'ProvedorIA deveria ser opencode' }

    $script:chamadasRota = 0
    $r = Invoke-BvClassificacaoDeLinha -IdLote 'teste-15'
    if ($r.Classificados -ne 1) { throw "somente o novo arquivo deveria ser classificado, foi $($r.Classificados)" }
    if ($script:chamadasRota -ne 1) { throw "rota opencode deveria ser chamada 1 vez, foi $($script:chamadasRota)" }

    $linhaRota = Get-BvLinhaPorCaminho -Caminho (Join-Path $pastaLib 'rota.pdf')
    if ($linhaRota.status -ne 'classificado') { throw "deveria estar classificado via rota opencode, esta $($linhaRota.status)" }
    if ($linhaRota.modelo -ne (Get-BvConfig).ModeloIA) { throw 'modelo no catalogo difere do config' }
    if ((Get-BvConfig).ModeloIA -notmatch '^opencode/') { throw 'ModeloIA deveria ser id real do provedor opencode' }

    $hist15 = Join-Path (Get-BvPastaClassificacoes) 'lote-teste-15.jsonl'
    if (-not (Test-Path -LiteralPath $hist15)) { throw 'historico do lote 15 ausente' }
    $reg15 = @(Get-Content -LiteralPath $hist15 | ForEach-Object { $_ | ConvertFrom-Json })
    if ($reg15.Count -ne 1 -or -not $reg15[0].valido) { throw 'historico deveria ter 1 registro valido' }
    if ($reg15[0].modelo -ne (Get-BvConfig).ModeloIA) { throw 'modelo no historico difere do config' }
}

if (Test-Path -LiteralPath $pastaRaiz) { Remove-Item -LiteralPath $pastaRaiz -Recurse -Force }

Remove-BvDadosLocais

Write-Host ''
Write-Host "Resultado: $script:aprovados passaram, $script:falhados falharam"
Write-Host 'dados\ local resetado apos os testes'

exit ($script:falhados -gt 0 ? 1 : 0)
