#Requires -Module Microsoft.Graph.Authentication
function Invoke-GraphGetRequest {
	<#
.SYNOPSIS
Helper function to query a graph API endpoint and handle pagination

.DESCRIPTION
This function queries a given Microsoft Graph API endpoint and handles pagination.
It can be used with the Microsoft Graph PowerShell module or with the Invoke-RestMethod cmdlet.

.PARAMETER ApiEndpoint
The API endpoint to query. This parameter is mandatory.

.PARAMETER UseGraphModule
A switch parameter to indicate whether to use the Microsoft Graph PowerShell module or not. If this switch is not provided, the function will use the Invoke-RestMethod cmdlet.

.PARAMETER AuthHeader
A hashtable containing the authorization header to use for the request. This parameter is mandatory if the UseGraphModule switch is not provided.

.PARAMETER AsPSObject
A switch parameter to indicate whether the output should be converted to a PowerShell object or not. If this switch is not provided, the output will be returned as is.

.EXAMPLE
Invoke-GraphGetRequest -ApiEndpoint "https://graph.microsoft.com/v1.0/me" -UseGraphModule

.EXAMPLE
Invoke-GraphGetRequest -ApiEndpoint "https://graph.microsoft.com/v1.0/me" -AuthHeader $authHeader

.OUTPUTS
The output of this function depends on the AsPSObject parameter. If this parameter is not provided, the output will be returned as is (hashtable). If this parameter is provided, the output will be converted to a PowerShell object.

#>
param (	  
    [Parameter(Mandatory)]
	  [string]$ApiEndpoint,
	  [switch]$UseGraphModule,    
	  [hashtable]$AuthHeader,
	  [switch]$AsPSObject
	)
$Output = if ($UseGraphModule){
    $Request = Invoke-MgGraphRequest -uri $ApiEndpoint -Method Get
    $Request.Value
    if ($Request.'@odata.nextLink'){  
    do {
    $Request=Invoke-MgGraphRequest -uri $Request.'@odata.nextLink' -Method Get -headers $AuthHeader
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
if ($AsPSObject) {return ($Output | foreach-object {[PSCustomObject]$_})}
else {return $Output}
}
# Connect to graph
Connect-MgGraph -Scopes DeviceManagementManagedDevices.Read.All,DeviceManagementManagedDevices.PrivilegedOperations.All -UseDeviceAuthentication
# Get list of Windows devices
$windowsDevices = Invoke-GraphGetRequest -ApiEndpoint "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=deviceType eq 'WindowsRT'" -UseGraphModule -AsPSObject
# Sync each device
foreach ($device in $windowsDevices){
"Invoking sync on Devicename: {0}`nSerial: {1}`nUPN: {2}`n" -f $device.deviceName,$device.serialNumber,$device.userPrincipalName # Output some progress text
Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($device.id)/syncDevice" -Method POST # Invoke Sync
}
