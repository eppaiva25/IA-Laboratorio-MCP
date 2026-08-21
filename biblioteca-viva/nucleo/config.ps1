function Get-BvConfig {
    return [pscustomobject]@{
        VersaoEsquema                = 1
        RaizCodigo                   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
        PastaDados                   = (Join-Path $PSScriptRoot '..\dados')
        PastasMigracao               = @('G:\Documentos_Todos\PDFs\Projeto PDFs')
        PastasManutencao             = @()
        ModoPadrao                   = 'migracao'
        ModosValidos                 = @('migracao', 'manutencao')
        NomeArquivoCatalogo          = 'catalogo.csv'
        NomeArquivoDiario            = 'diario.jsonl'
        NomeArquivoEsquema           = 'esquema.json'
        TamanhoId                    = 12
        LimiteAnaliseLeveMb          = 50
        StatusValidos                = @('novo', 'inventariado', 'classificado', 'proposto', 'aprovado', 'executado', 'verificado', '_REVISAR', '_PROBLEMAS', 'desaparecido', 'aguardando_hash')
        ExtensoesComModulo           = @('.pdf')
        ExtensoesConhecidasSemModulo = @('.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tif', '.tiff', '.mp3', '.wav', '.mp4', '.mkv', '.avi', '.zip', '.rar', '.7z', '.exe', '.msi', '.txt', '.rtf')

        PastaExtracoes               = 'extracoes'
        PastaClassificacoes          = 'classificacoes'
        Taxonomia                    = @('financeiro', 'documento_pessoal', 'automotivo', 'academico_tecnico', 'manual_produto', 'religioso', 'correspondencia', 'digitalizado_diverso', 'outro')
        DescricoesTaxonomia          = [ordered]@{
            financeiro           = 'extratos, recibos, impostos, comprovantes bancarios e pagamentos'
            documento_pessoal    = 'certidoes, documentos civis, titulos e comprovantes pessoais'
            automotivo           = 'multas, seguro, documentacao de veiculos'
            academico_tecnico    = 'teses, trabalhos tecnicos, artigos cientificos'
            manual_produto       = 'manuais, especificacoes e materiais de produtos'
            religioso            = 'sermoes, textos e materiais religiosos'
            correspondencia      = 'cartas, oficios e comunicacoes'
            digitalizado_diverso = 'digitalizacoes sem tema claramente identificavel'
            outro                = 'conteudo que nao se encaixa em nenhuma outra categoria'
        }
        ProvedorIA                   = 'opencode'
        ModeloIA                     = 'opencode/nemotron-3.5-lightning-free'
        UrlOpenRouter                = 'https://openrouter.ai/api/v1/chat/completions'
        LimiteCaracteresIA           = 6000
        MinimoCaracteresTexto        = 200
        ConfiancaMinima              = 0.6
    }
}
