Param(
    [string]$NetworkNameFilter,
    [string]$DnsServerIP,
    [string]$ReplaceDnsServerIP
)

If ($NetworkNameFilter) {
    $Networks = Get-MerakiNetwork | `
        Where-object {
            $_isBoundToConfigTemplate -eq $false -and
            $_.Name -like "*$NetworkNameFilter*"
        }
} else {
    $Networks = Get-MerakiNetworks | Where-Object {$_isBoundToConfigTemplate -eq $false}
}

foreach ($Network in $Networks) {
    # Get VLAn defined on appliance
    $ApplianceVLANS = $Network | Get-MerakiNetworkApplianceVLANS
    foreach ($ApplianceVLAN in $ApplianceVLANS) {
        if ($ApplianceVLAN.dhcpHandling = "Run a DHCP Server") {
            $dnsServers = $ApplianceVLAN.dnsNameservers
            if ($dnsServers.Contains($DnsServerIp)) {
                if ($ReplaceDnsServerIP) {
                    $dnsServers.Replace($DnsServerIP, $ReplaceDnsServerIP)
                }
                [void](Update-MerakiNetworkApplianceVLAN -NetworkId $Network.Id -VlanId $ApplianceVLAN.Id -DnsNameServers $dnsServers)
                $message = "Updated Network {0} VLAN {1} DNS Server to {2}" -f $Network.Name, $Vlan.Id, $dnsServers
                Write-Host $Message
            } else {
                $message = "Network {0} VLAN {1} DNS Server to {2}" -f $Network.Name, $Vlan.Id, $dnsServers
                Write-Host $Message
            }
        }
    }
    #Switch VLAN
    $Stacks = $Network | Get-MerakiNetworkSwitchStacks
    If ($Stacks) {
        foreach ($Stack in $Stacks) {
            $Interfaces = Get-MerakiSwitchStackRoutingInterfaces -networkId $Network.Id -id $Stack.Id
            if ($interfaces) {
                foreach ($interface in $Interfaces) {
                    $InterfaceDHCP = Get-MerakiSwitchStackRoutingInterfaceDHCP -interfaceId $Interface.Id -networkId $Network.id -stackId $Stack.Id
                    If ($InterfaceDHCP.dhcpMode = 'dhcpServer') {
                        if ($Interface.dnsNameServerOption = 'custom') {
                            if ($Interface.dnsCustomNameServers -contains $DnsServerIP) {
                                if ($ReplaceDnsServerIP) {
                                    $dnsServers = $Interface.dnsCustomNameServers.Where({$_ -ne $DnsServerIP})
                                    $dnsServers += $ReplaceDnsServerIP
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    $Switches = $Network | Get-MerakiNetworkDevices | Where-Object {$_.model -like "MS*"}

}