# Migrador-de-BD

Ejemplo de un migrador de base de datos utilizando **PowerShell** y **dbatools** para importar información desde archivos **CSV** hacia una **Base de datos de migración** y luego hacia otra **Base de datos final**.

## Descripción

Este proyecto muestra una prueba de concepto (POC) de cómo automatizar la migración de datos Se divide en dos fases:
- **Fase 1:** Migración de datos desde archivos CSV a una base de datos SQL Server utilizando el módulo **dbatools** de PowerShell.

## Requisitos

Antes de ejecutar el proyecto, asegúrate de contar con lo siguiente:

- Windows PowerShell 7+
- SQL Server
- Permisos para crear bases de datos y tablas
- Conexión al servidor SQL Server

---

# Instalación de dbatools

## 1. Verificar la versión de PowerShell

```powershell
$PSVersionTable.PSVersion
```

---

## 2. Habilitar la ejecución de scripts (si es necesario) VEREMOS

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Cuando PowerShell solicite confirmación, responder:

```text
Y
```

---

## 3. Instalar dbatools

```powershell
Install-Module dbatools -Scope CurrentUser
```

Si pregunta si confía en el repositorio **PSGallery**, responder:

```text
Y
```

---

## 4. Importar el módulo

```powershell
Import-Module dbatools Install-Module dbatools
```

---

## 5. Verificar la instalación

```powershell
Get-Module dbatools -ListAvailable
```

# Fase 1: Importar el CSV a SQL Server

## Crear Base de datos de ejemplo BDOriginal

Crear la base de datos ejecutando el siguiente script:

```sql
IF DB_ID('BDOriginal') IS NULL
    CREATE DATABASE BDOriginal;
GO

USE BDOriginal;
GO

IF OBJECT_ID('dbo.usuarios', 'U') IS NULL
    CREATE TABLE dbo.usuarios (
        IdUsuario        INT IDENTITY(1,1) PRIMARY KEY,
        Cuenta           NVARCHAR(50)  NOT NULL,
        Nombre           NVARCHAR(100) NULL,
        PrimerApellido   NVARCHAR(100) NULL,
        SegundoApellido  NVARCHAR(100) NULL
    );
GO
```

---

## Archivo CSV de ejemplo

```csv
Cuenta,Nombre,PrimerApellido,SegundoApellido
jgarcia,Juan,García,López
mpérez,María,Pérez,Rodríguez
clópez,Carlos,López,Martínez
agomez,Ana,Gómez,Sánchez
rgarcia,Rosa,García,Ramírez
lfdz,Luis,Fernández,Díaz
mtorres,Marta,Torres,Moreno
pgutierrez,Pedro,Gutiérrez,Romero
eramos,Elena,Ramos,Navarro
jsantos,José,Santos,Molina
```

---
## Comandos a ejecutar en PowerShell
```powershell
$server = Connect-DbaInstance `
    -SqlInstance "nombreServidor" `
    -Database "BDOriginal" `
    -TrustServerCertificate

Import-DbaCsv `
    -SqlInstance $server `
    -Database BDOriginal `
    -Table dbo.usuarios `
    -Path "C:...\usuarios.csv"
```

Si utilizas una instancia con contraseña y usuario:
Ejecuta el siguiente comando en PowerShell para que este solicite un usuario y una contraseña de forma segura.

```powershell
$credencial = Get-Credential
```
PowerShell muestra una ventana como esta:
- Usuario: el usuario configurado en SQL Server, por ejemplo usuario_migracion
- Contraseña: la contraseña de ese usuario
El resultado se guarda en $credencial como un objeto PSCredential. Después, dbatools lo utiliza así:

```powershell
$server = Connect-DbaInstance `
    -SqlInstance "srv-bd" `
    -Database "BDOriginal" `
    -SqlCredential $credencial `
    -TrustServerCertificate
```
Finalmente, importas el CSV:

```powershell
Import-DbaCsv `
    -SqlInstance $server `
    -Database "BDOriginal" `
    -Table "dbo.usuarios" `
    -Path "D:\FW.10.0 Pruebas\Migrador Prueba de concepto\usuarios.csv"
```
---



# Tecnologías utilizadas

- PowerShell
- dbatools
- SQL Server
- CSV

---

# Referencias

- https://dbatools.io/
- https://docs.dbatools.io/

---
