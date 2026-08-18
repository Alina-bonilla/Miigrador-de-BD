$sqlInstance = "srv-bd"
$nomDataBaseMig = "BDOriginal"
$SchemaDB = "dbo"
$TableDB = "Usuario"
$nomDataBaseFinal = "BDFinal"
$valorExtra = '2026-08-12 17:00:00' #Valor quemado para columna extra

# 1. Se crea la conexión con los servidores usando autenticación de Windows
$serverConectionOriginal = Connect-DbaInstance `
    -SqlInstance $sqlInstance `
    -Database $nomDataBaseMig `
    -TrustServerCertificate

$serverConectionFinal = Connect-DbaInstance `
    -SqlInstance $sqlInstance `
    -Database $nomDataBaseFinal `
    -TrustServerCertificate

# 2. Se copia los datos de la BDOriginal que tengan valido =1 a la BDFinal
    # Truncate: para limpiar la tabla antes de insertar los datos
    # KeepIdentity: para preservar las llaves de la BDOriginal
    # EnableException: para que se detenga si hay un error en la copia
Copy-DbaDbTableData `
    -SqlInstance $serverConectionOriginal `
    -Destination $serverConectionFinal `
    -Database $nomDataBaseMig `
    -Table $TableDB `
    -DestinationDatabase $nomDataBaseFinal `
    -DestinationTable $TableDB `
    -KeepIdentity `
    -Truncate `
    -EnableException `
    -Query "SELECT *
              FROM $SchemaDB.$TableDB WHERE Valido = 1"

# Imprime el resultado final de la tabla BDFinal.dbo.Usuario
Invoke-DbaQuery `
    -SqlInstance $serverConectionOriginal `
    -Database $nomDataBaseFinal `
    -Query "SELECT * FROM $SchemaDB.$TableDB ORDER BY IdUsuario" |
    Format-Table

Write-Host "Migración completada correctamente." -ForegroundColor Green

