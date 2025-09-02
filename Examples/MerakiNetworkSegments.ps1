using namespace System.Collections.Generic

param(
    [string]$ProfileName
)

$Segments = [List[object]]::New()

$Networks = Get-MerakiNetworks -profileName $ProfileName

foreach ($Network in $Networks) {
    Write-Host "$($Network.Name) : $($Network.id)"
    $Devices = Get-MerakiNetworkDevices -NetworkId $Network.Id | Where-Object {$_.model -like "MX*" -or $_.model -like "MS*"}
    $Appliances = $Devices.where({$_.Model -like "MX*"})
    $Switches = $Devices.Where({$_.Model -like "MS*"})
    try {
        $Stacks = Get-MerakiSwitchStack -NetworkId Network.Id
    } catch {
        # Do nothing
    }

    foreach ($Appliance in $Appliances) {
        try {
            $VLANS = Get-MerakiApplianceVLANS -Id $Network.Id 
        } catch {
            $VLANS = Get-MerakiApplianceSingleLan -Id $Network.Id
        }
        foreach ($VLAN in $VLANS) {
            $Segments.Add(
                [PSCustomObject]@{
                    'IP Range (CIDR)' = $VLAN.Subnet
                    'Segment High Level Description' = $Network.Name
                }
            )
        }
    }

    foreach ($Switch in $Switches) {
        $Interfaces = Get-MerakiSwitchRoutingInterface -serial $switch.serial 
        foreach ($Interface in $Interfaces) {
            if ($Interface.Subnet) {
                $Segments.Add( 
                    [PSCustomObject]@{
                        'IP Range (CIDR)' = $Interface.Subnet
                        'Segment High Level Description' = "$($Network.Name) : $($Interface.Name)"
                    }
                )
            }
        }
    }

    foreach ($Stack in $Stacks) {
        $Interfaces = Get-MerakiSwitchStackRoutingInterface -StackId $Stack.Id
        foreach ($Interface in $Interfaces) {
            $Segments.Add( 
                [PSCustomObject]@{
                    'IP Range (CIDR)' = $Interface.Subnet
                    'Segment High Level Description' = "$($Network.Name) : $($Interface.Name)"
                }
            )
        }
    }
}

return $Segments.ToArray()