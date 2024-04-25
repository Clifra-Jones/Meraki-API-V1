#Meraki Appliance Functions
using namespace System.Management
using namespace System.Collections.Generic

#region ContentFiltering
function Get-MerakiApplianceContentFilteringCategories() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$id
    )

    $Uri = "{0}/networks/{1}/appliance/contentFiltering/categories" -f $BaseURI, $id
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Returns the content filtering categories for this network.*
    .PARAMETER id
    The Network ID.
    .OUTPUTS
    An array of content filtering categories.
    .NOTES
    Filtering category IDs are different between MX devices. You cannot use category IDs from an MX84 to set categories on an MX100.
    It is best practice to pull the list of categories from the device before attempting to set any new categories.
    #>
}

Set-Alias -Name GMNetAppCFCats -Value Get-MerakiApplianceContentFilteringCategories -Option ReadOnly
Set-Alias -Name Get-MerakiNetworkApplianceContentFilteringCategories -Value Get-MerakiApplianceContentFilteringCategories -Option ReadOnly
Set-Alias -Name GMAppCFCats -Value Get-MerakiApplianceContentFilteringCategories -Option ReadOnly

<#
.Description
Retrieve content filtering Rules for a network
#>
function Get-MerakiApplianceContentFiltering() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$id
    )


    $Uri = "{0}/networks/{1}/appliance/contentFiltering" -f $BaseURI, $id
    $headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $headers -PreserveAuthorizationOnRedirect

        return $response    
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Get the content filtering settings for this appliance.
    .PARAMETER id
    The network Id.
    .OUTPUTS
    An array of Meraki content filtering objects.
    #>
}

Set-Alias -Name GMNetCF -Value Get-MerakiApplianceContentFiltering -Option ReadOnly
Set-Alias -Name Get-MerakiNetworkApplianceContentFiltering -Value Get-MerakiApplianceContentFiltering -Option ReadOnly
Set-Alias -Name GMAppCF -Value Get-MerakiApplianceContentFiltering -Option ReadOnly

function Update-MerakiApplianceContentFiltering() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$id,
        [ValidateScript(
            {
                if ($ContentFilteringRules) {
                    throw "The allowedURLPatterns parameter cannot be used with the ContentFilteringRules parameter."
                } elseif (-not $_) {
                        throw "The allowedURLPatterns parameter is require if the ContentFilteringRules parameter is omitted."
                } elseif ((-not $blockedURLPatterns) -or (-not $blockedUrlCategories) -or (-not $urlCategoryListSize)) {
                    throw "The allowedUrlPatterns parameter requires the blockedURLPatterns and blockedUrlCategories parameters "
                } else {
                    $true
                }
            }
        )]
        [string[]]$allowedURLPatterns,
        [Parameter(
            Mandatory=$true,
            ParameterSetName = "values"            
        )]
        [string[]]$blockedURLPatterns,
        [string[]]$blockedUrlCategories,
        [string]$urlCategoryListSize,
        [ValidateScript({
            $_ -and -not ($allowedURLPatterns -or $blockedUrlCategories -or $urlCategoryListSize)
        },ErrorMessage="The parameter ContentFilteringRules cannot be used with the allowedURLPatterns, blockedURLPatterns, blockedURLCategories -or urlCategoriesList parameters")]
        [psObject]$ContentFilteringRules
    )

    $Uri = "{0}/networks/{1}/appliance/contentFiltering" -f $BaseURI, $id
    $Headers = Get-Headers

    
    if ($ContentFilteringRules) {
        if ($ContentFilteringRules.allowedUrlPatterns) {
            $allowedURLPatterns = $ContentFilteringRules.allowedUrlPatterns
        }
        if ($ContentFilteringRules.blockedUrlPatterns) {
            $blockedURLPatterns = $ContentFilteringRules.blockedUrlPatterns
        }
        if ($ContentFilteringRules.urlCategoryListSize) {
            $urlCategoryListSize = $ContentFilteringRules.urlCategoryListSize
        }
        if ($ContentFilteringRules.blockedUrlCategories) {
            $ContentFilteringRules.blockedUrlCategories | ForEach-Object {                
                $blockedUrlCategories += $_.Id
            }
        }
    } 
    $properties = [ordered]@{}
    if ($allowedURLPatterns) {$properties.Add("allowedUrlPatterns", $allowedURLPatterns) }
    if ($blockedURLPatterns) {$properties.Add("blockedUrlPatterns", $blockedURLPatterns) }
    if ($urlCategoryListSize) {$properties.Add("urlCategoryListSize", $urlCategoryListSize) }
    if ($blockedUrlCategories) {$properties.Add("blockedUrlCategories", $blockedUrlCategories) }

    $psBody = [PSCustomObject]$properties
    
    $body = $psBody | ConvertTo-Json -Compress -Depth 6

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Body $body -Headers $Headers -PreserveAuthorizationOnRedirect
        return  $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Update the content filtering rules.
    .PARAMETER id
    The Network Id.
    .PARAMETER allowedURLPatterns
    An array of allowed URL patterns.
    .PARAMETER blockedURLPatterns
    AM array of blocked URL patterns.
    .PARAMETER blockedUrlCategories
    An array of blocked URL Categories.
    .PARAMETER urlCategoryListSize
    The list size of the category list. Note this parameter is not supported on MX100 and above devices.
    .PARAMETER ContentFilteringRules
    A Meraki content filtering rule object (not supported with other parameters).
    .OUTPUTS
    The updated Meraki content filtering object.
    .NOTES
    .EXAMPLE
    You must pull the Content Filtering Rules using the function Get-MerakiNetworkApplianceContentFiltering and then modify the properties of that object.
    Adding a new URL to the blocked URL Pattern
    PS> $cfr = Get-MerakiNetworks | Where-Object {$_.Name -like "Dallas} | Get-MerakiNetworkApplianceContentFiltering
    PS> $cfr.blockedUrlPatterns += "example.com"
    PS> Get-MerakiNetworks | Where-Object {$_.Name -like "Dallas"} | Update-MerakiNetworkApplianceContentFiltering -allowedUrlPatterns $cfr.allowedUrlPattern -blockedUrlPatterns $cfr.blockedUrlPatterns -blockedUrlCategories $cfr.blockedUrlCategories -urlCategoryListSize $cfr.urlCategoryListSize    
    or
    PS > Get-MerakiNetworks | Where-Object {$_.like "Dallas"} | Update-MerakiNetworkApplianceContentFiltering -ContentFilteringRules $cfr
    .EXAMPLE
    Updating Templates
    If you have networks bound to templates, you should must the template and allow the template to trickle the changes down to the bound network.
    PS> $cfr = Get-MerakiOrganizationConfigTemplates | Where-object {$_.Name -eq "Org-Template"} | Get-MerakiNetworkApplianceContentFiltering
    PS> $cfr.clockedUrlPatterns += "example.com"
    PS> Get-MerakiOrganizationConfigTemplates | Where-Object ($_.Name -eq "Org-Template"} Update-MerakiNetworkApplianceContentFiltering -ContentFilteringRules $cfr
    #>
}

Set-Alias -Name UMNetAppCF -value Update-MerakiApplianceContentFiltering -Option ReadOnly
Set-Alias -Name Update-MerakiNetworkApplianceContentFiltering -Value Update-MerakiApplianceContentFiltering -Option ReadOnly
Set-Alias -Name UMAppCF -value Update-MerakiApplianceContentFiltering -Option ReadOnly

function Add-MerakiApplianceContentFilteringRules() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String]$Id,
        [String[]]$allowedURLPatterns,
        [String[]]$blockedURLPatterns
    )

    Begin {

    }
    
    Process {
        if ((-not $allowedURLPatterns) -and (-not $blockedURLPatterns) ) {
            Write-Host "You must provide al least one of the content filtering patterns" -ForegroundColor Red
            exit
        }
        $cfr = Get-MerakiNetworkApplianceContentFiltering -Id $Id
        if ($allowedURLPatterns) {
            $allowedURLPatterns | ForEach-Object {
                $cfr.allowedUrlPatterns += $_
            }
        }
        If ($blockedURLPatterns) {
            $blockedURLPatterns | ForEach-Object {
                $cfr.blockedURLPatterns += $_
            }
        }
    
        Update-MerakiApplianceContentFiltering -Id $Id -ContentFilteringRules $Cfr
    }
    <#
    .SYNOPSIS
    Add new URL patterns.
    .DESCRIPTION
    Add the provided allowed and blocked URL patterns to the content filtering rule.
    .PARAMETER Id
    The Network ID.
    .PARAMETER allowedURLPatterns
    An array of allowed URL patterns.
    .PARAMETER blockedURLPatterns
    An array of blocked URL patterns.
    .OUTPUTS
    The updated content filtering rules.
    .EXAMPLE
    Add sites to the allowed and blocked URL patterns.
    PS> $Network | Add-MerakiNetworkApplianceContentFilteringRule -allowedUrlPatterns "xtz.com" -blockedUrlPatterns "badsite.com"
    #>
}

Set-Alias -Name AddMNetAppCFR -Value Add-MerakiApplianceContentFilteringRules -Option ReadOnly
Set-Alias -Name Add-MerakiNetworkApplianceContentFilteringRules -Value Add-MerakiApplianceContentFilteringRules -Option ReadOnly
Set-Alias -Name AddMAppCFR -Value Add-MerakiApplianceContentFilteringRules -Option ReadOnly

function Remove-MerakiApplianceContentFilteringRules () {
    [CmdletBinding(
        DefaultParameterSetName = 'default', 
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$id,
        [string[]]$allowedURLPatterns,
        [string[]]$blockedURLPatterns
    )

    Process {
        If ((-not $allowedURLPatterns) -and (-not $blockedURLPatterns)) {
            Write-Host "You must provide al least one fo the content filtering patterns" -ForegroundColor Red
            exit
        }
        $cfr = Get-MerakiNetworkApplianceContentFiltering -Id $id
        if ($allowedURLPatterns) {
            $AUPList = [System.Collections.ArrayList]::New($cfr.allowedUrlPatterns)
            $allowedURLPatterns | Foreach-Object {
                $AUPList.Remove($_)
            }
            $cfr.allowedUrlPatterns = $AUPList.ToArray()
        }

        if ($blockedURLPatterns) {
            $BUPList = [System.Collections.ArrayList]::New($cfr.blockedUrlPatterns)
            $blockedURLPatterns | ForEach-Object {
                $BUPList.remove($_)
            }
            $cfr.blockedUrlPatterns = $BUPList.ToArray()
        }
        $NetworkName = (Get-MerakiNetwork -Id $Id).Name
        if ($PSCmdlet.ShouldProcess("Network: $($NetworkName)", "Remove content filtering rules")) {
            Update-MerakiNetworkApplianceContentFiltering -id $id -ContentFilteringRules $cfr
        }
    }
    <#
    .SYNOPSIS
    Remove allowed and blocked URL patterns.
    .DESCRIPTION
    Removes the provided allowed and blocked URL patterns to the content filtering rule.
    .PARAMETER id
    The Network Id.
    .PARAMETER allowedURLPatterns
    Allowed URL patterns to remove.
    .PARAMETER blockedURLPatterns
    Blocked URL patterns to remove.
    .OUTPUTS
    The updated content filtering rules.
    .EXAMPLE
    Remove sites from the allowed and blocked URL patterns.
    PS> $Network | Remove-MerakiNetworkApplianceContentFilteringRule -allowedUrlPatterns "xtz.com" -blockedUrlPatterns "badsite.com"
    #>
}

Set-Alias -Name RemoveMNetAppCfr -Value Remove-MerakiNetworkApplianceContentFilteringRules -Option ReadOnly
Set-Alias -name Remove-MerakiNetworkApplianceContentFilteringRules -Value Remove-MerakiApplianceContentFilteringRules -Option ReadOnly
Set-Alias -Name RemoveMAppCfr -Value Remove-MerakiNetworkApplianceContentFilteringRules -Option ReadOnly
#endregion

#region Ports
function Get-MerakiAppliancePorts() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$id
    )

    Begin {

        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/ports" -f $BaseURI, $id

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name NetworkId -Value $Id
            }
            return $response
        }catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Returns the port configuration for the Network Appliance.
    .PARAMETER id
    The network Id.
    .OUTPUTS
    An array of Meraki port objects.
    #>
}

Set-Alias -Name GMAppPorts -value Get-MerakiAppliancePorts -Option ReadOnly

function Get-MerakiAppliancePort() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('Id')]
        [string]$NetworkId,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$Number
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/ports/{2}" -f $BaseURI, $NetworkId, $number

        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Return per-port VLAN settings for a single MX port.
    .PARAMETER id
    The ID of the Network
    .PARAMETER Number
    The port number
    .OUTPUTS
    An Appliance port object.
    #>
}

Set-Alias -Name Get-MerakiNetworkAppliancePort -Value Get-MerakiAppliancePort -Option ReadOnly


function Set-MerakiAppliancePort() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('Id')]
        [string]$NetworkId,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$Number,
        [int]$VlanId,
        [Parameter(Mandatory)]
        [ValidateSet('access','trunk')]
        [string]$Type,
        [ValidateSet('open', '8021x-radius', 'mac-radius', 'hybris-radius')]
        [ValidateScript({
            $_ -and $Type -eq 'access'
        }, ErrorMessage = 'Parameter AccessPolicy Can only be used with a access port.')]
        [string]$AccessPolicy,
        [ValidateScript({
            $_ -and $Type -eq 'trunk'
        }, ErrorMessage = "Parameter AllowedVLANS can only be used with a trunk port.")]
        [string]$AllowedVLANS,
        [ValidateScript({
            $_ -and $Type -eq 'trunk'
        }, ErrorMessage = 'Parameter DropUnTaggedTraffic can only be used with a trunk port. ')]
        [switch]$DropUntaggedTraffic,
        [switch]$Enabled
    )

    Begin {
        $Headers = Get-Headers

        $_Body = @{}

        if ($VlanId) {$_Body.Add("vlan", $VlanId)}
        if ($Type) {$_Body.Add("type", $Type)}
        if ($AccessPolicy) {$_Body.Add("accessPolicy", $AccessPolicy)}
        if ($AllowedVLANS) {$_Body.add("allowedVlans", $AllowedVLANS)}
        if ($DropUntaggedTraffic) {$_Body.Add("dropUntaggedTraffic", $true)}
        if ($Enabled) {$_Body.Add("enabled", $true)}

        $Body = $_Body | ConvertTo-Json -Depth 3 -Compress
    }

    Process{
        $Uri = "{0}/networks/{1}/appliance/ports/{2}" -f $BaseURI, $NetworkId, $Number

        try {
            $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $Body
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Update the per-port VLAN settings for a single MX port.
    .PARAMETER NetworkId
    The Id of the network
    .PARAMETER Number
    The port number to be updated.
    .PARAMETER VlanId
    Native VLAN when the port is in Trunk mode. Access VLAN when the port is in Access mode.
    .PARAMETER Type
    The type of the port: 'access' or 'trunk'.
    .PARAMETER AccessPolicy
    The name of the policy. Only applicable to Access ports. Valid values are: 'open', '8021x-radius', 'mac-radius', 'hybris-radius' for MX64 or Z3 or any MX supporting the per port authentication feature. Otherwise, 'open' is the only valid value and 'open' is the default value if the field is missing.
    .PARAMETER AllowedVLANS
    Comma-delimited list of the VLAN ID's allowed on the port, or 'all' to permit all VLAN's on the port.
    .PARAMETER DropUntaggedTraffic
    Trunk port can Drop all Untagged traffic. When true, no VLAN is required. Access ports cannot have dropUntaggedTraffic set to true.
    .OUTPUTS
    A port object.
    #>
}

Set-Alias -Name Set-MerakiNetworkAppliancePort -Value Set-MerakiAppliancePort -Option ReadOnly
#endregion

#region Static Routes

function Get-MerakiApplianceStaticRoutes() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$id
    )

    $uri = "{0}/networks/{1}/appliance/staticRoutes" -f $BaseURI, $id
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect        
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS 
    Returns the static routes for this network appliance.
    .PARAMETER id
    The Network Id.
    .OUTPUTS 
    An array of Meraki static route objects.
    #>
}

