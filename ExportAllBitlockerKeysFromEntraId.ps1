<#
.Sysnopsis
    Sample script to export a list of all devices from EntraId including BitlockerKeys using the Microsoft Graph and Import Excel modules.
    Exports list to an excel file. 
.Notes
    Author: David Just
    Date: 07/21/2024
    Website: https://davidjust.com
    Version: 1.1
#>

function Invoke-GraphGetRequest {
# Helper function to query a graph API endpoint and handle pagination
param (
[Parameter(Mandatory)]
[string]$ApiEndpoint,
[switch]$UseGraphModule,
[hashtable]$AuthHeader
)
    if ($UseGraphModule){
        $Request = Invoke-MgGraphRequest -uri $ApiEndpoint -Method Get
        $Request.Value
    if ($Request.'@odata.nextLink'){
        do {
            $Request=Invoke-MGGraphRequest -uri $Request.'@odata.nextLink' -Method Get
            $Request.Value
        }
        until (-Not $Request.'@odata.nextLink')
    }
}
else {
    if (-Not $AuthHeader){Write-Error "Please provide an authorization header with -AuthHeader" ; return}
        $Request = Invoke-RestMethod -uri $ApiEndpoint -Method Get -Headers $AuthHeader
        $Request.Value
    if ($Request.'@odata.nextLink'){
        do {
            $Request=Invoke-RestMethod -uri $Request.'@odata.nextLink' -Method Get -headers $AuthHeader
            $Request.Value
        }
            until (-Not $Request.'@odata.nextLink')
        }
    }
}

$GraphModuleCheck = Get-Module -ListAvailable Microsoft.Graph.Authentication
if (-Not $GraphModuleCheck){
    Write-Host "Installing Microsoft Graph Authentication Module"
    Install-Module Microsoft.Graph.Authentication
}
$ImportExcelModuleCheck = Get-Module -ListAvailable ImportExcel
if (-Not $ImportExcelModuleCheck){
    Write-Host "Installing ImportExcel Module"
    Install-Module ImportExcel
}
Import-Module Microsoft.Graph.Authentication,ImportExcel
$Scopes = @('Device.Read.All','BitlockerKey.Read.All')
$Null = Connect-MgGraph -Scopes Device.Read.All,BitlockerKey.Read.All

$Scopes | Foreach {
        if ($_ -notin (Get-MgContext).Scopes){
        Write-Error "Authentication scopes not found!"
        break
    }
}

$AllKeys = Invoke-GraphGetRequest -APIEndpoint "https://graph.microsoft.com/beta/informationProtection/bitlocker/recoveryKeys?`$top=999" -UseGraphModule
$WindowsDevices = Invoke-GraphGetRequest -APIEndpoint "https://graph.microsoft.com/v1.0/devices?`$top=100&`$filter=(trustType eq 'azuread') or (trustType eq 'serverad')" -UseGraphModule
$DeviceList = foreach ($Device in $WindowsDevices){
    $RecoveryKeys = $AllKeys | where {$_.deviceId -eq $Device.deviceId} |
    foreach {
    $Key = Invoke-MgGraphRequest -uri "https://graph.microsoft.com/beta/informationProtection/bitlocker/recoveryKeys/$($_.id)?`$select=key"
    @{
        Key = $Key.key
        RecoveryKeyID = $Key.id
    }
}
    [pscustomobject]@{
        DeviceName = $Device.displayName
        DeviceID = $Device.deviceId
        Model = $Device.model
        Manufacturer = $Device.manufacturer
        RecoveryKeys = $RecoveryKeys | convertto-json -compress
    }
}
$SavePath = "$env:UserProfile\BitlockerKeys.xlsx"
$DeviceList | Export-Excel -Path $SavePath -TableName BitlockerKeys -Autosize
Write-Host "Keys exported to $SavePath"