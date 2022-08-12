Connect-MgGraph -Scopes DeviceManagementManagedDevices.Read.All,DeviceManagementManagedDevices.PrivilegedOperations.All -UseDeviceAuthentication
Select-MgProfile -Name "beta"
$devices = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices" -Method Get
$windowsdevices = [array]$devices.value | where {$_.devicetype -eq "WindowsRT"} # filter for only Windows devices
foreach ($device in $windowsdevices){
"Invoking sync on Devicename: {0}`nSerial: {1}`nUPN: {2}`n" -f $device.deviceName,$device.serialNumber,$device.userPrincipalName # Output some progress text
Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($device.id)/syncDevice" -Method POST # Invoke Sync
}