Set-Alias -Name GMNetAppRoutes -Value Get-MerakiNetworkApplianceStaticRoutes -Option ReadOnly
Set-Alias -Name Get-MerakiNetworkApplianceStaticRoutes -Value Get-MerakiApplianceStaticRoutes -Option ReadOnly
Set-Alias -Name GMAppRoutes -Value Get-MerakiNetworkApplianceStaticRoutes -Option ReadOnly

function Add-MerakiApplianceStaticRoute() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$id,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$Subnet,
        [Parameter(Mandatory)]
        [Alias('GatewayIp')]
        [string]$NextHop,
        [Alias('GatewayVlanID')]
        [string]$NextHopVlanID
    )

    Begin {
        $Headers = Get-Headers

        $_Body = @{
            name = $Name
            subnet = $Subnet
            gatewayIp = $NextHop
        }

        if ($NextHopVlanID) {
            $_Body.Add("gatewayVlanId", $NextHopVlanID)
        }

        $body = $_Body | ConvertTo-Json -Depth 3
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/staticRoutes" -f $BaseURI, $Id
        try {
            $response = Invoke-RestMethod -Method Post -Uri $Uri -Headers $Headers -Body $body            
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Adds a static routes for an MX or teleworker network.
    .PARAMETER id
    The Id of the Network.
    .PARAMETER Name
    The name of the new static route
    .PARAMETER Subnet
    The subnet of the static route
    .PARAMETER GatewayIp
    The gateway IP (next hop) of the static route.
    .PARAMETER GatewayVlanIDGIthub
    .OUTPUTS
    An array of static route objects.
    #>    
}

function Set-MerakiApplianceStaticRoute() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$NetworkId,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('RouteId')]
        [string]$Id,        
        [string]$Name,
        [switch]$Disable,
        [string]$Subnet,
        [Alias('GatewayIp')]
        [string]$NextHopIp,
        [Alias('GatewayVlanID')]
        [string]$NextHopVlanID
    )

    $Headers = Get-Headers

    $_Body = @{}
    if ($Name) {
        $_Body.Add("name", $Name)
    }
    if ($Disable.IsPresent) {
        $_Body.Add("enabled", $false)
    } else {
        $_Body.Add("enabled", $true)
    }
    if ($subnet) {
        $_Body.Add("subnet", $subnet)
    }
    if ($NextHopIp) {
        $_Body.Add("gatewayIp", $NextHopIp)
    }
    if ($NextHopVlanID) {
        $_Body.Add("gatewayVlanId", $NextHopVlanID)
    }

    $body = $_Body | ConvertTo-Json -Depth 3 -Compress

    $Uri = "{0}/networks/{1}/appliance/staticRoutes/{0}" -F $BaseURI, $NetworkId, $ID

    try {
        $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .DESCRIPTION
    Update a static route for an MX or teleworker network.
    .PARAMETER NetworkId
    The ID of the network
    .PARAMETER Id
    The Id of the static route.
    .PARAMETER Name
    The name of the static route.
    .PARAMETER Disable
    Disable the static route. Omitting this parameter will enable the static route.
    .PARAMETER Subnet
    The subnet of the static route
    .PARAMETER NextHopIp
    The next hop IP of the static route.
    .PARAMETER NextHopVlanID
    The next hop IP VLAN ID of the static route.
    #>
}

function Remove-MerakiApplianceStaticRoute() {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    Param (
        [Parameter(Mandatory)]
        [Alias('NetworkId')]
        [string]$NetworkId,
        [Parameter(Mandatory)]
        [Alias('StaticRouteId')]
        [string]$id
    )

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/appliance/staticRoutes/{2}" -f $BaseURI, $NetworkId, $Id

    if ($PSCmdlet.ShouldProcess("Static route with Id: $Id", "Delete")) {
        try {
            $response = Invoke-RestMethod -Method Delete -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Delete a static route from an MX or teleworker network.
    .PARAMETER NetworkId
    The id of the network.
    .PARAMETER id
    The Id of the static route.
    #>
}
#endregion

#region VLANs
function Get-MerakiApplianceVLANS() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$id
    )

    Begin {
    
        $Headers = Get-Headers       
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/vlans" -f $BaseURI, $id

        try {
            $response =  Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect            
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Returns the VLANs for the network appliance.
    .PARAMETER id
    The network Id.
    .OUTPUTS
    AN array of Meraki VLAN objects.
    #>
}

Set-Alias -Name GMNetAppVLANs -Value Get-MerakiNetworkApplianceVLANS -Option ReadOnly
Set-Alias -Name Get-MerakiNetworkApplianceVLANS -Value Get-MerakiApplianceVLANS -Option ReadOnly
Set-Alias -Name GMAppVLANs -Value Get-MerakiApplianceVLANS -Option ReadOnly

function Get-MerakiApplianceVLAN() {
    [CmdletBinding(DefaultParameterSetName = 'default')]    
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [String]$networkId,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$id
    )
   
    $Uri = "{0}/networks/{1}/appliance/vlans/{2}" -f $BaseURI, $networkId, $id
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Returns a network appliance VLAN
    .PARAMETER networkId
    The Network Id.
    .PARAMETER id
    The VLAN Id.
    .OUTPUTS
    A Meraki VLAN object.
    #>
}

Set-Alias -Name GMNetAppVLAN -Value Get-MerakiApplianceVLAN -Option ReadOnly
Set-Alias -Name Get-MerakiNetworkApplianceVLAN -Value Get-MerakiApplianceVLAN -Option ReadOnly
Set-Alias -Name GMAppVLAN -Value Get-MerakiApplianceVLAN -Option ReadOnly

function Add-MerakiApplianceVlan() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$VlanId,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Subnet,
        [string]$ApplianceIp,
        [string]$GroupPolicyId,
        [ValidateSet('same','unique')]
        [string]$TemplateVlanType,
        [string]$CIDR,
        [int]$Mask,
        [switch]$Ipv6Enabled,
        [hashtable[]]$Ipv6PrefixAssignments,
        [switch]$MandatoryDHCP
    )

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/appliance/vlans" -f $BaseURI, $NetworkId

    $_Body = @{
        "id" = $VlanId
        "name" = $Name
    }
    if ($Subnet) { $_Body.Add("subnet", $Subnet) }
    if ($ApplianceIp) { $_Body.Add("applianceIp", $ApplianceIp) }
    if ($GroupPolicyId) { $_Body.Add("groupPolicyId", $GroupPolicyId) }
    if ($TemplateVlanType) { $_Body.Add("templateVlanType", $TemplateVlanType) }
    if ($CIDR) { $_Body.Add("cidr", $CIDR) }
    if ($Mask) { $_Body.Add("mask", $Mask ) }
    if ($Ipv6Enabled.IsPresent) {
        $_Body.Add("ipv6", @{
            "enabled" = $true
            "PrefixAssignments" = $Ipv6PrefixAssignments
        })        
    }
    if ($MandatoryDHCP.IsPresent) {
        $_Body.Add(
            @{
                "enabled" = $true
            }
        )
    }

    $body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .DESCRIPTION
    Creates a VLAN on the appliance in the specified network.
    .PARAMETER NetworkId
    The ID of the network to create the VLAN.
    .PARAMETER VlanId
    The VLAN ID of the new VLAN (must be between 1 and 4094).
    .PARAMETER Name
    The name of the new VLAN.
    .PARAMETER Subnet
    The subnet of the VLAN.
    .PARAMETER ApplianceIp
    The local IP of the appliance on the VLAN
    .PARAMETER GroupPolicyId
    The id of the desired group policy to apply to the VLAN
    .PARAMETER TemplateVlanType
    Type of subnetting of the VLAN. Applicable only for template network. Valid values are 'same', 'unique'.
    .PARAMETER CIDR
    CIDR of the pool of subnets. Applicable only for template network. Each network bound to the template will automatically pick a subnet from this pool to build its own VLAN.
    .PARAMETER Mask
    Mask used for the subnet of all bound to the template networks. Applicable only for template network.
    .PARAMETER Ipv6Enabled
    Enable IPv6 on VLAN.
    .PARAMETER Ipv6PrefixAssignments
    Prefix assignments on the VLAN
    .PARAMETER MandatoryDHCP
    Mandatory DHCP will enforce that clients connecting to this VLAN must use the IP address assigned by the DHCP server. Clients who use a static IP address won't be able to associate. Only available on firmware versions 17.0 and above
    #>
}
Set-Alias -Name Add-MerakiNetworkApplianceVlan -Value Add-MerakiApplianceVlan

Function Remove-MerakiApplianceVlan() {
    [CmdletBinding(
        SupportsShouldProcess, 
        ConfirmImpact = 'High',
        DefaultParameterSetName = 'default'
    )]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory)]
        [string]$VlanId
    )

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/appliance/vlans/{2}" -f $BaseURI, $NetworkId, $VlanId

    if ($PSCmdlet.ShouldProcess("VLAN ID $VlanId", "Delete")) {
        try {
            $response = Invoke-RestMethod -Method DELETE -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }           
    }
    <#
    .SYNOPSIS
    Remove a VLAN
    .DESCRIPTION
    Remove a Meraki Appliance VLAN
    .PARAMETER NetworkId
    The Id of the network
    .PARAMETER VlanId
    The VLAN ID to remove
    #>
}

Set-Alias -Name Remove-MerakiNetworkApplianceVlan -Value Remove-MerakiApplianceVlan -Option ReadOnly

function Set-MerakiApplianceVLAN() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$NetworkId,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]$VlanId,
        [string]$VlanName,
        [String]$ApplianceIp,
        [string]$Subnet,
        [string]$GroupPolicyId,
        [ValidateSet("same","unique")]
        [string]$TemplateVlanType,
        [string]$VpnNatSUbnet,
        [string]$CIDR,
        [string]$Mask,
        [ValidateScript({$_ -is [hashtable]})]
        [hashtable[]]$fixedIpAssignments,
        [hashtable[]]$ReservedIpRanges,
        [string]$DnsNameServers,
        [ValidateSet("Run a DHCP Server","Relay DHCP to another Server","Do not respond to DHCP requests")]
        [string]$DhcpHandling,
        [ValidateScript({
            $_ -and ($DhcpHandling -eq 'Relay DHCP to another Server"')
        }, ErrorMessage = "Parameter DhcpRelayServers is not valid when parameter DhcpHandling is 'Relay DHCP to another Server'")]
        [string[]]$DhcpRelayServerIPs,
        [ValidateSet(
            '30 minutes', '1 hour', '4 hours', '12 hours', '1 day', '1 week'
        )]
        [string]$DhcpLeaseTime,
        [bool]$DhcpBootOptionEnabled,
        [string]$DhcpBootNextServer,
        [string]$DhcpBootFilename,
        [hashtable[]]$DhcpOptions,
        [switch]$Ipv6Enabled,
        [hashtable[]]$IPv6PrefixAssignments,
        [bool]$MandatoryDhcp
    )

    Begin {
    
        $Headers = Get-Headers

        $_body = @{}
        if ($name) {
            $_.Body.Add("name", $Name)
        }
        if ($ApplianceIp) {
            $_body.Add("applianceIp", $ApplianceIp)
        }
        if ($subnet) {
            $_body.Add("subnet", $subnet)
        }
        if ($GroupPolicyId) {
            $_body.Add("groupPolicyId", $GroupPolicyId)
        }
        if ($TemplateVlanType) {
            $_body.Add("templateVlanType", $TemplateVlanType)
        }
        if ($CIDR) {
            $_body.Add("cidr", $CIDR)
        }
        if ($Mask) {
            $_body.Add("mask", $Mask)
        }
        if ($fixedIpAssignments) {
            $_body.Add("fixedIpAssignments", $fixedIpAssignments)
        }
        if ($ReservedIpRanges) {
            $_body.Add("reservedIpRanges", $ReservedIpRanges)
        }
        if ($DnsNameServers) {
            $_body.Add("dnsNameservers", $DnsNameServers.Replace(",",[char]10))
        }
        if ($DhcpHandling) {
            $_body.Add("dhcpHandling", $DhcpHandling)
        }
        if ($DhcpRelayServerIPs) {
            $_body.Add("dhcpRelayServerIps", $DhcpRelayServerIPs)
        }
        if ($DhcpLeaseTime) {
            $_body.Add("dhcpLeaseTime", $DhcpLeaseTime)
        }
        if ($DhcpBootOptionEnabled) {
            $_body.Add("dhcpBootOptionsEnabled", $DhcpBootOptionEnabled)
        }
        if ($DhcpBootNextServer) {
            $_body.Add("dhcpBootNextServer", $DhcpBootNextServer)
        }
        if ($DhcpBootFilename) {
            $_body.Add("dhcpBoofFilename", $DhcpBootFilename)
        }
        if ($Ipv6Enabled) {
            $_Body.Add("ipv6", @{
                "enabled" = $true
                "prefixAssignments" = $Ipv6PrefixAssignments
            })        
        }
        if ($MandatoryDhcp) {
            $_body.Add("mandatoryDhcp", $MandatoryDhcp)
        }
        if ($VpnNatSubnet) {
            $_body.Add("vpnNatSubnet", $VpnNatSubnet)
        }

        $body = $_body | ConvertTo-Json -Depth 10 -Compress
    }

    Process {
        # Return the network Info so we can determine is this network is assigned to a template.
        $Network = Get-MerakiNetwork -networkID $NetworkId

        # check for Template only parameters.
        if ($mask -or $CIDR -or $TemplateVlanType) {
            if ($Network.$_isBoundToConfigTemplate -eq $false) {
                Throw "Parameters 'mask', 'CIDR' and TemplateVLanType are only applicable to template networks."
            }
        }

        $Uri = "{0}/networks/{1}/appliance/vlans/{2}" -f $BaseURI, $NetworkId, $VlanId

        Try {
            $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            Throw $_
        }
    }
    <#
    .SYNOPSIS
    "Update Appliance VLAN"
    .DESCRIPTION
    "Updates settings for a Meraki Appliance VLAN"
    .PARAMETER id
    "Network Id"
    .PARAMETER VlanId
    "VLAN ID to be updated"
    .PARAMETER VlanName
    "Name of the VLAN"
    .PARAMETER ApplianceIp
    "Appliance IP for this VLAN (Default Gateway)"
    .PARAMETER Subnet
    "Subnet for this VLAN"
    .PARAMETER GroupPolicyId
    .ID of the group policy to apply to this VLAN"
    .PARAMETER TemplateVlanType
    "Type of subnetting of the VLAN. Applicable only for template network"
    .PARAMETER VpnNatSUbnet
    The translated VPN subnet if VPN and VPN subnet translation are enabled on the VLAN
    .PARAMETER CIDR
    CIDR of the pool of subnets. Applicable only for template network. Each network bound to the template will automatically pick a subnet from this pool to build its own VLAN.
    .PARAMETER Mask
    Mask used for the subnet of all bound to the template networks. Applicable only for template network.
    .PARAMETER fixedIpAssignments
    The DHCP fixed IP assignments on the VLAN. This should be an object that contains mappings from MAC addresses to objects that themselves each contain "ip" and "name" string fields. See the sample request/response for more details.
    A hash table that contains the following name value pairs.
    MAC: The MAC address of the device to assign the IP to.
    IP: the IP to assign. This must be withing the IP pool of the DHCP server.
    Name: A descriptive name for the device.
    .PARAMETER ReservedIpRanges
    The DHCP reserved IP ranges on the VLAN
    A hash table with the following name value pairs.
    comment: A text comment for the reserved range
    start: The first IP in the reserved range
    end: The last IP in the reserved range
    .PARAMETER DnsNameServers
    The DNS nameservers used for DHCP responses, either "upstream_dns", "google_dns", "opendns", or a newline separated string of IP addresses or domain names
    .PARAMETER DhcpHandling
    The appliance's handling of DHCP requests on this VLAN. One of: 'Run a DHCP server', 'Relay DHCP to another server' or 'Do not respond to DHCP requests'
    .PARAMETER DhcpRelayServerIPs
    The IPs of the DHCP servers that DHCP requests should be relayed to. Must be an array od strings.
    .PARAMETER DhcpLeaseTime
    The term of DHCP leases if the appliance is running a DHCP server on this VLAN. One of: '30 minutes', '1 hour', '4 hours', '12 hours', '1 day' or '1 week'
    .PARAMETER DhcpBootOptionEnabled
    Use DHCP boot options specified in other properties.
    .PARAMETER DhcpBootNextServer
    DHCP boot option to direct boot clients to the server to load the boot file from
    .PARAMETER DhcpBootFilename
    DHCP boot option for boot filename
    .PARAMETER DhcpOptions
    An array of hashtables with the following name/value pairs.
    .PARAMETER Ipv6Enabled
    Enable IPv6 on VLAN.
    .PARAMETER IPv6PrefixAssignments
    An array of hashtables containing IPv6 prefix assignments. 
    The hashtable must have the following name/value pairs.
    prefixAssignments: array[] Prefix assignments on the VLAN
    staticApplianceIp6: string Manual configuration of the IPv6 Appliance IP
    staticPrefix: string  Manual configuration of a /64 prefix on the VLAN
    autonomous: boolean Auto assign a /64 prefix from the origin to the VLAN
    .PARAMETER MandatoryDhcp
    Mandatory DHCP will enforce that clients connecting to this VLAN must use the IP address assigned by the DHCP server. Clients who use a static IP address won't be able to associate. Only available on firmware versions 17.0 and above
    #>
}

