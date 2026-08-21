if (-not (Get-Command Get-BvConfig -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'config.ps1')
}

function Get-BvRegistroModulos {
    return @(
        [pscustomobject]@{
            Extensao     = '.pdf'
            ScriptModulo = (Join-Path $PSScriptRoot '..\modulos\modulo_pdf.ps1')
        }
    )
}

function Get-BvRota {
    param([Parameter(Mandatory)][string]$Tipo)

    $tipoNormalizado = $Tipo.ToLowerInvariant()
    if (-not $tipoNormalizado.StartsWith('.')) { $tipoNormalizado = ".$tipoNormalizado" }

    $registro = @(Get-BvRegistroModulos | Where-Object { $_.Extensao -eq $tipoNormalizado })
    if ($registro.Count -gt 0) {
        return [pscustomobject]@{
            Estado       = 'ComModulo'
            Tipo         = $tipoNormalizado
            ScriptModulo = $registro[0].ScriptModulo
        }
    }

    $cfg = Get-BvConfig
    if ($cfg.ExtensoesConhecidasSemModulo -contains $tipoNormalizado) {
        return [pscustomobject]@{
            Estado       = 'ConhecidoSemModulo'
            Tipo         = $tipoNormalizado
            ScriptModulo = $null
        }
    }

    return [pscustomobject]@{
        Estado       = 'Desconhecido'
        Tipo         = $tipoNormalizado
        ScriptModulo = $null
    }
}

function Test-BvRegistroModulosValido {
    $cfg = Get-BvConfig
    $extensoesRegistro = @(Get-BvRegistroModulos | ForEach-Object { $_.Extensao })
    $diferencas = @(Compare-Object -ReferenceObject @($cfg.ExtensoesComModulo) -DifferenceObject $extensoesRegistro)
    return ($diferencas.Count -eq 0)
}
