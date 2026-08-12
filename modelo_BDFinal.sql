IF DB_ID('BDFinal') IS NULL
    CREATE DATABASE BDFinal;
GO

USE BDFinal;
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

IF OBJECT_ID('dbo.Perfil', 'U') IS NULL
    CREATE TABLE dbo.Perfil (
        IdPerfil          INT IDENTITY(1,1) PRIMARY KEY,
        Codigo            VARCHAR(20)   NOT NULL,
        Nombre            VARCHAR(100)  NOT NULL,
        --IdUsuarioCreacion INT           NOT NULL DEFAULT (0),
        ValorExtra     DATETIME      NOT NULL DEFAULT (SYSDATETIME())--Columna extra
    );
GO
