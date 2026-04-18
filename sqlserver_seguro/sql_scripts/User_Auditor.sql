USE master;
GO
-- Crear el login si no existe
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'UsuarioAuditor')
BEGIN
    CREATE LOGIN UsuarioAuditor WITH PASSWORD = 'ClaveSegura2026';
END
GO

USE TiendaMediosDigitales_DW_SA_Proyecto_DDA;
GO
-- Crear el usuario y darle solo lectura
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'UsuarioAuditor')
BEGIN
    CREATE USER UsuarioAuditor FOR LOGIN UsuarioAuditor;
    ALTER ROLE db_datareader ADD MEMBER UsuarioAuditor;
END
GO