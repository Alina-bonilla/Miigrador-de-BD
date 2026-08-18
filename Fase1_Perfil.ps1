$csvPath = "D:\FW.10.0 Pruebas\Migrador Prueba de concepto\perfiles_invalidos.csv"
$sqlInstance = "srv-bd"
$nomDataBase = "BDOriginal"
$SchemaDB = "dbo"
$TableDB = "Perfil"

# Se verifica la existencia del archivo CSV antes de continuar
# Test-Path: comprueba si una ruta existe.
# LiteralPath $csvPath: usa exactamente la ruta indicada, sin interpretar caracteres especiales como [ o *.
# PathType Leaf: exige que la ruta sea un archivo, no una carpeta.
if (-not (Test-Path -LiteralPath $csvPath -PathType Leaf)) {
    throw "No se encontró el archivo CSV: $csvPath"
}

# Se crea la conexión con el servidor usando autenticación de Windows
$serverConection = Connect-DbaInstance `
    -SqlInstance $sqlInstance `
    -Database $nomDataBase `
    -TrustServerCertificate

# 1. Obtener las columnas insertables de la tabla, excluye las columnas automaticas omo los id y las calculadas
# El símbolo | es el pipeline de PowerShell. Envía el resultado de Invoke-DbaQuery al siguiente comando Select-Object
# -ExpandProperty: Obtiene directamente la cadena con los nombres de las columnas
# El @(...) garantiza que $columnasSql sea una colección incluso cuando SQL devuelve una sola columna
$columnasSql = @(
    Invoke-DbaQuery `
        -SqlInstance $serverConection `
        -Database $nomDataBase `
        -Query @"
SELECT c.name AS Nombre
FROM sys.columns AS c
WHERE c.object_id = OBJECT_ID(N'$SchemaDB.$TableDB')
  AND c.is_identity = 0
  AND c.is_computed = 0
  AND c.name <> 'Valido'
ORDER BY c.column_id;
"@ |
    Select-Object -ExpandProperty Nombre
)
# -eq: operador “igual a”
if ($columnasSql.Count -eq 0) {
    throw "No se encontró $TableDB o la tabla no tiene columnas insertables."
}

Write-Host "Columnas esperadas por SQL Server:"
$columnasSql | ForEach-Object { Write-Host "  - $_" }

# 2. Leer los encabezados del CSV
# -Encoding UTF8: Indica que PowerShell debe interpretar el archivo con codificación UTF-8 (tildes y caracteres especiales)
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
    ForEach-Object { $_.Trim() } # recorre cada nombre de columna y elimina los espacios que pueda tener al inicio o al final
)
Write-Host "Columnas encontradas en el CSV:"
$columnasCsv | ForEach-Object { Write-Host "  - $_" }

# 3. Comparar las estructuras archivo con la tabla
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

# 4. Limpiar Tablas de Error y Ajuste antes de la carga de datos
Invoke-DbaQuery `
    -SqlInstance $serverConection `
    -Database $nomDataBase `
    -Query "TRUNCATE TABLE dbo.Error; TRUNCATE TABLE dbo.Ajuste;"

# 5. Importar si las estructuras coinciden
# QuoteMode Strict: exige que las comillas cumplan el formato CSV.
# MismatchedFieldAction ThrowException: cancela cuando una fila tiene más o menos campos.
# DuplicateHeaderBehavior ThrowException: rechaza encabezados duplicados.
# ParseErrorAction ThrowException: cancela al encontrar una fila mal formada.
# EnableException: permite capturar excepciones con tu propio bloque try/catch.

try{
    Import-DbaCsv `
        -SqlInstance $serverConection `
        -Database $nomDataBase `
        -Schema $SchemaDB  `
        -Table $TableDB `
        -Path $csvPath `
        -Delimiter "," `
        -Encoding UTF8 `
        -QuoteMode Strict `
        -MismatchedFieldAction ThrowException `
        -DuplicateHeaderBehavior ThrowException `
        -ParseErrorAction ThrowException `
        -Truncate `
        -EnableException

    # 6. Ajustar y Validar (SPs de Validaciones_F1.sql)
    # Invoke-DbaQuery: Ejecuta consultas, scripts y SP en instancias de SQL Server
    Invoke-DbaQuery `
        -SqlInstance $serverConection `
        -Database $nomDataBase `
        -Query "EXEC dbo.usp_Perfil_Ajustar;" `
        -EnableException

    Invoke-DbaQuery `
        -SqlInstance $serverConection `
        -Database $nomDataBase `
        -Query "EXEC dbo.usp_Perfil_Validar;" `
        -EnableException

    # 7. Actualizar indicador Valido (usp_MIG_ActualizarValidosTabla)
    Invoke-DbaQuery `
        -SqlInstance $serverConection `
        -Database $nomDataBase `
        -Query "EXEC dbo.usp_MIG_ActualizarValidosTabla @Tabla = 'dbo.Perfil', @ColumnaId = 'IdPerfil';" `
        -EnableException

    # 8. Obtener resultados (equivalente a 0 Migrador Reporte.sql) Se usa para mostrar los resultados de la migración y validación
    Write-Host "`n=== Ajustes (auto-corregidos) ==="
    Invoke-DbaQuery -SqlInstance $serverConection -Database $nomDataBase -Query "SELECT IdRegistro, Descripcion FROM dbo.Ajuste" | Format-Table

    Write-Host "=== Errores (filas invalidas) ==="
    Invoke-DbaQuery -SqlInstance $serverConection -Database $nomDataBase -Query "SELECT IdRegistro, Codigo, Descripcion FROM dbo.Error ORDER BY IdRegistro" | Format-Table

    Write-Host "=== Staging: Valido=1 vs Valido=0 ==="
    Invoke-DbaQuery -SqlInstance $serverConection -Database $nomDataBase -Query "SELECT Valido, COUNT(*) AS Cantidad FROM dbo.Perfil GROUP BY Valido" | Format-Table

    Write-Host "=== Detalle staging ==="
    Invoke-DbaQuery -SqlInstance $serverConection -Database $nomDataBase -Query "SELECT IdPerfil, Codigo, Nombre, Valido FROM dbo.Perfil ORDER BY IdPerfil" | Format-Table

    Write-Host "Migración completada correctamente." -ForegroundColor Green
}
catch {
    throw "Migración cancelada. Detalle: $($_.Exception.Message)"
}

