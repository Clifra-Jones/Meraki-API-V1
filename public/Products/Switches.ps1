#Meraki Switch Functions
using namespace System.Collections.Generic
function Get-MerakiSwitchStackRoutingInterfaces() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('StackId')]
        [String]$Id,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [String]$NetworkId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin{

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }

        $Headers = Get-Headers       
    }

    Process {
        $Uri = "{0}/networks/{1}/switch/stacks/{2}/routing/interfaces" -f $BaseURI, $NetworkId, $Id

        $Stack = Get-MerakiSwitchStack -stackId $id -networkId $NetworkId

        try {
            $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | foreach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "stackId" -Value $Id
                $_ | Add-Member -MemberType NoteProperty -Name "stackName" -Value $Stack.Name
                $_ | Add-Member -MemberType NoteProperty -Name "networkId" -Value $NetworkId
            }

            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Returns thr routing interfaces for a Switch stack.
    .PARAMETER Id
    The switch stack ID.
    .PARAMETER networkId
    The network Id.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile Name.
    .OUTPUTS
    An array of Meraki Interface Objects.
    #>
}

Set-Alias GMNetSWStRoutInts -Value Get-MerakiSwitchStackRoutingInterfaces

function Get-MerakiSwitchStackRoutingInterface() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
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
        [string]$interfaceId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }

        $headers = Get-Headers        
    }

    Process {
        $uri = "{0}/networks/{1}/switch/stacks/{2}/routing/interfaces/{3}" -f $BaseUri, $networkId, $stackId, $interfaceId

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $headers -PreserveAuthorizationOnRedirect

            return $response
        } catch {
            throw $_
        }
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
    .PARAMETER OrgId
    Optional Organization Id
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    A Meraki interface object.
    #>
}

Set-Alias -Name GMSWStackRoutInt -Value Get-MerakiSwitchStackRoutingInterface

