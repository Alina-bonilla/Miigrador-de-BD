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
        SegundoApellido  NVARCHAR(100) NULL,
        Valido   BIT          NOT NULL DEFAULT (1) --Indicador técnico de validez del registro
    );
GO

IF OBJECT_ID('dbo.Perfil', 'U') IS NULL
    CREATE TABLE dbo.Perfil (
        IdPerfil INT IDENTITY(1,1) PRIMARY KEY,
        Codigo   VARCHAR(MAX) NULL,
        Nombre   VARCHAR(MAX) NULL,
        Bloqueado BIT NOT NULL, --Columna Menos
        Valido   BIT  NOT NULL DEFAULT (1) --Indicador técnico de validez del registro
    );
GO

IF OBJECT_ID('dbo.Error', 'U') IS NULL
    CREATE TABLE dbo.Error (
        Id          INT IDENTITY(1,1) PRIMARY KEY,
        IdTabla     INT            NOT NULL,
        IdRegistro  INT            NOT NULL,
        Codigo      INT            NOT NULL,
        Descripcion NVARCHAR(255)  NOT NULL,
        Fecha       DATETIME       NOT NULL DEFAULT (GETDATE())
    );
GO

IF OBJECT_ID('dbo.Ajuste', 'U') IS NULL
    CREATE TABLE dbo.Ajuste (
        Id          INT IDENTITY(1,1) PRIMARY KEY,
        IdTabla     INT            NOT NULL,
        IdRegistro  INT            NOT NULL,
        Descripcion NVARCHAR(255)  NOT NULL,
        Fecha       DATETIME       NOT NULL DEFAULT (GETDATE())
    );
GO
