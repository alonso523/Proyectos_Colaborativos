USE master;
GO

-- =========================================================
-- 1. HARDENING DE LA INSTANCIA (Surface Area Reduction)
-- Deshabilitar funciones no esenciales para reducir vectores de ataque.
-- =========================================================
EXEC sp_configure 'show advanced options', 1; 
RECONFIGURE;

-- Deshabilitar xp_cmdshell (Evita ejecución de comandos de SO)
EXEC sp_configure 'xp_cmdshell', 0;

-- Deshabilitar acceso remoto no controlado
EXEC sp_configure 'remote access', 0;

-- Deshabilitar ejecución de código CLR (Net Framework)
EXEC sp_configure 'clr enabled', 0;

RECONFIGURE;
EXEC sp_configure 'show advanced options', 0; 
RECONFIGURE;
GO

-- =========================================================
-- 2. GESTIÓN DE ACCESOS (Principio de Menor Privilegio)
-- Creación del usuario auditor con permisos estrictamente de lectura.
-- =========================================================

-- Crear Login a nivel de servidor
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'UsuarioAuditor')
BEGIN
    CREATE LOGIN UsuarioAuditor WITH PASSWORD = 'ClaveSegura2026';
END
GO

-- Configurar acceso dentro de la base de datos del proyecto
USE TiendaMediosDigitales_DW_SA_Proyecto_DDA;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'UsuarioAuditor')
BEGIN
    CREATE USER UsuarioAuditor FOR LOGIN UsuarioAuditor;
    -- Asignar solo rol de lectura de datos
    ALTER ROLE db_datareader ADD MEMBER UsuarioAuditor;
END
GO

-- =========================================================
-- 3. VERIFICACIÓN DE DATOS SENSIBLES
-- Crear tabla de prueba si no existe para validar auditoría.
-- =========================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'Clientes_Privado')
BEGIN
    CREATE TABLE [dbo].[Clientes_Privado] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [Nombre] NVARCHAR(100),
        [Tarjeta_Credito] NVARCHAR(20)
    );
    INSERT INTO [dbo].[Clientes_Privado] (Nombre, Tarjeta_Credito) 
    VALUES ('Juan Perez', '4540-1111-2222-3333');
END
GO

PRINT 'Hardening aplicado exitosamente.';