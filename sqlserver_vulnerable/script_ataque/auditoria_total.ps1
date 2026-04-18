# auditoria_total.ps1
param (
    [string]$Server   = "sql_inseguro",
    [string]$Database = "master",
    [string]$User     = "sa",
    [string]$Pass     = "Seguridad2026!"
)

$connString = "Server=$Server;Database=$Database;User Id=$User;Password=$Pass;Connect Timeout=5;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connString)

try {
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)

    Write-Host "`n[+] 1. AUDITORÍA DE CONFIGURACIONES CRÍTICAS" -ForegroundColor Cyan
    $data_audit = New-Object System.Data.DataTable
    $cmd.CommandText = "SELECT name, value, value_in_use FROM sys.configurations WHERE name IN ('xp_cmdshell', 'show advanced options', 'remote access', 'clr enabled')"
    $adapter.Fill($data_audit) | Out-Null
    $data_audit | Format-Table -AutoSize

    Write-Host "[+] 2. AUDITORÍA DE LOGINS Y ACCESOS" -ForegroundColor Cyan
    $data_logins = New-Object System.Data.DataTable
    $cmd.CommandText = "SELECT name, type_desc, is_disabled, create_date FROM sys.server_principals WHERE type_desc IN ('SQL_LOGIN', 'WINDOWS_LOGIN')"
    $adapter.Fill($data_logins) | Out-Null
    $data_logins | Format-Table -AutoSize

    Write-Host "[+] 3. RECONOCIMIENTO DE RUTAS FÍSICAS (SISTEMA DE ARCHIVOS)" -ForegroundColor Cyan
    $data_paths = New-Object System.Data.DataTable
    $cmd.CommandText = "SELECT name, physical_name AS Ruta_Fisica, (size*8)/1024 AS Tamano_MB FROM sys.master_files"
    $adapter.Fill($data_paths) | Out-Null
    $data_paths | Format-Table -AutoSize

    Write-Host "[+] 4. PRUEBA DE CONECTIVIDAD DE RED (PUERTO 1433)" -ForegroundColor Cyan
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($Server, 1433, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne(2000, $false) # 2 segundos de timeout
        if ($wait) {
            $tcpClient.EndConnect($connect)
            Write-Host "  [OK] Puerto 1433 está ABIERTO y respondiendo en $Server." -ForegroundColor Green
        } else {
            Write-Host "  [!] Puerto 1433 está CERRADO o filtrado." -ForegroundColor Red
        }
        $tcpClient.Close()
    } catch {
        Write-Host "  [-] Error probando conexión: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "[!] 5. INTENTO DE ESCALADA: ACTIVACIÓN DE XP_CMDSHELL" -ForegroundColor Yellow
    try {
        $cmd.CommandText = "EXEC sp_configure 'show advanced options', 1; RECONFIGURE; EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;"
        $cmd.ExecuteNonQuery() | Out-Null
        
        $data_post = New-Object System.Data.DataTable
        $cmd.CommandText = "SELECT name, value_in_use FROM sys.configurations WHERE name = 'xp_cmdshell'"
        $adapter.Fill($data_post) | Out-Null
        $data_post | Format-Table -AutoSize
    } catch {
        Write-Host "[-] Bloqueado: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "[+] 6. VERIFICACIÓN DE CIFRADO EN REPOSO (TDE)" -ForegroundColor Cyan
    $data_tde = New-Object System.Data.DataTable
    $cmd.CommandText = "SELECT d.name, 
                        CASE COALESCE(db.encryption_state, 0)
                            WHEN 3 THEN 'CIFRADO (TDE ACTIVO)' 
                            ELSE 'VULNERABLE (SIN CIFRAR)' END as Estado 
                        FROM sys.databases d 
                        LEFT JOIN sys.dm_database_encryption_keys db ON d.database_id = db.database_id
                        WHERE d.name NOT IN ('master', 'model', 'msdb', 'tempdb')"
    $adapter.Fill($data_tde) | Out-Null
    $data_tde | Format-Table -AutoSize

    # --- NUEVAS ADICIONES PARA EL PROYECTO ---

    Write-Host "[+] 7. HUELLA TÉCNICA (INFORMACIÓN DEL MOTOR)" -ForegroundColor Cyan
    $data_ver = New-Object System.Data.DataTable
    $cmd.CommandText = "SELECT @@VERSION as Version_Detallada"
    $adapter.Fill($data_ver) | Out-Null
    $data_ver | Format-List | Out-String | Write-Host -ForegroundColor Gray

    Write-Host "[!] 8. PRUEBA DE AISLAMIENTO: INTENTO DE SALIDA A INTERNET" -ForegroundColor Yellow
    try {
        # Intenta usar el comando curl de Linux a través de xp_cmdshell
        $cmd.CommandText = "EXEC xp_cmdshell 'curl -I --connect-timeout 2 https://www.google.com'"
        $data_exit = New-Object System.Data.DataTable
        $adapter.Fill($data_exit) | Out-Null
        
        $output = ($data_exit | Out-String).Trim()
        if ($output -like "*HTTP/*") {
            Write-Host "  [ALERTA] El contenedor tiene salida a INTERNET. Riesgo de exfiltración de datos." -ForegroundColor Red
        } else {
            Write-Host "  [OK] No se detectó salida a red externa o comando bloqueado." -ForegroundColor Green
        }
    } catch {
        Write-Host "  [OK] Bloqueado: No se puede realizar la prueba de red externa." -ForegroundColor Green
    }

} catch {
    Write-Error "Error fatal en la conexión: $($_.Exception.Message)"
} finally {
    if ($conn.State -eq "Open") { $conn.Close() }
    Write-Host "`n[!] Auditoría Finalizada." -ForegroundColor Green
}