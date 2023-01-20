#Meraki Switch Functions

function Get-MerakiSwitchStackRoutingInterfaces() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String]$Id,
        [Parameter(
            Mandatory=$true
        )]
        [String]$networkId
    )

    Begin{
        $Headers = Get-Headers       
    }

    Process {
        $Uri = "{0}/networks/{1}/switch/stacks/{2}/routing/interfaces" -f $BaseURI, $networkId, $Id

        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers 

        return $response
    }
    <#
    .SYNOPSIS
    Returns thr routing interfaces for a Switch stack.
    .PARAMETER Id
    The switch stack ID.
    .PARAMETER networkId
    The network Id.
    .OUTPUTS
    An array of Meraki Interface Objects.
    #>
}

Set-Alias GMNetSWStRoutInts -Value Get-MerakiSwitchStackRoutingInterfaces

function Get-MerakiSwitchStackRoutingInterface() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$networkId,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$stackId,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$interfaceId
    )

    Begin {
        $headers = Get-Headers        
    }

    Process {
        $uri = "{0}/networks/{1}/switch/stacks/{2}/routing/interfaces/{3}" -f $BaseUri, $networkId, $stackId, $interfaceId

        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $headers

        return $response
    }
    <#
    .SYNOPSIS
    Return a Meraki Switch stack routing interface.
    .PARAMETER networkId
    The network Id.
    .PARAMETER stackId
    The stack Id.
    .PARAMETER interfaceId
    The interface Id.
    .OUTPUTS
    A Meraki interface object.
    #>
}

Set-Alias -Name GMSwStackRoutInt -Value Get-MerakiSwitchStackRoutingInterface

function Get-MerakiSwitchStackRoutingInterfacesDHCP() {
    [CmdletBinding()]
    Param(
        #Stack Id
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$id,
        #network ID
        [Parameter(
            Mandatory = $true            
        )]
        [string]$networkId
    )

    Begin {
        #$Headers = Get-Headers
        $responses = New-Object 'System.Collections.Generic.List[psobject]'
    }

    Process {
        $interfaces = Get-MerakiSwitchStackRoutingInterfaces -Id $id -networkId $networkId
        $InterfaceDHCP = $interfaces | Get-MerakiSwitchStackRoutingInterfaceDHCP -stackId $id -networkId $networkId
        $InterfaceDHCP | ForEach-Object {
            $responses.add($_)
        }
    }

    End {
        return $responses.ToArray()
    }
    <#
    .SYNOPSIS
    Returns the DHCP Settings for a switch stack interface.
    .PARAMETER id
    The stack Id.
    .PARAMETER networkId
    The network Id.
    .OUTPUTS
    An array of Meraki DHCP objects.
    #>
}

Set-Alias GMSwStRoutIntsDHCP -Value Get-MerakiSwitchRoutingInterfaceDHCPs

function Get-MerakiSwitchStackRoutingStaticRoutes() {
    [CmdletBinding()]
    Param(
        #stackId
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$id,
        #network ID
        [Parameter(
            Mandatory = $true
        )]
        [string]$networkId
    )

    Begin {
        $Headers = Get-Headers
        $responses = New-Object 'System.Collections.Generic.List[psobject]'        
    }

    Process {
        $StackName = (Get-MerakiNetworkSwitchStack -networkID $networkId -stackId $id).Name

        $Uri = "{0}/networks/{1}/switch/stacks/{2}/routing/staticRoutes" -f $BaseURI, $networkId, $id

        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

        $response | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "Stack" -Value $StackName
            $responses.add($_)
        }
    }

    End {
        return $responses.ToArray()
    }
    <#
    .SYNOPSIS
    Returns the switch stack static routes.
    .PARAMETER id
    The stack Id.
    .PARAMETER networkId
    The network Id.
    .OUTPUTS
    An array of Meraki witch stack static route objects.
    #>
}

set-alias GMSwStRoutStatic -Value Get-MerakiSwitchStackRoutingStaticRoutes

