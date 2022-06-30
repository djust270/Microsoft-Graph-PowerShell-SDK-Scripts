<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.195
	 Created on:   	6/30/2022 4:18 PM
	 Created by:   	Dave Just
	 Filename: Update-TeamsCallingLicenses.ps1    	
	===========================================================================
	.DESCRIPTION
		Update the license assignments in AzureAD associated with Teams voice calling.
#>
#Requires -Module Microsoft.Graph
#Requires -Module MicrosoftTeams

# As a precaution, backup all users phone number assignments
Connect-MicrosoftTeams
Get-CsOnlineUser | where LineUri | select Displayname, UserPrincipalName, DialPlan, @{
	N = "Line"; e = { $_.lineuri -replace 'tel:', '' }
} | export-Csv TeamsUsers.csv

# Replace with appropriate sku names
$OldSku = "BUSINESS_VOICE_MED2_TELCO"
$NewSku = "MCOTEAMS_ESSENTIALS", "MCOMEETBASIC"
# Get necessary permission scopes
$perms = 'User.Read.All', 'User.ReadWrite.All', 'Directory.Read.All'
Connect-MgGraph -Scopes $perms
Select-MgProfile beta

$Skus = Get-MgSubscribedSku # Get all skus in the tenant
$Users = Get-MGUser -All # Get all user accounts
$OldVoiceSku = $skus | where { $_.skupartnumber -eq "$OldSku" }
$NewVoiceSku = foreach ($Product in $NewSkus)
{
	$s = $skus | where { $_.skupartnumber -like "$Product" }
	@{ SkuID = $s.ID }
}

$i = 0 # Increment variable
foreach ($user in $Users) # Gather license assigments for all users
{
	Write-Progress -Activity "Processing User License details" -Status "Working on $($user.displayname)" -PercentComplete (($i / $Users.Count) * 100)
	$user.LicenseDetails = Get-MgUserLicenseDetail -UserId $user.id
	Start-Sleep -Milliseconds 200
	$i++
}

$UserLicenseDetails = $Users | where LicenseDetails
$NeedsUpdated = $UserLicenseDetails | where { $_.LicenseDetails.SkuPartNumber -like $OldSku }
foreach ($u in $NeedsUpdated)
{
	"Updating License assignment for {0}" -f $u.UserPrincipalName
	Set-MgUserLicense -UserId $u.id -AddLicenses $NewVoiceSku -RemoveLicenses @($OldVoiceSku.id) #Add new license and remove old
	Start-Sleep -Milliseconds 200
}

Get-CsOnlineUser | select name,lineuri



