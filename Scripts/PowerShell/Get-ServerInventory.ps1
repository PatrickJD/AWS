#Define Global Table Header#
$header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #3085e0;color: #ffff00}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
h1 {color: #000000; margin:10px 0px 0px 0px}
h2 {color: #1f66be; margin:10px 0px 0px 0px}
h3 {color: #028bff; margin:10px 0px 0px 0px}
body {background-color: #bcbcbc}
</style>
<title>Server: $env:computername</title>
"@

#Create functions to call later

function Get-SystemInfo
{
    [CmdletBinding()]
    param()

    $systeminfo = Get-ComputerInfo
    $systeminfo | Select-Object @{Name="Operating System";Expression={$systeminfo.OsName}},@{Name="OS Architecture";Expression={$systeminfo.OsArchitecture}},@{Name="Version";Expression={$systeminfo.OsVersion}},@{Name="Processor";Expression={$systeminfo.CsProcessors.Name}},@{Name="Total Processors";Expression={$systeminfo.CsNumberOfProcessors}},@{Name="Total Logical Cores";Expression={$systeminfo.CsNumberOfLogicalProcessors}},@{Name="Total Memory GB";Expression={"{0,0:N0}" -f($systeminfo.OsTotalVisibleMemorySize/1mb)}},@{Name="Total Page File GB";Expression={$systeminfo.OsSizeStoredInPagingFiles/1mb}}
}
function Get-DriveCapacity
{
    [CmdletBinding()]
    param()

    $localdrives = Get-WMIObject -Class win32_volume | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {Get-PSDrive -LiteralName $_.DriveLetter[0]}
    $localdrives | Select-Object Name,@{Name="Disk Size(GB)";Expression={"{0,0:N0}" -f($_.free/1gb +$_.used/1gb)}},@{Name="Disk Used(GB)";Expression={"{0,0:N0}" -f($_.used/1gb)}},@{Name="Disk Free(GB)";Expression={"{0,0:N0}" -f($_.free/1gb)}},@{Name="Free (%)";Expression={"{0,0:P0}" -f($_.free / ($_.free +$_.used))}}
}
function Get-Hotfixes
{
    [CmdletBinding()]
    param()
    
    Get-ComputerInfo | Select-Object -ExpandProperty OSHotFixes | Select-Object Description,HotFixID
}

function Get-InstalledApps
{
    [CmdletBinding()]
    param()
    
    Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -NotLike "*Update*" -and $_.DisplayName -NotLike "*Service Pack*"} | Select-Object DisplayName, DisplayVersion, Publisher
}
function Get-Services
{
    [CmdletBinding()]
    param()
    
    Get-Service | Select-Object @{Name="Name";Expression={$_.DisplayName}},Status
}
function Get-ScheduledTasks
{
    [CmdletBinding()]
    param()
    
    Get-ScheduledTask | Where-Object {$_.TaskPath -NotLike "*Microsoft*" -and $_.TaskPath -NotLike "*Apple*" -and $_.TaskPath -NotLike "*Adobe*" -and $_TaskName -NotLike "*Adobe*"} | Select-Object @{Name="Name";Expression={$_.TaskName}},State,Triggers
}
function Get-IpAddress
{
    [CmdletBinding()]
    param()
    
    Get-NetIPAddress | Where-Object {$_.IpAddress -NotLike "*::*" -and $_.IPAddress -NotLike "*127.0.0.1*" -and $_.IPAddress -NotLike "*169.254*"} | Select-Object IpAddress
}
function Get-ListeningPorts
{
    [CmdletBinding()]
    param()
    
    Get-NetTCPConnection | Where-Object {$_.State -eq "listen"}
}
#Get Output to HTML Fragment for general report#
$sysinfofragment = Get-SystemInfo | ConvertTo-HTML -PreContent "<h3>System Info</h3>" -Fragment
$volumesfragment = Get-DriveCapacity | ConvertTo-HTML -PreContent "<h3>Volumes</h3>" -Fragment
$hotfixesfragment = Get-Hotfixes | ConvertTo-HTML -PreContent "<h3>Hotfixes</h3>" -Fragment
$installedappsfragment = Get-InstalledApps | ConvertTo-HTML -PreContent "<h3>Installed Applications</h3>" -Fragment
$installedservicesfragment = Get-Services | ConvertTo-HTML -PreContent "<h3>Installed Services</h3>" -Fragment
$scheduledtaskfragment = Get-ScheduledTasks | ConvertTo-HTML -PreContent "<h3>Scheduled Tasks</h3>" -Fragment
$ipaddressfragment = Get-IpAddress | ConvertTo-HTML -PreContent "<h3>System IP Addresses</h3>" -Fragment
$portfragment = Get-ListeningPorts | ConvertTo-HTML -PreContent "<h3>Listening Ports</h3>" -Fragment

#Generate Server health report to ServerHealthReport.html#
ConvertTo-HTML -Head $header -PostContent "$sysinfofragment","$ipaddressfragment","$portfragment","$volumesfragment","$installedappsfragment","$installedservicesfragment","$scheduledtaskfragment","$hotfixesfragment" | Out-File "$($env:computername).html"