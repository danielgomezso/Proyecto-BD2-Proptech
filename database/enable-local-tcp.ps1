#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
$tcpPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL17.SQLUCR\MSSQLServer\SuperSocketNetLib\Tcp'
$backupPath = Join-Path $PSScriptRoot 'sqlucr-tcp-before.reg'
if (-not (Test-Path -LiteralPath $backupPath)) {
    & reg.exe export 'HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL17.SQLUCR\MSSQLServer\SuperSocketNetLib\Tcp' $backupPath /y
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo respaldar la configuración TCP.' }
}
Set-ItemProperty -LiteralPath $tcpPath -Name Enabled -Value 1
Set-ItemProperty -LiteralPath $tcpPath -Name ListenOnAllIPs -Value 0
Get-ChildItem -LiteralPath $tcpPath | ForEach-Object {
    $settings = Get-ItemProperty -LiteralPath $_.PSPath
    if ($settings.IpAddress) {
        $enabled = if ($settings.IpAddress -eq '127.0.0.1') { 1 } else { 0 }
        Set-ItemProperty -LiteralPath $_.PSPath -Name Enabled -Value $enabled
        if ($enabled -eq 1) {
            Set-ItemProperty -LiteralPath $_.PSPath -Name TcpDynamicPorts -Value ''
            Set-ItemProperty -LiteralPath $_.PSPath -Name TcpPort -Value '14330'
        }
    }
}
Restart-Service -Name 'MSSQL$SQLUCR'
'SQLUCR configurado en 127.0.0.1:14330' | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'sqlucr-tcp-result.txt')