Set-Alias -Name SetMNAppVLAN  -Value Set-MerakiNetworkApplianceVLAN -Option ReadOnly
Set-Alias -Name Set-MerakiNetworkApplianceVLAN -Value Set-MerakiApplianceVLAN -Option ReadOnly
#endregion

#region Monitoring
function Get-MerakiApplianceDhcpSubnets() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$serial
    )

    Begin {        
        $Headers = Get-Headers
    }

    Process {
        $Url = "{0}/devices/{1}/appliance/dhcp/subnets" -f $BaseURI, $Serial
        try {
            $response = Invoke-RestMethod -Method GET -Uri $Url -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Returns DHCP Subnets for an appliance.
    .DESCRIPTION
    Returns information and statistics for an appliances DHCP subnets. Including used count and free count.
    .PARAMETER serial
    The serial number of the appliance.
    .OUTPUTS
    A collection of Subnet objects.
    #>
}

function Get-MerakiApplianceClientSecurityEvents() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$ClientId,
        [Parameter(
            Mandatory,
            ParameterSetName = 'dates'
        )]
        [ValidateScript({
            $_ -gt (Get-Date).AddDays(-791)
        }, ErrorMessage = "StartDate cannot be more that 791 days prior to today")]
        [datetime]$StartDate,
        [Parameter(
            Mandatory,
            ParameterSetName = 'dates'
        )]
        [ValidateScript({
            $_ -lt $StartDate.AddDays(791)
        }, ErrorMessage = "End date cannot be more than 791 days after StartDate")]
        [datetime]$EndDate,
        [Parameter(
            Mandatory,
            ParameterSetName = 'days'
        )]
        [ValidateScript({
            $_ -lt 791
        })]
        [int]$Days,
        [int]$PerPage       
    )

    Begin {

        $Headers = Get-Headers

        $Results = [List[PsObject]]::New()
        
        if (StartDate) {
            $query = "?t0={0}" -f ($StartDate.ToString("0"))
        }
        if ($EndDate) {
            if ($query) {
                $query = "{0}&" -f $query
            } else {
                $Query = "?"
            }
            $query = "{0}t1={1}" -f $query, ($EndDate.ToString("0"))
        }
        if ($Days) {
            $seconds = [TimeSpan]::FromDays($Days).TotalSeconds
            if ($query) {
                $query = "{0}&" -f $query
            } else {
                $query = "?"
            }
            $Query = "{0}timespan={1}" -f $Query, $seconds
        }
        if ($PerPage) {
            if ($query) {
                $query = "{0}&" -f $query
            } else {
                $query = "?"
            }
            $query = "{0}perPage={1}" -f $query, $PerPage
        }
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/clients/{2}/security/events" -f $BaseURI, $Id, $ClientId

        try {

            $response = Invoke-WebRequest -Method Get -Uri $Uri -Headers -PreserveAuthorizationOnRedirect

            [List[PsObject]]$result = $response.Content | ConvertFrom-Json
            if ($result) {
                $Results.AddRange($result)
            }
            $page = 1
            if ($Pages -ne 1) {
                $done = $false
                do {
                    if ($response.RelationLink['next']) {
                        $Uri = $response.RelationLink['next']
                        $response = Invoke-WebRequest -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
                        [List[PsObject]]$result = $response.Content | ConvertFrom-Json
                        if ($result) {
                            $Results.AddRange($result)
                        }
                        $page += 1
                        if ($page -gt $Pages) {
                            $done = $true
                        }
                    } else {
                        $done = $true
                    }
                } until ($done)
            }
            return $Results
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Returns the security events for a client. Clients can be identified by a client key or either the MAC or IP depending on whether the network uses Track-by-IP.
    .PARAMETER Id
    The ID of the network.
    .PARAMETER ClientId
    The ID of the client.
    .PARAMETER StartDate
    The beginning of the timespan for the data. Data is gathered after the specified StartDate value. The maximum lookback period is 791 days from today.
    .PARAMETER EndDate
    The end of the timespan for the data. t1 can be a maximum of 791 days after StartDate.
    .PARAMETER Days
    The timespan for which the information will be fetched. If specifying timespan, do not specify parameters StartDate and EndDate. The value must be less than or equal to 791 days. The default is 31 days.
    .PARAMETER PerPage
    The number of entries per page returned. Acceptable range is 3 - 1000. Default is 100.
    .OUTPUTS
    An array of security event objects.
    #>
}


#endregion

Set-Alias -Name GMNetAppDhcpSubnet -Value Get-MerakiApplianceDhcpSubnets -Option ReadOnly
Set-ALias -Name Get-MerakiNetworkApplianceDhcpSubnets -Value Get-MerakiNetworkApplianceDhcpSubnets -Option ReadOnly
Set-Alias -Name GMAppDhcpSubnet -Value Get-MerakiApplianceDhcpSubnets -Option ReadOnly


#region VPN
function Get-MerakiApplianceSiteToSiteVPN() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$id,
        [switch]$hr
    )


    $Uri = "{0}/networks/{1}/appliance/vpn/siteToSiteVpn" -f $BaseURI, $id
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
        if ($hr) {
            $heading = [pscustomobject][ordered]@{
                network = (Get-MerakiNetwork -networkID $id).name
                mode = $response.mode
            }
            Write-Output $heading | Format-List
            Write-Output "Hubs:"
            if ($response.mode = "spoke") {
                $hubs = @()
                $response.hubs | ForEach-Object {
                    $Hub = [PSCustomObject][ordered]@{
                        Name = (Get-MerakiNetwork -networkID $_.HubId).name
                        DefaultRoute = $_.useDefaultRoute
                    }
                    $Hubs += $Hub
                }
                Write-Output $hubs | Format-Table
            }
            Write-Output "Subnets:"
            $subnets = @()
            $response.subnets | ForEach-Object {
                $subnet = [PSCustomObject][ordered]@{
                    localSubnet = $_.localSubnet
                    useVpn = $_.useVpn
                }
                $subnets += $subnet
            }
            Write-Output $subnets | Format-Table
        } else {
            return $response
        }
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Returns a Meraki Network appliance Site-to-Site VPN configuration.
    .PARAMETER id
    The network Id.
    .PARAMETER hr
    Formats the output into 2 tables. Hubs and Subnets.
    .OUTPUTS
    If -hr is specified outputs tables to the console.
    If -hr is omitted, outputs a Meraki Site-to-Site VPN object.
    #>
}

Set-Alias -Name GMNetAppSSVpn -Value Get-MerakiNetworkApplianceSiteToSiteVPN -Option ReadOnly
Set-Alias -Name Get-MerakiNetworkApplianceSiteToSiteVPN -Value Get-MerakiApplianceSiteToSiteVPN -Option ReadOnly
Set-Alias -Name GMAppSSVpn -Value Get-MerakiApplianceSiteToSiteVPN -Option ReadOnly

function Set-MerakiApplianceSiteToSiteVpn() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]        
        [string]$NetworkId,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateSet('none', 'spoke', 'hub')]
        [string]$Mode,
        [Parameter(ValueFromPipelineByPropertyName)]
        [psobject[]]$Hubs,
        [Parameter(ValueFromPipelineByPropertyName)]
        [psobject[]]$Subnets
    )

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/appliance/vpn/siteToSiteVpn" -f $BaseURI, $NetworkId

    If ($VpnSettings) {
        $body = $VpnSettings | ConvertTo-Json -Depth 6 -Compress
    } else {

        $_Body = @{
            mode = $mode
        }

        if ($Hubs) {
            foreach ($Hub in $hubs) {
                if (-not $Hub.hubid) {
                    throw "Property hubId is required for all Hubs"
                }
            }
            $_Body.Add("hubs", $Hubs)
        }

        if ($Subnets) {
            foreach($Subnet in $Subnets) {
                if (-not $Subnet.localSubnet) {
                    throw "Property localSubnet is requored for all Subnets"
                }
            }
            $_Body.Add("subnets", $Subnets)
        }

        $body = $_Body | ConvertTo-Json -Depth 6 -Compress
    }

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $Body -PreserveAuthorizationOnRedirect
        return $response
    }
    catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Update Network Site-to-Site VPN
    .DESCRIPTION
    Update the Meraki Network Site to Site VPN Settings.
    .PARAMETER NetworkId
    The ID of the to update
    .PARAMETER VpnSettings
    A Object containing the VPN Settings to apply. This parameter must be used without other parameters.
    .PARAMETER Mode
    The site-to-site VPN mode. Can be one of 'none', 'spoke' or 'hub'
    .PARAMETER Hubs
    The list of VPN hubs, in order of preference. In spoke mode, at least 1 hub is required.
    Hub objects contain the following properties.
    hubId:string (Required) - The network ID of the hub.

    useDefaultRoute:boolean - Only valid in 'spoke' mode. Indicates whether default route traffic should be sent to this hub.
    .PARAMETER Subnets
    The list of subnets and their VPN presence.
    Subnet object contain the following properties:
    localSubnet:string (required) - The CIDR notation subnet used within the VPN
    useVpn: boolean - Indicates the presence of the subnet in the VPN
    .EXAMPLE
    Updating an existing network configured as a spoke.
    # The easiest way to do this is to get the current von settings in an object.
    $VpnSettings = Get-MerakiNetworkApplianceSiteToSiteCpn -id N_1246598574
    # Modify the settings in this object
    # Set the 1st hub destination
    $VpnSettings.hubs[0].hubId = N_5452659857
    $VpnSettings.hubs[0].useDefaultRoute = $false
    # Modify the 2nd hub destination
    $VpnSettings.hubs[0].hubId = N_4585965254
    $VpnSettings.hubs[0].useDefaultRoute = $false
    # Modify the subnet settings if necessary
    $VpnSettings.Subnets[0].localSubnet = 10.5.5.5/24
    $VpnSettings.Subnets[0].useVpn = $true
    # Update the VPN Settings
    Set-MeraqkiNetworkApplianceSiteToSiteVpn -NetworkId N_1246598574 -VpnSettings $VpnSettings
    .EXAMPLE
    In this example we are going to convert a Hub (mess) network to a Spoke network
    In this instance the subnet is already set as we want it so we will only change the mode and add in the remote hub networks.
    
    # Create an array of hubs object
    $Hubs = @(
        @{
            hubId = "N_54265629254"
            useDefaultRoute = $False
        },
        @{
            hubId = "N_75485962345"
            useDefaultroute = $false
        }
    )
    Set-MerakiNetworkApplianceSiteToSiteVpn -NetworkId N_845926352 -Mode Spoke -Hubs $Hubs
    #>
}

Set-Alias -Name Set-MerakiNetworkApplianceSiteToSiteVpn -Value Set-MerakiApplianceSiteToSiteVpn -Option ReadOnly
#endregion




#region CellularFirewall
function Get-MerakiApplianceCellularFirewallRules () {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('NetworkId')]
        [string]$Id
    )

    Begin {
        $Headers = Get-Headers
    }
    
    Process {
        $Uri = "{0}/networks/{1}/appliance/firewall/cellularFirewallRules" -f $BaseURI, $Id        

        $Network = Get-MerakiNetwork -networkID $Id

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $rules = $response.rules
            $number = 1
            $rules | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "NetworkId" -Value $Id
                $_ | Add-Member -MemberType NoteProperty -Name "NetworkName" -Value $Network.Name
                $_ | Add-Member -MemberType NoteProperty -Name "RuleNumber" -Value $number
                $number += 1
            }
            return $rules
        }
        catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Returns the Cellular firewall rules for this network.
    .PARAMETER Id
    The Network ID to retrieve the rules from.
    #>
}

function Set-MerakiApplianceCellularFirewallRules() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [psObject[]]$Rules
    )

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/appliance/firewall/cellularFirewallRules" -f $BaseURI, $Id

    # Remove the default rule if it exists.
    $Rules = $Rules.where({$_.comment -ne 'Default rule'})

    # Remove the RuleNumber, NetworkName, and NetworkId properties if it exists
    $Rules = $Rules | Select-Object -ExcludeProperty RuleNumber, NetworkId, NetworkName

    $_Rules = @{
        rules = $Rules
    }

    $body = $_Rules | ConvertTo-Json -Depth 4 

    $Network = Get-MerakiNetwork -Id $Id
    try {
        $Rules = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        $Number = 1
        $Rules | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name 'NetworkId' -Value $Id
            $_ | Add-Member -MemberType NoteProperty -Name 'NetworkName' -Value $Network.Name
            $_ | Add-Member -MemberType NoteProperty -Name 'RuleNumber' -Value $Number
            $Number += 1
        }
        return $response
    } catch {
        throw $_
    }
    <#
    .DESCRIPTION
    Update the network's cellular firewall rules
    .PARAMETER Id
    The network ID to update the rules on.
    .PARAMETER Rules
    An array of objects containing the following properties.
    comment: string Description of the rule (optional)
    destCidr*: string Comma-separated list of destination IP address(es) (in IP or CIDR notation), fully-qualified domain names (FQDN) or 'any'
    destPort: string Comma-separated list of destination port(s) (integer in the range 1-65535), or 'any'
    policy*: string 'allow' or 'deny' traffic specified by this rule
    protocol*: string The type of protocol (must be 'tcp', 'udp', 'icmp', 'icmp6' or 'any')
    srcCidr*: string Comma-separated list of source IP address(es) (in IP or CIDR notation), or 'any' (note: FQDN not supported for source addresses)
    srcPort: string Comma-separated list of source port(s) (integer in the range 1-65535), or 'any'
    syslogEnabled: boolean Log this rule to syslog (true or false, boolean value) - only applicable if a syslog has been configured (optional)
    .NOTES
    The Rules returned from Get-MerakiApplianceCellularFirewallRules contain the properties RuleNumber, NetworkId, and NetworkName.
    These properties are removed by this function before being sent to the API endpoint.
    If you create the rules array manually you do not need to include these properties.
    Changes to these rules should be done with the associated Add-, Set-, and Remove- functions.
    #>
}

