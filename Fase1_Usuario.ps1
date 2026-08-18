$csvPath = "C:\...\Migrador Prueba de concepto\usuarios.csv"
$sqlInstance = "srv-bd"
$nomDataBase = "BDOriginal"
$SchemaDB = "dbo"
$TableDB = "Usuario"

# Se verifica la existencia del archivo CSV antes de continuar
if (-not (Test-Path -LiteralPath $csvPath -PathType Leaf)) {
    throw "No se encontró el archivo CSV: $csvPath"
}

# Se crea la conexión con el servidor usando autenticación de Windows
$serverConection = Connect-DbaInstance `
    -SqlInstance $sqlInstance `
    -Database $nomDataBase `
    -TrustServerCertificate

# 1. Limpiar Tablas de Error y Ajuste antes de la carga de datos
Invoke-DbaQuery `
    -SqlInstance $serverConection `
    -Database $nomDataBase `
    -Query "TRUNCATE TABLE dbo.Error; TRUNCATE TABLE dbo.Ajuste;"

# 2. Importar si las estructuras coinciden
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

    # 3. Ajustar y Validar (SPs de Validaciones_F1.sql)
    # Invoke-DbaQuery: Ejecuta consultas, scripts y SP en instancias de SQL Server
    Invoke-DbaQuery `
        -SqlInstance $serverConection `
        -Database $nomDataBase `
        -Query "EXEC dbo.usp_Usuario_Ajustar;" `
        -EnableException

    Invoke-DbaQuery `
        -SqlInstance $serverConection `
        -Database $nomDataBase `
        -Query "EXEC dbo.usp_Usuario_Validar;" `
        -EnableException

    # 4. Actualizar indicador Valido (usp_MIG_ActualizarValidosTabla)
    Invoke-DbaQuery `
        -SqlInstance $serverConection `
        -Database $nomDataBase `
        -Query "EXEC dbo.usp_MIG_ActualizarValidosTabla @Tabla = 'dbo.Usuario', @ColumnaId = 'IdUsuario';" `
        -EnableException

    # 5. Obtener resultados (equivalente a 0 Migrador Reporte.sql) Se usa para mostrar los resultados de la migración y validación
    Write-Host "`n=== Ajustes (auto-corregidos) ==="
    Invoke-DbaQuery -SqlInstance $serverConection -Database $nomDataBase -Query "SELECT IdRegistro, Descripcion FROM dbo.Ajuste" | Format-Table

    Write-Host "=== Errores (filas invalidas) ==="
    Invoke-DbaQuery -SqlInstance $serverConection -Database $nomDataBase -Query "SELECT IdRegistro, Codigo, Descripcion FROM dbo.Error ORDER BY IdRegistro" | Format-Table

    Write-Host "=== Staging: Valido=1 vs Valido=0 ==="
    Invoke-DbaQuery -SqlInstance $serverConection -Database $nomDataBase -Query "SELECT Valido, COUNT(*) AS Cantidad FROM dbo.Usuario GROUP BY Valido" | Format-Table

    Write-Host "=== Detalle staging ==="
    Invoke-DbaQuery -SqlInstance $serverConection -Database $nomDataBase -Query "SELECT IdUsuario, Cuenta, Nombre, PrimerApellido, SegundoApellido, Valido FROM dbo.Usuario ORDER BY IdUsuario" | Format-Table

    Write-Host "Migración completada correctamente." -ForegroundColor Green
}
catch {
    throw "Migración cancelada. Detalle: $($_.Exception.Message)"
}

