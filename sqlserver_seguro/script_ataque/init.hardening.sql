-- init-hardening.sql
USE master;
GO

-- 1. Restaurar la base de datos
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TiendaMediosDigitales_DW_SA_Proyecto_DDA')
BEGIN
    RESTORE DATABASE TiendaMediosDigitales_DW_SA_Proyecto_DDA
    FROM DISK = '/var/opt/mssql/backup/TiendaMediosDigitales_DW_SA_Proyecto_DDA.bak'
    WITH MOVE 'TiendaMediosDigitales_DW_SA_Proyecto_DDA'
         TO '/var/opt/mssql/data/TiendaMediosDigitales_DW_SA_Proyecto_DDA.mdf',
         MOVE 'TiendaMediosDigitales_DW_SA_Proyecto_DDA_log'
         TO '/var/opt/mssql/data/TiendaMediosDigitales_DW_SA_Proyecto_DDA_log.ldf',
    REPLACE;
END
GO
USE TiendaMediosDigitales_DW_SA_Proyecto_DDA;
GO 

CREATE TABLE [dbo].[Clientes_Privado] (
    [Id] INT PRIMARY KEY IDENTITY(1,1),
    [Nombre] NVARCHAR(100),
    [Email] NVARCHAR(100),
    [Password_Hash] NVARCHAR(MAX), -- En un caso real sería un hash, aquí pondremos texto plano
    [Tarjeta_Credito] NVARCHAR(20)
);

INSERT INTO [dbo].[Clientes_Privado] (Nombre, Email, Password_Hash, Tarjeta_Credito)
VALUES 
('Juan Perez', 'juan.perez@ejemplo.com', 'ClaveSegura2026', '4540-1111-2222-3333'),
('Maria Lopez', 'm.lopez@seguridad.cl', 'Admin123!', '3714-0000-9999-8888');
GO

-- 2. Crear el Login en el servidor (el "Portero")
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'UsuarioAuditor')
BEGIN
    CREATE LOGIN UsuarioAuditor WITH PASSWORD = 'ClaveSegura2026';
END
GO

-- 3. Configurar el Usuario dentro de la DB (el "Inquilino")
USE TiendaMediosDigitales_DW_SA_Proyecto_DDA;
GO

-- Si el usuario ya venía en el backup, lo borramos para evitar el error de "huérfano"
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'UsuarioAuditor')
BEGIN
    DROP USER UsuarioAuditor;
END
GO

CREATE USER UsuarioAuditor FOR LOGIN UsuarioAuditor;
ALTER ROLE db_datareader ADD MEMBER UsuarioAuditor;
GO

-- 4. Hardening Final
USE master;
GO
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;
GO