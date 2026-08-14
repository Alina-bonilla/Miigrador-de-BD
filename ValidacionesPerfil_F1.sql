USE BDOriginal;
GO

-- ============================================================
-- Validaciones Fase 1 Ajustar -> Validar -> ActualizarValidos
-- ============================================================

IF OBJECT_ID('dbo.ufn_MIG_TRIM', 'FN') IS NOT NULL DROP FUNCTION dbo.ufn_MIG_TRIM;
GO
CREATE FUNCTION dbo.ufn_MIG_TRIM (@Valor NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    IF @Valor IS NULL RETURN NULL;
    DECLARE @R NVARCHAR(MAX);
    SET @R = REPLACE(REPLACE(REPLACE(REPLACE(@Valor,
            CHAR(160), CHAR(32)),  -- espacio no separable
            CHAR(9), CHAR(32)),    -- tab
            CHAR(13), CHAR(32)),   -- CR
            CHAR(10), CHAR(32));   -- LF
    RETURN LTRIM(RTRIM(@R));
END
GO


IF OBJECT_ID('dbo.usp_Perfil_Ajustar', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Perfil_Ajustar;
GO
CREATE PROCEDURE dbo.usp_Perfil_Ajustar
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdTabla INT = OBJECT_ID('dbo.Perfil');
    DECLARE @Ajustes TABLE (IdRegistro INT);

    UPDATE dbo.Perfil 
    SET Codigo = dbo.ufn_MIG_TRIM(Codigo), 
        Nombre = dbo.ufn_MIG_TRIM(Nombre)
    
    OUTPUT INSERTED.IdPerfil INTO @Ajustes
    WHERE Codigo <> dbo.ufn_MIG_TRIM(Codigo) 
        OR Nombre <> dbo.ufn_MIG_TRIM(Nombre);

    INSERT INTO dbo.Ajuste (IdTabla, IdRegistro, Descripcion)
    SELECT @IdTabla, IdRegistro, 'Se ajustaron 1 o mas campos de texto (TRIM)'
    FROM @Ajustes;
END
GO


IF OBJECT_ID('dbo.usp_Perfil_Validar', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Perfil_Validar;
GO
CREATE PROCEDURE dbo.usp_Perfil_Validar
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdTabla INT = OBJECT_ID('dbo.Perfil');

    -- Regla 3: vacio o nulo
    INSERT INTO dbo.Error (IdTabla, IdRegistro, Codigo, Descripcion)
    SELECT @IdTabla, IdPerfil, 3, 'Campo de texto vacio o nulo'
    FROM dbo.Perfil 
    WHERE LEN(Codigo) = 0 
        OR Codigo IS NULL 
        OR LEN(Nombre) = 0 
        OR Nombre IS NULL;

    -- Regla 3: longitud > 255
    INSERT INTO dbo.Error (IdTabla, IdRegistro, Codigo, Descripcion)
    SELECT @IdTabla, IdPerfil, 3, 'Campo de texto mayor a 255 caracteres'
    FROM dbo.Perfil 
    WHERE LEN(Codigo) > 255 
    OR LEN(Nombre) > 255;

    -- Regla 4: duplicados por Codigo (todas las filas del grupo se marcan)
    INSERT INTO dbo.Error (IdTabla, IdRegistro, Codigo, Descripcion)
    SELECT @IdTabla, P.IdPerfil, 4, 'Codigo duplicado: ' + P.Codigo
    FROM dbo.Perfil P
    INNER JOIN (SELECT Codigo FROM dbo.Perfil WHERE Codigo IS NOT NULL
                GROUP BY Codigo HAVING COUNT(*) > 1) D ON D.Codigo = P.Codigo;

    -- Regla 5: duplicados por Codigo (todas las filas del grupo se marcan)
    INSERT INTO dbo.Error (IdTabla, IdRegistro, Codigo, Descripcion)
	SELECT 
		@IdTabla,
		P.IdPerfil,
		10,
		'El indicador bloqueado tiene un valor diferente a 1 o 0 o está vacío.'
	FROM dbo.Perfil P
	WHERE LEN(P.Bloqueado) = 0 
        OR P.Bloqueado IS NULL 
        OR (LEN(P.Bloqueado) > 0 AND (P.Bloqueado<>'0' AND P.Bloqueado<>'1' ))

END
GO


IF OBJECT_ID('dbo.usp_MIG_ActualizarValidosTabla', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_MIG_ActualizarValidosTabla;
GO
CREATE PROCEDURE dbo.usp_MIG_ActualizarValidosTabla
    @Tabla SYSNAME, @ColumnaId SYSNAME
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = N'UPDATE T SET Valido = 0
                 FROM ' + QUOTENAME(PARSENAME(@Tabla,2)) + N'.' + QUOTENAME(PARSENAME(@Tabla,1)) + N' T
                 INNER JOIN dbo.Error E
                     ON OBJECT_ID(@Tabla) = E.IdTabla AND T.' + QUOTENAME(@ColumnaId) + N' = E.IdRegistro';
    EXEC sp_executesql @SQL, N'@Tabla SYSNAME', @Tabla;
END
GO
