param (
[parameter(mandatory=$true)]
[mailaddress]$UPN
)
$UPN = $UPN.Address
Get-MgUser -UserId $UPN | select -ExpandProperty ID
try {
Invoke-MgGraphRequest -Method PATCH -Uri /v1.0/users/$userid -Body (@{"PasswordPolicies" = "DisablePasswordExpiration"}) -ErrorAction Stop
"Sucessfully disabled password expiration for {0}" -f $UPN
}
Catch {
$_
}