USE BDOriginal;
GO

-- ============================================================
-- Validaciones Fase 1 Ajustar -> Validar
-- ============================================================

IF OBJECT_ID('dbo.usp_Usuario_Ajustar', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Usuario_Ajustar;
GO
CREATE PROCEDURE dbo.usp_Usuario_Ajustar
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdTabla INT = OBJECT_ID('dbo.Usuario');
    DECLARE @Ajustes TABLE (IdRegistro INT);

    UPDATE dbo.Usuario 
    SET Cuenta = dbo.ufn_MIG_TRIM(Cuenta), 
        Nombre = dbo.ufn_MIG_TRIM(Nombre),
        PrimerApellido = dbo.ufn_MIG_TRIM(PrimerApellido),
        SegundoApellido = dbo.ufn_MIG_TRIM(SegundoApellido)
    
    OUTPUT INSERTED.IdUsuario INTO @Ajustes
    WHERE Cuenta <> dbo.ufn_MIG_TRIM(Cuenta) 
        OR Nombre <> dbo.ufn_MIG_TRIM(Nombre)
        OR PrimerApellido <> dbo.ufn_MIG_TRIM(PrimerApellido)
        OR SegundoApellido <> dbo.ufn_MIG_TRIM(SegundoApellido);

    INSERT INTO dbo.Ajuste (IdTabla, IdRegistro, Descripcion)
    SELECT @IdTabla, IdRegistro, 'Se ajustaron 1 o mas campos de texto (TRIM)'
    FROM @Ajustes;
END
GO


IF OBJECT_ID('dbo.usp_Usuario_Validar', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Usuario_Validar;
GO
CREATE PROCEDURE dbo.usp_Usuario_Validar
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UsuariosObjectId INT = OBJECT_ID('dbo.Usuario');

    -- Regla 3: Cuenta vacía o nula
    INSERT INTO dbo.Error (IdTabla, IdRegistro, Codigo, Descripcion)

    SELECT
        @UsuariosObjectId,
        P.IdUsuario,
        3,
        'El campo cuenta es mayor a 50 caracteres o está vacío.'
    FROM dbo.Usuario AS P
    WHERE DATALENGTH(P.Cuenta) > 50
       OR DATALENGTH(P.Cuenta) = 0
       OR P.Cuenta IS NULL;


    -- Regla 3: Nombre vacío o nulo
    INSERT INTO dbo.Error (IdTabla, IdRegistro, Codigo, Descripcion)
    SELECT
        @UsuariosObjectId,
        P.IdUsuario,
        3,
        'El campo nombre es mayor a 100 caracteres o está vacío.'
    FROM dbo.Usuario AS P
    WHERE DATALENGTH(P.Nombre) > 100
       OR DATALENGTH(P.Nombre) = 0
       OR P.Nombre IS NULL;


    -- Regla 3: Primer apellido vacío o nulo
    INSERT INTO dbo.Error (IdTabla, IdRegistro, Codigo, Descripcion)
    SELECT
        @UsuariosObjectId,
        P.IdUsuario,
        3,
        'El campo primer apellido es mayor a 100 caracteres o está vacío.'
    FROM dbo.Usuario AS P
    WHERE DATALENGTH(P.PrimerApellido) > 100
       OR DATALENGTH(P.PrimerApellido) = 0
       OR P.PrimerApellido IS NULL;


    -- Regla 3: Segundo apellido vacío o nulo
    INSERT INTO dbo.Error (IdTabla, IdRegistro, Codigo, Descripcion)
    SELECT
        @UsuariosObjectId,
        P.IdUsuario,
        3,
        'El campo segundo apellido es mayor a 100 caracteres o está vacío.'
    FROM dbo.Usuario AS P
    WHERE DATALENGTH(P.SegundoApellido) > 100
       OR DATALENGTH(P.SegundoApellido) = 0
       OR P.SegundoApellido IS NULL;


    -- Regla 4: Cuenta repetida
    INSERT INTO dbo.Error (IdTabla, IdRegistro, Codigo, Descripcion)
    SELECT DISTINCT
        @UsuariosObjectId,
        P.IdUsuario,
        4,
        'El valor del campo cuenta está repetido.'
    FROM dbo.Usuario AS P
    INNER JOIN dbo.Usuario AS P2
        ON P2.Cuenta = P.Cuenta
       AND P2.IdUsuario <> P.IdUsuario;
END
GO