function Set-MerakiApplianceCellularFirewallRule() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [int]$RuleNumber,
        [ValidateSet('allow','deny')]
        [string]$Policy,
        [ValidateSet('tcp', 'udp', 'icmp', 'icmp6', 'any')]
        [string]$Protocol,
        [Alias('srcPort')]
        [string]$SourcePort,
        [ALias('srcCidr')]
        [string]$SourceCidr,
        [Alias('DestCidr')]
        [string]$DestinationCidr,
        [Alias('destPort')]
        [string]$DestinationPort,
        [switch]$SyslogEnabled,
        [string]$Comment
    )

    $Rules = @{}
    Get-MerakiApplianceCellularFirewallRules -id $Id | ForEach-Object {
        $Rules.Add($_.RuleNumber, $_)
    }

    If ($Policy) {
        $Rules[$RuleNumber].Policy = $Policy
    }
    if ($Protocol) {
        $Rules[$RuleNumber].Protocol = $Protocol
    }
    if ($SourceCidr) {
        $Rules[$RuleNumber].srcCidr = $SourceCidr
    }
    if ($SourcePort) {
        $Rules[$RuleNumber].srcPort = $SourcePort
    }
    if ($DestinationCidr) {
        $Rules[$RuleNumber].destCidr = $DestinationCidr
    }
    if ($DestinationPort) {
        $Rules[$RuleNumber].destPort = $DestinationPort
    }
    if ($Comment) {
        $Rules[$RuleNumber].comment = $Comment
    }
    if ($SyslogEnabled) {
        $Rule[$RuleNumber].syslogEnabled = $true
    }

    $Rules = $Rules.Values 

    
    try {
        $Rules = Set-MerakiApplianceCellularFirewallRules -Id $Id -rules $Rules
        return $Rules
    }
    catch {
        throw $_
    }
    <#
    .DESCRIPTION
    Updates a single cellular firewall rule in the specified network.    
    .PARAMETER Id
    The ID of the network.
    .PARAMETER RuleNumber
    The RuleNumber to update.
    .PARAMETER Policy
    'allow' or 'deny' traffic specified by this rule
    .PARAMETER protocol
    The type of protocol (must be 'tcp', 'udp', 'icmp', 'icmp6' or 'any')
    .PARAMETER SourcePort
    Comma-separated list of source port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER SourceCidr
    Comma-separated list of source IP address(es) (in IP or CIDR notation), or 'any' (note: FQDN not supported for source addresses)
    .PARAMETER DestinationCidr
    Comma-separated list of destination IP address(es) (in IP or CIDR notation), fully-qualified domain names (FQDN) or 'any'
    .PARAMETER DestinationPort
    Comma-separated list of destination port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER SyslogEnabled
    Log this rule to syslog (true or false, boolean value) - only applicable if a syslog has been configured (optional)
    .PARAMETER Comment
    Description of the rule (optional)
    #>
}

function Add-MerakiApplianceCellularFirewallRule() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [ValidateSet('allow','deny')]
        [string]$Policy,
        [Parameter(Mandatory = $true)]
        [ValidateSet('tcp', 'udp', 'icmp', 'icmp6', 'any')]
        [string]$protocol,
        [Alias('srcPort')]
        [string]$SourcePort = 'any',
        [Parameter(Mandatory = $true)]
        [ALias('srcCidr')]
        [string]$SourceCidr,
          [Parameter(Mandatory = $true)]
        [Alias('DestCidr')]
        [string]$DestinationCidr,
        [Alias('destPort')]
        [string]$DestinationPort = 'any',
        [switch]$SyslogEnabled,
        [Parameter(Mandatory = $true)]
        [string]$Comment
    )

    Begin {

    }

    Process {
        $Rules = Get-MerakiApplianceCellularFirewallRules -Id $Id

        # Remove the default rule

        
        $Properties = @{
            "policy"        = $Policy
            "srcCidr"       = $SourceCidr
            "srcPort"       = $SourcePort
            "protocol"      = $protocol
            "destCidr"      = $DestinationCidr
            "destPort"      = $DestinationPort
            "comment"       = $Comment
            "RuleNUmber"    = -1
        }
        if ($SyslogEnabled.IsPresent) { $properties.Add("syslogEnabled", $SyslogEnabled) }
        $rule = [PSCustomObject]$Properties

        $Rules += $rule

        try {
            $response = Set-MerakiNetworkApplianceCellularFirewallRules -Id $id -Rules $Rules
            return $response
        }
        catch {
            throw $_
        }
    }
    <#
    Adds a cellular firewall rule to the network
    .PARAMETER Id
    The ID of the network.
    .PARAMETER Policy
    'allow' or 'deny' traffic specified by this rule
    .PARAMETER protocol
    The type of protocol (must be 'tcp', 'udp', 'icmp', 'icmp6' or 'any')
    .PARAMETER SourcePort
    Comma-separated list of source port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER SourceCidr
    Comma-separated list of source IP address(es) (in IP or CIDR notation), or 'any' (note: FQDN not supported for source addresses)
    .PARAMETER DestinationCidr
    Comma-separated list of destination IP address(es) (in IP or CIDR notation), fully-qualified domain names (FQDN) or 'any'
    .PARAMETER DestinationPort
    Comma-separated list of destination port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER SyslogEnabled
    Log this rule to syslog (true or false, boolean value) - only applicable if a syslog has been configured (optional)
    .PARAMETER Comment
    Description of the rule (optional)
    #>
}

function Remove-MerakiApplianceCellularFirewallRule() {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [int]$RuleNumber
    )

    $Rules = Get-MerakiApplianceCellularFirewallRules -id $NetworkId | Where-Object {$_.RuleNumber -ne $RuleNumber} | `
        Select-Object -ExcludeProperty RuleNumber


    if ($PSCmdlet.ShouldProcess("Cellular Firewall Rule number $RuleNumber", 'DELETE')) {
        try {
            $response = Set-MerakiApplianceCellularFirewallRules -Id $NetworkId -Rules $Rules
            return $response
        }
        catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Deletes a cellular firewall rule.
    .PARAMETER NetworkId
    The ID of the network to remove the rule.
    .PARAMETER RuleIndex
    The rule number to be removed.
    #>
}

function Get-MerakiApplianceInboundCellularFirewallRules() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/appliance/firewall/inboundCellularFirewallRule" -f $BaseURI, $Id
        
        $Network = Get-MerakiNetwork -networkID $Id

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $Number = 1
            $response | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "NetworkId" -Value $Id
                $_ | Add-Member -MemberType NoteProperty -Name "NetworkName" -Value $Network.Name
                $_ | Add-Member -MemberType NoteProperty -Name "RuleNumber" -Value $Number
                $Number += 1
            }
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION 
    Return the inbound cellular firewall rules for an MX network
    .PARAMETER Id
    The Id of the network.
    .OUTPUTS
    An array of inbound cellular firewall rule objects.
    #>
}

function Set-MerakiApplianceInboundCellularFirewallRules () {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory)]
        [PsObject[]]$Rules
    )

    Begin {
        $Headers = Get-Headers

        # Remove the default rule if it exists.
        $Rules = $Rules.Where({$_.comment -ne "Default rule"})

        # Remove the RuleNumber, NetworkId, amd NetworkName properties if they exists
        $Rules = $Rules | Select-Object -ExcludeProperty RuleNumber, NetworkId, NetworkName

        $rules = @{
            rules = $Rules
        }

        $Body = $rules | ConvertTo-Json -Depth 4 -Compress
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/firewall/inboundCellularFirewallRules" -f $BaseURI, $Id

        $Network = Get-MerakiNetwork -Id $Id

        try {
            $Rules = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $Body
            $Number = 1
            $Rules | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name 'NetworkId' -Value $Id
                $_ | Add-Member -MemberType NoteProperty -Name 'NetworkName' -Value $Network.Name
                $_ | Add-Member -MemberType NoteProperty -Name 'RuleNumber' -Value $Number
                $Number += 1
            }
            return $response
        } catch {
            throw $_
        }

    }
    <#
    .DESCRIPTION
    Update the inbound cellular firewall rules of an MX network
    .PARAMETER Id
    The Id of the network.
    .PARAMETER Rules
    An array of inbound cellular firewall rules that include the following properties
    comment: string Description of the rule (optional)
    destCidr*: string Comma-separated list of destination IP address(es) (in IP or CIDR notation), fully-qualified domain names (FQDN) or 'any'
    destPort: string Comma-separated list of destination port(s) (integer in the range 1-65535), or 'any'
    policy*: string 'allow' or 'deny' traffic specified by this rule
    protocol*: string The type of protocol (must be 'tcp', 'udp', 'icmp', 'icmp6' or 'any')
    srcCidr*: string Comma-separated list of source IP address(es) (in IP or CIDR notation), or 'any' (note: FQDN not supported for source addresses)
    srcPort: string Comma-separated list of source port(s) (integer in the range 1-65535), or 'any'
    syslogEnabled: boolean Log this rule to syslog (true or false, boolean value) - only applicable if a syslog has been configured (optional)
    .NOTES
    The Rules returned from Get-MerakiApplianceInboundFirewallRules contain the properties RuleNumber, NetworkId, and NetworkName.
    These properties are removed by this function before being sent to the API endpoint.
    If you create the rules array manually you do not need to include these properties.
    Changes to these rules should be done with the associated Add-, Set-, and Remove- functions.   
    .OUTPUTS
    An array of updated inbound cellular firewall rules.
    #>
}

function Add-MerakiApplianceInboundCellularFirewallRule() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [string]$Comment,
        [Parameter(Mandatory)]
        [ValidateSet('allow','deny' )]
        [string]$Policy,
        [Alias('srcCidr')]
        [string]$SourceCIDR,
        [ALias('srcPort')]
        [string]$SourcePort = 'any',
        [ValidateSet('tcp', 'udp', 'icmp', 'icmp6', 'any')]
        [string]$Protocol = 'any',
        [Parameter(Mandatory)]
        [Alias('destCidr')]
        [string]$DestinationCIDR,
        [Alias('destPort')]
        [string]$DestinationPort = 'any',
        [switch]$SyslogEnabled
    )

    Begin {

        $Rules = Get-MerakiApplianceInboundCellularFirewallRules -Id $Id

        $Rules = $Rules.Where({$_.Comment -ne 'Default rule'}) | Select-Object -ExcludeProperty RuleNumber

        $Properties = @{
            "policy"    = $Policy
            "srcCidr"   = $SourceCidr
            "srcPort"   = $SourcePort
            "protocol"  = $protocol
            "destCidr"  = $DestinationCidr
            "destPort"  = $DestinationPort
            "comment"   = $Comment
        }

        if ($SyslogEnabled.IsPresent) {$Properties.Add("syslogEnabled", $true)}
        $Rule = [PSCustomObject]$Properties

        $Rules += $Rule

        try {
            $response = Set-MerakiNetworkApplianceInboundCellularFirewallRules -Id $id -Rules $Rules
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Add an inbound cellular firewall rule to an MX network.
    .PARAMETER Id
    The ID of the network.
    .PARAMETER Policy
    'allow' or 'deny' traffic specified by this rule
    .PARAMETER protocol
    The type of protocol (must be 'tcp', 'udp', 'icmp', 'icmp6' or 'any')
    .PARAMETER SourcePort
    Comma-separated list of source port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER SourceCidr
    Comma-separated list of source IP address(es) (in IP or CIDR notation), or 'any' (note: FQDN not supported for source addresses)
    .PARAMETER DestinationCidr
    Comma-separated list of destination IP address(es) (in IP or CIDR notation), fully-qualified domain names (FQDN) or 'any'
    .PARAMETER DestinationPort
    Comma-separated list of destination port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER SyslogEnabled
    Log this rule to syslog (true or false, boolean value) - only applicable if a syslog has been configured (optional)
    .PARAMETER Comment
    Description of the rule (optional)
    #>
}

function Set-MerakiApplianceInboundCellularFirewallRule() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [int]$RuleNumber,
        [ValidateSet('allow','deny')]
        [string]$Policy,
        [ValidateSet('tcp', 'udp', 'icmp', 'icmp6', 'any')]
        [string]$Protocol,
        [Alias('srcPort')]
        [string]$SourcePort,
        [ALias('srcCidr')]
        [string]$SourceCidr,
        [Alias('DestCidr')]
        [string]$DestinationCidr,
        [Alias('destPort')]
        [string]$DestinationPort,
        [switch]$SyslogEnabled,
        [string]$Comment
    )

    Begin {
        $Rules = @{}
    }

    Process {
        Get-MerakiApplianceInboundCellularFirewallRules -id $Id | Foreach-Object {
            $Rules.Add($_.RuleNumber, $_)
        }

        If ($Policy) {
            $Rules[$RuleNumber].Policy = $Policy
        }
        if ($Protocol) {
            $Rules[$RuleNumber].Protocol = $Protocol
        }
        if ($SourceCidr) {
            $Rules[$RuleNumber].srcCidr = $SourceCidr
        }
        if ($SourcePort) {
            $Rules[$RuleNumber].srcPort = $SourcePort
        }
        if ($DestinationCidr) {
            $Rules[$RuleNumber].destCidr = $DestinationCidr
        }
        if ($DestinationPort) {
            $Rules[$RuleNumber].destPort = $DestinationPort
        }
        if ($Comment) {
            $Rules[$RuleNumber].comment = $Comment
        }
        if ($SyslogEnabled) {
            $Rule[$RuleNumber].syslogEnabled = $true
        }        

        $Rules = $Rules.Values

        try {
            $Rules = Set-MerakiApplianceInboundCellularFirewallRules -id -Rules $Rules
            return $Rules
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Updates a single inbound cellular firewall rule in the specified network.
    You must get the rule index using the Get-MerakiNetworkApplianceCellularFirewallRule function.
    .PARAMETER Id
    The ID of the network.
    .PARAMETER RuleIndex
    The RuleIndex to update.
    .PARAMETER Policy
    'allow' or 'deny' traffic specified by this rule
    .PARAMETER protocol
    The type of protocol (must be 'tcp', 'udp', 'icmp', 'icmp6' or 'any')
    .PARAMETER SourcePort
    Comma-separated list of source port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER SourceCidr
    Comma-separated list of source IP address(es) (in IP or CIDR notation), or 'any' (note: FQDN not supported for source addresses)
    .PARAMETER DestinationCidr
    Comma-separated list of destination IP address(es) (in IP or CIDR notation), fully-qualified domain names (FQDN) or 'any'
    .PARAMETER DestinationPort
    Comma-separated list of destination port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER SyslogEnabled
    Log this rule to syslog (true or false, boolean value) - only applicable if a syslog has been configured (optional)
    .PARAMETER Comment
    Description of the rule (optional)
    #>
}

function Remove-MerakiApplianceInboundCellularFirewallRule() {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory)]
        [string]$NetworkId,
        [Parameter(Mandatory)]
        [int]$RuleNumber
    )

    $Rules = Get-MerakiApplianceInboundCellularFirewallRules -id $NetworkId | Where-Object {$_.RuleNumber -ne $RuleNumber} | `
        Select-Object -ExcludeProperty RuleNumber

    if ($PSCmdlet.ShouldProcess("Inbound Cellular Firewall Rule Number $ruleNumber", "Delete")) {
        try {
            $response = Set-MerakiApplianceInboundCellularFirewallRules -Id $NetworkId -Rules $Rules
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Deleted an inbound cellular firewall rule.
    .PARAMETER NetworkId
    The Id of the network.
    .PARAMETER RuleNumber
    The rule number to be removed.
    #>
}
#endregion

#region InboundFirewallRules
function Get-MerakiApplianceInboundFirewallRules() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id
    )

    Begin {
        $Headers = get-Headers
    }

    Process{
        $Uri = "{0}/networks/{1}/appliance/firewall/inboundFirewallRules" -f $BaseURI, $Id

        $Network = Get-MerakiNetwork -id $Id

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
            $Rules = $response.rules
            $Number = 1
            $Rules | Foreach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "NetworkId" -Value $id
                $_ | Add-Member -MemberName NoteProperty -Name "NetworkName" -Value $Network.Name
                $_ | Add-Member -MemberType NoteProperty -Name "RuleNumber" -Value $Number
                $number += 1
            }
            return $Rules
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Return the inbound firewall rules for an MX network
    .PARAMETER Id
    The Id of the network.
    .OUTPUTS
    An array of inbound firewall rules.
    #>
}