function Get-MerakiSwitchStackRoutingInterfaceDHCP() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$interfaceId,
        [Parameter(
            Mandatory = $true
        )]
        [string]$networkId,
        [Parameter(
            Mandatory = $true
        )]
        [string]$stackId
    )

    Begin{
        $Headers = Get-Headers
        $interfaceDHCPs = New-Object 'System.Collections.Generic.List[psobject]'
        $NetworkName = (Get-MerakiNetwork -networkID $networkId).name
        $StackName = (Get-MerakiNetworkSwitchStack -networkId $networkId -stackId $stackId).Name
    }

    Process {
        $interfaceName = (Get-MerakiSwitchStackRoutingInterface -networkId $networkId -stackId $stackId -interfaceId $interfaceId).Name

        $Uri = "{0}/networks/{1}/switch/stacks/{2}/routing/interfaces/{3}/dhcp" -f $BaseURI, $networkId, $stackId, $interfaceId
        
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

        $Dhcp = [PSCustomObject]@{
            networkId = $networkId
            networkName = $NetworkName            
            stackId = $stackId
            stackName = $StackName
            interfaceId = $interfaceid
            interfaceName = $interfaceName
            dhcpMode = $response.dhcpMode
            dhcpLeastTime = $response.dhcpLeaseTime
            dnsNameServersOption = $response.dnsNameServersOption
            dnsCustomNameServers = $response.dnsCustomNameServers
            dhcpOptions = $response.dhcpOptions
            reservedIpRanges = $response.reservedIpRanges
            fixedIpAssignments = $response.fixedIpAssignments
            bootOptionsEnabled = $response.bootOptionsEnabled
            bootFileName = $response.bootFileName
            bootNextServer = $response.bootNextServer
        }
        $interfaceDHCPs.Add($Dhcp)
    }

    End {
        return $interfaceDHCPs.ToArray()
    }
    <#
    .SYNOPSIS
    Returns the Meraki switch stack routing interface DHCP setting for an interface.
    .PARAMETER interfaceId
    The interface Id.
    .PARAMETER networkId
    The network Id
    .PARAMETER stackId
    The Stack Id.
    .OUTPUTS
    A Meraki interface DHCP object.
    #>
}

Set-Alias GMSwStRoutIntDHCP -Value Get-MerakiSwitchRouting

function Get-MerakiSwitchRoutingInterfaces() {
    [CmdLetBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$serial
    )

    Begin {
         $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/devices/{1}/switch/routing/interfaces" -f $BaseUri, $serial

        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

        return $response
    }
    <#
    .SYNOPSIS
    Returns the routing interfaces for a Meraki switch.
    .PARAMETER serial
    The serial number of the switch.
    .OUTPUTS
    An array of Meraki switch interfaces.
    #>
}

Set-Alias -Name GMSWRoutInts -value Get-MerakiSwitchRoutingInterfaces -Option ReadOnly

