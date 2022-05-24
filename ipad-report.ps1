Connect-MgGraph -Scopes DeviceManagementManagedDevices.Read.All
$iosdevices = Get-MgDeviceManagementManagedDevice -Filter "OperatingSystem eq 'ios'"
$ipadReport = foreach ($device in ($iosdevices | where model -like "*ipad*")){
# Get last 4 digits of serial
$modelstring = $device.serialnumber.Substring($device.serialnumber.length -4)
# Search apple support page with last 4 serial digits
$url = "http://support-sp.apple.com/sp/product?cc=$modelstring`&lang=en_US"
$modelsearch = Invoke-RestMethod -Method GET -uri $url
$model = $modelsearch.root.configCode
# Build report. Add additional properties as desired
[pscustomobject]@{
DeviceName = $device.DeviceName
UserDisplayName = $device.UserDisplayname
SerialNumber = $device.serialNumber
model = $model
}
}
$ipadReport | export-csv "IpadReport.csv" -NoTypeInformation
& .\IpadReport.csv