function Set-MerakiApplianceInboundFirewallRules() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory)]
        [PsObject[]]$Rules
    )

    Begin {
        $Headers = Get-Headers

        # Remove the default rule if it exists
        $Rules = $Rules.Where({$_.comment -ne 'Default rule'})

        #Remove the RuleNumber, NetworkId, and NetworkName properties if they exist.
        $Rules = $Rules | Select-Object -ExcludeProperty RuleNumber, NetworkName, NetworkId

        $_Rules = @{
            rules = $Rules
        }

        $body = $_Rules |ConvertTo-Json -Depth 4 -Compress
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/firewall/inboundFirewallRules" -f $BaseURI, $id

        try {
            $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            $rules = $response.range
            return $response.rules
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Update the inbound firewall rules of an MX network
    .PARAMETER Id
    The Id of the network.
    .PARAMETER Rules
    An array of inbound firewall rules objects.
    .OUTPUTS
    An array of updated inbound firewall rules.
    #>
}

 function Add-MerakiApplianceInboundFirewallRule() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [ValidateSet('allow','deny')]
        [string]$Policy,
        [Parameter(Mandatory = $true)]
        [ValidateSet('tcp', 'udp', 'icmp', 'icmp6', 'any')]
        [string]$protocol,
        [Alias('srcPort')]
        [string]$SourcePort = 'any',
        [Parameter(Mandatory = $true)]
        [ALias('srcCidr')]
        [string]$SourceCidr,
          [Parameter(Mandatory = $true)]
        [Alias('DestCidr')]
        [string]$DestinationCidr,
        [Alias('destPort')]
        [string]$DestinationPort = 'any',
        [switch]$SyslogEnabled,
        [Parameter(Mandatory = $true)]
        [string]$Comment
    )

    Begin {
        $Rules = Get-MerakiApplianceInboundFirewallRules -Id $Id Select-Object -ExcludeProperty RuleNumber

        $Rules = $Rules | Where-Object {$_.comment -ne 'Default rule'}

        $Properties = @{
            "policy"        = $Policy
            "srcCidr"       = $SourceCidr
            "srcPort"       = $SourcePort
            "protocol"      = $protocol
            "destCidr"      = $DestinationCidr
            "destPort"      = $DestinationPort
            "comment"       = $Comment
            "RuleNumber"    = -1
            "NetworkId"     = "NA"
            "NetworkName"   = "NA"
        }
        if ($SyslogEnabled.IsPresent) { $Properties.Add("syslogEnabled", $true)}
        $rule = [PSCustomObject]$Properties

        $Rules += $rule

        try {
            $response = Set-MerakiApplianceInboundCellularFirewallRules -id $id -Rules $Rules
            return $response.rules
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Adds an inbound firewall rule to the network.
    .PARAMETER Policy
    'allow' or 'deny' traffic specified by this rule
    .PARAMETER protocol
    The type of protocol (must be 'tcp', 'udp', 'icmp', 'icmp6' or 'any')
    .PARAMETER SourcePort
    Comma-separated list of source port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER SourceCidr
    Comma-separated list of source IP address(es) (in IP or CIDR notation), or 'any' (note: FQDN not supported for source addresses)
    .PARAMETER DestinationCidr
    Comma-separated list of destination IP address(es) (in IP or CIDR notation), fully-qualified domain names (FQDN) or 'any'
    .PARAMETER DestinationPort
    Comma-separated list of destination port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER SyslogEnabled
    Log this rule to syslog (true or false, boolean value) - only applicable if a syslog has been configured (optional)
    .PARAMETER Comment
    Description of the rule (optional)
    #>
 }

 function Set-MerakiApplianceInboundFirewallRule() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [int]$RuleNumber,
        [ValidateSet('allow','deny')]
        [string]$Policy,
        [ValidateSet('tcp', 'udp', 'icmp', 'icmp6', 'any')]
        [string]$Protocol,
        [Alias('srcPort')]
        [string]$SourcePort,
        [ALias('srcCidr')]
        [string]$SourceCidr,
        [Alias('DestCidr')]
        [string]$DestinationCidr,
        [Alias('destPort')]
        [string]$DestinationPort,
        [switch]$SyslogEnabled,
        [string]$Comment
    )

    Begin {
        $Rules = @{}
    }

    Process {
        Get-MerakiApplianceInboundFirewallRules -id $id | ForEach-Object {
            $Rules.Add($_.RuleNumber, $_)
        }

        If ($Policy) {
            $Rules[$RuleNumber].Policy = $Policy
        }
        if ($Protocol) {
            $Rules[$RuleNumber].Protocol = $Protocol
        }
        if ($SourceCidr) {
            $Rules[$RuleNumber].srcCidr = $SourceCidr
        }
        if ($SourcePort) {
            $Rules[$RuleNumber].srcPort = $SourcePort
        }
        if ($DestinationCidr) {
            $Rules[$RuleNumber].destCidr = $DestinationCidr
        }
        if ($DestinationPort) {
            $Rules[$RuleNumber].destPort = $DestinationPort
        }
        if ($Comment) {
            $Rules[$RuleNumber].comment = $Comment
        }
        if ($SyslogEnabled) {
            $Rule[$RuleNumber].syslogEnabled = $true
        }

        $Rules = $Rules.Values

        try {
            $response = Set-MerakiApplianceInboundFirewallRules -id $Id -Rules $Rules
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Updates a single inbound firewall rule in the specified network.
    .PARAMETER Id
    The ID of the network.
    .PARAMETER RuleNumber
    The RuleNumber to update.
    .PARAMETER Policy
    'allow' or 'deny' traffic specified by this rule
    .PARAMETER protocol
    The type of protocol (must be 'tcp', 'udp', 'icmp', 'icmp6' or 'any')
    .PARAMETER SourcePort
    Comma-separated list of source port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER SourceCidr
    Comma-separated list of source IP address(es) (in IP or CIDR notation), or 'any' (note: FQDN not supported for source addresses)
    .PARAMETER DestinationCidr
    Comma-separated list of destination IP address(es) (in IP or CIDR notation), fully-qualified domain names (FQDN) or 'any'
    .PARAMETER DestinationPort
    Comma-separated list of destination port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER SyslogEnabled
    Log this rule to syslog (true or false, boolean value) - only applicable if a syslog has been configured (optional)
    .PARAMETER Comment
    Description of the rule (optional)
    #>
 }

 function Remove-MerakiApplianceInboundFirewallRule() {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory)]
        [string]$NetworkId,
        [Parameter(Mandatory)]
        [int]$RuleNumber
    )

    $Rules = Get-MerakiApplianceInboundFirewallRules -id $NetworkId | Where-Object {$_.RuleNUmber -ne $RuleNumber}

    if ($PSCmdlet.ShouldProcess("Inbound Firewall Rule number $RuleNumber", "Delete")) {
        try {
            $response = Set-MerakiApplianceInboundFirewallRules -id $NetworkId -Rules $Rules
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Deletes an inbound firewall rule.
    .PARAMETER NetworkId
    The ID of the network.
    .PARAMETER RuleNumber
    The rule number to remove.    
    #>
 }
#endregion

#region Firewalled Services
function Get-MerakiApplianceFirewalledService() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [ValidateSet('ICMP','web','SNMP')]
        [string]$Service
    )

    Begin {

        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/firewall/firewalledServices" -f $BaseURI, $Id
        if ($Service) {
            $Uri = "{0}/{1}" -f $Uri, $Service
        }
        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | Add-Member -MemberType NoteProperty -Name "NetworkId" -Value $Id
            return $response
        }
        catch {
            Throw $_
        }
    }
    <#
    .DESCRIPTION
    Retrieve the Appliance firewalled services.
    .PARAMETER Id
    The Id of the network.
    #>
}

function Set-MerakiApplianceFirewalledService() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$Service,
        [Parameter(Mandatory)]
        [ValidateSet('blocked', 'restricted', 'unrestricted')]
        [string]$Access,
        [ValidateScript({
            ($_ -and $Access -eq 'restricted') -or
            ((-not $_) -and ($Access -in 'blocked','unrestricted'))
        })]
        [string[]]$AllowedIps
    )

    Begin {
        $Headers = Get-Headers

        $_Body = @{
            access = $Access
        }
        if ($Access -eq 'restricted') {
            $_Body.Add("allowedIps", $AllowedIps)
        }

        $body = $_Body | ConvertTo-Json -Depth 3 -Compress
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/firewall/firewalledServices/{2}" -f $BaseURI, $Id, $Service

        try {
            $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
}
#endregion

#region L3 Firewall Rules
Function Get-MerakiApplianceL3FirewallRules() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$id
    )

    $Uri = "{0}/networks/{1}/appliance/firewall/l3FirewallRules" -f $BaseURI, $Id

    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
        $rules = $response.Rules
        $ruleId = 1
        $rules | Foreach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "RuleId" -Value $ruleId
            $RuleId += 1
        }
        return $rules
    } catch {
        Throw $_
    }
    <#
    .DESCRIPTION
    Retrieve the network appliance level 3 firewall rules.
    .PARAMETER id
    The network Id.
    #>
}

function Set-MerakiApplianceL3FirewallRules() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(
            Mandatory
        )]
        [psobject[]]$Rules
    )

    Begin {

        $Headers = Get-Headers

        # The below statements are used if rules are being copied from another network/

        # Remove the RuleNumber, NetworkId, and NetworkName property if they exist.
        $Rules = $Rules | Select-Object -Property * -ExcludeProperty RuleNumber, NetworkId, NetworkName
        

        # Remove the default rule if it exists.
        $Rules = $Rules | Where-Object {$_.comment -ne 'Default rule'}
    }

    Process {
    
        $Uri = "{0}/networks/{1}/appliance/firewall/l3FirewallRules" -f $BaseUri, $id
        $_body = @{
            "rules" = $Rules
        }
        $body = $_body | ConvertTo-Json -Depth 5 -Compress

        $Network = Get-MerakiNetwork -Id $Id
        try {
            $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            $Rules = $response.rules
            $Number = 1
            $Rules | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name 'NetworkId' -Value $Id
                $_ | Add-Member -MemberType NoteProperty -Name 'NetworkName' -Value $Network.Name
                $_ | Add-Member -MemberType NoteProperty -Name 'RuleNumber' -Value $Number
                $Number += 1
            }
            return $response.rules
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Removes the specified level 3 firewall rules from a network. (This is irreversible!)
    .PARAMETER Id
    The ID of the network.
    .PARAMETER Rules
    An array of firewall rules objects.
    .PARAMETER PassThru
    Returns the updated list of rules.
    #>
}

function Add-MerakiApplianceL3FirewallRule() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [ValidateSet('allow','deny')]
        [string]$Policy,
        [string]$Comment,
        [ValidateSet('tcp', 'udp', 'icmp', 'icmp6', 'any')]
        [string]$Protocol,
        [ValidateScript(
            {
                $subnetPart = $_.split("/")
                $_ -eq "any" -or ([IPAddress]$subnetPart[0] -is [IPAddress] -and $SubnetPart[1] -In 0..32)
            }
        )]
        [string]$SourceCIDR,
        [string]$SourcePort = 'any',
        [ValidateScript(
            {
                $subnetPart = $_.split("/")
                $_ -eq "any" -or [IPAddress]$subnetPart[0] -is [IPAddress] -and $SubnetPart[1] -In 0..32
            }
        )]
        [string]$DestinationCIDR,
        [string]$DestinationPort = 'any',
        [switch]$SyslogEnabled,
        [switch]$PassThru
    )
    
    Process {
        $Rules = Get-MerakiApplianceL3FirewallRules -id $Id 
        
        $Properties = [PSCustomObject]@{
            policy = $policy
            comment = $Comment
            protocol = $Protocol
            destPort = $DestinationPort
            destCidr = $DestinationCIDR
            srcPort = $SourcePort
            srcCidr = $SourceCIDR
            $RuleNumber = -1
            $NetworkId = "NA"
            $NetworkName = "NA"
        }
        If ($SyslogEnabled) {$Properties.Add("syslogEnabled", $true)}
        $Rule = [PSCustomObject]$Properties
        
        $Rules += $Rule
        try {
            $Rules = Set-MerakiApplianceL3FirewallRules -Id $Id -Rules $Rules
            return $Rules
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Add a Level 3 Firewall rule.
    .DESCRIPTION
    Adds a Level 3 firewall rule to a Meraki Appliance.
    .PARAMETER Id
    The Network ID.
    .PARAMETER Policy
    The Policy for this rule.
    .PARAMETER Comment
    Description of the rule.
    .PARAMETER Protocol
    The protocol to use
    .PARAMETER SourceCIDR
    Comma-separated list of source IP address(es) (in IP or CIDR notation), or 'any' (note: FQDN not supported for source addresses)
    .PARAMETER SourcePort
    Comma-separated list of source port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER DestinationCIDR
    Comma-separated list of destination IP address(es) (in IP or CIDR notation), fully-qualified domain names (FQDN) or 'any'
    .PARAMETER DestinationPort
    Comma-separated list of destination port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER SyslogEnabled
    Log this rule to syslog - only applicable if a syslog has been configured (optional)
    .PARAMETER PassThru
    Return the newly created rule.
    #>
}

function Set-MerakiApplianceL3FirewallRule() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory
        )]
        [string]$NetworkId,
        [int]$RuleNumber,
        [ValidateSet('allow','deny')]
        [string]$Policy,
        [string]$Comment,
        [ValidateSet('tcp', 'udp', 'icmp', 'icmp6', 'any')]
        [string]$Protocol,
        [ValidateScript(
            {
                $subnetPart = $_.split("/")
                [IPAddress]$subnetPart[0] -is [IPAddress] -and $SubnetPart[1] -In 0..32
            }
        )]
        [string]$SourceCIDR,
        [string]$SourcePort,
        [ValidateScript(
            {
                $subnetPart = $_.split("/")
                [IPAddress]$subnetPart[0] -is [IPAddress] -and $SubnetPart[1] -In 0..32
            }
        )]
        [string]$DestinationCIDR,
        [string]$DestinationPort,
        [switch]$SyslogEnabled
    )

    $Rules_ = @{}
    Get-MerakiApplianceL3FirewallRules -id $NetworkId | ForEach-Object {
        $Rules_.Add($_.RuleNumber, $_)
    }

    if (-not $Rule_[$RuleNumber]) {
        throw "Invalid Rule Id"
    }

    If ($Policy) {
        $Rules_[$RuleNumber].policy = $Policy
    }
    if ($Comment) {
        $Rules_[$RuleNumber].comment = $Comment
    }
    if ($Protocol) {
        $Rules_[$RuleNumber].protocol = $Protocol
    }
    if ($SourceCIDR) {
        $Rule_[$RuleNumber].srcCIDR - $SourceCIDR
    }
    if ($SourcePort) {
        $Rule_[$RuleNumber].srcPort = $SourcePort
    }
    if ($DestinationCIDR) {
        $Rule_[$RuleNumber].destCIDR = $DestinationCIDR
    }
    if ($DestinationPort) {
        $Rule_[$RuleNumber].destPort = $DestinationPort
    }
    if ($SyslogEnabled) {
        $Rule_[$RuleNumber].syslogEnabled = $SyslogEnabled
    }

    $Rules = $Rules_.Values

    try {
        $Rules = Set-MerakiApplianceL3FirewallRules -Id $Id -Rules $Rules
        return $Rules  
    } catch {
        throw $_
    }

    <#
    .SYNOPSIS
    Update an existing level 3 firewall rule.
    .DESCRIPTION
    Update an existing Level 3 firewall rule on a meraki Appliance.
    .PARAMETER NetworkId
    The Id of the network
    .PARAMETER RuleId
    The Id of the rule to update.
    .PARAMETER Policy
    allow' or 'deny' traffic specified by this rule
    .PARAMETER Comment
    Description of the rule (optional)
    .PARAMETER Protocol
    The type of protocol (must be 'tcp', 'udp', 'icmp', 'icmp6' or 'any')
    .PARAMETER SourceCIDR
    Comma-separated list of source IP address(es) (in IP or CIDR notation), or 'any' (note: FQDN not supported for source addresses)
    .PARAMETER SourcePort
    Comma-separated list of source port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER DestinationCIDR
    Comma-separated list of destination IP address(es) (in IP or CIDR notation), fully-qualified domain names (FQDN) or 'any'
    .PARAMETER DestinationPort
    Comma-separated list of destination port(s) (integer in the range 1-65535), or 'any'
    .PARAMETER SyslogEnabled
    Log this rule to syslog (true or false, boolean value) - only applicable if a syslog has been configured (optional)
    .PARAMETER 
    #>
}