function Get-MerakiSwitchRoutingInterface() {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true            
        )]
        [String]$serial,        
        [Parameter(
            Mandatory = $true
        )]
        [String]$interfaceId
    )

    $Uri = "{0}/devices/{1}/switch/routing/interfaces/{2}" -f $BaseUri, $serial, $interfaceId
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Mestod GET -Uri $Uri -Headers $Headers`

    return $response
    <#
    .SYNOPSIS
    Returns an interface for a Meraki switch.
    .PARAMETER serial
    The serial number of the switch.
    .PARAMETER interfaceId
    The interface Id.
    .OUTPUTS
    A Meralki switch interface object.
    #>
}

Set-Alias -Name GMSWRoutInt -Value Get-MerakiSwitchRoutingInterface -Option ReadOnly

function Get-MerakiSwitchRoutingInterfaceDHCP() {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true            
        )]
        [String]$serial,
        [Parameter(
            Mandatory = $true
        )]
        [String]$interfaceId
    )

        $Uri = "{0}/devices/{1}/switch/routing/interfaces/{2}/dhcp" -f $BaseUri, $serial, $interfaceId
        $Headers = Get-Headers       

        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
        return $response
    <#
    .SYNOPSIS
    Return DHCP settings for a Meraki switch interface.
    .PARAMETER serial
    The serial number of the switch.
    .PARAMETER interfaceId
    The interface Id.
    .OUTPUTS
    A Meraki wwitch interface DHCP Settings.
    #>
}

Set-Alias GMSWRoutIntDHCP -value Get-MerakiSwitchRoutingInterfaceDHCP -option ReadOnly

function Get-MerakiSwitchRoutingStaticRoutes() {
    [CmdLetBinding()]
    Param(
        #Parameter Help
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String]$serial        
    )

    $Uri = "{0}/devices/{1}/switch/routing/staticRoutes" -f $BaseUri, $serial
    $Headers = Get-Headers
    $device = Get-MerakiDevice -Serial $serial
    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
    $response | foreach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name "switch" -Value $device.name
    }

    return $response
    <#
    .SYNOPSIS
    Returns the static routes for a Meraki switch.
    .PARAMETER serial
    The serial number of the switch.
    .OUTPUTS
    AN array of Meraki static routes.
    #>
}

Set-Alias -Name GMSWRoutStatic -value Get-MerakiSwitchRoutingStaticRoutes -Option ReadOnly

function Get-MerakiNetworkSwitchLAG() {
    [CmdLetBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]$id
    )

    Begin {
        $Headers = Get-Headers
        $responses = New-Object System.Collections.Generic.List[psObject]
    }

    Process {
        $Uri = "{0}/networks/{1}/switch/linkAggregations" -f $BaseUri, $Id
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
        $Lnum = 1
        $response | ForEach-Object {
            $lagID = $_.Id
            $_.switchPorts | foreach-Object {
                $switchName = (Get-MerakiDevice -serial $_.serial).Name
                $portName = (Get-MerakiDeviceSwitchPort -serial $_.serial -portId $_.portId).Name
                $Lag = [PSCustomObject]@{
                    lagID = $LagID
                    lagNumber = $Lnum
                    Switch = $SwitchName
                    Port = $_.PortId
                    portName = $portName
                }
                $responses.Add($Lag)
            }
            $lnum += 1
        }
    }

    End {
        return $responses.ToArray()
    }
    <#
    .SYNOPSIS
    Return the LAB configurations for a Meraki Network.
    .PARAMETER id
    The network Id.
    .OUTPUTS
    An array of switch lag objects.
    #>
}

Set-Alias -Name GMNetSWLag -value Get-MerakiNetworkSwitchLAG -Option ReadOnly

function Get-MerakiNetworkSwitchStacks() {
    [CmdLetBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String]$id
    )

    $Uri = "{0}/networks/{1}/switch/stacks" -f $BaseURI, $id
    $Headers = Get-Headers

    $Network = Get-MerakiNetwork -networkID $id
    if ($network.productTypes -contains "switch") {

        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

        return $response
    } else {
        return $null
    }
    <#
    .SYNOPSIS
    Returns the switch stacks for a Meraki network.
    .PARAMETER id
    The network Id.
    .OUTPUTS
    An array of Meraki switch stack objects.
    #>
}

Set-Alias -Name GMNetSWStacks -Value Get-MerakiNetworkSwitchStacks -Option ReadOnly

function Get-MerakiNetworkSwitchStack() {
    [CmdLetBinding()]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [String]$networkId,
        [Parameter(
            Mandatory = $true
        )]
        [string]$stackId
    )

    $Uri = "{0}/networks/{1}/switch/stacks/{2}" -f $BaseURI, $networkId, $stackId
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $uri -Headers $Headers

    return $response
    <#
    .SYNOPSIS
    Returns a Meraki network switch stack.
    .PARAMETER networkId
    The network Id.
    .PARAMETER stackId
    The stack Id.
    .OUTPUTS
    A Meraki switch stack object.
    #>
}

set-alias GMSwStack -Value Get-MerakiNetworkSwitchStack

function Get-MerakiSwitchPorts() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$serial
    )

    Begin {
        $Headers = Get-Headers       
        $responses = New-Object System.Collections.Generic.List[psobject]
    }

    Process {
        $switchName = (Get-MerakiDevice -Serial $serial).Name
        $Uri = "{0}/devices/{1}/switch/ports" -f $BaseURI, $serial
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
        $response | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "switch" -Value $switchname
            $responses.Add($_)
        }
    }

    End {
        return $responses.ToArray()
    }
    <#
    .SYNOPSIS
    Returns the port configurations for a Meraki switch
    .PARAMETER serial
    The serial number of the switch.
    .OUTPUTS
    An array of Meraki switch port objects.
    #>
}

Set-Alias GMSwPorts -Value Get-MerakiSwitchPorts -Option ReadOnly

function Get-MerakiDeviceSwitchPort() {
    [CmdLetBinding()]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [string]$serial,
        [Parameter(
            Mandatory = $true
        )]
        [string]$portId
    )
    
    $Uri = "{0}/devices/{1}/switch/ports/{2}" -f $BaseURI, $serial, $portId
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
    <#
    .SYNOPSIS
    Returns the port configuration for a Meraki switch port.
    .PARAMETER serial
    The switch serial number.
    .PARAMETER portId
    The port Id.
    .OUTPUTS
    A Meraki switch port object.]
    #>
}

Set-Alias -Name GMDevSwPort -Value Get-MerakiDeviceSwitchPort

function Reset-MerakiSwitchPorts() {
    [CmdLetBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String]$serial,
        [Parameter(
            Mandatory = $true
        )]
        [string[]]$ports
    )

    $Uri = "{0}/devices/{1}/devices/ports/cycle"
    $Headers = Get-Headers

    $psBody = @{}
    $psBody.Add("ports", $ports)

    $body = $psBody | ConvertTo-JSON

    $response = Invoke-RestMethod -Method POST -Uri $Uri -body $body -header $Headers

    return $response
    <#
    .SYNOPSIS
    Resets (cycles) a Meraki switch port.
    .PARAMETER serial
    The switch serial number.
    .PARAMETER ports
    An array of port Ids.
    .OUTPUTS
    An array of ports that were reset.
    #>
}

Set-Alias -Name RMSWPorts -Value Reset-MerakiSwitchPorts -Option ReadOnly 

function Get-MerakiSwitchPortsStatus() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$serial,
        [ValidateScript(
            {
                if ($Days) {
                    throw "The StartDate parameter cannot be used with the Days parameter."
                } else {
                    $true
                }
            }
        )]
        [ValidateScript({$_ -is [datetime]})]
        [datetime]$StartDate,
        [ValidateScript(
            {
                if ($StartDate) {
                    throw "The Days parameter cannot be used with the StartDate parameter."
                } else {
                    $true
                }
            }
        )]
        [ValidateScript({$_ -is [int]})]
        [int]$Days
    )

    Begin {
        $Headers = Get-Headers
        Set-Variable -Name Query

        if ($StartDate) {
            $_startDate = "{0:s}" -f $StartDate
            $Query = "t0={0}" -f $_startDate
        }
        if ($Days) {
            $ts = [timespan]::FromDays($Days)
            if ($Query) {
                $Query += "&"
            }
            $Query += "timespan" -f ($ts.TotalSeconds)
        }
    }

    Process {
        $Uri = "{0}/devices/{1}/switch/ports/statuses" -f $BaseURI, $serial

        if ($Query) {
            $Uri += "?{0}" -f $Query
        }
        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Return the status for all the ports of a switch
    .DESCRIPTION
    REturns a collection of switch poe=rt status objects for a switch.
    .PARAMETER serial
    Serial Number of the switch.
    .PARAMETER StartDate
    The Starting date to retrieve data. Cannot be more than 31 days prior to today.
    .PARAMETER Days
    Number of days back from today to retrieve data. Cannot be more than 31 days.
    .OUTPUTS
    A collection if port status objects.
    #>
}

Set-Alias -name GMSWPortStatus  -Value Get-MerakiSwitchPortsStatus -Option ReadOnly

function Get-MerakiSwitchPortsPacketCounters() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$serial,
        [ValidateScript({$_ -is [decimal]})]
        [decimal]$Hours
    )

    Begin {
        $Headers = Get-Headers

        Set-Variable -Name Query

        if ($Days) {
            $ts = [timespan]::FromHours($Hours)
            if ($Query) {
                $Query += "&"
            }
            $Query += "timespan={0}" -f ($ts.TotalSeconds)
        }
    }

    Process {
        $Uri = "{0}/devices/{1}/switch/ports/statuses/packets" -f $BaseURI, $serial
        if ($Query) {
            $Uri += "?{0}" -f $Query
        }

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Return the packet counters for all the ports of a switch
    .DESCRIPTION
    Returns packet counter statustics for all ports of a switch.
    .PARAMETER serial
    Serial number of the switch.
    .PARAMETER Hours
    The number of hours to return the data. The default is 24 hours (1 day). Can be entered as a decimal number. For the last 30 minutes enter .5.
    .OUTPUTS
    A collection if packet counter objects.
    #>
}

Set-Alias -Name GMSWPortsPacketCntrs -Value Get-MerakiSwitchPortsPacketCounters