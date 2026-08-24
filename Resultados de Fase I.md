# Fase I

Datos obtenidos durante el desarrollo de la **Fase I**.

## Resultados de ejecución correcta

Comandos utilizados

```powershell
PS C:\Users> $server = Connect-DbaInstance `
>>     -SqlInstance "nomServer" `
>>     -Database "BDOriginal" `
>>     -TrustServerCertificate


PS C:\Users\UsuarioGA> Import-DbaCsv `
>>     -SqlInstance $server `
>>     -Database "BDOriginal" `
>>     -Table "dbo.usuarios" `
>>     -Path "C:\...\usuarios.csv"
>>     -Delimiter "," `
>>     -Encoding UTF8 `
>>     -EnableException

ComputerName  : DESKTOP-2N2DH5F
InstanceName  : SQLSERVER
SqlInstance   : DESKTOP-2N2DH5F\SQLSERVER
Database      : BDOriginal
Table         : usuarios
Schema        : dbo
RowsCopied    : 10
Elapsed       : 680,12 ms
RowsPerSecond : 14,8
Path          : "C:\...\usuarios.csv"
```

## Errores provocados

### 1. Se elimina la coma de uno de los registros

```csv
Cuenta,Nombre,PrimerApellido,SegundoApellido
jgarcia,Juan,García,López
mpérez,María,Pérez,Rodríguez
clópez,Carlos,López,Martínez
agomez,Ana,Gómez,Sánchez
rgarcia,Rosa,GarcíaRamírez
lfdz,Luis,Fernández,Díaz
mtorres,Marta,Torres,Moreno
pgutierrez,Pedro,Gutiérrez,Romero
eramos,Elena,Ramos,Navarro
jsantos,José,Santos,Molina
```
El resultado fue:
- No se inserto ningún dato en la base de datos
- Se muestra este **Warning** en el PowerShell
  

```powershell
PS C:\Users> Import-DbaCsv `
>>     -SqlInstance $server `
>>     -Database "BDOriginal" `
>>     -Table "dbo.usuarios" `
>>     -Path "C:\...\usuarios.csv"
>>     -Delimiter "," `
>>     -Encoding UTF8 `
>>     -EnableException
WARNING: [16:36:30][Import-DbaCsv] Failure | CSV parse error
```

### 2. Se eliminan los datos de la última columna "Segundo Apellido", junto con el nombre de esta en el encabezado.

El resultado fue:
- Se insertaron los datos y para la columna faltante se agrego null, ya que esta columna permitia nulos.

```powershell
ComputerName  : DESKTOP-2N2DH5F
InstanceName  : SQLSERVER
SqlInstance   : DESKTOP-2N2DH5F\SQLSERVER
Database      : BDOriginal
Table         : usuarios
Schema        : dbo
RowsCopied    : 10
Elapsed       : 196,09 ms
RowsPerSecond : 51,3
Path          : D:\..\usuariosSinColumna.csv
```

<img width="460" height="267" alt="image" src="https://github.com/user-attachments/assets/0b381d74-7f0e-44df-b0b4-64690a511c67" />

### 3. Se validan los datos del CSV antes de migrarlos a la BD
Para ello se utilizo un archivo de tipo .ps1 (esto por la cantidad de comandos a usar, suele ser la mejor opción)

```powershell
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
```

Parámetros del módulo dbatools utilizados para validar:
- MismatchedFieldAction ThrowException: cancela cuando una fila tiene más o menos campos.
- QuoteMode Strict: exige que las comillas cumplan el formato CSV.
- DuplicateHeaderBehavior ThrowException: rechaza encabezados duplicados.
- ParseErrorAction ThrowException: cancela al encontrar una fila mal formada.
- EnableException: permite capturar excepciones con tu propio bloque try/catch.

Import-DbaCsv usa una transacción de forma predeterminada; si ocurre un error, revierte la importación completa. Pagina del módulo https://dbatools.io/Import-DbaCsv/

### 3. No existe la tabla o no tiene columnas insertables.

El resultado fue:
- Para perfiles (se mantuvo la validación larga).
<img width="1016" height="120" alt="image" src="https://github.com/user-attachments/assets/9a9d7eb0-f4ae-4fcb-8f1d-0e2ed41c1ee5" />

- Para usuarios (sin validación larga)
<img width="1362" height="113" alt="image" src="https://github.com/user-attachments/assets/a102aa95-0135-48e4-bdd4-dfe95d2fee13" />

### 4. Archivo CSV vacío.
<img width="1442" height="137" alt="image" src="https://github.com/user-attachments/assets/fcbd4783-b413-4446-a098-9a98d6b7cee3" />

### 5. Si el archivo CSV solo tiene una ",".

El resultado fue:
- No se insertan datos
<img width="906" height="507" alt="image" src="https://github.com/user-attachments/assets/9d184719-e699-41ec-94d1-4d8ffab8300d" />