function Remove-MerakiApplianceL3FirewallRule() {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory
        )]
        [string]$NetworkId,
        [Parameter(Mandatory)]
        [string]$RuleId,
        [switch]$PassThru
    )

    $Uri = "{0}/networks/{1}/appliance/firewall/l3FirewallRules" -f $BaseUri, $NetworkId

    $Headers = Get-Headers

    $Rules = Get-MerakiApplianceL3FirewallRules -id $NetworkId

    # Remove the Default Rule
    $Rules = $Rules | Where-Object {$_.comment -ne "Default rule"}

    $Rule = $Rules | Where-Object {$_.RuleId -eq $RuleId}
    if (-not $Rule) {
        throw "Invalid Rule Id"
    }

    # Remove the Rule to be deleted
    $Rules = $Rules | Where-Object {$_.RuleId -ne $RuleId}

    # Remove the Rule Property
    $Rules = $Rules | Select-Object -Property * -ExcludeProperty RuleId

    $_Body = @{rules = $Rules}

    $body = $_Body | ConvertTo-Json -Depth 5 -Compress
    if ($PSCmdlet.ShouldProcess("Rule:$($Rule.Comment)", "Delete")) {
        try {
            $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            return $response.rules
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION 
    Delete the specified level 3 firewall rule. (This cannot be undone!)
    .PARAMETER NetworkId
    The Id of the network.
    .PARAMETER RuleId
    The Rule Id to be deleted.
    .PARAMETER PassThru
    return the updated rules.
    #>
}
#endregion

#region L7 firewall rules
function Get-MerakiApplianceL7FirewallRules() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/firewall/l7FirewallRules" -f $BaseURI, $Id

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $Rules = $response.rules
            $Number = 1
            $Rules | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name 'NetworkId' -Value $Id
                $_ | Add-Member -MemberType NoteProperty -Name "RuleNumber" -Value $Number
                $Number += 1
            }
            return $Rules
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Returns the MX L7 firewall rules for an MX network.
    .PARAMETER Id
    The Id of the network.
    .OUTPUTS
    An array of level 7 firewall rules.    
    #>
}

function Set-MerakiApplianceL7FirewallRules() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [PsObject[]]$Rules
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/firewall/l7FirewallRules" -f $BaseURI, $Id

        # Remove the default rule if it exists
        $Rules = $Rules.where({$_.comment -ne 'Default rule'})

        # Remove the RuleNumber property
        $Rules = $Rules | Select-Object -ExcludeProperty RuleNumber

        $_Rules = @{
            rules = $Rules
        }

        $Body = $_Rules | ConvertTo-Json -Depth 4 -Compress

        try {
            $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $Body -PreserveAuthorizationOnRedirect
            return $response.rule
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Update the MX L7 firewall rules for an MX network
    .PARAMETER Id
    The ID of the network.
    .PARAMETER Rules
    An array of level 7 firewall rules.
    .OUTPUTS
    AN array of updated level 7 firewall rules.
    #>
}

function Add-MerakiApplianceL7FirewallRule() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory)]
        [ValidateSet('application', 'applicationCategory', 'host', 'port', 'ipRange')]
        [string]$Type,
        [Parameter(Mandatory)]
        [string]$Value
    )

    Begin {
        $Properties = @{
            policy      = 'deny'
            type        = $Type
            value       = $Value
            RuleNumber  = -1
            NetworkId = "NA"
            NetworkName = "NA"

        }
        $Rule = [PsCustomObject]$Properties        
    }

    Process {
        [array]$Rules = Get-MerakiApplianceL7FirewallRules -id $Id
        $Rules += $Rule

        try {
            $Rules = Set-MerakiApplianceL7FirewallRules -Id $Id -Rules $Rules
            return $Rules
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Add a new MX L7 firewall rules for an MX network.
    .PARAMETER Id
    The Id if the Network.
    .PARAMETER Type
    Type of the L7 rule. One of: 'application', 'applicationCategory', 'host', 'port', 'ipRange'
    .PARAMETER Value
    The 'value' of what you want to block. Format of 'value' varies depending on type of the rule. 
    The application categories and application ids can be retrieved from the the 
    'Get-MerakiNetworkApplianceApplicationCategories' endpoint. The countries follow the two-letter ISO 3166-1 alpha-2 format
    .OUTPUTS
    An array of Level 7 Firewall Rules
    #>
}

function Set-MerakiApplianceL7FirewallRule () {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [int]$RuleNumber,        
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('application', 'applicationCategory', 'host', 'port', 'ipRange')]
        [string]$Type,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Value
    )

    Process {
        $Rules_ = @{}
        Get-MerakiApplianceL7FirewallRules -id $Id| ForEach-Object {
            $Rules_.Add($_.RuleNumber, $_)            
        }

        if ($type) {
            $Rules_[$RuleNumber].type = $Type
        }
        if ($Value) {
            $Rules_[$RuleNumber].value = $Value
        }

        $Rules = $Rules_.Values

        try {
            $Rules = Set-MerakiApplianceL7FirewallRules -Id $Id -Rules $Rules
            return $Rules
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Update an MX L7 firewall rule for an MX network.
    .PARAMETER Id
    The ID of the network.
    .PARAMETER RuleNumber
    The rule number to update.
    .PARAMETER Type
    Type of the L7 rule. One of: 'application', 'applicationCategory', 'host', 'port', 'ipRange'
    .PARAMETER Value
    The 'value' of what you want to block. Format of 'value' varies depending on type of the rule. 
    The application categories and application ids can be retrieved from the the 
    'Get-MerakiNetworkApplianceApplicationCategories' endpoint. The countries follow the two-letter ISO 3166-1 alpha-2 format
    .OUTPUTS
    An array of Level 7 Firewall Rules
    #>
}

function Remove-MerakiApplianceL7FirewallRule() {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    Param (
        [Parameter(Mandatory)]
        [string]$NetworkId,
        [Parameter(Mandatory)]
        [string]$RuleNumber
    )

    $Rules = Get-MerakiApplianceL7FirewallRules -Id $NetworkId | Where-Object {$_.RuleNumber -ne $RuleNumber}

    if ($PSCmdlet.ShouldProcess("Level7 firewall rule number $RuleNumber", "Delete")) {
        try {
            $Rules = Set-MerakiApplianceL7FirewallRules -Id $NetworkId -Rules $Rules
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Deletes an MX L7 firewall rule for an MX network.
    .PARAMETER Id
    The ID of the network.
    .PARAMETER RuleNumber
    The rule number to update.
    .OUTPUTS
    An array of Level 7 Firewall Rules
    #>
}

Function Get-MerakiApplianceL7ApplicationCategories() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/firewall/l7FirewallRules/applicationCategories" -f $BaseURI, $Id

        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response.ApplicationCategories
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Return the L7 firewall application categories and their associated applications for an MX network.
    .PARAMETER Id
    The ID of the Network.
    .OUTPUTS
    An array of application category objects.
    #>
}
#endregion

#region Firewall NAR Rules
function Get-MerakiApplianceFirewallNatRules() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory)]
        [ValidateSet('OneToMany','OneToOne','PortForwarding')]
        [string]$Type
    )

    Begin {
        $Headers = Get-Headers
        switch ($type) {
            'OneToMany' {
                $Uri = "{0}/networks/{1}/appliance/firewall/oneToManyNatRules"
            }
            'OneToOne' {
                $Uri = "{0}/networks/{1}/appliance/firewall/oneToOneNatRules"
            }
            'PortForwarding'{
                $Uri = "{0}/networks/{networkId}/appliance/firewall/portForwardingRules"
            }
        }
    }

    Process {
        $Uri = $Uri -f $BaseURI, $Id

        $Network = Get-MerakiNetwork -NetworkId $Id

        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            [array]$Rules = $response.rules
            $number = 1
            $Rules | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name 'NetworkId' -Value $Id
                $_ | Add-Member -MemberType NoteProperty -Name 'NetworkName' -Value $Network.Name
                $_ | Add-Member -MemberType NoteProperty -Name 'RuleNumber' -Value $number
                $Number += 1
            }
            return $Rules
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Return the NAT mapping rules for an MX network
    .PARAMETER Id
    The ID of the network.
    .PARAMETER Type
    The type of mapping rule. One of OneToMany, OneToOne, or PortForwarding
    .OUTPUTS
    An array of NAT mapping rules.\
    #>
}

function Set-MerakiApplianceFirewallNatRules() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory)]
        [PsObject]$Rules,
        [Parameter(Mandatory)]
        [ValidateSet('OneToMany','OneToOne','PortForwarding')]
        [string]$Type
    )

    Begin {
        $Headers = Get-headers
        
        switch ($type) {
            'OneToMany' {
                $Uri = "{0}/networks/{1}/appliance/firewall/oneToManyNatRules"
            }
            'OneToOne' {
                $Uri = "{0}/networks/{1}/appliance/firewall/oneToOneNatRules"
            }
            'PortForwarding'{
                $Uri = "{0}/networks/{networkId}/appliance/firewall/portForwardingRules"
            }
        }
    }

    Process {
        $Uri = $Uri -f $BaseURI, $Id

        # Remove the RuleNumber, NetworkId, and NetworkName properties.
        [array]$Rules = $Rules | Select-Object -ExcludeProperty RuleNumber, NetworkName, NetworkId
        $Rules_ = @{
            rules = $Rules
        }

        $Body = $Rules_ | ConvertTo-Json -Depth 10 #-Compress

        $Network = Get-MerakiNetwork -networkID $Id

        try {
            $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $Body
            $Rules = $response.rules
            $Number = 1
            $Rules | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name 'NetworkId' -Value $Id
                $_ | Add-Member -MemberType NoteProperty -Name 'NetworkName' -Value $Network.name
                $_ | Add-Member -MemberType NoteProperty -Name 'RuleNumber' -Value $number
                $number += 1
            }

            Return $Rules
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Set the one to many NAT mapping rules for an MX network/
    .PARAMETER Id
    The Id of the network.
    .PARAMETER Rules
    An array of mapping rules. This object depends on the rule type. Incompatible rule(s) fo the specified type will throw an error.
    .PARAMETER Type
    The type of mapping rule. One of OneToMany, OneToOne, or PortForwarding
    .OUTPUTS an array of NAT Mapping Rules
    .NOTES
    The Rules collection varies depending on the type of rules being written.
    This parameter can accept either a PSCustomObject or a HashTable

    One to Many rules consist of the following Schema: * = required
    publicIp*: string The IP address that will be used to access the internal resource from the WAN
    uplink*: string The physical WAN interface on which the traffic will arrive ('internet1' or, if available, 'internet2')
    portRules*: array[] An array of associated forwarding rules with the following properties:
        localIp: string Local IP address to which traffic will be forwarded
        localPort: string Destination port of the forwarded traffic that will be sent from the MX to the specified host on the LAN. If you simply wish to forward the traffic without translating the port, this should be the same as the Public port
        name: string A description of the rule
        protocol: string 'tcp' or 'udp'
        publicPort: string Destination port of the traffic that is arriving on the WAN
        allowedIps: array[] Remote IP addresses or ranges that are permitted to access the internal resource via this port forwarding rule, or 'any'

    One To One Mapping rules consist of the following schema: * = required
    lanIp*: string The IP address of the server or device that hosts the internal resource that you wish to make available on the WAN
    name: string A descriptive name for the rule
    publicIp: string The IP address that will be used to access the internal resource from the WAN
    uplink: string The physical WAN interface on which the traffic will arrive ('internet1' or, if available, 'internet2')
    allowedInbound: array[] The ports this mapping will provide access on, and the remote IPs that will be allowed access to the resource
        protocol: string Either of the following: 'tcp', 'udp', 'icmp-ping' or 'any'
        allowedIps: array[] An array of ranges of WAN IP addresses that are allowed to make inbound connections on the specified ports or port ranges, or 'any'
        destinationPorts: array[] An array of ports or port ranges that will be forwarded to the host on the LAN

    Port Forwarding rules consist of the following schema: * = required
    lanIp*: string The IP address of the server or device that hosts the internal resource that you wish to make available on the WAN
    localPort*: string A port or port ranges that will receive the forwarded traffic from the WAN
    name: string A descriptive name for the rule
    protocol*: string TCP or UDP. Valid values are 'tcp', 'udp' 
    publicPort*: string A port or port ranges that will be forwarded to the host on the LAN
    uplink: string The physical WAN interface on which the traffic will arrive ('internet1' or, if available, 'internet2' or 'both')    
    allowedIps*: array[] An array of ranges of WAN IP addresses that are allowed to make inbound connections on the specified ports or port ranges (or any)
    #>
}

