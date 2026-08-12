# PoC Fase 1 - Carga y validacion de BDOriginal.dbo.Perfil
# Replica el paquete SEG F1 (Cargar -> Ajustar -> Validar -> ActualizarValidos) sin SSIS

Import-Module dbatools

$server = ".\SQLSERVER"
$conn = Connect-DbaInstance -SqlInstance $server -TrustServerCertificate

# 1. Limpiar Tablas (espejo del paso Limpiar del paquete)
Invoke-DbaQuery -SqlInstance $conn -Database BDOriginal -Query "TRUNCATE TABLE dbo.Error; TRUNCATE TABLE dbo.Ajuste;"

# 2. Cargar CSV -> staging (TRIM lo hace T-SQL, no el loader)
Import-DbaCsv -SqlInstance $conn -Database BDOriginal -Schema dbo -Table Perfil `
    -Path "D:\FW.10.0 Pruebas\Migrador Prueba de concepto\perfiles_invalidos.csv" `
    -MismatchedFieldAction PadWithNulls -TrimmingOption None -Truncate -EnableException

# 3. Ajustar y Validar (SPs de Validaciones_F1.sql)
Invoke-DbaQuery -SqlInstance $conn -Database BDOriginal -Query "EXEC dbo.usp_Perfil_Ajustar;"
Invoke-DbaQuery -SqlInstance $conn -Database BDOriginal -Query "EXEC dbo.usp_Perfil_Validar;"

# 4. Compuerta Valido (espejo de usp_MIG_ActualizarValidosTabla)
Invoke-DbaQuery -SqlInstance $conn -Database BDOriginal -Query "EXEC dbo.usp_MIG_ActualizarValidosTabla @Tabla = 'dbo.Perfil', @ColumnaId = 'IdPerfil';"

# 5. Reporte (equivalente a 0 Migrador Reporte.sql)
Write-Host "`n=== Ajustes (auto-corregidos) ==="
Invoke-DbaQuery -SqlInstance $conn -Database BDOriginal -Query "SELECT IdRegistro, Descripcion FROM dbo.Ajuste" | Format-Table

Write-Host "=== Errores (filas invalidas) ==="
Invoke-DbaQuery -SqlInstance $conn -Database BDOriginal -Query "SELECT IdRegistro, Codigo, Descripcion FROM dbo.Error ORDER BY IdRegistro" | Format-Table

Write-Host "=== Staging: Valido=1 vs Valido=0 ==="
Invoke-DbaQuery -SqlInstance $conn -Database BDOriginal -Query "SELECT Valido, COUNT(*) AS Cantidad FROM dbo.Perfil GROUP BY Valido" | Format-Table

Write-Host "=== Detalle staging ==="
Invoke-DbaQuery -SqlInstance $conn -Database BDOriginal -Query "SELECT IdPerfil, Codigo, Nombre, Valido FROM dbo.Perfil ORDER BY IdPerfil" | Format-Table
