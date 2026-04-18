-- PASO 1: Configurar la Master Key en MASTER
USE master;
GO
-- Si ya existe, esto no fallar� por el bloque TRY
BEGIN TRY
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'ContrasenaMaestraDefinitiva_2026';
END TRY
BEGIN CATCH
    PRINT 'La Master Key ya existe o requiere ser abierta.';
END CATCH
GO

-- PASO 2: Crear el Certificado en MASTER (Es vital que est� aqu�)
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'TDE_Certificado_Seguro')
BEGIN
    CREATE CERTIFICATE TDE_Certificado_Seguro 
    WITH SUBJECT = 'Certificado Cifrado Proyecto DDA';
END
GO

-- PASO 3: Crear la llave de cifrado en la base de datos de usuario
USE TiendaMediosDigitales_DW_SA_Proyecto_DDA;
GO

-- Forzamos el uso del certificado que vive en master
BEGIN TRY
    CREATE DATABASE ENCRYPTION KEY
    WITH ALGORITHM = AES_256
    ENCRYPTION BY SERVER CERTIFICATE TDE_Certificado_Seguro;
    PRINT 'Llave de cifrado de base de datos creada exitosamente.';
END TRY
BEGIN CATCH
    PRINT 'La llave ya existe o hay un error de permisos: ' + ERROR_MESSAGE();
END CATCH
GO

-- PASO 4: Activar el cifrado
ALTER DATABASE TiendaMediosDigitales_DW_SA_Proyecto_DDA SET ENCRYPTION ON;
GO

use master;
go
SELECT 
    d.name AS [Base de Datos], 
    db.encryption_state,
    CASE db.encryption_state 
        WHEN 1 THEN 'No Cifrado'
        WHEN 2 THEN 'Cifrado en Progreso'
        WHEN 3 THEN 'CIFRADO COMPLETO (TDE)'
        ELSE 'Estado Desconocido'
    END AS [Estado de Seguridad]
FROM sys.databases d
LEFT JOIN sys.dm_database_encryption_keys db ON d.database_id = db.database_id
WHERE d.name = 'TiendaMediosDigitales_DW_SA_Proyecto_DDA';

USE master;
GO
SELECT 
    d.name AS [Base de Datos], 
    db.encryption_state,
    CASE db.encryption_state 
        WHEN 3 THEN 'Vitoria! CIFRADO ACTIVO' 
        ELSE 'A�n no cifrado' 
    END AS Estado
FROM sys.databases d
INNER JOIN sys.dm_database_encryption_keys db ON d.database_id = db.database_id
WHERE d.name = 'TiendaMediosDigitales_DW_SA_Proyecto_DDA';