function Add-MerakiApplianceFirewallNatRule() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory)]
        [ValidateSet('OneToMany','OneToOne','PortForwarding')]
        [string]$Type,
        [ValidateScript({
            ($_ -and $Type -eq 'OneToMany') -or ($_ -and $Type -eq 'OneToOne')
        }, ErrorMessage = 'Property PublicIp is invalid for a PortForwarding rule')]
        [string]$PublicIp,
        [Parameter(Mandatory)]
        [ValidateSet('internet1', 'internet2')]
        [string]$Uplink,
        [ValidateScript({
            $_ -and $Type -eq 'OneToMany'
        }, ErrorMessage = 'Parameter PortRules is only valid for a OneToMany Rule')]        
        [PsObject[]]$PortRules,
        [ValidateScript({
            ($_ -and $Type -eq 'OneToOne') -or ($_ -and $type -eq 'PortForwarding')
        }, ErrorMessage = 'Parameter LanIp is invalid for a OneToMany rule.')]
        [string]$LanIp,
        [ValidateScript({
            ($_ -and $Type -eq 'OneToOne') -or ($_ -and $Type -eq 'PortForwarding')
        }, ErrorMessage = 'Parameter Name is invalid for a OneToMany rule.')]
        [string]$Name,
        [ValidateScript({
            $_ -and $Type -eq 'OneToOne'
        }, ErrorMessage = 'Parameter AllowedInbound is only valid for a OneToMany rule')]
        [PsObject]$AllowedInbound,
        [ValidateScript({
            $_ -and $Type -eq 'PortForwarding'
        }, ErrorMessage = 'Parameter Protocol is only valid for a PortForwarding rule.')]
        [ValidateSet('tcp','udp')]
        [string]$Protocol,
        [ValidateScript({
            $_ -and $Type -eq 'PortForwarding'
        }, ErrorMessage = 'Parameter PublicPort is only valid for a PortForwarding rule.')]
        [string]$PublicPort,
        [ValidateScript({
            $_ -and $Type -eq 'PortForwarding'
        }, ErrorMessage = 'Parameter LocalPort is only valid for a PortForwarding rule.')]
        [string]$LocalPort,
        [ValidateScript({
            $_ -and $Type -eq 'PortForwarding'
        }, ErrorMessage = 'Parameter AllowedIps is only valid for a PortForwarding rule.')]
        [string[]]$AllowedIps
    )

    Begin {

        switch ($Type) {
            'OneToMany' {
                $Properties = @{
                    publicIp    = $PublicIP
                    uplink      = $Uplink
                    portRules   = $PortRules
                    RuleNumber  = -1
                    NetworkId   = 'NA'
                    NetworkName = 'NA'
                }
                $Rule = [PSCustomObject]$Properties
            }
            'OneToOne' {
                $Properties = @{
                    publicIp        = $PublicIP
                    uplink          = $Uplink
                    lanIp           = $lanIp
                    name            = $Name
                    allowedInbound  = $AllowedInbound
                    RuleNNumber     = -1
                    NetworkId       = 'NA'
                    NetworkName     = 'NA'
                }
                $Rule = [PSCustomObject]$Properties
            }
            'PortForwarding' {
                $Properties = @{
                    lanIp       = $lanIp
                    localPort   = $LocalPort
                    name        = $Name
                    protocol    = $Protocol
                    publicPort  = $PublicPort
                    uplink      = $Uplink
                    allowedIps  = $AllowedIps
                    RuleNumber  = -1
                    NetworkId   = 'NA'
                    NetworkName = 'NA'
                }
            }
        }        
    }

    Process {
        $Rules = Get-MerakiApplianceFirewallNatRules -Id $Id -Type $Type
        if ($Rules) {
            $Rules += $Rule
        } else {
            $Rules = @($Rule)
        }
        try{
            $Rules = Set-MerakiApplianceFirewallNatRules -Id $Id -Type $Type -Rules $Rules
            return $Rules
        } catch {
            throw $_
        }    
    }
    <#
    .DESCRIPTION
    Add a One to Many NAT mapping rule to an MX network
    .PARAMETER Id
    The Id of tye network.
    .PARAMETER Type
    The type of rule, can be one of: 'OneToMany','OneToOne',or 'PortForwarding'
    .PARAMETER PublicIP
    The IP address that will be used to access the internal resource from the WAN.
    This parameter is only valid for for OneToMany and OneToOne rules.
    .PARAMETER Uplink
    The physical WAN interface on which the traffic will arrive ('internet1' or, if available, 'internet2')    
    .PARAMETER PortRules
    An array of associated forwarding rules with the following properties:
        localIp: string Local IP address to which traffic will be forwarded
        localPort: string Destination port of the forwarded traffic that will be sent from the MX to the specified host on the LAN. If you simply wish to forward the traffic without translating the port, this should be the same as the Public port
        name: string A description of the rule
        protocol: string 'tcp' or 'udp'
        publicPort: string Destination port of the traffic that is arriving on the WAN
        allowedIps: array[] Remote IP addresses or ranges that are permitted to access the internal resource via this port forwarding rule, or 'any'

        This property can be either a PsObject or a HashTable
        This property is only valid for OneToMany rules.
    .PARAMETER LanIp
    The IP address of the server or device that hosts the internal resource that you wish to make available on the WAN
    This parameter is only valid for OneToOne or PortForwarding rules.
    .PARAMETER Name
    A descriptive name for the rule.
    This parameter is only valid for OneToOne or PortForwarding rules.
    .PARAMETER AllowedInbound
    The ports this mapping will provide access on, and the remote IPs that will be allowed access to the resource
    The parameter is only valid for OneToMany rules.
    .PARAMETER Protocol
    TCP or UDP. Valid values are 'tcp', 'udp'
    The parameter is only valid for PortForwarding rules.
    .PARAMETER PublicPort
    A port or port ranges that will be forwarded to the host on the LAN.
    The parameter is only valid for PortForwarding rules.
    .PARAMETER LocalPort
    A port or port ranges that will receive the forwarded traffic from the WAN
    The parameter is only valid for PortForwarding rules.
    .PARAMETER AllowedIps
    An array of ranges of WAN IP addresses that are allowed to make inbound connections on the specified ports or port ranges (or any)
    The parameter is only valid for PortForwarding rules.
    .OUTPUTS
    An array of One top Many Firewall NAT rules
    #>
}

Function Set-MerakiApplianceFirewallNatRule() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory)]
        [int]$RuleNumber,
        [Parameter(Mandatory)]
        [ValidateSet('OneToMany','OneToOne','PortForwarding')]
        [string]$Type,
        [ValidateScript({
            ($_ -and $Type -eq 'OneToMany') -or ($_ -and $Type -eq 'OneToOne')
        }, ErrorMessage = 'Property PublicIp is invalid for a PortForwarding rule')]
        [string]$PublicIp,
        [Parameter(Mandatory)]
        [ValidateSet('internet1', 'internet2')]
        [string]$Uplink,
        [ValidateScript({
            $_ -and $Type -eq 'OneToMany'
        }, ErrorMessage = 'Parameter PortRules is only valid for a OneToMany Rule')]
        [Parameter(Mandatory)]
        [PsObject[]]$PortRules,
        [ValidateScript({
            ($_ -and $Type -eq 'OneToOne') -or ($_ -and $type -eq 'PortForwarding')
        }, ErrorMessage = 'Parameter LanIp is invalid for a OneToMany rule.')]
        [string]$LanIp,
        [ValidateScript({
            ($_ -and $Type -eq 'OneToOne') -or ($_ -and $Type -eq 'PortForwarding')
        }, ErrorMessage = 'Parameter Name is invalid for a OneToMany rule.')]
        [string]$Name,
        [ValidateScript({
            $_ -and $Type -eq 'OneToMany'
        }, ErrorMessage = 'Parameter AllowedInbound is only valid for a OneToMany rule')]
        [PsObject]$AllowedInbound,
        [ValidateScript({
            $_ -and $Type -eq 'PortForwarding'
        }, ErrorMessage = 'Parameter Protocol is only valid for a PortForwarding rule.')]
        [ValidateSet('tcp','udp')]
        [string]$Protocol,
        [ValidateScript({
            $_ -and $Type -eq 'PortForwarding'
        }, ErrorMessage = 'Parameter PublicPort is only valid for a PortForwarding rule.')]
        [string]$PublicPort,
        [ValidateScript({
            $_ -and $Type -eq 'PortForwarding'
        },ErrorMessage = 'Parameter LocalPort is only valid for a PortForwarding rule.')]
        [string]$LocalPort,
        [ValidateScript({
            $_ -and $Type -eq 'PortForwarding'
        }, ErrorMessage = 'Parameter AllowedIps is only valid for a PortForwarding rule.')]
        [string[]]$AllowedIps

    )

    $Rules_ = @{}
    Get-MerakiApplianceFirewallNatRules -Id $NetworkId -Type $Type | ForEach-Object {
        $Rules_.Add($_.RuleNumber, $_)
    }
    if ($PublicIP) {
        $Rules_[$RuleNumber].publicIp = $PublicIP
    }
    if ($Uplink) {
        $Rules_[$RuleNumber].Uplink = $Uplink
    }
    if ($PortRules) {
        $Rules_[$RuleNumber].portRules = $PortRules
    }                
    if ($PublicIp) {
        $Rules_[$RuleNumber].PublicIp = $PublicIp
    }
    if ($Uplink) {
        $Rules_[$RuleNumber].Uplink = $Uplink
    }
    if ($LanIp) {
        $Rules_[$RuleNumber].lanIp = $LanIp
    }
    if ($Name) {
        $Rules_[$RuleNumber].Name = $Name
    }
    if ($AllowedInbound) {
        $Rules_[$RuleNumber].allowedInbound = $AllowedInbound
    }
    if ($LocalPort) {
        $Rules_[$RuleNumber].localPort = $LocalPort
    }
    if ($PublicPort) {
        $Rules_[$RuleNumber].publicPort = $PublicPort
    }
    if ($AllowedIps) {
        $Rules_[$RuleNumber].allowedIps = $AllowedIps
    }

    try {
        $Rules = Set-MerakiApplianceFirewallNatRules -Id $Id -Type $Type -Rules $Rules.Values
        return $Rules
    } catch {
        throw $_
    }
    <#
    .DESCRIPTION
    Add a One to Many NAT mapping rule to an MX network
    .PARAMETER Id
    The Id of tye network.
    .PARAMETER RuleNumber
    The rule number oto be updated.
    .PARAMETER Type
    The type of rule, can be one of: 'OneToMany','OneToOne',or 'PortForwarding'
    .PARAMETER PublicIP
    The IP address that will be used to access the internal resource from the WAN.
    This parameter is only valid for for OneToMany and OneToOne rules.
    .PARAMETER Uplink
    The physical WAN interface on which the traffic will arrive ('internet1' or, if available, 'internet2')    
    .PARAMETER PortRules
    An array of associated forwarding rules with the following properties:
        localIp: string Local IP address to which traffic will be forwarded
        localPort: string Destination port of the forwarded traffic that will be sent from the MX to the specified host on the LAN. If you simply wish to forward the traffic without translating the port, this should be the same as the Public port
        name: string A description of the rule
        protocol: string 'tcp' or 'udp'
        publicPort: string Destination port of the traffic that is arriving on the WAN
        allowedIps: array[] Remote IP addresses or ranges that are permitted to access the internal resource via this port forwarding rule, or 'any'

        This property can be either a PsObject or a HashTable
        This property is only valid for OneToMany rules.
    .PARAMETER LanIp
    The IP address of the server or device that hosts the internal resource that you wish to make available on the WAN
    This parameter is only valid for OneToOne or PortForwarding rules.
    .PARAMETER Name
    A descriptive name for the rule.
    This parameter is only valid for OneToOne or PortForwarding rules.
    .PARAMETER AllowedInbound
    The ports this mapping will provide access on, and the remote IPs that will be allowed access to the resource
    The parameter is only valid for OneToMany rules.
    .PARAMETER Protocol
    TCP or UDP. Valid values are 'tcp', 'udp'
    The parameter is only valid for PortForwarding rules.
    .PARAMETER PublicPort
    A port or port ranges that will be forwarded to the host on the LAN.
    The parameter is only valid for PortForwarding rules.
    .PARAMETER LocalPort
    A port or port ranges that will receive the forwarded traffic from the WAN
    The parameter is only valid for PortForwarding rules.
    .PARAMETER AllowedIps
    An array of ranges of WAN IP addresses that are allowed to make inbound connections on the specified ports or port ranges (or any)
    The parameter is only valid for PortForwarding rules.
    .OUTPUTS
    An array of One top Many Firewall NAT rules
    #>
}

function Remove-MerakiApplianceFirewallNatRule {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory)]
        [string]$NetworkId,
        [Parameter(Mandatory)]
        [ValidateSet('OneToMany','OneToOne','PortForwarding')]
        [string]$Type,
        [Parameter(Mandatory)]
        [int]$RuleNumber
    )

    $Rules = Get-MerakiApplianceFirewallNatRules -Id $Id -Type $Type
    
    $Rules = $Rules.Where({$_.RuleNumber -ne $RuleNumber})

    if ($PSCmdlet.ShouldProcess("$Type rule number $RuleNumber", "Delete")) {
        try {
            $Rules = Set-MerakiApplianceFirewallNatRules -Id $Id -Type OneToMany -Rules $Rules
            return $Rules
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION 
    Deletes a One To Many firewall NAT rule
    .PARAMETER NetworkId
    The Id of the network.
    .PARAMETER RuleNumber
    The rule number to delete
    #>
}
#endregion

#region prefixes
function Get-MerakiApplianceDelegatesStaticPrefixes() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/prefixes/delegated/statics" -f $BaseURI, $Id

        Try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name 'NetworkId' -Value $Id
            }
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Retrieves static delegated prefixes for a network.
    .PARAMETER Id
    The Id of the network.
    .OUTPUTS
    An array of static prefixes.
    #>

 
}
function Get-MerakiApplianceDelegatesStaticPrefix() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$PrefixId
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/prefixes/delegated/statics/{2}" -f $BaseURI, $id, $PrefixId

        try {
            $response = Invoke-RestMethod -Method Get -URI $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name 'NetworkId' -Value $Id                
            }
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Return a static delegated prefix from a network
    .PARAMETER Id
    The ID of the network.
    .PARAMETER PrefixId
    The Static Prefix Id.
    .OUTPUTS
    A Delegated Static prefix object.
    #>
}

function Add-MerakiApplianceDelegatedStaticPrefix() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [string]$Description,
        [Parameter(Mandatory)]
        [string]$Prefix,
        [Parameter(Mandatory)]
        [ValidateSet('independent', 'internet')]
        [string]$Type,
        [Parameter(Mandatory)]
        [string[]]$Interfaces
    )

    Begin {
        $Headers = Get-Headers

        $_Body = @{
            prefix = $Prefix
            origin = @{
                type = $Type
                interfaces = $Interfaces
            }
        }

        if ($Description) {
            $_Body.Add("description", $Description)
        }

        $body = $_Body | ConvertTo-Json -Depth 4 -Compress
    }

    Process{
        $Uri = "{0}/networks/{1}/appliance/prefixes/delegated/statics" -f $BaseURI, $Id 

        try {
            $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            $response | Add-Member -MemberType NoteProperty -Name 'NetworkId' -Value $Id
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Add a static delegated prefix from a network
    .PARAMETER Id
    The Id of the network.
    .PARAMETER Description
    A name or description for the prefix
    .PARAMETER Prefix
    A static IPv6 prefix
    .PARAMETER Type
    Type of the origin. Valid values are 'independent', 'internet'
    .PARAMETER Interfaces
    An array of interfaces associated with the prefix. i.e. 'wan1'
    .OUTPUTS
    A delegated static prefix object.
    #>    
}

function Set-MerakiApplianceDelegatedStaticPrefix() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$PrefixId,
        [string]$Description,
        [string]$Prefix,
        [ValidateSet('independent', 'internet')]
        [string]$Type,
        [string[]]$Interfaces
    )

    Begin {
        $Headers = Get-Headers
        
        $_Body = @{}
        if ($Description) {
            $_Body.Add("description", $Description)
        }
        if ($Prefix) {
            $_Body.Add("prefix", $Prefix)
        }
        if ($Type) {
            $_Body['origin'].type = $Type
        }
        if ($Interfaces) {
            $_Body['origin'].interfaces = $Interfaces
        }

        $body = $_Body | ConvertTo-Json -Depth 4 -Compress
    }

    Process {
        $Uri = "{0}/networks/{networkId}/appliance/prefixes/delegated/statics/{staticDelegatedPrefixId}" -f $BaseURI, $Id, $PrefixId

        try {
            $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            $response | Add-Member -MemberType NoteProperty -Name 'NetworkId' -Value $Id
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Update a static delegated prefix from a network.
    .PARAMETER Id
    The ID of the network.
    .PARAMETER PrefixId
    The Prefix Id.
    .PARAMETER Prefix
    A static IPv6 prefix
    .PARAMETER Type
    Type of the origin. Valid values are 'independent', 'internet'
    .PARAMETER Interfaces
    An array of interfaces associated with the prefix. i.e. 'wan1'
    .OUTPUTS
    A delegated static prefix object.   
    #>
}

function Remove-MerakiApplianceDelegatedStaticPrefix() {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory)]
        [string]$NetworkId,
        [Parameter(Mandatory)]
        [string]$PrefixId
    )

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/appliance/prefixes/delegated/statics/{2}" -f $BaseURI, $Id, $PrefixId

    if ($PSCmdlet.ShouldProcess("Static Prefix ID $PrefixId", "Delete")) {
        $response = Invoke-RestMethod -Method Delete -Uri $Uri -Headers $Headers
        return $response
    } catch {
        throw $_
    }
    <#
    .DESCRIPTION
    Delete a static delegated prefix from a network
    .PARAMETER NetworkId
    The ID of te network
    .PARAMETER PrefixId
    The Prefix Id
    .OUTPUTS
    HTTP response, response status 204 = success.
    #>
}
#endregion

