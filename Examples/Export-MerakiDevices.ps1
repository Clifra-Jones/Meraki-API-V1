using namespace System.Collections.Generic
Param(
    [Parameter()]
    [ValidateSet('MX','MR','MS','VMX')]
    [string]$DeviceType,

    [Parameter()]
    [string]$ProfileName,

    [string]$OutputPath
)

# If the output file path is not provided configure it here.
if(-Not $OutputPath) {
    $OutputPath = "MerakiDevices_$(Get-Date -f 'yyyMMdd_HHmmss').csv"
}

# Gather the networks into a hash table indexed by Network ID.
# This is faster that calling the API endpoint for each device in the loop below.
$Networks = @{}
Get-MerakiNetworks | ForEach-Object {
    $Networks[$_.Id] = $_
}

# If the ProfileName is provided add it to the params hash table
# the profile name determines the organization. This is only required if not using the default profile.
# You must have configured the profile to use this parameter.
$params = @{}
if ($ProfileName) {
    $params['ProfileName'] = $ProfileName
}

# Get the organization devices. These are all registered devices in the organization
# Devices are filtered by Device Type. e.g. MX, MS, MR. if not provided all devices are returned.
$OrgDevices = Get-MerakiOrganizationDevices @params | Where-Object {$_.model -like "$DeviceType*"}

# Create a .Net list object. Populating a list object is faster than using the Powershell += operator to add items to an array.
$DeviceList = [List[PsObject]]::New()

# Look through the $OrgDevices array. Build the DeviceEntry object an add it to the DeviceList.
foreach ($Device in $OrgDevices) {
    # Retrieve the network from the $Networks hash table by the Devices Network ID.
    $Network = $Networks[$Device.NetworkId]

    # Create the Device Entry object.
    $DeviceEntry = [PSCustomObject]@{
        serial = $Device.serial
        NetworkID = $Network.Id
        NetworkName = $Network.Name
        ProductType = $Device.productType
        Model = $Device.model
        Location = $Device.Address
        Latitude = $Device.lat
        Longitude = $Device.lng
        MAC = $Device.mac
        ConfigUpdatedAt = $Device.ConfigurationUpdatedAt
        Firmware = $Device.Firmware
        SoftwareVersion = ($Device.details.Where({$_.Name -eq 'Running software version'})).value
    }

    # Add the DeviceEntry to the DeviceList.
    $DeviceList.Add($DeviceEntry)
}

# Export the DeviceList to a CSV file.
$DeviceList.ToArray() | Export-csv -Path $OutputPath
