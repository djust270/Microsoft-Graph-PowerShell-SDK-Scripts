<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.195
	 Created on:   	5/20/2022 9:22 AM
	 Created by:   	Dave Just
	 Organization: 	
	 Filename: LegacySignInsAudit.ps1    	
	===========================================================================
	.DESCRIPTION
	 	Export an audit report of legacy authentication sign ins. Report will fetch the past 7 days. To expand, edit line 58
#>
#Requires -Module Microsoft.Graph
function Get-LegacySignins {
	param (
		[int]$last = 7
	)
	begin
	{
		$limit = (Get-Date).AddDays(-$last)
		$today = Get-Date
		$filter = $filter = "(createdDateTime ge $limit and createdDateTime lt $today and (clientAppUsed eq 'AutoDiscover' or clientAppUsed eq 'Exchange ActiveSync' or clientAppUsed eq 'Exchange Online PowerShell' or clientAppUsed eq 'Exchange Web Services' or clientAppUsed eq 'IMAP4' or clientAppUsed eq 'MAPI Over HTTP' or clientAppUsed eq 'Offline Address Book' or clientAppUsed eq 'Other clients' or clientAppUsed eq 'Outlook Anywhere (RPC over HTTP)' or clientAppUsed eq 'POP3' or clientAppUsed eq 'Reporting Web Services' or clientAppUsed eq 'Authenticated SMTP' or clientAppUsed eq 'Outlook Service'))"
	}
	process
	{
		$logs = Get-MgAuditLogSignIn -filter $filter -all
	}
	end
	{
		return $logs
	}
}

Function Set-SaveFileFolderLocation
# Open a folder browser dialog box to select a folder path
{
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
	Out-Null
	
	$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
	$FolderBrowser.Description = "Select folder location to save output"
	$FolderBrowser.ShowDialog() | Out-Null
	return $FolderBrowser.SelectedPath
}

# Connect to Graph
Connect-MgGraph -Scopes Directory.Read.All,AuditLog.Read.All -ForceRefresh -UseDeviceAuthentication

$folder = Set-SaveFileFolderLocation
$signins = Get-LegacySignins -last 7 #Edit the last flag to specify the number of days for the report. 
$tenant = ([mailaddress](Invoke-MgGraphRequest -Method get -Uri "v1.0/me").userPrincipalName).host -replace '\.\w+', ''
try { Get-InstalledModule ImportExcel | Out-Null; $ImportExcel = $true }
catch { $ImportExcel = $false }

$report = $signins | select createddatetime, userdisplayname, userprincipalname, AppDisplayName, ClientAppUsed, IPAddress, @{ n = 'AdditionalDetails'; e = { $_.status.additionaldetails } }
$path = ($folder + '\' + $tenant + '-LegacySignIns.xlsx')
if ($ImportExcel)
{
	Export-Excel -InputObject $report -Path $path -TableName legacysignins -AutoSize
}
else { Export-Csv -InputObject $report -Path $path -NoTypeInformation }
Disconnect-MgGraph