#region IntrusionMalware
function Get-MerakiApplianceSecurityIntrusion() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/security/intrusion" -f $BaseURI, $Id

        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Returns all supported intrusion settings for an organization
    .PARAMETER Id
    The ID of the network.
    .OUTPUTS
    An intrusion settings object.
    #>
}

function Set-MerakiApplianceSecurityIntrusion() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,        
        [ValidateSet('connectivity','balanced','security')]
        [string]$IdsRuleSets,
        [ValidateSet('disabled','detection','prevention' )]
        [string]$Mode,
        [Parameter(ParameterSetName = "default")]
        [switch]$UseDefault,
        [Parameter(ParameterSetName = 'non-default')]
        [string[]]$ExcludeCidr,
        [Parameter(ParameterSetName = 'non-default')]
        [string[]]$IncludeCidr
    )

    Begin {
        $_Body = @{}

        if ($IdsRuleSets) {
            $_Body.Add("idsRuleSets", $IdsRuleSets)
        }
        if ($Mode) {
            $_Body.add("mode", $Mode)
        }
        if ($UseDefault.IsPresent) {
            $_Body["protectedNetworks"].useDefault = $true
        }
        if ($ExcludeCidr) {
            $_Body["protectedNetworks"].excludeCidr = $ExcludeCidr
        }
        if ($IncludeCidr) {
            $_Body["protectedNetworks"].includeCidr = $IncludeCidr
        }

        $body = $_Body | ConvertTo-Json -Depth 4 -Compress
    }    

    Process {
        $Uri = "{0}/networks/{1}/appliance/security/intrusion" -f $BaseURI, $Id

        try {
            $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Set the supported intrusion settings for an MX network
    .PARAMETER Id
    The ID of the Network.
    .PARAMETER IdsRuleSets
    Set the detection ruleset 'connectivity','balanced','security' (optional - omitting will leave current config unchanged). 
    Default value is 'balanced' if none currently saved
    .PARAMETER Mode
    Set mode to 'disabled','detection','prevention' (optional - omitting will leave current config unchanged)
    .PARAMETER UseDefault
    Whether to use special IPv4 addresses: https://tools.ietf.org/html/rfc5735 (required). Default value is true if none currently saved.
    .PARAMETER ExcludeCidr
    List of IP addresses or subnets being excluded from protection (required if 'useDefault' is false)
    .PARAMETER IncludeCidr
    list of IP addresses or subnets being protected (required if 'useDefault' is false)
    #>
}

function Get-MerakiApplianceSecurityMalwareSettings() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/security/malware" -f $BaseURI, $Id

        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $number = 1
            $response.AllowedFiles | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name 'Number' -Value $number
                $number += 1
            }
            $number = 1
            $response.AllowedUrls | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name 'Number' -Value $number
                $number += 1
            }
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Returns all supported malware settings for an MX network.
    .PARAMETER Id
    The ID of the network.
    .OUTPUTS
    A malware settings object
    #>
}

function Set-MerakiApplianceSecurityMalwareSettings() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory)]
        [bool]$Enabled,
        [PsObject[]]$AllowedFiles,
        [PsObject[]]$AllowedUrls
    )

    Begin {
        $Headers = Get-Headers

        if ($Enabled.IsPresent) {
            $_Body = @{
                mode = 'enabled'
            }

            if ($AllowedFiles) {
                $_Body.Add("allowedFiles", $AllowedFiles)
            }

            if ($AllowedUrls) {
                $_Body.Add("allowedUrls", $AlloweeUrls)
            }
        } else {
            $_Body = @{
                mode = 'disabled'
                allowedFiles = @()
                allowedUrls = @()
            }
        }

        $body = $_Body | ConvertTo-Json -Depth 4 -Compress
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/security/malware" -f $BaseURI, $id

        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -Body $body  -PreserveAuthorizationOnRedirect
            $number = 1
            $response.AllowedFiles | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name 'Number' -Value $number
                $number += 1
            }
            $number = 1
            $response.AllowedUrls | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name 'Number' -Value $number
                $number += 1
            }         
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Set the supported malware settings for an MX network
    .PARAMETER Id
    The Id of the network.
    .PARAMETER Enabled
    Set the malware prevention to enabled or disabled. Setting this to false will clear the AllowedFiles and AllowedUrl settings.
    .PARAMETER AllowedFiles
    An array of allowed file Objects. Properties are:
        comment*: string Comment about the allowed entity
        sha256*: string The file sha256 hash to allow
    .PARAMETER AllowedUrls
    An array of allowed Url objects Properties are:
        comment*: string Comment about the allowed entity
        url*: string The url to allow
    #>
}

#endregion

#region Single Lan
function Get-MerakiApplianceSingleLan() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$id
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/singleLan" -f $BaseURI, $Id

        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Return single LAN configuration.
    .PARAMETER id
    The id of the Network.
    .OUTPUTS
    A single LAN configuration object.
    #>
}

function Set-MerakiApplianceSingleLan() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param (
        [Parameter(Mandatory)]
        [string]$NetworkId,
        [string]$ApplianceIp,
        [string]$subnet,
        [Parameter(ParameterSetName = 'ipv6')]
        [switch]$Ipv6Enabled,
        [Parameter(ParameterSetName = 'ipv6')]
        [PSObject[]]$Ipv6PrefixAssignments,
        [switch]$MandatoryDHCP
    )

    $_Body = @{}

    if ($ApplianceIp) {
        $_Body.Add("applianceIp", $ApplianceIp)
    }
    if ($subnet) {
        $_.Body.Add("subnet", $subnet)
    }
    if ($Ipv6Enabled.IsPresent) {
        $_Body['ipv6'].Enabled = $true
    }
    if ($Ipv6PrefixAssignments) {
        $_Body['ipv6'].prefixAssignments = $Ipv6PrefixAssignments
    }
    if ($MandatoryDHCP.IsPresent) {
        $Body['mandatoryDhcp'].Enabled = $true
    }

    $body = $_Body | ConvertTo-Json
    
    $Uri = "{0}/networks/{networkId}/appliance/singleLan" -f $BaseURI, $Id
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .DESCRIPTION
    Return single LAN configuration
    .PARAMETER NetworkId
    The Id of the Network.
    .PARAMETER ApplianceIp
    The local IP of the appliance on the single LAN
    .PARAMETER subnet
    The subnet of the single LAN
    .PARAMETER Ipv6Enabled
    Enable IPv6 on single LAN
    .PARAMETER Ipv6PrefixAssignments
    An array of Ipv6 prefix assignments on the single LAN.
    .PARAMETER MandatoryDHCP
    Mandatory DHCP will enforce that clients connecting to this single LAN must use the IP address assigned by the DHCP server. Clients who use a static IP address won't be able to associate.
    #>
}
#endregion

#region SSIDs
function Get-MerakiApplianceSSID() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [int]$SsidNumber
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/ssids" -f $BaseURI, $Id
        if ($SsidNumber) {
            $Uri = "{0}/{1}" -f $Uri, $SsidNumber
        }

        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Return the SSID(s) in this network
    .PARAMETER Id
    The IDof the network
    .PARAMETER SsidNumber
    The ssid number to return a single ssid.
    .OUTPUTS
    A single or an array of SSID objects
    #>
}

Set-Alias -Name Get-MerakiApplianceSSIDs -Value Get-MerakiApplianceSSID -Option ReadOnly

function Set-MerakiApplianceSSID() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('SSIDNumber')]
        [int]$Number,
        [string]$Name,
        [bool]$Enabled,
        [int]$DefaultVlanId,
        [ValidateSet('8021x-meraki', '8021x-radius', 'open', 'psk')]
        [string]$AuthMode,
        [ValidateSet('wep', 'wpa')]
        [ValidateScript({
            $_ -and $AuthMode -eq 'psk'
        })]
        [string]$EncryptionMode,
        [ValidateScript({
            $_ -and $AuthMode -eq 'psk'
        }, ErrorMessage = "Parameter Passkey is only valid when AuthMode = 'psk'")]
        [string]$Passkey,
        [ValidateSet('WPA1 and WPA2', 'WPA2 only', 'WPA3 Transition Mode', 'WPA3 only')]
        [ValidateScript({
            ($_ -and ($AuthMode -eq 'psk' -and $EncryptionMode -eq 'wpa')) -or
            ($_ -and $AuthMode -in '8021x-meraki','8021x-radius')
        }, ErrorMessage = "The parameter WpaEncryptionMOde is only valid if (1) the AuthMode is 'psk' & the EncryptionMode is 'wpa' OR (2) the AuthMode is '8021x-meraki' OR (3) the authMode is '8021x-radius'")]
        [string]$WpaEncryptionMode,
        [switch]$Hide,
        [switch]$DhcpEnforcedDeAuthentication,
        [switch]$Dot11wEnabled,
        [switch]$Dot11wRequired,
        [ValidateScript({
            $_ -and $AuthMode -eq '8021x-radius'
        })]
        [PsObject]$RadiusServers
    )

    Begin {
        $Headers = Get-Headers

        $_Body = @{}
        if ($Name) {
            $_Body.Add("Name", $Name)
        }
        if ($Enabled) {
            $_Body.Add("enabled", $Enabled)
        }
        if ($DefaultVlanId) {
            $_Body.Add("defaultVlanId",$DefaultVlanId)
        }
        if ($AuthMode) {
            $_Body.Add("authMode", $AuthMode)
        }
        if ($Passkey) {
            $_Body.Add("Psk", $Passkey)
        }
        if ($EncryptionMode) {
            $_Body.Add("encryptionMode", $EncryptionMode)
        }
        if ($Hide.IsPresent) {
            $_Body.Add("visible", $False)
        } else {
            $_Body.Add("visible", $true)
        }
        if ($DhcpEnforcedDeAuthentication) {
            $_Body.Add("dhcpEnforceDeauthentication",@{
                enabled = $true
            })
        }
        if ($Dot11wEnabled) {
            $_Body["dot11w"].enabled = $true
        }
        if ($Dot11wRequired) {
            $_Body["dot11w"].required = $true
        }
        if ($RadiusServers) {
            $_Body.Add("radiusServers", $RadiusServers)
        }

        $body = $_Body | ConvertTo-Json -Depth 6 -Compress
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/ssids/{2}" -f $BaseURI, $Id, $Number
        try {
            $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Update the attributes of an MX SSID
    .PARAMETER Id
    The Id of the network.
    .PARAMETER Number
    The number of the ssid.
    .PARAMETER Name
    The name of the ssid.
    .PARAMETER Enabled
    Enable or disable an ssid.
    .PARAMETER DefaultVlanId
    The default VLAN for the ssid.
    .PARAMETER AuthMode
    The association control method for the SSID ('open', 'psk', '8021x-meraki' or '8021x-radius').
    .PARAMETER EncryptionMode
    The psk encryption mode for the SSID ('wep' or 'wpa'). This param is only valid if the authMode is 'psk'.
    .PARAMETER Passkey
    The passkey for the SSID. This param is only valid if the authMode is 'psk'.
    .PARAMETER WpaEncryptionMode
    The types of WPA encryption. ('WPA1 and WPA2', 'WPA2 only', 'WPA3 Transition Mode' or 'WPA3 only'). This param is only valid if (1) the authMode is 'psk' & the encryptionMode is 'wpa' OR (2) the authMode is '8021x-meraki' OR (3) the authMode is '8021x-radius'
    .PARAMETER Hide
    Hide this SSID. Omitting this parameter will make the ssid visible.
    .PARAMETER DhcpEnforcedDeAuthentication
    DHCP Enforced Deauthentication enables the disassociation of wireless clients in addition to Mandatory DHCP. This param is only valid on firmware versions >= MX 17.0 where the associated LAN has Mandatory DHCP Enabled.
    .PARAMETER Dot11wEnabled
    Enable 802.11w
    .PARAMETER Dot11wRequired
    Require 802.11w
    .PARAMETER RadiusServers
    The RADIUS 802.1x servers to be used for authentication. This param is only valid if the authMode is '8021x-radius'.
    .OUTPUTS
    An SSID Object.
    #>
}
#endregion

#region WarmSpare
function Get-MerakiApplianceWarmSpare() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{2}/appliance/warmSpare/swap" -f $BaseURI, $Id

        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Return MX warm spare settings
    .PARAMETER Id
    The Id of the network.
    .OUTPUTS
    An appliance warm spare object
    #>
}

function Set0MerakiApplianceWarmSpare() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [bool]$Enabled,
        [string]$SpareSerial,
        [ValidateSet('virtual','public')]
        [string]$UplinkMode,
        [string]$Wan1Ip,
        [string]$Wan2Ip
    )

    Begin {
        $Headers = Get-Headers

        $_Body = @{}
        if ($Enable) {
            $_Body.Add("enabled", $Enabled)
        }
        if ($SpareSerial) {
            $_Body.Add("spareSerial", $SpareSerial)
        }
        if ($UplinkMode) {
            $_Body.Add("uplinkMOde", $UplinkMode)
        }
        if ($Wan1Ip) {
            $_Body.Add("virtualIp1", $Wan1Ip)
        }
        if ($Wan2Ip) {
            $_Body.Add("virtualIp2", $Wan2Ip)
        }

        $body = $_Body | ConvertTo-Json -Depth 3 -Compress
    }

    Process {
        $Uri = "{0}/networks/{networkId}/appliance/warmSpare" -f $BaseURI, $Id

        try {
            $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Update MX warm spare settings.
    .PARAMETER Id
    The Id of the network.
    .PARAMETER Enabled
    Enable pr disable the warm spare.
    .PARAMETER SpareSerial
    Serial number of the warm spare appliance
    .PARAMETER UplinkMode
    Uplink mode, either virtual or public
    .PARAMETER Wan1Ip
    The WAN 1 shared IP
    .PARAMETER Wan2Ip
    The WAN 2 shared IP
    .OUTPUTS
    A warm spare object.
    #>
}

function Invoke-SwapMerakiApplianceWarmSpare() {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    Param (
        [Parameter(Mandatory)]
        [Alias('NetworkId')]
        [string]$Id
    )

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/appliance/warmSpare/swap" -f $BaseURI, $Id
    $NetworkName = (Get-MerakiNetwork -Id $Id).Name
    if ($PSCmdlet.ShouldProcess("Network $NetworkName to warm spare", "Swap")) {
        try {
            $response = Invoke-RestMethod -Method Post -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Swap MX primary and warm spare appliances
    .PARAMETER Id
    The network Id
    .OUTPUTS 
    A warm spare object.
    #>
}

#endregion