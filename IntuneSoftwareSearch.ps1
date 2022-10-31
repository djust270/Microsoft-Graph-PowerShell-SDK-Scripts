<#
Author: David Just
Website: github.com/djust270
Date: 10/31/2022
.SYNOPSIS
    Search managed device app inventory for specific software. Return Device info, User Info and Software Info (name/version)
#>
param (
    [Parameter(Mandatory)]
    [ValidateSet('Windows','Android','iOS','macOS')]
    [String]$OS,
    [Parameter(Mandatory)]
    [String]$SoftwareName
)
$Devices = Get-MgDeviceManagementManagedDevice -Filter "startswith(OperatingSystem,`'$OS`')"
foreach ($Device in $Devices){
    $SoftwareInventory = [array](Invoke-MgGraphRequest -URI "https://graph.microsoft.com/beta/deviceManagement/manageddevices/$($Device.ID)/detectedApps" -Method GET).Value
    $Results = $SoftwareInventory | Where-Object {$_.displayName -like "*$SoftwareName*"}
    if ($Results.count -gt 0){
        [PSCustomObject]@{
            DeviceName = $Device.DeviceName
            DeviceID = $Device.ID
            UserDisplayName = $Device.UserDisplayName
            UserUPN = $Device.UserPrincipalName
            SoftwareName = $Results.displayName
            SoftwareVersion = $Results.version
        }
    }
    else {
        "No Results found for $SoftwareName"
    }
}
