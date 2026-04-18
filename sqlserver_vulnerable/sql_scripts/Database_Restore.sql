RESTORE DATABASE TiendaMediosDigitales_DW_SA_Proyecto_DDA
FROM DISK = '/var/opt/mssql/backup/TiendaMediosDigitales_DW_SA_Proyecto_DDA.bak'
WITH MOVE 'TiendaMediosDigitales_DW_SA_Proyecto_DDA'
     TO '/var/opt/mssql/data/TiendaMediosDigitales_DW_SA_Proyecto_DDA.mdf',
     MOVE 'TiendaMediosDigitales_DW_SA_Proyecto_DDA_log'
     TO '/var/opt/mssql/data/TiendaMediosDigitales_DW_SA_Proyecto_DDA_log.ldf',
     REPLACE;
GO