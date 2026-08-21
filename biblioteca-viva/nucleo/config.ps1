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
    }
}
