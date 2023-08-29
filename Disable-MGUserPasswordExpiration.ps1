# Disable user password expiration
function Disable-MGUserPasswordExpiration {
[CmdletBinding()]
param (
[parameter(mandatory=$true)]
[mailaddress]$UPN
)
$UPN = $UPN.Address
try {
Invoke-MgGraphRequest -Method PATCH -Uri /v1.0/users/$UPN -Body (@{"PasswordPolicies" = "DisablePasswordExpiration"}) -ErrorAction Stop
"Sucessfully disabled password expiration for {0}" -f $UPN
}
Catch {
$_
}
}
