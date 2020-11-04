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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
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
}

set-alias GMSwStack -Value Get-MerakiNetworkSwitchStack

<#
.Description
Retrieve Switch Port settigs for a switch
#>
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
}

Set-Alias -Name RMSWPorts -Value Reset-MerakiSwitchPorts -Option ReadOnly  