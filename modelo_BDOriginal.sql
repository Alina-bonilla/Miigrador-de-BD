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

