$csvPath = "D:\FW.10.0 Pruebas\Migrador Prueba de concepto\usuarios.csv"
# Conexión con autenticación de Windows
$server = Connect-DbaInstance `
    -SqlInstance "srv-bd" `
    -Database "BDOriginal" `
    -TrustServerCertificate

# 1. Obtener las columnas insertables de dbo.usuarios
$columnasSql = @(
    Invoke-DbaQuery `
        -SqlInstance $server `
        -Database "BDOriginal" `
        -Query @"
SELECT c.name AS Nombre
FROM sys.columns AS c
WHERE c.object_id = OBJECT_ID(N'dbo.usuarios')
  AND c.is_identity = 0
  AND c.is_computed = 0
ORDER BY c.column_id;
"@ |
    Select-Object -ExpandProperty Nombre
)
if ($columnasSql.Count -eq 0) {
    throw "No se encontró dbo.usuarios o la tabla no tiene columnas insertables."
}
Write-Host "Columnas esperadas por SQL Server:"
$columnasSql | ForEach-Object { Write-Host "  - $_" }

# 2. Leer los encabezados del CSV
$primerRegistro = Import-Csv `
    -Path $csvPath `
    -Delimiter "," `
    -Encoding UTF8 |
    Select-Object -First 1
if ($null -eq $primerRegistro) {
    throw "El CSV está vacío o no contiene registros."
}
$columnasCsv = @(
    $primerRegistro.PSObject.Properties.Name |
    ForEach-Object { $_.Trim() }
)
Write-Host "Columnas encontradas en el CSV:"
$columnasCsv | ForEach-Object { Write-Host "  - $_" }

# 3. Comparar las estructuras
$columnasFaltantes = @(
    $columnasSql |
    Where-Object { $_ -notin $columnasCsv }
)
$columnasSobrantes = @(
    $columnasCsv |
    Where-Object { $_ -notin $columnasSql }
)
if ($columnasFaltantes.Count -gt 0 -or $columnasSobrantes.Count -gt 0) {
    $mensajes = @()
    if ($columnasFaltantes.Count -gt 0) {
        $mensajes += "Faltan columnas en el CSV: $($columnasFaltantes -join ', ')"
    }
    if ($columnasSobrantes.Count -gt 0) {
        $mensajes += "El CSV tiene columnas no existentes en la tabla: $($columnasSobrantes -join ', ')"
    }
    throw "Migración cancelada. $($mensajes -join '. ')"
}

# 4. Importar si las estructuras coinciden
try{
Import-DbaCsv `
    -SqlInstance $server `
    -Database "BDOriginal" `
    -Schema "dbo" `
    -Table "usuarios" `
    -Path $csvPath `
    -Delimiter "," `
    -Encoding UTF8 `
    -QuoteMode Strict `
    -MismatchedFieldAction ThrowException `
    -DuplicateHeaderBehavior ThrowException `
    -ParseErrorAction ThrowException `
    -EnableException
Write-Host "Migración completada correctamente." -ForegroundColor Green
}
catch {
    throw "Migración cancelada. El CSV contiene una fila inválida: $($_.Exception.Message)"
}