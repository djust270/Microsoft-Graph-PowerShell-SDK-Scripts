$RequiredModules = @(
'Microsoft.Graph.Authentication'
'Microsoft.Graph.Identity.DirectoryManagement'
'Microsoft.Graph.Users'
)
foreach ($Module in $RequiredModules) {
	if (-Not ([bool](get-module -ListAvailable -Name $Module))){
		"Installing module {0}" -f $Module
		Install-Module $Module -scope CurrentUser -Force
	}
}

#File Save box function 
Function Get-SaveFileLocation
{
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
	Out-Null
	
	$SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
	$SaveFileDialog.initialDirectory = [system.Environment]::GetFolderPath('Desktop')
	$SaveFileDialog.filter = "CSV (*.CSV) | All files (*.*)"
	$SaveFileDialog.ShowDialog() | Out-Null
	$SaveFileDialog.filename
}

# Get Friendly License Names
$MSLicenseInfo = Invoke-WebRequest -UseBasicParsing "https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference"
    $SkuCSVLink=($MSLicenseInfo.links | Where-Object {$_.href -match ".csv"}).href
    $WebClient=[System.Net.WebClient]::New()
    $InMemoryCSV = $WebClient.DownloadString($SkuCSVLink)
    $ProductSkuCSV = ConvertFrom-CSV -Delimiter ',' -InputObject $InMemoryCSV
    $WebClient.Dispose()

# Get necessary permission scoped
$perms = 'Directory.Read.All'

Connect-MgGraph -Scopes $perms

# Get all tenant skus
[Array]$Skus = Get-MgSubscribedSku
$TenantLicenseDetails = $Skus | select SkuPartNumber, ConsumedUnits, @{ n = 'TotalUnits'; e = { $_.prepaidunits.enabled } }, @{ n = 'FriendlyName'; e= {$_ | foreach { $FriendlyLicenses[$_.SkuPartNumber] } } }
[Array]$Users = Get-MGUser -All
$i = 0
foreach ($user in $Users)
{
	Write-Progress -Activity "Processing User License details" -Status "Working on $($user.displayname)" -PercentComplete (($i / $Users.Count) * 100)
	$user.LicenseDetails = Get-MgUserLicenseDetail -UserId $user.id
	$i++
}
$UserLicenseDetails = $Users | where LicenseDetails | select UserPrincipalName, @{ n = 'Licenses'
e = { 
		($_ | foreach { $_.licensedetails | foreach {
			$a = $_
			$FriendlyLicense = ($ProductSkuCSV | Where-Object {$_.String_ID -eq $a.SkuPartNumber} | Select-Object -First 1).Product_Display_Name
			if ($FriendlyLicense) { $FriendlyLicense }
					else { $a.SkuPartID }
				}
			}) -join ';'
	}
}
Write-Verbose "Enter Save FilePath"
$savepath = Get-SaveFileLocation # Open Save File dialogbox
$UserLicenseDetails | Export-Csv $savepath -NoTypeInformation # Export to CSV
& $savepath # Automatically open the CSV once complete
Disconnect-mgGraph | Out-Null