function Add-MerakiSwitchStackRoutingInterface() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$StackId,
        [Parameter(Mandatory = $true)]
        [int]$VlanId,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Subnet,
        [string]$InterfaceIp,
        [string]$DefaultGateway,
        [string]$Ipv6Address,
        [ValidateScript({$_ -eq 'static' -and ($Ipv6Address)}, ErrorMessage = "Parameter Ipv6Assignment must be 'static' if Parameter Ipv6Address is specified.")]
        [string]$Ipv6AssignmentMode,
        [string]$Ipv6Gateway,
        [string]$Ipv6Prefix,
        [ValidateScript({$_ -is [int]})]
        [int]$OspfCost,
        [string]$OspfArea,
        [switch]$OspfIsPassiveEnabled,
        [ValidateScript({$_ -is [int]})]
        [int]$OspfV3Cost,
        [string]$OspfV3Area,
        [switch]$OspfV3IsPassiveEnabled,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/stack/{2}/routing/interfaces" -f $BaseURI, $NetworkId, $StackId

    $_Body = @{
        "vlanId" = $VlanId
        "name" = $Name            
    }
    if ($Subnet) { $_Body.Add("Subnet", $Subnet) }
    if ($InterfaceIp) { $_Body.Add("InterfaceIp", $InterfaceIp) }
    if ($DefaultGateway) { $_Body.Add("defaultGateway", $DefaultGateway) }
    if ($Ipv6Address) {
        $_Body.Add("ipv6", @{
            "assignmentMode" = $Ipv6AssignmentMode
            "address" = $Ipv6Address
            "prefix" = $Ipv6Prefix
            "gateway" = $Ipv6Gateway
        })
    }
    if ($OspfCost) {
        $_Body.Add("ospfSettings", @{
            "area" = $OspfArea
            "cost" = $OspfCost
            "isPassiveEnabled" = $OspfIsPassiveEnabled.IsPresent`
        })
    }
    if ($OspfV3Cost) {
        $_Body.Add("ospfV3", @{
            "area" = $OspfV3Area
            "cost" = $OspfV3Cost
            "isPassiveEnabled" = $OspfV3IsPassiveEnabled.IsPresent
        })
    }

    $body = $_Body | ConvertTo-Json -Depth 5 -Compress
    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Add Meraki Switch stack routing interface
    .DESCRIPTION
    Add an interface to a Meraki network.
    .PARAMETER NetworkId
    The Id of the network.
    .PARAMETER StackId
    The Id of the switch stack.
    .PARAMETER VlanId
    The VLAN this routed interface is on. VLAN must be between 1 and 4094
    .PARAMETER Name
    A friendly name or description for the interface or VLAN.
    .PARAMETER Subnet
    The network that this routed interface is on, in CIDR notation (ex. 10.1.1.0/24).
    .PARAMETER InterfaceIp
    The IP address this switch stack will use for layer 3 routing on this VLAN or subnet. This cannot be the same as the switch's management IP.
    .PARAMETER DefaultGateway
    The next hop for any traffic that isn't going to a directly connected subnet or over a static route. This IP address must exist in a subnet with a routed interface.
    .PARAMETER Ipv6Address
    The IPv6 address of the interface. Required if assignmentMode is 'static'. Must not be included if assignmentMode is 'eui-64'.
    .PARAMETER Ipv6AssignmentMode
    The IPv6 assignment mode for the interface. Can be either 'eui-64' or 'static'. 
    .PARAMETER Ipv6Gateway
    The IPv6 default gateway of the interface. Required if prefix is defined and this is the first interface with IPv6 configured for the stack.
    .PARAMETER Ipv6Prefix
    The IPv6 prefix of the interface. Required if IPv6 object is included.
    .PARAMETER OspfCost
    The path cost for this interface. Defaults to 1, but can be increased up to 65535 to give lower priority.
    .PARAMETER OspfArea
    The OSPF area to which this interface should belong. Can be either 'disabled' or the identifier of an existing OSPF area. Defaults to 'disabled'.
    .PARAMETER OspfIsPassiveEnabled
    When enabled, OSPF will not run on the interface, but the subnet will still be advertised.
    .PARAMETER OspfV3Cost
    The path cost for this interface. Defaults to 1, but can be increased up to 65535 to give lower priority.
    .PARAMETER OspfV3Area
    The OSPF area to which this interface should belong. Can be either 'disabled' or the identifier of an existing OSPF area. Defaults to 'disabled'.
    .PARAMETER OspfV3IsPassiveEnabled
    When enabled, OSPF will not run on the interface, but the subnet will still be advertised.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    #>
}

Set-Alias -Name AddMSSRteInt -Value Add-MerakiSwitchStackRoutingInterface

Function Remove-MerakiSwitchStackRoutingInterface() {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'defailt')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$StackId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/stacks/{2}/routing/interfaces" -f $BaseURI, $NetworkId, $StackId
    $STack = Get-MerakiNetworkSwitchStack -networkId $NetworkId -stackId $StackId

    if ($PSCmdlet.ShouldProcess("Delete","Stack: $($Stack.name)")) {
        try {
            $response = Invoke-RestMethod -Method DELETE -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Remove Meraki switch stack routing interface
    .DESCRIPTION
    Remove an interface from a Meraki switch stack
    .PARAMETER NetworkId
    Network ID of the network containing the switch stack
    .PARAMETER StackId
    The stack ID of the stack to be removed.
    .PARAMETER OrgId
    Optional Organization id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    Returns HTML status code. Code 204 - Successful.
    #>
}

Set-Alias -Name RemoveMSStackRouteInt -Value Remove-MerakiSwitchStackRoutingInterface

function Set-MerakiSwitchStackRoutingInterface() {
    [CmdletBinding(DefaultParameterSetName ='default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$StackId,
        [Parameter(Mandatory = $true)]
        [string]$InterfaceId,
        [Parameter(Mandatory = $true)]
        [int]$VlanId,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Subnet,
        [string]$InterfaceIp,
        [string]$DefaultGateway,
        [string]$Ipv6Address,
        [ValidateScript({$_ -eq "static -and ($ipv6Address)"}, ErrorMessage = "Parameter Ipv6Assignment mode must be static if parameter Ipv6Address is specified.")]
        [string]$Ipv6AssignmentMode,
        [string]$Ipv6Gateway,
        [string]$Ipv6Prefix,
        [ValidateScript({$_ -is [int]})]
        [int]$OspfCost,
        [string]$OspfArea,
        [bool]$OspfIsPassiveEnabled,
        [ValidateScript({$_ -is [int]})]
        [int]$OspfV3Cost,
        [string]$OspfV3Area,
        [bool]$OspfV3IsPassiveEnabled,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/stacks/{2}/routing/interfaces/{3}" -f $BaseURI, $NetworkId, $StackId, $InterfaceId

    $_Body = @{
        "vlanId" = $VlanId
        "name" = $Name            
    }
    if ($Subnet) { $_Body.Add("Subnet", $Subnet) }
    if ($InterfaceIp) { $_Body.Add("InterfaceIp", $InterfaceIp) }
    if ($DefaultGateway) { $_Body.Add("defaultGateway", $DefaultGateway) }
    if ($Ipv6Address) {
        $_Body.Add("ospfSettings", @{
            "area" = $OspfArea
            "cost" = $OspfCost
            "isPassiveEnabled" = $OspfIsPassiveEnabled
        })
    }
    if ($OspfV3Cost) {
        $_Body.Add("ospfV3", @{
            "area" = $OspfV3Area
            "cost" = $OspfV3Cost
            "isPassiveEnabled" = $OspfV3IsPassiveEnabled
        })
    }

    $body = $_Body | ConvertTo-Json -Depth 5 -Compress
    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }

    <#
    .DESCRIPTION
    Update a switch stack routing interface.
    .PARAMETER NetworkId
    The network Id.
    .PARAMETER StackId
    The stack Id.
    .PARAMETER InterfaceId
    The Interface Id.
    .PARAMETER VlanId
    The VLAN this routed interface is on. VLAN must be between 1 and 4094
    .PARAMETER Name
    A friendly name or description for the interface or VLAN.
    .PARAMETER Subnet
    The network that this routed interface is on, in CIDR notation (ex. 10.1.1.0/24).
    .PARAMETER InterfaceIp
    The IP address this switch stack will use for layer 3 routing on this VLAN or subnet. This cannot be the same as the switch's management IP.
    .PARAMETER DefaultGateway
    The next hop for any traffic that isn't going to a directly connected subnet or over a static route. This IP address must exist in a subnet with a routed interface.
    .PARAMETER Ipv6Address
    The IPv6 address of the interface. Required if assignmentMode is 'static'. Must not be included if assignmentMode is 'eui-64'.
    .PARAMETER Ipv6AssignmentMode
    The IPv6 assignment mode for the interface. Can be either 'eui-64' or 'static'. 
    .PARAMETER Ipv6Gateway
    The IPv6 default gateway of the interface. Required if prefix is defined and this is the first interface with IPv6 configured for the stack.
    .PARAMETER Ipv6Prefix
    The IPv6 prefix of the interface. Required if IPv6 object is included.
    .PARAMETER OspfCost
    The path cost for this interface. Defaults to 1, but can be increased up to 65535 to give lower priority.
    .PARAMETER OspfArea
    The OSPF area to which this interface should belong. Can be either 'disabled' or the identifier of an existing OSPF area. Defaults to 'disabled'.
    .PARAMETER OspfIsPassiveEnabled
    When enabled, OSPF will not run on the interface, but the subnet will still be advertised.
    .PARAMETER OspfV3Cost
    The path cost for this interface. Defaults to 1, but can be increased up to 65535 to give lower priority.
    .PARAMETER OspfV3Area
    The OSPF area to which this interface should belong. Can be either 'disabled' or the identifier of an existing OSPF area. Defaults to 'disabled'.
    .PARAMETER OspfV3IsPassiveEnabled
    When enabled, OSPF will not run on the interface, but the subnet will still be advertised.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    #>
}

Set-Alias -Name SetMSStkRteInt -Value Set-MerakiSwitchStackRoutingInterface


# function Get-MerakiSwitchStackRoutingInterfacesDHCP() {
#     [CmdletBinding()]
#     Param(
#         #Stack Id
#         [Parameter(
#             Mandatory = $true,
#             ValueFromPipeline = $true,
#             ValueFromPipelineByPropertyName = $true
#         )]
#         [string]$id,
#         #network ID
#         [Parameter(
#             Mandatory = $true            
#         )]
#         [string]$networkId
#     )

#     Begin {
#         #$Headers = Get-Headers
#         $responses = New-Object 'System.Collections.Generic.List[psobject]'
#     }

#     Process {
#         $interfaces = Get-MerakiSwitchStackRoutingInterfaces -Id $id -networkId $networkId
#         $InterfaceDHCP = $interfaces | Get-MerakiSwitchStackRoutingInterfaceDHCP -stackId $id -networkId $networkId
#         $InterfaceDHCP | ForEach-Object {
#             $responses.add($_)
#         }
#     }

#     End {
#         return $responses.ToArray()
#     }
#     <#
#     .SYNOPSIS
#     Returns the DHCP Settings for a switch stack interface.
#     .PARAMETER id
#     The stack Id.
#     .PARAMETER networkId
#     The network Id.
#     .OUTPUTS
#     An array of Meraki DHCP objects.
#     #>
# }

# Set-Alias GMSwStRteIntsDHCP -Value Get-MerakiSwitchStackRoutingInterfacesDHCP

function Get-MerakiSwitchStackRoutingStaticRoutes() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
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
        [string]$networkId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }

        $Headers = Get-Headers
        $responses = New-Object 'System.Collections.Generic.List[psobject]'        
    }

    Process {
        $StackName = (Get-MerakiNetworkSwitchStack -networkID $networkId -stackId $id).Name

        $Uri = "{0}/networks/{1}/switch/stacks/{2}/routing/staticRoutes" -f $BaseURI, $networkId, $id

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

            $response | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "Stack" -Value $StackName
                $responses.add($_)
            }
        } catch {
            throw $_
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
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    An array of Meraki switch stack static route objects.
    #>
}

set-alias GMSwStRoutStatic -Value Get-MerakiSwitchStackRoutingStaticRoutes

function Get-MerakiSwitchStackRoutingStaticRoute() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("NetworkId")]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [string]$StackId,
        [Parameter(Mandatory = $true)]
        [string]$StaticRouteId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }

        $Headers = $Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/switch/stacks/{2}/routing/staticRoutes/{3}" -f $BaseURI, $NetworkId, $StackId, $StaticRouteId

        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }

}

function Set-MerakiNetworkSwitchStackRoutingStaticRoute() {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$StackId,
        [Parameter(Mandatory = $true)]
        [string]$StaticRouteId,
        [string]$Name,
        [string]$NextHopIp,
        [string]$Subnet,
        [switch]$AdvertiseViaOspf,
        [switch]$PreferOverOspfRoutes
    )

    $Header = Get-Header

    $Uri = "{0}/networks/{1}/switch/stacks/{2}/routing/staticRoutes/{3}" -f $BaseURI, $NetworkId, $StackId, $StaticRouteId

    $_Body = @{}

    if ($Name) { $_Body.Add("name", $Name) }
    if ($NextHopIp) { $_Body.Add("nextHopIp",$NextHopIp) }
    if ($Subnet) { $_Body.Add("subnet", $Subnet) }
    if ($AdvertiseViaOspf.IsPresent) { $_Body.Add("advertiseViaOspfEnabled",$true)}
    if ($PreferOverOspfRoutes) { $_Body.Add("preferOverOspfRoutesEnabled", $true)}

    $body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Header -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .DESCRIPTION 
    Retrieves a static route for the specified network.
    .PARAMETER NetworkId
    The Id of the network
    .PARAMETER StackId
    The Id of the stack.
    .PARAMETER StaticRouteId
    The Id of the static route.
    .PARAMETER Name
    Name od the static route.
    .PARAMETER NextHopIp
    IP address of the next hop device to which the device sends its traffic for the subnet
    .PARAMETER Subnet
    The subnet which is routed via this static route and should be specified in CIDR notation (ex. 1.2.3.0/24)
    .PARAMETER AdvertiseViaOspf
    Option to advertise static route via OSPF
    .PARAMETER PreferOverOspfRoutes
    Option to prefer static route over OSPF routes
    .OUTPUTS
    A static route object.
    #>
}

Set-Alias -name SetMNSSRteStRoute -Value Set-MerakiNetworkSwitchStackRoutingStaticRoute

function Remove-MerakiSwitchStackRoutingStaticRoute() {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$StackId,
        [Parameter(Mandatory = $true)]
        [string]$StaticRouteId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/switch/stacks/{1}/routing/staticRoutes/{2}" -f $BaseURI, $NetworkId, $StackId, $StaticRouteId

    $StaticRoute = Get-MerakiSwitchStackRoutingStaticRoute -Id $NetworkId -StackId $StackId -StaticRouteId $StaticRouteId

    if ($PSCmdlet.ShouldProcess("Delete","Static Route: $($Staticroute.Name)")) {
        try {
            $response = Invoke-RestMethod -Method DELETE -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Remove a Meraki switch stack static route.
    .DESCRIPTION
    Remove a static route from a Meraki switch stack.
    .PARAMETER NetworkId
    Network ID of te network containing the switch
    .PARAMETER StackId
    Stack ID to remove the route from.
    .PARAMETER StaticRouteId
    Static Route ID to remove.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    Return HTML status code. 204 = Successful.
    #>
}

Set-Alias -name RSWStkRteInt -Value Remove-MerakiSwitchStackRoutingStaticRoute -Option ReadOnly

function Get-MerakiSwitchStackRoutingInterfaceDHCP() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$interfaceId,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$networkId,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$stackId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin{

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }


        $Headers = Get-Headers
    }

    Process {
        $NetworkName = (Get-MerakiNetwork -networkID $networkId).name
        $StackName = (Get-MerakiNetworkSwitchStack -networkId $networkId -stackId $stackId).Name
        $interfaceName = (Get-MerakiSwitchStackRoutingInterface -networkId $networkId -stackId $stackId -interfaceId $interfaceId).Name

        $Uri = "{0}/networks/{1}/switch/stacks/{2}/routing/interfaces/{3}/dhcp" -f $BaseURI, $networkId, $stackId, $interfaceId

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

            $Dhcp = [PSCustomObject]@{
                networkId = $networkId
                networkName = $NetworkName            
                stackId = $stackId
                stackName = $StackName
                interfaceId = $interfaceid
                interfaceName = $interfaceName
                dhcpMode = $response.dhcpMode
                dhcpLeaseTime = $response.dhcpLeaseTime
                dnsNameServersOption = $response.dnsNameServersOption
                dnsCustomNameServers = $response.dnsCustomNameServers
                dhcpOptions = $response.dhcpOptions
                reservedIpRanges = $response.reservedIpRanges
                fixedIpAssignments = $response.fixedIpAssignments
                bootOptionsEnabled = $response.bootOptionsEnabled
                bootFileName = $response.bootFileName
                bootNextServer = $response.bootNextServer
            }
            return $Dhcp
        } catch {
            throw $_
        }
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
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name
    .OUTPUTS
    A Meraki interface DHCP object.
    #>
}

Set-Alias GMSwStRoutIntDHCP -Value Get-MerakiSwitchStackRoutingInterfaceDHCP
Set-Alias -Name Get-MerakiSwitchStackRoutingInterfacesDHCP -Value Get-MerakiSwitchStackRoutingInterfaceDHCP

function Set-MerakiSwitchStackRoutingInterfaceDhcp() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$StackId,
        [Parameter(Mandatory = $true)]
        [string]$interfaceId,
        [ValidateSet('dhcpDisabled', 'dhcpRelay', 'dhcpServer')]
        [string]$DhcpMode,
        [ValidateSet('30 minutes', '1 hour', '4 hours', '12 hours', '1 day', '1 week')]
        [string]$DhcpLeaseTime,
        [ValidateSet('googlePublicDns', 'openDns', 'custom')]
        [string]$DnsNameServerOption,
        [string[]]$DnsCustomNameServers,
        [switch]$BootOptionsEnabled,
        [string]$BootNextServer,
        [string]$BootFilename,
        [hashtable]$DhcpOptions,
        [hashtable[]]$ReservedIpRanges,
        [hashtable[]]$fixedIpAssignments,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/stacks/{2}/routing/interfaces{3}/dhcp" -f $BaseURI, $NetworkId, $Stackid, $interfaceId

    $_body = @{}

    if ($DhcpMode) { $_body.Add("dhcpMode", $DhcpMode) }
    if ($DhcpLeaseTime) { $_body.Add("dhcpLeaseTime", $DhcpLeaseTime) }
    if ($DnsNameServerOption) { $_body.Add("dnsNameServerOption", $DnsNameServerOption) }
    if ($DnsCustomNameServers) { $_body.Add("dnsCustomNameservers", $DnsCustomNameServers) }
    if ($BootOptionsEnabled.IsPresent) { $_body.Add("bootOptionsEnabled", $true) }
    if ($BootNextServer) { $_body.Add("bootNextServer", $BootNextServer) }
    if ($BootFilename) { $_body.Add("bootFilename", $BootFilename) }
    if ($DhcpOptions) { $_body.Add("dhcpOptions", $DhcpOptions) }
    if ($ReservedIpRanges) { $_body.Add("reservedIpRanges", $ReservedIpRanges) }
    if ($fixedIpAssignments) { $_body.Add("fixedIpAssignments",$fixedIpAssignments) }

    $body = $_body | ConvertTo-Json -Depth 10 -Compress
     
    try{
        $result = Invoke-RestMethod -Method PUT -Headers $Headers -Uri $Uri -Body $body -PreserveAuthorizationOnRedirect
        return $result
    } catch {
        throw $_
    }
    <#
    .DESCRIPTION
    Update a switch stack interface DHCP settings
    .PARAMETER NetworkId
    The ID of the network
    .PARAMETER StackId
    The Od os the stack.
    .PARAMETER interfaceId
    The Id of the interface.
    .PARAMETER DhcpMode
    The DHCP mode options for the switch stack interface ('dhcpDisabled', 'dhcpRelay' or 'dhcpServer')
    .PARAMETER DhcpLeaseTime
    The DHCP lease time config for the dhcp server running on switch stack interface ('30 minutes', '1 hour', '4 hours', '12 hours', '1 day' or '1 week')
    .PARAMETER DnsNameServerOption
    The DHCP name server option for the dhcp server running on the switch stack interface. ('googlePublicDns', 'openDns' or 'custom')
    .PARAMETER DnsCustomNameServers
    The DHCP name server IPs when DHCP name server option is 'custom'.
    .PARAMETER BootOptionsEnabled
    Enable DHCP boot options to provide PXE boot options configs for the dhcp server running on the switch stack interface.
    .PARAMETER BootNextServer
    The PXE boot server IP for the DHCP server running on the switch stack interface
    .PARAMETER BootFilename
    The PXE boot server file name for the DHCP server running on the switch stack interface
    .PARAMETER DhcpOptions
    Array of DHCP options (hash table) consisting of code, type and value for the DHCP server running on the switch stack interface.
    code: string The code for DHCP option which should be from 2 to 254
    type: string The type of the DHCP option which should be one of ('text', 'ip', 'integer' or 'hex')
    value: string The value of the DHCP option
    .PARAMETER ReservedIpRanges
    Array of DHCP reserved IP assignments (hash table) for the DHCP server running on the switch stack interface
    comment: string The comment for the reserved IP range
    end: string The ending IP address of the reserved IP range
    start: string The starting IP address of the reserved IP range
    .PARAMETER fixedIpAssignments
    Array of DHCP fixed IP assignments (hashtable) for the DHCP server running on the switch stack interface.
    ip: string The IP address of the client which has fixed IP address assigned to it
    mac: string The MAC address of the client which has fixed IP address
    name: string The name of the client which has fixed IP address
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    #>
}

Set-Alias -Name UMSStkRteIntDhcp -Value Update-MerakiSwitchStackRoutingInterfaceDhcp

function Get-MerakiSwitchRoutingInterfaces() {
    [CmdLetBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$serial,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }

         $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/devices/{1}/switch/routing/interfaces" -f $BaseUri, $serial

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | ForEach-Object {
                $Switch = Get-MerakiDevice -Serial $serial
                $_ | Add-Member -MemberType NoteProperty -Name "switchName" -Value $switch.Name
                $_ | Add-Member -MemberType NoteProperty -Name "serial" -Value $serial
            }

            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Returns the routing interfaces for a Meraki switch.
    .PARAMETER serial
    The serial number of the switch.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    An array of Meraki switch interfaces.
    #>
}

Set-Alias -Name GMSWRoutInts -value Get-MerakiSwitchRoutingInterfaces -Option ReadOnly

function Get-MerakiSwitchRoutingInterface() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    param (
        [Parameter(
            Mandatory = $true            
        )]
        [String]$serial,        
        [Parameter(
            Mandatory = $true
        )]
        [String]$interfaceId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Uri = "{0}/devices/{1}/switch/routing/interfaces/{2}" -f $BaseUri, $serial, $interfaceId
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Returns an interface for a Meraki switch.
    .PARAMETER serial
    The serial number of the switch.
    .PARAMETER interfaceId
    The interface Id.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    A Meralki switch interface object.
    #>
}

Set-Alias -Name GMSWRoutInt -Value Get-MerakiSwitchRoutingInterface -Option ReadOnly

function Add-MerakiSwitchRoutingInterface() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Serial,
        [Parameter(Mandatory = $true)]
        [ValidateRange(1,4096)]
        [int]$VlanId,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Subnet,
        [string]$DefaultGateway,
        [string]$InterfaceIp,
        [ValidateSet('disabled', 'enabled', 'IGMP snooping querier')]
        [string]$MulticastRouting,
        [string]$Ipv6Address,
        [ValidateSet('eui-64','static')]
        [ValidateScript({$_ -eq 'static' -and $Ipv6Address}, ErrorMessage = "Ipv6Address cannot be specified with Ipv6Assignment mode 'eui-64'")]
        [string]$Ipv6AssignmentMode,
        [string]$Ipv6Gateway,
        [string]$Ipv6Prefix,
        [int]$OspfCost,
        [string]$OspfArea,
        [switch]$OspfIsPassive,
        [int]$OspfV3Cost,
        [string]$OspfV3Area,
        [switch]$OspfV3IsPassive,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/devices/{1}/switch/routing/interfaces" -f $BaseURI, $Serial

    $_Body = @{
        "name" = $Name
        "vlanId" = $VlanId
    }

    if ($Sbnet) { $_Body.Add("subnet", $Subnet) }
    if ($InterfaceIp) { $_Body.Add("interfaceIp", $InterfaceIp) }
    if ($DefaultGateway) { $_Body.Add("defaultGateway", $DefaultGateway) }
    if ($InterfaceIp) { $_Body.Add("interfaceIp", $InterfaceIp) }
    if ($MulticastRouting) { $_Body.Add("multicastRouting", $MulticastRouting) }
    if ($Ipv6Address) {
        $_Body.Add("ipv6", @{
            "assignmentMode" = $Ipv6AssignmentMode
            "prefix" = $Ipv6Prefix
            "address" = $Ipv6Address
            "gateway" = $Ipv6Gateway
        })
    }
    if ($OspfV3Cost) {
        if (-not $OspfArea) {$OspfArea = 'disabled'}
        $_Body.Add("ospfSettings", @{
            "area" = $OspfArea
            "cost" = $OspfCost
            "isPassEnabled" = $OspfIsPassive.IsPresent
        })
    }
    if ($OspfV3Cost) {
        if (-not $OspfV3Area) {$OspfV3Area = 'disabled'}
        $_Body.Add("ospfV3", @{
            "area" = $OspfV3Area
            "cost" = $OspfV3Cost
            "isPassiveEnabled" = $OspfV3IsPassive.IsPresent
        })
    }
    
    $body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Add a routing interface to a switch.
    .DESCRIPTION
    Add a VLAN interface to a Meraki switch.
    .PARAMETER Serial
    Serial number of the switch.
    .PARAMETER VlanId
    The VLAN this routed interface is on. VLAN must be between 1 and 4094.
    .PARAMETER Name
    A friendly name or description for the interface or VLAN.
    .PARAMETER Subnet
    The network that this routed interface is on, in CIDR notation (ex. 10.1.1.0/24
    .PARAMETER DefaultGateway
    The next hop for any traffic that isn't going to a directly connected subnet or over a static route. 
    This IP address must exist in a subnet with a routed interface. Required if this is the first IPv4 interface.
    .PARAMETER InterfaceIp
    The IP address this switch will use for layer 3 routing on this VLAN or subnet. This cannot be the same as the switch's management IP.
    .PARAMETER MulticastRouting
    Enable multicast support if, multicast routing between VLANs is required. 
    Options are: 'disabled', 'enabled' or 'IGMP snooping querier'. Default is 'disabled'.
    .PARAMETER Ipv6Address
    The IPv6 address of the interface. Required if assignmentMode is 'static'. Must not be included if assignmentMode is 'eui-64'.
    .PARAMETER Ipv6AssignmentMode
    The IPv6 assignment mode for the interface. Can be either 'eui-64' or 'static'.
    .PARAMETER Ipv6Gateway
    The IPv6 default gateway of the interface. Required if prefix is defined and this is the first interface with IPv6 configured for the switch.
    .PARAMETER Ipv6Prefix
    The IPv6 prefix of the interface. Required if IPv6 object is included.
    .PARAMETER OspfCost
    The path cost for this interface. Defaults to 1, but can be increased up to 65535 to give lower priority.
    .PARAMETER OspfArea
    The OSPF area to which this interface should belong. Can be either 'disabled' or the identifier of an existing OSPF area. Defaults to 'disabled'.
    .PARAMETER OspfIsPassive
    When enabled, OSPF will not run on the interface, but the subnet will still be advertised.
    .PARAMETER OspfV3Cost
    The path cost for this interface. Defaults to 1, but can be increased up to 65535 to give lower priority.
    .PARAMETER OspfV3Area
    The OSPFv3 area to which this interface should belong. 
    Can be either 'disabled' or the identifier of an existing OSPFv3 area. Defaults to 'disabled'.
    .PARAMETER OspfV3IsPassive
    When enabled, OSPFv3 will not run on the interface, but the subnet will still be advertised.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name
    .OUTPUTS
    "Interface Object"    
    #>
}

Set-Alias -name AddMSRouteInt -Value Add-MerakiSwitchRoutingInterface

function Set-MerakiSwitchRoutingInterface() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Serial,
        [Parameter(Mandatory = $true)]
        [string]$InterfaceId,
        [ValidateRange(1,4096)]
        [int]$VlanId,
        [string]$Name,
        [string]$Subnet,
        [string]$DefaultGateway,
        [string]$InterfaceIp,
        [ValidateSet('disabled', 'enabled', 'IGMP snooping querier')]
        [string]$MulticastRouting,
        [string]$Ipv6Address,
        [ValidateSet('eui-64','static')]
        [ValidateScript({$_ -eq 'static' -and ($Ipv5Address)}, ErrorMessage = "Parameter Ipv6Assignment must be 'static' if parameter Ipv6Address is specified")]
        [string]$Ipv6AssignmentMode,
        [string]$Ipv6Gateway,
        [string]$Ipv6Prefix,
        [ValidateScript({$_ -is [int]})]
        [int]$OspfCost,
        [string]$OspfArea,
        [switch]$OspfIsPassive,
        [ValidateScript({$_ -is [int]})]
        [int]$OspfV3Cost,
        [string]$OspfV3Area,
        [switch]$OspfV3IsPassive ,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/devices/{2}/switch/routing/interfaces/{2}" -f $BaseURI, $Serial, $InterfaceId

    $_Body = @{}

    if ($VlanId) { $_Body.Add("vlanId", $VlanId) }
    if ($Name) { $_Body.Add("name", $Name) }
    if ($Sbnet) { $_Body.Add("subnet", $Subnet) }
    if ($InterfaceIp) { $_Body.Add("interfaceIp", $InterfaceIp) }
    if ($DefaultGateway) { $_Body.Add("defaultGateway", $DefaultGateway) }
    if ($InterfaceIp) { $_Body.Add("interfaceIp", $InterfaceIp) }
    if ($MulticastRouting) { $_Body.Add("multicastRouting", $MulticastRouting) }
    if ($Ipv6Address) {
        $_Body.Add("ipv6", @{
            "assignmentMode" = $Ipv6AssignmentMode
            "prefix" = $Ipv6Prefix
            "address" = $Ipv6Address
            "gateway" = $Ipv6Gateway
        })
    }
    if ($OspfV3Cost) {
        $_Body.Add("ospfSettings", @{
            "area" = $OspfArea
            "cost" = $OspfCost
            "isPassEnabled" = $OspfIsPassive.IsPresent
        })
    }
    if ($OspfV3Cost) {
        $_Body.Add("ospfV3", @{
            "area" = $OspfV3Area
            "cost" = $OspfV3Cost
            "isPassiveEnabled" = $OspfV3IsPassive.IsPresent
        })
    }

    $body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        Throw $_
    }
    <#
    .SYNOPSIS
    Set Meraki Switch Interface.
    .DESCRIPTION
    Set a Meraki switch routing interface.
    .PARAMETER Serial
    Switch serial number.
    .PARAMETER InterfaceId
    Interface ID to be updates.
    .PARAMETER VlanId
    The VLAN this routed interface is on. VLAN must be between 1 and 4094.
    .PARAMETER Name
    A friendly name or description for the interface or VLAN.
    .PARAMETER Subnet
    The network that this routed interface is on, in CIDR notation (ex. 10.1.1.0/24).
    .PARAMETER DefaultGateway
    The next hop for any traffic that isn't going to a directly connected subnet or over a static route. 
    This IP address must exist in a subnet with a routed interface. Required if this is the first IPv4 interface.
    .PARAMETER InterfaceIp
    The IP address this switch will use for layer 3 routing on this VLAN or subnet. This cannot be the same as the switch's management IP.
    .PARAMETER MulticastRouting
    Enable multicast support if, multicast routing between VLANs is required. 
    Options are: 'disabled', 'enabled' or 'IGMP snooping querier'. Default is 'disabled'.
    .PARAMETER Ipv6Address
    The IPv6 address of the interface. Required if assignmentMode is 'static'. Must not be included if assignmentMode is 'eui-64'.
    .PARAMETER Ipv6AssignmentMode
    The IPv6 assignment mode for the interface. Can be either 'eui-64' or 'static'.
    .PARAMETER Ipv6Gateway
    The IPv6 default gateway of the interface. Required if prefix is defined and this is the first interface with IPv6 configured for the switch.
    .PARAMETER Ipv6Prefix
    The IPv6 prefix of the interface. Required if IPv6 object is included.
    .PARAMETER OspfCost
    The path cost for this interface. Defaults to 1, but can be increased up to 65535 to give lower priority.
    .PARAMETER OspfArea
    The OSPF area to which this interface should belong. Can be either 'disabled' or the identifier of an existing OSPF area. Defaults to 'disabled'.
    .PARAMETER OspfIsPassive
    When enabled, OSPF will not run on the interface, but the subnet will still be advertised.
    .PARAMETER OspfV3Cost
    The path cost for this interface. Defaults to 1, but can be increased up to 65535 to give lower priority.
    .PARAMETER OspfV3Area
    The OSPFv3 area to which this interface should belong. Can be either 'disabled' or the identifier of an existing OSPFv3 area. Defaults to 'disabled'.
    .PARAMETER OspfV3IsPassive
    When enabled, OSPFv3 will not run on the interface, but the subnet will still be advertised.
    .PARAMETER OrgId
    Optional Organization id.
    .PARAMETER ProfileName
    Optional Profile Name.
    .OUTPUTS
    Interface object.
    #>
}

Set-Alias -name SetMSRteInt -Value Set-MerakiSwitchRoutingInterface

function Remove-MerakiSwitchRoutingInterface() {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Serial,
        [Parameter(Mandatory = $true)]
        [string]$InterfaceId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/devices/{1}/switch/routing/interfaces/{2}" -f $BaseURI, $Serial, $InterfaceId

    $Interface = Get-MerakiSwitchRoutingInterface -serial $Serial -interfaceId $InterfaceId

    if ($PSCmdlet.ShouldProcess('Delete', "Interface $($interface.name)")) {
        try {
            $response = Invoke-RestMethod -Method DELETE -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Remove a routing interface
    .DESCRIPTION
    Remove a Meraki switch routing interface.
    .PARAMETER Serial
    Serial number of the switch
    .PARAMETER InterfaceId
    Id of the interface.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile Name.
    .OUTPUTS
    An HTML status code. Code 204 = success.
    #>
}

function Get-MerakiSwitchRoutingInterfaceDHCP() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName   
        )]
        [String]$serial,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [String]$interfaceId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }


        $Headers = Get-Headers       
    }

    Process {
        $interface = Get-MerakiSwitchRoutingInterface -interfaceId $interfaceId -serial $serial
        $Switch = Get-MerakiDevice -Serial $serial

        $Uri = "{0}/devices/{1}/switch/routing/interfaces/{2}/dhcp" -f $BaseUri, $serial, $interfaceId
        
        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            
            $DHCP = [PSCustomObject]@{
                    interfaceId = $interfaceId
                    interfaceName = $interface.Name
                    switchSerial = $serial
                    switchName = $switch.Name                    
                    dhcpMode = $response.dhcpMode
                    dhcpLeaseTime        = $response.dhcpLeaseTime
                    dnsNameserversOption = $response.dnsNameserversOption
                    dnsCustomNameservers = $response.bootOptionsEnabled
                    bootOptionsEnabled   = $response.dhcpOptionEnabled
                    dhcpOptions          = $response.dhcpOptions
                    reservedIpRanges     = $response.reservedIpRanges
                    fixedIpAssignments   = $response.fixedIpAssignments
                }
            return $dhcp
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Return DHCP settings for a Meraki switch interface.
    .PARAMETER serial
    The serial number of the switch.
    .PARAMETER interfaceId
    The interface Id.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    A Meraki switch interface DHCP Settings.
    #>
}

Set-Alias GMSWRoutIntDHCP -value Get-MerakiSwitchRoutingInterfaceDHCP -option ReadOnly

function Set-MerakiSwitchRoutingInterfaceDhcp() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Serial,
        [Parameter(Mandatory)]
        [string]$InterfaceId,
        [ValidateSet('dhcpDisabled', 'dhcpRelay', 'dhcpServer')]
        [string]$DhcpMode,
        [ValidateScript({$_ -and $DhcpMode -eq 'dhcpRelay'}, ErrorMessage = "Parameter DhcpRelayServerIps is only valid with DhcpMode 'dhcpRelay'")]
        [string[]]$DhcpRelayServerIps,
        [ValidateSet('30 minutes', '1 hour', '4 hours', '12 hours', '1 day', '1 week')]
        [string]$DhcpLeaseTime,
        [ValidateSet('googlePublicDns', 'openDns', 'custom')]
        [string]$DnsNameServerOptions,
        [string[]]$DnsCustomNameServers,
        [Parameter(ParameterSetName = 'boot')]
        [switch]$BootOptionsEnabled,
        [Parameter(ParameterSetName = 'boot')]
        [string]$BootNextServer,
        [Parameter(ParameterSetName = 'boot')]
        [string]$BootFileName,
        [hashtable[]]$DhcpOptions,
        [hashtable[]]$ReservedIpRanges,
        [hashtable[]]$FixedIpRanges,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/devices/{1}/switch/routing/interface/{2}/dhcp" -f $BaseURI, $Serial, $InterfaceId

    $_Body = @{}

    if ($DhcpMode) { $_Body.Add("dhcpMode", $DhcpMode) }
    if ($DhcpRelayServerIps) { $_Body.Add("dhcpRelayServerIps", $DhcpRelayServerIps) }
    if ($DhcpLeaseTime) { $_Body.Add("shcpLeaseTime", $DhcpLeaseTime) } 
    if ($DnsNameServerOptions) { $_Body.Add("dnsNameserverOptions", $DnsNameServerOptions) }
    if ($DnsCustomNameServers) { $_Body.Add("dnsCustomNameservers", $DnsCustomNameServers) }
    if ($BootOptionsEnabled) { $_Body.Add("bootOptionsEnabled", $BootOptionsEnabled.IsPresent) } 
    if ($BootNextServer) { $_Body.Add("bootNextServer", $BootNextServer) }
    if ($BootFileName) { $_Body.Add("bootFileName", $BootFileName) }
    if ($DhcpOptions) { $_Body.Add("dhcpOptions", $DhcpOptions) }
    if ($ReservedIpRanges) { $_Body.Add("reservedIpRanges", $ReservedIpRanges) }
    if ($FixedIpRanges) { $_Body.Add("fixedIpRanges",$FixedIpRanges) }

    $body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Update Meraki switch routing interface DHCP Settings
    .DESCRIPTION
    Add or update the Meraki switch routing interface DHCP settings.
    Use this method to configure DHCP setting for a new interface.
    .PARAMETER Serial
    Device serial number
    .PARAMETER InterfaceId
    Interface Id of the interface to be updated.
    .PARAMETER DhcpMode
    The DHCP mode options for the switch interface ('dhcpDisabled', 'dhcpRelay' or 'dhcpServer')
    .PARAMETER DhcpRelayServerIps
    The DHCP relay server IPs to which DHCP packets would get relayed for the switch interface
    .PARAMETER DhcpLeaseTime
    The DHCP lease time config for the dhcp server running on switch interface 
    ('30 minutes', '1 hour', '4 hours', '12 hours', '1 day' or '1 week')
    .PARAMETER DnsNameServerOptions
    The DHCP name server option for the dhcp server running on the switch interface ('googlePublicDns', 'openDns' or 'custom')
    .PARAMETER DnsCustomNameServers
    The DHCP name server IPs when DHCP name server option is 'custom'
    .PARAMETER BootOptionsEnabled
    Enable DHCP boot options to provide PXE boot options configs for the dhcp server running on the switch interface
    .PARAMETER BootNextServer
    The PXE boot server IP for the DHCP server running on the switch interface
    .PARAMETER BootFileName
    The PXE boot server filename for the DHCP server running on the switch interface
    .PARAMETER DhcpOptions
    Array of DHCP options consisting of code, type and value for the DHCP server running on the switch interface
    DHCP option objects consist of the following fields.
    code:string - The code for DHCP option which should be from 2 to 254
    type:string - The type of the DHCP option which should be one of ('text', 'ip', 'integer' or 'hex')
    value:string - The value of the DHCP option
    .PARAMETER FixedIpRanges
    Array of DHCP fixed IP assignments for the DHCP server running on the switch interface
    Fixed Ip Range objects consist of the following fields.
    ip*:string - The IP address of the client which has fixed IP address assigned to it
    mac*: string - The MAC address of the client which has fixed IP address
    name*: string - The name of the client which has fixed IP address
    .PARAMETER ReservedIpRanges
    Array of DHCP reserved IP assignments for the DHCP server running on the switch interface
    Reserved Ip Range objects consist of the following fields
    comment:string - The comment for the reserved IP range
    end:string - The ending IP address of the reserved IP range
    start:string - The starting IP address of the reserved IP range
    .PARAMETER OrgId
    Optional Organization Id
    .PARAMETER ProfileName
    Optional Profile name.
    #>    
}

Set-Alias -Name SetMSRteIntDHCP -Value Set-MerakiSwitchRoutingInterfaceDhcp

#region Switch Static Routes
function Get-MerakiSwitchRoutingStaticRoutes() {
    [CmdLetBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String]$serial,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }

        $Headers = Get-Headers
    }

    Process {

        $Uri = "{0}/devices/{1}/switch/routing/staticRoutes" -f $BaseUri, $serial
        $device = Get-MerakiDevice -Serial $serial

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | foreach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "switch" -Value $device.name
                $_ | Add-Member -MemberType NoteProperty -Name 'serial' -Value $serial
            }

            return $response
        } catch {
            throw $_
        }
    }

    <#
    .SYNOPSIS
    Returns the static routes for a Meraki switch.
    .PARAMETER serial
    The serial number of the switch.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    AN array of Meraki static routes.
    #>
}

Set-Alias -Name GMSWRoutStatic -value Get-MerakiSwitchRoutingStaticRoutes -Option ReadOnly

function Get-MerakiSwitchRoutingStaticRoute() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Serial,
        [Parameter(Mandatory = $true)]
        [string]$StaticRouteId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/devices/{1}/switch/routing/staticRoutes/{2}" -f $BaseURI, $Serial, $StaticRouteId

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Retrieve a Static Route
    .DESCRIPTION
    Retrieve a Meraki Switch Static Route
    .PARAMETER Serial
    The serial number of the switch.
    .PARAMETER StaticRouteId
    The ID of the Static Route
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    A Static route object
    #>
}

function Add-MerakiSwitchRoutingStaticRoute() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Serial,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$NextHopIp,
        [Parameter(Mandatory = $true)]
        [string]$Subnet,
        [switch]$AdvertiseViaOspfEnabled,
        [switch]$PreferOverOspfRoutesEnabled,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/devices/{1}/switch/routing/staticRoutes/{2}" -f $BaseURI, $Serial

    $_Body = @{
        "name" = $Name
        "netxHopIp" = $NextHopIp
        "subnet" = $Subnet
    }
    if ($AdvertiseViaOspfEnabled.IsPresent) { $_Body.Add("advertiseViaOspfEnabled", $AdvertiseViaOspfEnabled.IsPresent) }
    if ($PreferOverOspfRoutesEnabled.IsPresent) { $_Body.Add("preferOverOspfRoutesEnabled", $PreferOverOspfRoutesEnabled) } 
    
    $body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Create a Static Route
    .DESCRIPTION
    Create a Static route on a Meraki switch
    .PARAMETER Serial
    The serial number of the switch
    .PARAMETER Name
    The name of the static route
    .PARAMETER NextHopIp
    IP address of the next hop device to which the device sends its traffic for the subnet
    .PARAMETER Subnet
    The subnet which is routed via this static route and should be specified in CIDR notation (ex. 1.2.3.0/24)
    .PARAMETER AdvertiseViaOspfEnabled
    Option to advertise static route via OSPF
    .PARAMETER PreferOverOspfRoutesEnabled
    Option to prefer static route over OSPF routes
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    An object containing the newly created static route
    #>
}

function Set-MerakiSwitchRoutingStaticRoute() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Serial,
        [Parameter(Mandatory = $true)]
        [string]$StaticRouteId,
        [string]$Name,
        [string]$NextHopIp,
        [string]$Subnet,
        [switch]$AdvertiseViaOspfEnabled,
        [switch]$PreferOverOspfRoutesEnabled,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/devices/{1}/switch/routing/staticRoutes/{2}" -f $BaseUri, $Serial, $StaticRouteId

    if ($Name) { $_Body.Add("name", $Name) }
    if ($NextHopIp) { $_Body.Add("nextHopIp", $NextHopIp) }
    if ($Subnet) { $_Body.Add("subnet", $Subnet) }
    if ($AdvertiseViaOspfEnabled.IsPresent) { $_Body.Add("advertiseViaOspfEnabled", $AdvertiseViaOspfEnabled.IsPresent) }
    if ($PreferOverOspfRoutesEnabled.IsPresent) { $_Body.Add("preferOverOspfRoutesEnabled", $PreferOverOspfRoutesEnabled) } 
    
    $body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Update a static route
    .DESCRIPTION
    Update a Meraki switch static route
    .PARAMETER Serial
    Serial number of the switch
    .PARAMETER StaticRouteId
    The statis route Id
    .PARAMETER Name
    Name or description for layer 3 static route
    .PARAMETER NextHopIp
    IP address of the next hop device to which the device sends its traffic for the subnet
    .PARAMETER Subnet
    The subnet which is routed via this static route and should be specified in CIDR notation (ex. 1.2.3.0/24)
    .PARAMETER AdvertiseViaOspfEnabled
    Option to advertise static route via OSPF
    .PARAMETER PreferOverOspfRoutesEnabled
    Option to prefer static route over OSPF routes.
    .PARAMETER OrgId
    Optional Organization Id
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    An object containing the updated static route
    #>
}

function Remove-MerakiSwitchStaticRoute() {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Serial,
        [Parameter(Mandatory = $true)]
        [string]$StaticRouteId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/devices/{1}/switch/routing/staticRoute/{2}" -f $BaseURI, $Serial, $StaticRouteId

    $StaticRoute = Get-MerakiSwitchStaticRoute -Serial $Serial -StaticRouteId $StaticRouteId

    if ($PSCmdlet.ShouldProcess('Delete', "StaticRoute $($StaticRoute.Name)") ) {
        try {
            $response = Invoke-RestMethod -Method DELETE -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Remove a static route
    .DESCRIPTION
    Remove a Meraki switch static route
    .PARAMETER Serial
    The serial number of the switch
    .PARAMETER StaticRouteId
    The ID of the static Route
    .PARAMETER OrgId
    Optional Organization id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    An html status code. Code 204 = success
    #>
}

#endregion

function Get-MerakiNetworkSwitchLAG() {
    [CmdLetBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]$id,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }

        $Headers = Get-Headers
        $responses = New-Object System.Collections.Generic.List[psObject]
    }

    Process {
        $Uri = "{0}/networks/{1}/switch/linkAggregations" -f $BaseUri, $Id
        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
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
        } catch {
            throw $_
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
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    An array of switch lag objects.
    #>
}

Set-Alias -Name GMNetSWLag -value Get-MerakiNetworkSwitchLAG -Option ReadOnly

function Add-MerakiNetworkSwitchLAG() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [hashtable[]]$SwitchPorts,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/LinkAggregations"

    $Aggregations = @{
        "switchPorts" = $SwitchPorts
    }

    $body = $Aggregations | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Create a Link Aggregation Port
    .DESCRIPTION
    Create a Link Aggregation Port on Meraki Switches.
    .PARAMETER NetworkId
    Network ID to add the LAG to.
    .PARAMETER SwitchPorts
    Switch Ports to use in the LAG.
    SwitchPorts is a an array of hashtable objects. These objects are either switch ports or switch profile ports. Defined as below.

        switchPorts: array[] - Array of switch or stack ports for creating aggregation group. Minimum 2 and maximum 8 ports are supported.
            portId*:string - Port identifier of switch port. For modules, the identifier is "SlotNumber_ModuleType_PortNumber" (Ex: "1_8X10G_1"), otherwise it is just the port number (Ex: "8").
            serial*:string - Serial number of the switch.

        switchProfilePorts: array[] - Array of switch profile ports for creating aggregation group. Minimum 2 and maximum 8 ports are supported.
            portId*:string - Port identifier of switch port. For modules, the identifier is "SlotNumber_ModuleType_PortNumber" (Ex: "1_8X10G_1"), otherwise it is just the port number (Ex: "8").
            profile*:string - Profile identifier.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS 
    A LAG object.
    #>
}

function Set-MerakiNetworkSwitchLAG() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$LinkAggregationId,
        [hashtable[]]$SwitchPorts,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/linkAggregations/{2}" -f $BaseURI. $NetworkId, $LinkAggregationId

    $Aggregations = @{
        "id" = $LinkAggregationId
        "switchPorts" = $SwitchPorts
    }

    $body = $Aggregations | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    MOdify a Link Aggregation Port
    .DESCRIPTION
    Modify a Link Aggregation Port on Meraki Switches.
    .PARAMETER NetworkId
    Network ID to add the LAG to.
    .PARAMETER LinkAggregationId
    The ID of the LAG (Use Get-MerakiNetworkSwitchLAG to get the ID)
    .PARAMETER SwitchPorts
    Switch Ports to modify in the LAG.
    You must provide all ports in the LAG
    .PARAMETER OrgId
    Optional Organization Id
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS 
    A LAG object.
    #>
}

function Remove-MerakiNetworkSwitchLAG() {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$LinkAggregationId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/linkAggregations/{2}" -f $BaseURI, $NetworkId, $LinkAggregationId

    if ($PSCmdlet.ShouldProcess("Delete","LAG ID:$LinkAggregationId")) {
        try {
            Invoke-RestMethod -Method DELETE -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Create a Link Aggregation Port
    .DESCRIPTION
    Create a Link Aggregation Port on Meraki Switches.
    .PARAMETER NetworkId
    Network ID to add the LAG to.
    .PARAMETER LinkAggregationId
    ID of the LAG to remove.
    .PARAMETER OrgId
    Optional Organization Id
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS 
    HTML response code. Code 204 = Success.
    #>
}

function Get-MerakiNetworkSwitchStacks() {
    [CmdLetBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("NetworkId")]
        [String]$id,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/stacks" -f $BaseURI, $id

    $Network = Get-MerakiNetwork -networkID $id

    if ($network.productTypes -contains "switch") {
        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name NetworkId -Value $Network.Id
                $_ | Add-Member -MemberType NoteProperty -Name NetworkName -Value $Network.Name
            }

            return $response
        } catch {
            throw $_
        }
    } else {
        return $null
    }
    <#
    .SYNOPSIS
    Returns the switch stacks for a Meraki network.
    .PARAMETER id
    The network Id.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    An array of Meraki switch stack objects.
    #>
}

Set-Alias -Name GMNetSWStacks -Value Get-MerakiNetworkSwitchStacks -Option ReadOnly

function Get-MerakiSwitchStack() {
    [CmdLetBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [String]$networkId,
        [Parameter(
            Mandatory = $true
        )]
        [string]$stackId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Uri = "{0}/networks/{1}/switch/stacks/{2}" -f $BaseURI, $networkId, $stackId
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Returns a Meraki network switch stack.
    .PARAMETER networkId
    The network Id.
    .PARAMETER stackId
    The stack Id.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    A Meraki switch stack object.
    #>
}
Set-Alias Get-MerakiNetworkSwitchStack -Value Get-MerakiSwitchStack
set-alias GMSwStack -Value Get-MerakiSwitchStack

function New-MerakiSwitchStack() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]        
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string[]]$Serials,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/stacks" -f $BaseURI, $NetworkId

    $_Body = @{
        "name" = $Name
        "serials" = $Serials
    }

    $body = $_Body | ConvertTo-Json -Depth 3 -Compress

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Create a new Switch Stack.
    .DESCRIPTION
    Create a new switch stack in a Meraki network
    .PARAMETER NetworkId
    The Id of the network to create the stack in
    .PARAMETER Name
    The name of the stack
    .PARAMETER Serials
    an array of switch serial numbers to add to the stack.
    .PARAMETER OrgId
    Optional Organization id.
    .PARAMETER ProfileName
    Optional Profile name
    .OUTPUTS
    An object containing the newly created stack
    #>
}

Set-Alias -Name New-MerakiSwitchStack -Value New-MerakiNeworkSwitchStack

function Add-MerakiSwitchStackSwitch() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$StackId,
        [Parameter(Mandatory = $true)]
        [string]$serial,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/stack/{2}/add" -f $BaseURI, $NetworkId, $StackId

    $_Body = @{
        "serial" = $serial
    }

    $body = $_Body | ConvertTo-Json -Compress

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS 
    Add a switch to a stack.
    .DESCRIPTION
    Add a new switch to an existing Meraki switch stack
    .PARAMETER NetworkId
    The Id of the network
    .PARAMETER StackId
    The ID of the stack
    .PARAMETER serial
    The serial number of the new switch
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    An object containing the stack.
    #>
}

Set-Alias -Name AMSSSwitch -Value Add-MerakiSwitchStackSwitch

function Remove-MerakiSwitchStackSwitch() {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$SwitchStackId,
        [Parameter(Mandatory = $true)]
        [string]$Serial,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/stacks/{2}/remove" -f $BaseURI, $SwitchStackId

    $_Body = @{
        "serial" = $Serial
    }

    $body = $_Body | ConvertTo-Json -Compress

    if ($PSCmdlet.ShouldProcess('Remove', "Stack member switch $Serial") ) {
        try {
            $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Remove a switch from a stack
    .DESCRIPTION
    Remove a switch from a Meraki switch stack
    .PARAMETER NetworkId
    The id o ftghe network
    .PARAMETER SwitchStackId
    The ID of the switch stack
    .PARAMETER Serial
    The serial number of the switch to remove.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile Name.
    .OUTPUTS
    An object containing the modified stack
    #>
}

function Remove-MerakiSwitchStack() {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$SwitchStackId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/stacks/{2}" -f $BaseURI, $NetworkId, $SwitchStackId
    
    $Stack = Get-MerakiSwitchStack -networkId $NetworkId -SwitchStackId $SwitchStackId

    if ($PSCmdlet.ShouldProcess('Delete',"Switch stack $($stack.name)") ) {
        try {
            $response = Invoke-RestMethod -Method DELETE -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Remove a switch stack
    .DESCRIPTION
    Remove a switch stack from a Meraki network
    .PARAMETER NetworkId
    The network ID.
    .PARAMETER SwitchStackId
    The switch stack Id.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    AN HTML response code. REsponse code of 204 = success
    #>
}

#region Switch Ports
function Get-MerakiSwitchPorts() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$serial,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }


        $Headers = Get-Headers       
        $responses = New-Object System.Collections.Generic.List[psobject]
    }

    Process {
        $switchName = (Get-MerakiDevice -Serial $serial).Name
        $Uri = "{0}/devices/{1}/switch/ports" -f $BaseURI, $serial
        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "switch" -Value $switchname
                $responses.Add($_)
            }
        } catch {
            throw $_
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
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    An array of Meraki switch port objects.
    #>
}

Set-Alias GMSwPorts -Value Get-MerakiSwitchPorts -Option ReadOnly

function Get-MerakiSwitchPort() {
    [CmdLetBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [string]$serial,
        [Parameter(
            Mandatory = $true
        )]
        [string]$portId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    
    $Uri = "{0}/devices/{1}/switch/ports/{2}" -f $BaseURI, $serial, $portId
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Returns the port configuration for a Meraki switch port.
    .PARAMETER serial
    The switch serial number.
    .PARAMETER portId
    The port Id.
    .PARAMETER OrgId
    Optional Organization id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    A Meraki switch port object.]
    #>
}

Set-Alias -Name GMSwPort -Value Get-MerakiSwitchPort
Set-Alias -Name GMDevSwPort -Value Get-MerakiDeviceSwitchPort
Set-Alias -Name Get-MerakiDeviceSwitchPort -Value Get-MerakiSwitchPort

function Set-MerakiSwitchPort() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Serial,
        [Parameter(Mandatory = $true)]
        [string]$PortId,
        [string]$Name,
        [string[]]$Tags,
        [switch]$Enabled,
        [switch]$PoeEnabled,
        [ValidateSet('trunk', 'access')]
        [string]$Type,
        [ValidateRange(1,4096)]
        [ValidateScript({$_ -is [int]})]
        [int]$Vlan,
        [ValidateRange(1,4096)]
        [ValidateScript({$_ -is [int]})]
        [int]$VoiceVlan,
        [string]$AllowedVlans,
        [switch]$IsolationEnabled,
        [switch]$rstpEnabled,
        [ValidateSet('disabled', 'root guard', 'bpdu guard', 'loop guard')]
        [string]$stpGuard,
        [string]$LinkNegotiation,
        [string]$PortScheduleId,
        [ValidateSet('Alert only', 'Enforce')]
        [string]$udld,
        [ValidateSet('Open', 'Custom access policy', 'MAC allow list', 'Sticky MAC allow list')]
        [string]$AccessPolicyType,
        [ValidateScript({$_ -is [int]})]
        [int]$AccessPolicyNumber,
        [string[]]$MacAllowList,
        [string[]]$StickyMacAllowList,
        [ValidateScript({$_ -is [int]})]
        [int]$StickyMacAllowListLimit,
        [switch]$StormControlEnabled,
        [string]$AdaptivePolicyGroupId,
        [switch]$PeerStgCapable,
        [switch]$FlexibleStackingEnabled,
        [switch]$DaiTrusted,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    switch ($AccessPolicyType) {
        'Custom access policy' {
            if (-not $AccessPolicyNumber) {
                Write-Host "Parameter AccessPolicyNumber is required when parameter AccessPolicyType is 'Custom access policy'." -ForegroundColor Red
                return
            }
        }
        'MAC allow list' {
            if (-not $MacAllowList) {
                Write-Host "Parameter MacAllowList is required when paramter AccessPolicyType is 'MAC allow list'." -ForegroundColor Red
                return
            }
        }
        'Sticky MAC allow list' {
            if (-not $StickyMacAllowList) {
                Write-Host "Parameter StickyMacAllowList is required when parameter AccessPolicyType is 'Sticky MAC allow list'." -ForegroundColor Red
                return
            }

            if (-not $StickyMacAllowListLimit) {
                Write-Host "Parameter StickyMacAllowListLimit is required when parameter AccessPolicyType is 'Sticky MAC allow list'." -ForegroundColor Red
                return
            }
        }
    }

    $Headers = Get-Headers

    $Uri = "{0}/devices/{1}/switch/ports/{2}" -f $BaseURI, $Serial, $PortId

    $_Body = @{}

    if ($Name) { $_Body.Add("name", $Name) }
    if ($Tags) { $_Body.Add("tags", $Tags) }
    if ($Enabled.IsPresent) { $_Body.Add("enabled", $Enabled.IsPresent) }
    if ($PoeEnabled.IsPresent) { $_Body.Add("poeEnabled", $PoeEnabled.IsPresent) }
    if ($Type) { $_Body.Add("type", $Type) }
    if ($Vlan) { $_Body.Add("vlan", $Vlan) }
    if ($VoiceVlan) { $_Body.Add("voiceVlan", $VoiceVlan) }
    if ($AllowedVlans) { $_Body.Add("allowedVlans", $AllowedVlans) }
    if ($IsolationEnabled.IsPresent) { $_Body.add("isolationEnabled", $IsolationEnabled.IsPresent) }
    if ($rstpEnabled.IsPresent) { $_Body.Add("rstpEnabled", $PoeEnabled.IsPresent)}
    if ($stpGuard) { $_Body.Add("stpGuard", $stpGuard) }
    if ($LinkNegotiation) { $_Body.Add("linkNegotiation", $LinkNegotiation) }
    if ($PortScheduleId) { $_Body.Add("portScheduleId", $PortScheduleId) }
    if ($udld) { $_Body.Add("udld", $udld) }
    if ($AccessPolicyType) { $_Body.Add("AccessPolicyType", $AccessPolicyType) }
    if ($AccessPolicyNumber) { $_Body.Add("accessPolicyNumber", $AccessPolicyNumber) }
    if ($MacAllowList) { $_Body.Add("macAllowList", $MacAllowList) }
    if ($StickyMacAllowList) { $_Body.Add("stickyMacAllowList", $StickyMacAllowList) }
    if ($StickyMacAllowListLimit) { $_Body.Add("stickyMacAllowListLimit", $StickyMacAllowListLimit) }
    if ($StormControlEnabled) { $_Body.Add("stormControlenabled", $StormControlEnabled) }
    if ($AdaptivePolicyGroupId) { $_Body.Add("adaptivePolicyGroupId", $AdaptivePolicyGroupId) }
    if ($PeerStgCapable) { $_Body.Add("peerStgCapable", $PeerStgCapable) }
    if ($FlexibleStackingEnabled) { $_Body.Add("flexibleStackingEnabled", $FlexibleStackingEnabled) }
    if ($DaiTrusted) { $_Body.Add("daiTrusted", $DaiTrusted) }

    $body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }

    <#
    .SYNOPSIS 
    Modify a switch port
    .DESCRIPTION
    Modify a Meraki Switch port configuration
    .PARAMETER Serial
    Serial number of the switch
    .PARAMETER PortId
    ID of the port to modify
    .PARAMETER Name
    Name for the switch port
    .PARAMETER Tags
    The list of tags of the switch port
    .PARAMETER Enabled
    The status of the switch port
    .PARAMETER PoeEnabled
    The PoE status of the switch port
    .PARAMETER Type
    The type of the switch port ('trunk' or 'access')
    .PARAMETER Vlan
    The VLAN of the switch port. A null value will clear the value set for trunk ports
    .PARAMETER VoiceVlan
    The voice VLAN of the switch port. Only applicable to access ports
    .PARAMETER AllowedVlans
    The VLANs allowed on the switch port. Only applicable to trunk ports
    .PARAMETER IsolationEnabled
    The isolation status of the switch port
    .PARAMETER rstpEnabled
    The rapid spanning tree protocol status
    .PARAMETER stpGuard
    The state of the STP guard ('disabled', 'root guard', 'bpdu guard' or 'loop guard'
    .PARAMETER LinkNegotiation
    The link speed for the switch port
    .PARAMETER PortScheduleId
    The ID of the port schedule. A value of null will clear the port schedule
    .PARAMETER udld
    The action to take when Unidirectional Link is detected (Alert only, Enforce). Default configuration is Alert only
    .PARAMETER AccessPolicyType
    The type of the access policy of the switch port. Only applicable to access ports. Can be one of 'Open', 'Custom access policy', 'MAC allow list' or 'Sticky MAC allow list'
    .PARAMETER AccessPolicyNumber
    The number of a custom access policy to configure on the switch port. Only applicable when 'accessPolicyType' is 'Custom access policy'
    .PARAMETER MacAllowList
    Only devices with MAC addresses specified in this list will have access to this port. Up to 20 MAC addresses can be defined. Only applicable when 'accessPolicyType' is 'MAC allow list'
    .PARAMETER StickyMacAllowList
    The initial list of MAC addresses for sticky Mac allow list. Only applicable when 'accessPolicyType' is 'Sticky MAC allow list'
    .PARAMETER StickyMacAllowListLimit
    The maximum number of MAC addresses for sticky MAC allow list. Only applicable when 'accessPolicyType' is 'Sticky MAC allow list'
    .PARAMETER StormControlEnabled
    The storm control status of the switch port
    .PARAMETER AdaptivePolicyGroupId
    The adaptive policy group ID that will be used to tag traffic through this switch port. This ID must pre-exist during the configuration, else needs to be created using adaptivePolicy/groups API. Cannot be applied to a port on a switch bound to profile.
    .PARAMETER PeerStgCapable
    If true, Peer SGT is enabled for traffic through this switch port. Applicable to trunk port only, not access port. Cannot be applied to a port on a switch bound to profile.
    .PARAMETER FlexibleStackingEnabled
    For supported switches (e.g. MS420/MS425), whether or not the port has flexible stacking enabled.
    .PARAMETER DaiTrusted
    If true, ARP packets for this port will be considered trusted, and Dynamic ARP Inspection will allow the traffic.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name
    .OUTPUTS
    A port object.
    #>
}

function Reset-MerakiSwitchPorts() {
    [CmdLetBinding(DefaultParameterSetName = 'default')]
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
        [string[]]$ports,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Uri = "{0}/devices/{1}/devices/ports/cycle"
    $Headers = Get-Headers

    $psBody = @{}
    $psBody.Add("ports", $ports)

    $body = $psBody | ConvertTo-JSON

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -body $body -header $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Resets (cycles) a Meraki switch port.
    .PARAMETER serial
    The switch serial number.
    .PARAMETER ports
    An array of port Ids.    
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    An array of ports that were reset.
    #>
}

Set-Alias -Name RMSWPorts -Value Reset-MerakiSwitchPorts -Option ReadOnly 

function Get-MerakiSwitchPortsStatus() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$serial,
        [ValidateScript({$_ -is [datetime]})]
        [datetime]$StartDate,
        [ValidateScript({$_ -is [int]})]
        [int]$Days,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }

    
        if ($Days) {
            if ($StartDate) {
                Write-Host "The Days parameter cannot be used with the StartDate parameter." -BackgroundColor Red
                return
            }
        }

        $Headers = Get-Headers
        Set-Variable -Name Query

        if ($StartDate) {
            $_startDate = "{0:s}" -f $StartDate
            $Query = "t0={0}" -f $_startDate
        }
        if ($Days) {
            $Seconds = [TimeSpan]::FromDays($Days).TotalSeconds
            if ($Query) {$Query += "&"}
            $Query = "{0}timespan={1}" -f $Query, $Seconds
        }
    }

    Process {
        $Uri = "{0}/devices/{1}/switch/ports/statuses" -f $BaseURI, $serial

        if ($Query) {
            $Uri += "?{0}" -f $Query
        }
        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
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
    .PARAMETER OrgId
    Optional Organization Name
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    A collection if port status objects.
    #>
}

Set-Alias -name GMSWPortStatus  -Value Get-MerakiSwitchPortsStatus -Option ReadOnly

#endregion

function Get-MerakiSwitchPortsPacketCounters() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$serial,
        [ValidateScript({$_ -is [decimal]})]
        [decimal]$Hours,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }

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
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Return the packet counters for all the ports of a switch
    .DESCRIPTION
    Returns packet counter statistics for all ports of a switch.
    .PARAMETER serial
    Serial number of the switch.
    .PARAMETER Hours
    The number of hours to return the data. The default is 24 hours (1 day). Can be entered as a decimal number. For the last 30 minutes enter .5.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile Name.
    .OUTPUTS
    A collection if packet counter objects.
    #>
}

Set-Alias -Name GMSWPortsPacketCntrs -Value Get-MerakiSwitchPortsPacketCounters

#region Port Schedules
function Get-MerakiSwitchPortSchedules() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }
        
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/switch/portSchedules" -f $BaseURI, $Id

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Retrieve switch port schedules.
    .DESCRIPTION
    Retrieve Meraki switch port schedule for a network.
    .PARAMETER Id
    Network ID to retrieve port schedules
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    A port schedules object
    #>
}

function Add-MerakiSwitchPortSchedule(){
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [hashtable]$PortSchedule,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/portSchedules" -f $BaseURI, $NetworkId
    
    $_Body = @{
        "name" = $Name
        "portSchedule" = $PortSchedule
    }

    $body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Create a port schedule
    .DESCRIPTION
    Create a Meraki Switch port schedule
    .PARAMETER NetworkId
    Network to apply the port schedule to
    .PARAMETER Name
    The name of the port schedule
    .PARAMETER PortSchedule
    The schedule for switch port scheduling. Schedules are applied to days of the week. 
    When it's empty, default schedule with all days of a week are configured. 
    Any unspecified day in the schedule is added as a default schedule configuration of the day.

    An object of port schedules. Schedulee consist of:
    Day of week (Monday, Teusday, etc)
        Active: boolean - Whether the schedule is active (true) or inactive (false) during the time specified between 'from' and 'to'. Defaults to true.
        from:string - The time, from '00:00' to '24:00'. Must be less than the time specified in 'to'. Defaults to '00:00'. Only 30 minute increments are allowed.
        to: string - The time, from '00:00' to '24:00'. Must be greater than the time specified in 'from'. Defaults to '24:00'. Only 30 minute increments are allowed.
    (see examples)
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    A port schedule object.
    .EXAMPLE
    The following example show how to create a port schedule.

    $portSchedule = @{
        monday = @{
            active = "true"
            from = "08:00"
            to = "17:00"
        },
        tuesday = @{
            active = "true"
            from = "08:00"
            to = "17:00"
        },
        wednesday = @{
            active = "true"
            from = "08:00"
            to = "17:00"
        },
        thursday = @{
            active = "true"
            from = "08:00"
            to = "17:00"
        },
        friday = @{
            active = "true"
            from = "08:00"
            to = "17:00"
        },
        saturday = @{
            active = "true"
            from = "00:00"
            to = "24:00"
        },
        sunday = @{
            active = "true"
            from = "00:00"
            to = "24:00"
        },
    }
    $result = Add-MerakiSwitchPortSchedule -NetworkId $NetworkId -Name "Weekday Schedule" -PortSchedule $PortSchedule
    #>
}

function Set-MerakiSwitchPortSchedule() {
    [CmdletBinding(DefaultParameterSetName = 'defailt')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$PortScheduleId,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [hashtable]$PortSchedule,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/portSchedules/{2}" -f $BaseURI, $NetworkId, $PortScheduleId

    $_body = @{
        name = $Name
        portSchedule = $PortSchedule
    }

    $body = $_body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        return $response
    }
    <#
    .SYNOPSIS
    Modify a port schedule
    .DESCRIPTION
    Modify a Meraki switch port Schedule
    .PARAMETER NetworkId
    Network ID of the network to modify
    .PARAMETER PortScheduleId
    ID of the port schedule to modify. (To get the ID ise Get-MerakiSwitchPortSchedule)
    .PARAMETER Name
    The name of the port schedule
    .PARAMETER PortSchedule
    Hash table of daily schedules.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name
    .OUTPUTS
    A port scheduler object
    #>
}

function Remove-MerakiSwitchPortSchedule() {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$PortScheduleId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/switch/portSchedules/{2}" -f $BaseURI, $NetworkId, $PortScheduleId

    $PortSchedule = (Get-MerakiSwitchPortSchedules -NetworkId $NetworkId).Where({$_.id -eq $PortScheduleId})
    
    if ($PSCmdlet.ShouldProcess('Delete',"Port Schedule $($PortSchedule.Name)")) {
        try {
            $response = Invoke-RestMethod -Method DELETE -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Delete a port schedule
    .DESCRIPTION
    Delete a Meraki switch port schedule
    .PARAMETER NetworkId
    Network ID of the network to remove the port schedule
    .PARAMETER PortScheduleId
    ID of the port schedule to remove.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile Name
    .OUTPUTS
    HTML status code. Code 204 = Successful
    #>
}
#endregion

#region QOS Rules
function Get-MerakiSwitchQosRules() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }

        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/switch/qosRules" -f $BaseURI, $id

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS 
    Retrieve QOS rules for switches
    .DESCRIPTION
    Retrieve the QOS rules for a Meraki network switches
    .PARAMETER Id
    The network Id to get the QOS rules from.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    Am array QOS rules objects.
    #>    
}

function Get-MerakiSwitchQosRule() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [string]$QosRuleId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/qosRules/{2}" -f $BaseURI, $Id, $QosRuleId

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }

    <#
    .SYNOPSIS
    Retrieve switch QOS rule.
    .DESCRIPTION
    Retrieve a Meraki switch QOS rule.
    .PARAMETER Id
    Network ID to retrieve the rules from.
    .PARAMETER QosRuleId
    ID of the QOS rule to retrieve.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    A QOS rule object.
    #>
}

function Add-MerakiSwitchQosRule() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [ValidateRange(1,4096)]
        [int]$Vlan,
        [ValidateSet("ANY", "TCP", "UDP")]
        [string]$Protocol = "ANY",
        [Alias('srcPort')]
        [int]$SourcePort,
        [Alias('srcPortRange')]
        [string]$SourcePortRange,        
        [Alias('dstPort')]        
        [int]$DestinationPort,
        [Alias('dstPortRange')]
        [string]$DestinationPortRange,
        [ValidateRange(-1,0)]
        [int]$dscp,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    if ($Protocol -eq 'ANY') {
        if ($SourcePort) {
            Write-Host "Parameter SourcePort cannot be used when Protocol is 'ANY'" -ForegroundColor Red
            return
        }

        if ($SourcePortRange) {
            write-host "Parameter SourcePortRange cannot be use when parameter Protocol is 'ANY'." -ForegroundColor Red
            return
        }

        if ($DestinationPort) {
            Write-Host "Parameter DestinationPort cannot be use when parameter Protocol is 'ANY'." -ForegroundColor Red
            return
        }

        if ($DestinationPortRange) {
            Write-Host "Parameter DestinationPortRange cannot be use when parameter Protocol is 'ANY'." -ForegroundColor Red
            return
        }
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/qosRules" -f $BaseURI, $NetworkId

    $_Body = @{
        vlan = $Vlan
    }

    if ($SourcePort) { $_Body.Add("srcPort", $SourcePort) }
    if ($SourcePortRange) { $_Body.Add("srcPortRange", $SourcePortRange) }
    if ($Protocol) { $_Body.Add("protocol", $Protocol) }
    if ($DestinationPort) { $_Body.Add("dstPort", $DestinationPort) }
    if ($DestinationPortRange) {$_Body.Add("dstPortRange", $DestinationPortRange) }
    if ($dscp) {$_Body.Add("dscp", $dscp) }

    $body = $_Body | ConvertTo-Json -Compress

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Create a QOS rule.
    .DESCRIPTION
    Create a QOS rule for Meraki network switches.
    .PARAMETER NetworkId
    Network ID fo the network.
    .PARAMETER Vlan
    The VLAN of the incoming packet. A null value will match any VLAN.
    .PARAMETER Protocol
    The protocol of the incoming packet. Can be one of "ANY", "TCP" or "UDP". Default value is "ANY"
    .PARAMETER SourcePort
    The source port of the incoming packet. Applicable only if protocol is TCP or UDP.
    .PARAMETER SourcePortRange
    The source port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
    .PARAMETER DestinationPort
    The destination port of the incoming packet. Applicable only if protocol is TCP or UDP.
    .PARAMETER DestinationPortRange
    The destination port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
    .PARAMETER dscp
    DSCP tag. Set this to -1 to trust incoming DSCP. Default value is 0
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    A QOS Rule Object
    #>
}

function Set-MerakiSwitchQosRule() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$QosRuleId,
        [int]$Vlan,
        [ValidateSet("ANY", "TCP", "UDP")]
        [string]$Protocol = "ANY",
        [ValidateScript({$_ -and (Protocol -ne 'ANY')}, ErrorMessage = "Protocol Must not be 'ANY'")]        
        [Alias('srcPort')]
        [int]$SourcePort,
        [ValidateScript({$_ -and (Protocol -ne 'ANY')}, ErrorMessage = "Protocol Must not be 'ANY'")]        
        [Alias('srcPortRange')]
        [string]$SourcePortRange,        
        [ValidateScript({$_ -and (Protocol -ne 'ANY')}, ErrorMessage = "Protocol Must not be 'ANY'")]        
        [Alias('dstPort')]        
        [int]$DestinationPort,
        [ValidateScript({$_ -and (Protocol -ne 'ANY')}, ErrorMessage = "Protocol Must not be 'ANY'")]
        [Alias('dstPortRange')]
        [string]$DestinationPortRange,
        [ValidateRange(-1,0)]
        [int]$dscp,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }


    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/qosRules{2}" -f $BaseURI, $NetworkId, $QosRuleId

    $_Body = @{
        vlan = $Vlan
    }

    if ($SourcePort) { $_Body.Add("srcPort", $SourcePort) }
    if ($SourcePortRange) { $_Body.Add("srcPortRange", $SourcePortRange) }
    if ($Protocol) { $_Body.Add("protocol", $Protocol) }
    if ($DestinationPort) { $_Body.Add("dstPort", $DestinationPort) }
    if ($DestinationPortRange) {$_Body.Add("dstPortRange", $DestinationPortRange) }
    if ($dscp) {$_Body.Add("dscp", $dscp) }

    $body = $_Body | ConvertTo-Json -Compress

    try {
        $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Update a QOS rule.
    .DESCRIPTION
    Update a QOS rule for Meraki network switches.
    .PARAMETER NetworkId
    Network ID fo the network.
    .PARAMETER QosRuleId
    ID of the QQOS Rule to be updated.
    .PARAMETER Vlan
    The VLAN of the incoming packet. A null value will match any VLAN.
    .PARAMETER Protocol
    The protocol of the incoming packet. Can be one of "ANY", "TCP" or "UDP". Default value is "ANY"
    .PARAMETER SourcePort
    The source port of the incoming packet. Applicable only if protocol is TCP or UDP.
    .PARAMETER SourcePortRange
    The source port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
    .PARAMETER DestinationPort
    The destination port of the incoming packet. Applicable only if protocol is TCP or UDP.
    .PARAMETER DestinationPortRange
    The destination port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
    .PARAMETER dscp
    DSCP tag. Set this to -1 to trust incoming DSCP. Default value is 0
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    A QOS Rule Object
    #>
}

function Remove-MerakiSwitchQosRule() {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$QosRuleId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/qosRules/{2}" -f $BaseURI, $NetworkId, $QosRuleId

    if ($PSCmdlet.ShouldProcess('Delete',"QOS Rule: $QosRuleId")) {
        try {
            $response = Invoke-RestMethod -Method DELETE -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Remove a QOS rule.
    .DESCRIPTION
    Remove a QOS rule from Meraki Network Switches
    .PARAMETER NetworkId
    The Network Id
    .PARAMETER QosRuleId
    The QOS Rule Id.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    HTML status code. Code 204 = success
    #>
}

function Get-MerakiSwitchQosRulesOrder() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$NetworkId,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }

        $Headers = Get-Headers

        $Rules = [List]::New()
    }

    Process {
        $Uri = "{0}/networks/{1}/switch/qosRules/order" -f $BaseURI, $NetworkId

        $Network = Get-MerakiNetwork -networkID $NetworkId

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | Add-Member -MemberType NoteProperty -Name "NetworkId" -Value $Network.ID
            $response | Add-Member -MemberType NoteProperty -Name "NetworkName" -Value $Network.Name
            $Rules.Add($response)
        } catch {
            throw $_
        }
    }

    End {
        return $Rules.ToArray()
    }
    <#
    .SYNOPSIS
    Return QOS rules order.
    .DESCRIPTION
    Return the quality of service rule IDs by order in which they will be processed by the switch
    .PARAMETER NetworkId
    The Network Id
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    An object containing an array of QOS rule IDs in order of processing
    #>
}

function Set-MerakiSwitchQosRuleOrder() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string[]]$RuleIds,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/qosRules/order" -f $BaseURI, $NetworkId

    $_Body = @{
        ruleIds = $RuleIds
    }

    $body = $_Body | ConvertTo-Json -Compress

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Update the QOS rules order
    .DESCRIPTION
    Update the order in which the rules should be processed by the switch
    .PARAMETER NetworkId
    The network Id
    .PARAMETER RuleIds
    An array of RuleIds
    .PARAMETER OrgId
    Optional Organization Od.
    .PARAMETER ProfileName
    Optional Profile name/
    .OUTPUTS
    An object containing an array of QOS rule IDs in order of processing
    #>
}

#endregion

#region Access Policies
function Get-MerakiSwitchAccessPolicies() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }

        $Headers = Get-Headers

        $policies = [List]::New()
    }

    Process {
        $Uri = "{0}/networks/{1}/switch/accessPolicies"

        $Network = Get-MerakiNetwork -networkID $Id

        try {
            $policyid = 1
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "policyId" -Value $pid
                $policyid += 1
            }

            $policy = [PSCustomObject]@{
                NetworkId = $Network.Id
                NetworkName = $Network.Name
                policies = $response
            }
            $policies.Add($policy)            
        } catch {
            throw $_
        }
    }

    End {
        return $policies.ToArray()
    }
    <#
    .SYNOPSIS
    Return the access policies for a network
    .DESCRIPTION
    Return the switch access policies for a Meraki network.
    .PARAMETER Id
    The ID of the network.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    an object containing the Access policies
    #>
}

function Get-MerakiSwitchAccessPolicy() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$AccessPolicyNumber,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/network/{1}/switch/accessPolicies/{2}" -f $BaseURI, $NetworkId, $AccessPolicyNumber

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Return an access policy
    .DESCRIPTION
    Return a specific access policy from a network
    .PARAMETER NetworkId
    The Id of the network
    .PARAMETER AccessPolicyNumber
    The access policy number to return
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    An object containing the access policy
    #>
}

function Add-MerakiSwitchAccessPolicy() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Single-Host','Multi-Host','Multi-Domain','Multi-Auth')]
        [string]$HostMode,
        [Parameter(Mandatory = $true)]
        [PSObject[]]$RadiusServers,
        [ValidateRange(1,4096)]
        [int]$GuestVlanId,
        [ValidateSet('Hybrid authentication','802.1x','AC authentication bypass')]
        [string]$AccessPolicyType,
        [ValidateSet('','11')]
        [String]$RadiusGroupAttribute = '',
        [ValidateScript({$_.isPresent -and $AccessPolicyType -eq 'Hybrid Authentication'}, ErrorMessage = "AccessPolicyType must equal 'Hybrid Authentication'")]
        [switch]$IncreaseAccessSpeed,
        [Parameter(ParameterSetName = 'RadiusAccounting')]
        [switch]$RadiusAccountingEnabled,
        [switch]$RadiusCoaSupportEnabled,
        [switch]$RadiusTestingEnabled,
        [switch]$UrlredirectWalledGardenEnabled,
        [switch]$VoiceVlanClients,
        [string[]]$UrlRedirectWalledGardenRanges,
        [string]$Dot1xControlDirection,
        [PSObject]$Radius,
        [Parameter(ParameterSetName = 'RadiusAccounting')]
        [PSObject[]]$RadiusAccountingServers,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    if ($IncreaseAccessSpeed.IsPresent -and ($AccessPolicyType -NE "Hybrid authentication")) {
        Write-Host "Parameter IncreaseAccessSpeed can only be used when parameter AccessPolicyType is 'Hybrid authentication'" -ForegroundColor Red
        return
    }
    
    if ($RadiusCoaSupportEnabled.IsPresent -and (-not $RadiusAccountingServers)) {
        Write-Host "Parameter RadiusAccountingServers must be used if parameter RadiusAccountingEnabled is present." -ForegroundColor Red
        return
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/accessPolicies" -f $BaseURI, $NetworkId

    $_Body = @{
        name = $Name
        hostMode = $HostMode
        radiusAccountingEnabled = $RadiusAccountingEnabled.IsPresent
        radiusCoaSupportEnabled = $RadiusCoaSupportEnabled.IsPresent
        radiusTestingEnabled = $RadiusTestingEnabled.IsPresent
        urlRedirectWalledGardenEnabled = $UrlredirectWalledGardenEnabled.IsPresent
    }

    foreach ($RadiusServer in $RadiusServers) {
        If ( (-not $RadiusServer.host) -or (-not $RadiusServer.port) -or (-not $RadiusServer.secret) ) {
            throw "Invalid Radius Server obect"
        }
    }
    $_Body.Add("radiusServers", $RadiusServers)

    if ($GuestVlanId) { $_Body.Add("guestVlanId", $GuestVlanId) }
    if ($AccessPolicyType) { $_Body.Add("accessPolicyType", $AccessPolicyType) }
    if ($RadiusGroupAttribute) { $_Body.Add("radiusGroupAttribute", $RadiusGroupAttribute) }
    if ($IncreaseAccessSpeed.IsPresent) { $_Body.Add("increaseAccessSpeed", $IncreaseAccessSpeed) }
    if ($VoiceVlanClients) { $_Body.Add("voiceVlanClients", $VoiceVlanClients) }
    if ($UrlRedirectWalledGardenRanges) { $_Body.Add("urlRedirectWalledGardenRanges", $UrlRedirectWalledGardenRanges) }
    if ($Dot1xControlDirection) {
        $_Body.Add("dot1x", @{
            controlledDirection = $Dot1xControlDirection
        })
    }
    if ($Radius) { $_Body.Add("radius", $Radius) }
    if ($RadiusAccountingServers) {
        foreach ($RadiusAccountingServer in $RadiusAccountingServers) {
            if ( (-not $RadiusAccountingServers.port) -or (-not $RadiusAccountingServer.host) -or (-not $RadiusAccountingServer.secret) ) {
                Throw "Invalid Radius Accounting Server Object."
            }
        }
        $_Body.Add("radiusAccountingServers", $RadiusAccountingServers) 
    }

    $body = $_Body | ConvertTo-Json -Depth 10 -Compress

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    }
    catch {
        Throw $_
    }
    <#
    .SYNOPSIS
    Create a switch access policy
    .DESCRIPTION
    Create a Meraki switch access policy for a network.
    .PARAMETER NetworkId
    The network Id of the network to create the policy
    .PARAMETER Name
    The name of the access policy
    .PARAMETER HostMode
    Host Mode for the access policy.
    .PARAMETER RadiusServers
    List of RADIUS servers to require connecting devices to authenticate against before granting network access.
    A radius server object consists of the following:
        port*:integer - UDP port that the RADIUS server listens on for access requests
        host*:string - Public IP address of the RADIUS server
        secret*:string - RADIUS client shared secret
    
    See examples for creating these objects
    .PARAMETER GuestVlanId
    ID for the guest VLAN allow unauthorized devices access to limited network resources.
    .PARAMETER AccessPolicyType
    Access Type of the policy. Automatically 'Hybrid authentication' when hostMode is 'Multi-Domain'.
    .PARAMETER RadiusGroupAttribute
    Acceptable values are "" for None, or "11" for Group Policies ACL
    .PARAMETER IncreaseAccessSpeed
    Enabling this option will make switches execute 802.1X and MAC-bypass authentication simultaneously so that clients authenticate faster. Only required when accessPolicyType is 'Hybrid Authentication.
    .PARAMETER RadiusAccountingEnabled
    Enable to send start, interim-update and stop messages to a configured RADIUS accounting server for tracking connected clients
    .PARAMETER RadiusCoaSupportEnabled
    Change of authentication for RADIUS re-authentication and disconnection
    .PARAMETER RadiusTestingEnabled
    If enabled, Meraki devices will periodically send access-request messages to these RADIUS servers
    .PARAMETER UrlredirectWalledGardenEnabled
    Enable to restrict access for clients to a specific set of IP addresses or hostnames prior to authentication.
    .PARAMETER VoiceVlanClients
    CDP/LLDP capable voice clients will be able to use this VLAN. Automatically true when hostMode is 'Multi-Domain'.
    .PARAMETER UrlRedirectWalledGardenRanges
    IP address ranges, in CIDR notation, to restrict access for clients to a specific set of IP addresses or hostnames prior to authentication
    .PARAMETER Dot1xControlDirection
    Supports either 'both' or 'inbound'. Set to 'inbound' to allow unauthorized egress on the switchport. Set to 'both' to control both traffic directions with authorization. Defaults to 'both'
    .PARAMETER Radius
    Object for RADIUS Settings
    A radius object consists of the following

        failedAuthVlanId:integer - VLAN that clients will be placed on when RADIUS authentication fails. Will be null if hostMode is Multi-Auth
        reAuthenticationInterval:integer - Re-authentication period in seconds. Will be null if hostMode is Multi-Auth
            criticalAuth:object - Critical auth settings for when authentication is rejected by the RADIUS server
            dataVlanId:integer - VLAN that clients who use data will be placed on when RADIUS authentication fails. Will be null if hostMode is Multi-Auth
            voiceVlanId:integer - VLAN that clients who use voice will be placed on when RADIUS authentication fails. Will be null if hostMode is Multi-Auth
            suspendPortBounce:boolean - Enable to suspend port bounce when RADIUS servers are unreachable
    
    See examples for creating this object.
    .PARAMETER RadiusAccountingServers
    List of RADIUS accounting servers to require connecting devices to authenticate against before granting network access
    A RadiusAccounting server object consist of the following:
        port*:integer - UDP port that the RADIUS Accounting server listens on for access requests
        host*:string - Public IP address of the RADIUS accounting server
        secret*:string - RADIUS client shared secret

    See examples for creating these objects.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    OptionalProfile name
    .OUTPUTS
    An Access Policy Object
    .EXAMPLE
    Creating Radius server object. This applies to parameters RadiusServers and RadiusAccountingServers
    Create using a PSCustomeObject:
    $RadiusServers = [PSCustomObject@(
        @{
            host = "10.10.10.1"
            port = 1812
            secret = "SGFDOI2;TH60MD-877TH4"
        },
        {
            host = "10.10.10.2"
            port = 1812
            secret = "QWSISJ564SDLK47^$JH/2342"
        }
    )

    Create using a hashtable:
     $RadiusServers = @(
        @{
            host = "10.10.10.1"
            port = 1812
            secret = "SGFDOI2;TH60MD-877TH4"
        },
        {
            host = "10.10.10.2"
            port = 1812
            secret = "QWSISJ564SDLK47^$JH/2342"
        }
    )
    .EXAMPLE Create the Radius object.
    Create using a PSCustomObject
    $radius = [PSCustomObject]@{
        failedAuthVlanId = 10
        reAuthenticationInterval = 20
        criticalAuth = @{
            dataVlanId = 30
            voiceVlanId = 40
            suspendPortBounce = true
        }
    }

    Create using a hash table:
    $radius = @{Remove-MerakiSwitchStaticRoute
            dataVlanId = 30
            voiceVlanId = 40
            suspendPortBounce = true
        }
    }
    #>    
}

function Set-MerakiSwitchAccessPolicy() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$AccessPolicyNumber,        
        [string]$Name,
        [ValidateSet('Single-Host','Multi-Host','Multi-Domain','Multi-Auth')]
        [string]$HostMode,
        [PSObject[]]$RadiusServers,
        [ValidateRange(1,4096)]
        [int]$GuestVlanId,
        [ValidateSet('Hybrid authentication','802.1x','AC authentication bypass')]
        [string]$AccessPolicyType,
        [ValidateSet('','11')]
        [String]$RadiusGroupAttribute = '',
        [ValidateScript({$_.IsPresent -and $AccessPolicyType -eq "Hybrid Authentication"}, ErrorMessege="AccessPolicyType must equal 'Hybrid Authentication")]
        [switch]$IncreaseAccessSpeed,
        [Parameter(ParameterSetName = 'Radius Accounting')]
        [switch]$RadiusAccountingEnabled,        
        [switch]$RadiusCoaSupportEnabled,
        [switch]$RadiusTestingEnabled,
        [switch]$UrlRedirectWalledGardenEnabled,
        [switch]$VoiceVlanClients,
        [string[]]$UrlRedirectWalledGardenRanges,
        [string]$Dot1xControlDirection,
        [PSObject]$Radius,
        [Parameter(ParameterSetName = 'RadiusAccounting')]
        [PSObject[]]$RadiusAccountingServers,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }
    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/accessPolicies{2}" -f $BaseURI, $NetworkId, $AccessPolicyNumber

    $_Body = @{}
    if ($Name) { $_Body.Add("name", $Name) }
    if ($HostMode) { $_Body.Add("hostMode", $HostMode) }
    if ($RadiusAccountingServers) { $_Body.Add("radiusAccountingEnabled", $RadiusAccountingEnabled.IsPresent) }
    if ($RadiusCoaSupportEnabled) { $_Body.Add("radiusCoaSupportEnabled", $RadiusCoaSupportEnabled.IsPresent) }
    if ($RadiusTestingEnabled) { 
        $_Body.Add("radiusTestingEnabled", $RadiusTestingEnabled.IsPresent)
        $_Body.Add("urlRedirectWalledGardenEnabled", $UrlredirectWalledGardenEnabled.IsPresent) 
    }
    if ($RadiusServers) {
        foreach ($RadiusServer in $RadiusServers) {
            If ( (-not $RadiusServer.host) -or (-not $RadiusServer.port) -or (-not $RadiusServer.secret) ) {
                throw "Invalid Radius Server obect"
            }
        }
        $_Body.Add("radiusServers", $RadiusServers)
    }
    if ($GuestVlanId) { $_Body.Add("guestVlanId", $GuestVlanId) }
    if ($AccessPolicyType) { $_Body.Add("accessPolicyType", $AccessPolicyType) }
    if ($RadiusGroupAttribute) { $_Body.Add("radiusGroupAttribute", $RadiusGroupAttribute) }
    if ($IncreaseAccessSpeed.IsPresent) { $_Body.Add("increaseAccessSpeed", $IncreaseAccessSpeed) }
    if ($VoiceVlanClients) { $_Body.Add("voiceVlanClients", $VoiceVlanClients) }
    if ($UrlRedirectWalledGardenRanges) { $_Body.Add("urlRedirectWalledGardenRanges", $UrlRedirectWalledGardenRanges) }
    if ($Dot1xControlDirection) {
        $_Body.Add("dot1x", @{
            controlledDirection = $Dot1xControlDirection
        })
    }
    if ($Radius) { $_Body.Add("radius", $Radius) }
    if ($RadiusAccountingServers) {
        foreach ($RadiusAccountingServer in $RadiusAccountingServers) {
            if ( (-not $RadiusAccountingServers.port) -or (-not $RadiusAccountingServer.host) -or (-not $RadiusAccountingServer.secret) ) {
                Throw "Invalid Radius Accounting Server Object."
            }
        }
        $_Body.Add("radiusAccountingServers", $RadiusAccountingServers) 
    }

    $body = $_Body | ConvertTo-Json -Depth 10 -Compress

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    }
    catch {
        Throw $_
    }
    <#
    .SYNOPSIS
    Create a switch access policy
    .DESCRIPTION
    Create a Meraki switch access policy for a network.
    .PARAMETER NetworkId
    The network Id of the network to create the policy
    .PARAMETER AccessPolicyNumber
    The number of the policy to update
    .PARAMETER Name
    The name of the access policy
    .PARAMETER HostMode
    Host Mode for the access policy.
    .PARAMETER RadiusServers
    List of RADIUS servers to require connecting devices to authenticate against before granting network access.
    .PARAMETER GuestVlanId
    ID for the guest VLAN allow unauthorized devices access to limited network resources.
    .PARAMETER AccessPolicyType
    Access Type of the policy. Automatically 'Hybrid authentication' when hostMode is 'Multi-Domain'.
    .PARAMETER RadiusGroupAttribute
    Acceptable values are "" for None, or "11" for Group Policies ACL
    .PARAMETER IncreaseAccessSpeed
    Enabling this option will make switches execute 802.1X and MAC-bypass authentication simultaneously so that clients authenticate faster. Only required when accessPolicyType is 'Hybrid Authentication.
    .PARAMETER RadiusAccountingEnabled
    Enable to send start, interim-update and stop messages to a configured RADIUS accounting server for tracking connected clients
    .PARAMETER RadiusCoaSupportEnabled
    Change of authentication for RADIUS re-authentication and disconnection
    .PARAMETER RadiusTestingEnabled
    If enabled, Meraki devices will periodically send access-request messages to these RADIUS servers
    .PARAMETER UrlredirectWalledGardenEnabled
    Enable to restrict access for clients to a specific set of IP addresses or hostnames prior to authentication.
    .PARAMETER VoiceVlanClients
    CDP/LLDP capable voice clients will be able to use this VLAN. Automatically true when hostMode is 'Multi-Domain'.
    .PARAMETER UrlRedirectWalledGardenRanges
    IP address ranges, in CIDR notation, to restrict access for clients to a specific set of IP addresses or hostnames prior to authentication
    .PARAMETER Dot1xControlDirection
    Supports either 'both' or 'inbound'. Set to 'inbound' to allow unauthorized egress on the switchport. Set to 'both' to control both traffic directions with authorization. Defaults to 'both'
    .PARAMETER Radius
    Object for RADIUS Settings
    .PARAMETER RadiusAccountingServers
    List of RADIUS accounting servers to require connecting devices to authenticate against before granting network access
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS 
    An Access Policy object.
    #>
}

function Remove-MerakiSwitchAccessPolicy() {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$AccessPolicyNumber,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}switch/accessPolicies/{2}" -f $BaseURI, $NetworkId, $AccessPolicyNumber

    $AccessPolicy = Get-MerakiSwitchAccessPolicy -NetworkId $NetworkId -AccessPolicyNumber $AccessPolicyNumber

    if ($PSCmdlet.ShouldProcess('Delete', "Access Policy: $($AccessPolicy.Name)")) {
        try {
            $response = Invoke-RestMethod -Method DELETE -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        }
        catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Delete an Access Policy
    .DESCRIPTION 
    Delete a Meraki switch Access Policy
    .PARAMETER NetworkId
    The network Id to delete the policy from.
    .PARAMETER AccessPolicyNumber    
    The access policy number to delete.
    .PARAMETER OrgId
    Optional Organization id.
    .PARAMETER ProfileName
    Optional Profile name.
    #>
}
#endregion

#region Routing Multicast
function Get-MerakiSwitchRoutingMulticast() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }
    
        $Headers = Get-Headers
        $Multicasts = [List]::New()
    }

    Process {
        $Uri = "{0}/networks/{1}/switch/routing/milticast" -f $Id
        $Network = Get-MerakiNetwork -networkID $Id
        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $Multicast = [PSCustomObject]@{
                NetworkId = $Network.Id
                NetworkName = $Network.Name
                $MulticastSettings = $response
            }
            $Multicasts.Add($Multicast)
        } catch {
            throw $_
        }
    }

    End {
        return $Multicasts
    }
    <#
    .SYNOPSIS
    Retrieve multicast settings for switches
    .DESCRIPTION
    Retrieve the multicast setting for switches in a Meraki network.
    .PARAMETER Id
    Network ID of the network to retrieve the settings.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS 
    A multicast settings object
    #>
}

function Set-MerakiSwitchRoutingMulticast() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [switch]$FloodUnknownMulticastTrafficEnabled,
        [switch]$igmpSnoopingEnabled,
        [PSObject[]]$Overrides,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/routing/multicast" -f $NetworkId

    $_Body = @{
        defaultSettings = @{
            floodUnknownMulticastTrafficEnabled = $FloodUnknownMulticastTrafficEnabled.IsPresent
            igmpSnoopingEnabled = $igmpSnoopingEnabled.IsPresent
        }
    }

    if ($Overrides) {
        $_Body.Add("Overrides", $Overrides)
    }

    $body = $_Body | ConvertTo-Json -Depth 5 -Compress
    
    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response        
    } catch {
        throw $_
    }

    <#
    .SYNOPSIS
    Update switch multicast routing
    .DESCRIPTION
    Updte the multicast routing for switches in a Meraki network.
    .PARAMETER NetworkId
    The network Id of the network to update
    .PARAMETER FloodUnknownMulticastTrafficEnabled
    Default setting for FloodUnknownMulticastTrafficEnabled.
    .PARAMETER igmpSnoopingEnabled
    Default setting for igmpSnoopingEnabled
    .PARAMETER Overrides
    Array of paired switches/stacks/profiles and corresponding multicast settings. An empty array will clear the multicast settings.
    An override object consists of:
        floodUnknownMulticastTrafficEnabled*:boolean - Flood unknown multicast traffic setting for switches, switch stacks or switch profiles )required)
        igmpSnoopingEnabled*:boolean - IGMP snooping setting for switches, switch stacks or switch profiles (required)
        stacks: array[] - List of switch stack ids for non-template network
        switchProfiles:array[] - List of switch profiles ids for template network
        switches:array[] List of switch serials for non-template network
    .PARAMETER OrgId
    Optional Organization id.
    .PARAMETER ProfileName
    Optional Profile name.
    #>
}
#endregion

#region OSPF
function Get-MerakiSwitchRoutingOspf() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
            )]
            [Alias('NetworkId')]
            [string]$Id,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }

        $Headers = Get-Headers        
    }

    Process {
        $Uri = "{0}/networks/{1}/switch/routing/ospf" -f $BaseURI, $Id

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Return routing OSPF setting
    .DESCRIPTION
    Return the Meraki network OSPF settings
    .PARAMETER Id
    The Id of the network
    .PARAMETER OrgId
    Optional Organization id.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    An object containing the OSPF settings
    #>
}

function Set-MerakiSwitchRoutingOspf() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [ValidateScript({$_ -is [int]})]
        [int]$DeadTimerInSeconds,
        [ValidateRange(1,255)]
        [ValidateScript({$_ -is [int]})]
        [int]$HelloTimerInSeconds,
        [switch]$Enabled,
        [Parameter(ParameterSetName = 'Md5')]
        [switch]$Md5AuthenticationEnabled,
        [ValidateRange(1,255)]
        [Parameter(ParameterSetName = 'Md5')]
        [int]$Md5AuthenticationKeyId,
        [Parameter(ParameterSetName = 'Md5')]
        [securestring]$Md5AuthenticationPassphrase,
        [ValidateScript({$_ -is [int]})]
        [int]$V3DeadTimerInSeconds,
        [ValidateRange(1.255)]
        [ValidateScript({$_ -is [int]})]
        [int]$V3HelloTimerInSeconds,
        [switch]$V3Enabled,
        [PSObject[]]$V3Areas,
        [psobject[]]$Areas,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/routing/ospf" -f $BaseURI, $NetworkId

    $_Body = @{}
    if ($Enabled.IsPresent) {
        if ($DeadTimerInSeconds) { $_Body.Add("deadTimerInSeconds", $DeadTimerInSeconds) }
        if ($HelloTimerInSeconds) { $_Body.Add("helloTimerInSeconds", $HelloTimerInSeconds) }
        $_Body.Add("enabled", $Enabled.IsPresent)
        if ($Md5AuthenticationEnabled.IsPresent) {
            $_Body.Add("md5Authentication", $Md5AuthenticationEnabled.IsPresent)
            $_Body.Add("md5AuthenticationKey", @{
                "id" = $Md5AuthenticationKeyId
                "passphrase" = $Md5AuthenticationPassphrase
            })
        }
    }
    if ($V3Enabled) {
        $_Body.Add("v3", @{})
        if ($V3DeadTimerInSeconds) { $_Body.v3.Add("deadTimerInSeconds", $V3DeadTimerInSeconds)}
        if ($V3HelloTimerInSeconds) { $_Body.v3.Add("helloTimerInSeconds", $V3HelloTimerInSeconds)}
        $_Body.v3.Add("enabled", $V3Enabled.IsPresent)
        $_Body.v3.Add("areas", $V3Areas)            
    }
    if ($Areas) { $_Body.Add("areas", $Areas) }

    $body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Modify the OSPF settings
    .DESCRIPTION
    Modify a Meraki Networks OSPF settings
    .PARAMETER NetworkId
    The Network ID
    .PARAMETER DeadTimerInSeconds
    Time interval to determine when the peer will be declared inactive/dead. Value must be between 1 and 65535
    .PARAMETER HelloTimerInSeconds
    Time interval in seconds at which hello packet will be sent to OSPF neighbors to maintain connectivity. Value must be between 1 and 255. Default is 10 seconds.
    .PARAMETER Enabled
    Boolean value to enable or disable OSPF routing. OSPF routing is disabled by default.
    .PARAMETER Md5AuthenticationEnabled
    Boolean value to enable or disable MD5 authentication. MD5 authentication is disabled by default.
    .PARAMETER Md5AuthenticationKeyId
    MD5 authentication key index. Key index must be between 1 to 255
    .PARAMETER Md5AuthenticationPassphrase
    MD5 authentication passphrase
    .PARAMETER V3DeadTimerInSeconds
    Time interval to determine when the peer will be declared inactive/dead. Value must be between 1 and 65535
    .PARAMETER V3HelloTimerInSeconds
    Time interval in seconds at which hello packet will be sent to OSPF neighbors to maintain connectivity. Value must be between 1 and 255. Default is 10 seconds.
    .PARAMETER V3Enabled
    Boolean value to enable or disable V3 OSPF routing. OSPF V3 routing is disabled by default.
    .PARAMETER V3Areas
    an array of OSPF v3 areas
    An area object consists of:
        areaId*:string - OSPF area ID
        areaName*:string - Name of the OSPF area
        areaType*:string - Area types in OSPF. Must be one of: ["normal", "stub", "nssa"]
    
    * required
    .PARAMETER Areas
    An array of OSPF areas
    An area object consists of:
        areaId*:string - OSPF area ID
        areaName*:string - Name of the OSPF area
        areaType*:string - Area types in OSPF. Must be one of: ["normal", "stub", "nssa"]

    * required
    .PARAMETER OrgId
    Optiona; Organization Name
    .PARAMETER ProfileName
    Optional Profile name.
    #>
}

#Access control Lists

function Get-MerakiSwitchAccessControlList() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )
    Begin {

        if (-not $OrgID) {
            $config = Read-Config
            if ($profileName) {
                $OrgID = $config.profiles.$profileName
                if (-not $OrgID) {
                    throw "Invalid profile name!"
                }
            } else {
                $OrgID = $config.profiles.default
            }        
        }

        $Headers = Get-Headers
    }

    Process {
        $switches = Get-MerakiNetworkDevices -id $Id | Where-Object {$_.Model -like "MS*"}
        if ($switches) {
            $Uri = "{0}/networks/{1}/switch/accessControlLists" -f $BaseURI, $Id

            try {
                $id = 1
                $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
                $Rules = [List[psobject]]::New()
                $response | ForEach-Object {
                    $_.rules | Add-Member -MemberType NoteProperty -Name "Id" -Value $id
                    $id += 1
                    $Rules.Add($_.rules)
                }

                return $Rules.ToArray()
            } catch {
                throw $_
            }
        }
    }
    <#
    .SYNOPSIS
    Get Meraki switch ACLs
    .DESCRIPTION
    Retrieve Access control LIsts for Meraki Switches
    .PARAMETER Id
    The Network ID
    .PARAMETER OrgId
    Optional Organization name.
    .PARAMETER ProfileName
    Optional Profile name.
    .OUTPUTS
    An array of ACL objects.
    #>
}

Set-Alias -Name GMSWACL -Value Get-MerakiSwitchAccessControlList

function Add-MerakiSwitchAccessControlEntry() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [string]$Vlan = 'any',
        [Alias('SrcPort')]
        [string]$SourcePort = 'any',
        [Alias('SrcCidr')]
        [string]$SourceCidr = 'any',
        [string]$Protocol = 'any',
        [ValidateSet('allow', 'deny')]
        [string]$Policy,
        [ValidateSet('any', 'ipv4', 'ipv6')]
        [string]$IpVersion,
        [Alias('DstPort')]
        [string]$DestinationPort = 'any',
        [Alias('DstCidr')]
        [string]$DestinationCidr = 'any',
        [string]$Comment,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/accessControlLists" -f $BaseURI, $NetworkId

    $Acl = (Get-MerakiSwitchAccessControlList -Id $NetworkId).Where({$_.comment -ne "Default rule"}) | Select-Object * -ExcludeProperty Id

    $Ace = [PSCustomObject]@{
        vlan = $vlan
        srcPort = $SourcePort
        srcCidr = $SourceCidr
        protocol = $Protocol
        policy = $Policy
        ipVersion = $IpVersion
        dstPort = $DestinationPort
        dstCidr = $DestinationCidr
        comment = $Comment
    }

    $Acl += $Ace
    $body = $acl | ConvertTo-Json -Depth 5 -Compress

    try {
        $id = 1
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        $response | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "Id" -Value $id
            $Id += 1
        }
        return $response
    } catch {
        throw $_
    }
    <#
    .DESCRIPTION
    Adds an Access Control entry to the switch access control list.
    .PARAMETER NetworkId
    The Id of the network.
    .PARAMETER Vlan
    Incoming traffic VLAN
    .PARAMETER SourcePort
    The source port.
    .PARAMETER SourceCidr
    Source IP address (in IP or CIDR notation)
    .PARAMETER Protocol
    The type of protocol
    .PARAMETER Policy
    allow' or 'deny' traffic specified by this rule
    .PARAMETER IpVersion
    IP address version 
    .PARAMETER DestinationPort
    The destination port.
    .PARAMETER DestinationCidr
    Destination IP address (in IP or CIDR notation)
    .PARAMETER Comment
    Description of the rule (optional)
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    #>
}

Set-Alias -Name AMSWAce -Value Add-MerakiSwitchAccessControlEntry

function Remove-MerakiSwitchAccessControlEntry() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [int]$Id,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/accessControlList" -f $BaseURI, $NetworkId

    $Acl = (Get-MerakiSwitchAccessControlList -NetworkId $NetworkId).where({$_.comment -ne "Default rule"})

    $NewAcl = $Acl.Where({$_.Id -ne $id}) | Select-Object * -ExcludeProperty Id

    $body = $NewAcl | ConvertTo-Json -Depth 5 -Compress

    try {
        $Id = 1
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        $response | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "Id" -Value $Id
            $Id += 1
        }
        return $response
    } catch {

    }
    <#
    .DESCRIPTION
    Deletes a switch access control entry from the list.
    .PARAMETER NetworkId
    The Id of the network.
    .PARAMETER Id
    The ID of the Access Control Entry
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile Name.
    #>
}

Set-Alias -Name RMSWAce -value Remove-MerakiSwitchAccessControlEntry

function Set-MerakiSwitchAccessControlEntry() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Int]$Id,
        [string]$Vlan = 'any',
        [Alias('SrcPort')]
        [string]$SourcePort = 'any',
        [Alias('SrcCidr')]
        [string]$SourceCidr = 'any',
        [string]$Protocol = 'any',
        [ValidateSet('allow', 'deny')]
        [string]$Policy,
        [ValidateSet('any', 'ipv4', 'ipv6')]
        [string]$IpVersion,
        [Alias('DstPort')]
        [string]$DestinationPort = 'any',
        [Alias('DstCidr')]
        [string]$DestinationCidr = 'any',
        [string]$Comment,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }
    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/accessControlList" -f $BaseURI, $NetworkId

    $Acl = (Get-MerakiSwitchAccessControlList -NetworkId $NetworkId).Where({$_.comment -ne "Default rule"})

    $Ace = $Acl.Where({$_.Id -eq $Id})

    If ($Vlan) { $Ace.vlan = $Vlan }
    if ($SourcePort) { $Ace.srcPort = $SourcePort }
    if ($SourceCidr) { $Ace.srcCidr = $SourceCidr }
    if ($Protocol) { $Ace.protocol = $Protocol }
    if ($Policy) { $Ace.policy = $Policy }
    if ($IpVersion) { $Ace.ipVersion = $IpVersion }
    if ($DestinationPort) { $Ace.dstPort = $DestinationPort}
    if ($DestinationCidr) { $Ace.DstCidr = $DestinationCidr}
    if ($Comment) { $Ace.comment = $Comment}

    $NewAcl = $Acl.Where({$_.Id -ne $Id}) | Select-Object * -ExcludeProperty Id
    $NewAce = $Ace | Select-Object * -ExcludeProperty Id
    $NewAcl += $NewAce

    $body = $NewAcl | ConvertTo-Json -Depth 5 -Compress

    Try {
        $id = 1
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        $response | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "Id" -Value Id
            $Id += 1
        }
        return $response
    } catch {
        Throw $_
    }
    <#
    .DESCRIPTION
    Updates an Access Control Entry inthe Access Control List.
    .PARAMETER NetworkId
    The Id of the network.
    .PARAMETER Id
    The Access Control Entry Id.
    .PARAMETER SourcePort
    The source port.
    .PARAMETER SourceCidr
    Source IP address (in IP or CIDR notation)
    .PARAMETER Protocol
    The type of protocol
    .PARAMETER Policy
    allow' or 'deny' traffic specified by this rule
    .PARAMETER IpVersion
    IP address version 
    .PARAMETER DestinationPort
    The destination port.
    .PARAMETER DestinationCidr
    Destination IP address (in IP or CIDR notation)
    .PARAMETER Comment
    Description of the rule (optional)
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile name.
    #>
}