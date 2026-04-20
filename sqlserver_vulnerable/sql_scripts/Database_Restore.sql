-- Ejecturar en batch
--docker cp "C:\Administracion de Bases Datos\Cuatrimestre 4\DDA\TiendaMediosDigitales_DW_SA_Proyecto_DDA.bak" sql_inseguro:/var/opt/mssql/backup/TiendaMediosDigitales_DW_SA_Proyecto_DDA.bak

RESTORE DATABASE TiendaMediosDigitales_DW_SA_Proyecto_DDA
FROM DISK = '/var/opt/mssql/backup/TiendaMediosDigitales_DW_SA_Proyecto_DDA.bak'
WITH MOVE 'TiendaMediosDigitales_DW_SA_Proyecto_DDA'
     TO '/var/opt/mssql/data/TiendaMediosDigitales_DW_SA_Proyecto_DDA.mdf',
     MOVE 'TiendaMediosDigitales_DW_SA_Proyecto_DDA_log'
     TO '/var/opt/mssql/data/TiendaMediosDigitales_DW_SA_Proyecto_DDA_log.ldf',
     REPLACE;
GO