# Fase I

Datos obtenidos durante el desarrollo de la **Fase I**.

## Resultados de ejecución correcta

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

Se elimina la coma de uno de los registros

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
WARNING: [16:36:30][Import-DbaCsv] Failure | CSV parse error
```

