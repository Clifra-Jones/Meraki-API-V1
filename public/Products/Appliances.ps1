#Meraki Appliance Functions
using namespace System.Management
function Get-MerakiNetworkApplianceContentFilteringCategories() {
    [CmdletBinding()]
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
    It is best practive to pull the list of categories from the device before attempting to set any new categories.
    #>
}

Set-Alias GMNetAppCFCats -Value Get-MerakiNetworkApplianceContentFilteringCategories -Option ReadOnly

<#
.Description
Retrieve content filtering Rules for a network
#>
function Get-MerakiNetworkApplianceContentFiltering() {
    [CmdletBinding()]
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

Set-Alias GMNetCF -Value Get-MerakiNetworkApplianceContentFiltering -Option ReadOnly

function Update-MerakiNetworkApplianceContentFiltering() {
    [CmdletBinding()]
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
        [ValidateScript({$_ -and -not ($allowedURLPatterns -or $blockedUrlCategories -or $urlCategoryListSize)}, 
            ErrorMessage="The parameter ContentFilteringRules cannot be used with the allowedURLPatterns, blockedURLPatterns, blockedURLCategories -or urlCategoriesList parameters")]
        [psObject]$ContentFilteringRules
    )

    If ($ContentFilteringRules) {
        if ($allowedURLPatterns) {
            Write-Host "The Parameter AlloweeUrlPatterns cannot be used with"
        }
    }

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
    If you have networks bound to templates, you should update the template and allow the template to trickle the changes down to the bound network.
    PS> $cfr = Get-MerakiOrganizationConfigTemplates | Where-object {$_.Name -eq "Org-Tremplate"} | Get-MerakiNetworkApplianceContentFiltering
    PS> $cfr.clockedUrlPatterns += "example.com"
    PS> Get-MerakiOrganizationConfigTemplates | Where-Object ($_.Name -eq "Org-Template"} Update-MerakiNetworkApplianceContentFiltering -ContentFilteringRules $cfr
    #>
}

Set-Alias -Name UMNetAppCF -value Update-MerakiNetworkApplianceContentFiltering -Option ReadOnly

function Add-MerakiNetworkApplianceContentFilteringRules() {
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
    
        Update-MerakiNetworkApplianceContentFiltering -Id $Id -ContentFilteringRules $Cfr
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

Set-Alias -Name AddMNetAppCFR -Value Add-MerakiNetworkApplianceContentFilteringRules -Option ReadOnly

function Remove-MerakiNetworkApplianceContentFilteringRules () {
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

        Update-MerakiNetworkApplianceContentFiltering -id $id -ContentFilteringRules $cfr
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

set-Alias -Name RemoveMNetAppCfr -Value Remove-MerakiNetworkApplianceContentFilteringRules -Option ReadOnly

function Get-MerakiAppliancePorts() {
    [cmdletbinding()]
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
            return $response
        }catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Returns the port copnfiguration for the Network Appliance.
    .PARAMETER id
    The network Id.
    .OUTPUTS
    An array of Meraki port objects.
    #>
}

Set-Alias -Name GMAppPorts -value Get-MerakiAppliancePorts -Option ReadOnly

function Get-MerakiNetworkApplianceStaticRoutes() {
    [CmdletBinding()]
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
    Returns the stauc routes for this network appliance.
    .PARAMETER id
    The Network Id.
    .OUTPUTS 
    An array of Meraki static route objects.
    #>
}

Set-Alias -Name GMNetAppRoutes -Value Get-MerakiNetworkApplianceStaticRoutes -Option ReadOnly

#region VLANs
function Get-MerakiNetworkApplianceVLANS() {
    [cmdletbinding()]
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

function Get-MerakiNetworkApplianceVLAN() {
    [cmdletbinding()]    
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

Set-Alias -name GMNetAppVLAN -Value Get-MerakiNetworkApplianceVLAN -Option ReadOnly

function Add-MerakiNetworkApplianceVlan() {
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
        [hashtable]$Ipv6PrefixAssignments,
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
}

Function Remove-MerakiNetworkApplianceVlan() {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory)]
        [string]$VlanId
    )

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/appliance/vlans/{2}" -f $BaseURI, $NetworkId, $VlanId

    if ($PSCmdlet.ShouldProcess("Delete", "VLAN ID $VlanId")) {
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

function Set-MerakiNetworkApplianceVLAN() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [Alias("NetworkId")]
        [string]$id,
        [Parameter(Mandatory = $true)]
        [string]$VlanId,
        [string]$VlanName,
        [String]$ApplianceIp,
        [string]$Subnet,
        [string]$GroupPolicyId,
        [ValidateSet("same","unique")]
        [string]$TemplateVlanType,
        [string]$TranslateVPNSubnet,
        [string]$CIDR,
        [string]$Mask,
        [ValidateScript({$_ -is [hashtable]})]
        [hashtable]$fixedIpAssignments,
        [hashtable[]]$ReservedIpRanges,
        [string]$DnsNameServers,
        [ValidateSet("Run a DHCP Server","Relay DHCP to another Server","Do not respond to DHCP requests")]
        [string]$DhcpHandling,
        [ValidateScript({$_ -and ($DhcpHandling -eq 'Relay DHCP to another Server"')}, ErrorMessage = "Parameter DhcpRelayServers is not valid when parameter DhcpHandling is 'Relay DHCP to another Server'")]
        [string[]]$DhcpRelayServerIPs,
        [ValidateSet(
            '30 minutes', '1 hour', '4 hours', '12 hours', '1 day', '1 week'
        )]
        [string]$DhcpLeaseTime,
        [bool]$DhcpBootOptionEnabled,
        [string]$DhcpBootNextServer,
        [string]$DhcpBootFilename,
        [hashtable]$DhcpOptions,
        [hashtable]$IPv6,
        [bool]$MandatoryDhcp,
        [string]$VpnNatSubnet
    )
    
    $Headers = Get-Headers

    # Return the network Info so we can determine is thi snetwork is assinged to a template.
    $Network = Get-MerakiNetwork -networkID $id

    # check for Template only parameters.
    if ($mask -or $CIDR -or $TemplateVlanType) {
        if ($Network.$_isBoundToConfigTemplate -eq $false) {
            Throw "Parameters 'mask', 'CIDR' and TemplateVLanType are only applicable to template networks."
        }
    }

    $Uri = "{0}/networks/{1}/appliance/vlans/{2}" -f $BaseURI, $id, $VlanId

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
        $_body.Add("ReservedIpRanges", $ReservedIpRanges)
    }
    if ($DnsNameServers) {
        $_body.Add("dnsNameservers", $DnsNameServers)
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
    if ($IPv6) {
        $_body.Add("ipv6", $IPv6)
    }
    if ($MandatoryDhcp) {
        $_body.Add("mandatoryDhcp", $MandatoryDhcp)
    }
    if ($VpnNatSubnet) {
        $_body.Add("vpnNatSubnet", $VpnNatSubnet)
    }

    $body = $_body | ConvertTo-Json -Depth 10 -Compress

    Try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        Throw $_
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
    .PARAMETER TranslateVPNSubnet

    #>
}

Set-Alias -Name SetMNAppVLAN  -Value Set-MerakiNetworkApplianceVLAN

#endregion

function Get-MerakiNetworkApplianceSiteToSiteVPN() {
    [CmdletBinding()]
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

function Set-MerakiNetworkApplianceSiteToSiteVpn() {
    [CmdletBinding()]
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


function Get-MerakiApplianceUplinkStatuses() {
    [CmdletBinding()]
    Param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String]$networkId="*",
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String]$serial="*",
        [string]$profileName
    )

    $config = Read-Config
    if ($profileName) {
        $OrgID = $config.profiles.$profileName
        if (-not $orgId) {
            throw "invalid profile name!"
        }
    } else {
        $OrgID = $config.profiles.default
    }

    $Uri = "{0}/organizations/{1}/appliance/uplink/statuses" -f $BaseURI, $OrgID
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response | Where-Object {$_.networkID -like $networkID -and $_.serial -like $serial}
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Returns the Uplink status of Meraki Networks.
    .PARAMETER networkId
    Filters the output by network Id.
    .PARAMETER serial
    Filters the output by Appliance serial number.
    .PARAMETER profileName
    Returns uplink status for appliances in this profile. if omitted uses the default profile.
    .OUTPUTS
    An array of Meraki uplink objects.
    #>
}

Set-Alias -Name GMAppUpStat -value Get-MerakiApplianceUplinkStatuses -Option ReadOnly

function Get-MerakiNetworkApplianceVpnStats() {
    [cmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$id,
        [ValidateSet({$_ -is [int]})]
        [int]$perPage=100,
        [ValidateSet({$_ -is [int]})]
        [int]$timespan=5,
        [switch]$Sumarize,
        [string]$profileName
    )

    Begin {
        $Headers = Get-Headers
        $config = read-config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgId) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }

        class vpnPeer {
            [string]$networkID
            [string]$networkName
            [string]$peerNetworkId
            [string]$peerNetworkName
            [int]$receivedKilobytes
            [int]$sentKilobytes
        }

        class summaryVpnPeer {
            [string]$networkID
            [string]$networkName
            [int]$totalReceivedKilobytes
            [int]$totalSentKilobytes
        }
    }

    Process {
        $Network = Get-MerakiNetwork -networkID $id

        $Uri = "{0}/organizations/{1}/appliance/vpn/stats" -f $BaseURI, $OrgID

        $TimeSpan_Seconds = (New-TimeSpan -Days $timespan).TotalSeconds

        $Uri = "{0}?perPage={1}&networkIds%5B%5D={2}&timespan={3}" -f $Uri, $timespan, $id, $TimeSpan_Seconds

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            
            $peers = $response.merakiVpnPeers
            $PeerNetworks = New-object System.Collections.Generic.List[psobject]
            foreach ($peer in $peers) {
                $P = [vpnPeer]::New()
                $P.networkID = $id
                $P.networkName = $Network.name
                $P.peerNetworkId = $peer.networkId
                $P.peerNetworkName = $peer.networkName
                $P.receivedKilobytes = $peer.usageSummary.receivedInKilobytes
                $P.sentKiloBytes = $peer.usageSummary.sentInKilobytes

                $PeerNetworks.Add($P)
            }
            $vpnPeers = $PeerNetworks.ToArray()

            if ($Sumarize) {   
                $summary = [summaryVpnPeer]::New()
                $summary.networkID = $id
                $Summary.networkName = $Network.name
                $summary.totalReceivedKilobytes = ($vpnPeers | Measure-Object -Property receivedKilobytes -Sum).Sum
                $summary.totalSentKilobytes = ($vpnPeers | Measure-Object -Property sentKilobytes -Sum).Sum            

                return $summary
            } else {
                $vpnPeers
            }
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Returns VPN statistics for the given organization network.
    .PARAMETER id
    The Network Id.
    .PARAMETER perPage
    The number of entries per page returned. Acceptable range is 3 - 300. Default is 300.
    .PARAMETER timespan
    Number of seconds to return data for. default = 5.
    .PARAMETER Sumarize
    Summerize the statistics,
    .PARAMETER profileName
    Return statistics for this profile. Note: The network ID must exist in this organization.
    .OUTPUTS 
    AN array op VPN peer objects or a summary object.
    #>
}

Set-Alias -Name GMAVpnStats -Value Get-MerakiNetworkApplianceVpnStats -Option ReadOnly

function Get-MerakiNetworkApplianceDhcpSubnets() {
    [CmdletBinding()]
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
    Returns inforation and statistics for an appliances DHCP subnets. Including used count and free count.
    .PARAMETER serial
    The serial number of the appliance.
    .OUTPUTS
    A collection of Subnet objects.
    #>
}

Set-Alias -Name GMNetAppDhcpSubnet -Value Get-MerakiNetworkApplianceDhcpSubnets -Option ReadOnly

#region Firewall
function Get-MerakiNetworkApplianceCellularFirewallRules () {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [Alias('NetworkId')]
        [string]$Id        
    )

    Begin {
        $Headers = Get-Headers

        $Uri = "{0}/network/{1}/appliance/firewall/cellularFirewallRules" -f $BaseURI, $Id        
    }
    
    Process {

        $Network = Get-MerakiNetwork -networkID $Id

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | Add-Member -MemberType NoteProperty -Name "NetworkId" -Value $Id
            $response | Add-Member -MemberType NoteProperty -Name "NetworkName" -Value $Network.Name
            return $response
        }
        catch {
            throw $_
        }
    }
}

function Set-MerakiNetworkApplianceCellularFirewallRules() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [psObject[]]$Rules
    )

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/appliance/firewall/cellularFirewallRules" -f $BaseURI, $Id

    $body = $Rules | ConvertTo-Json -Depth 4 -Compress

    try {
        $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
}

function Set-MerakiNetworkApplianceCellularFirewallRule() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [Alias('Networkid')]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [int]$RuleIndex,
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

    $rules = (Get-MerakiNetworkApplianceCellularFirewallRules -id $Id).rules

    $alRules = [System.Collections.ArrayList]$rules
    $alRules.RemoveAt($RuleIndex)
    $Properties = [PSCustomObject]@{
        "policy" = $Policy
        "srcCidr" = $SourceCidr
        "srcPort" = $SourcePort
        "protocol" = $protocol
        "destCidr" = $DestinationCidr
        "destPort" = $DestinationPort
        "comment" = $Comment
    }
    if ($SyslogEnabled.IsPresent) { $properties.Add("syslogEnabled", $SyslogEnabled) }
    $rule = [PSCustomObject]$Properties
    
    $alRules.Insert($RuleIndex, $rule)
    $newRules = $alRules.ToArray()
    
    try {
        $response = Set-MerakiNetworkApplianceCellularFirewallRules -Id $NetworkId, -rules $newRules
        return $response
    }
    catch {
        throw $_
    }
}

function Add-MerakiNetworkApplianceCellularFirewallRule() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [Alias('Networkid')]
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

    $Rules = (Get-MerakiNetworkApplianceCellularFirewallRules -Id $Id).rules

    $Properties = [PSCustomObject]@{
        "policy" = $Policy
        "srcCidr" = $SourceCidr
        "srcPort" = $SourcePort
        "protocol" = $protocol
        "destCidr" = $DestinationCidr
        "destPort" = $DestinationPort
        "comment" = $Comment
    }
    if ($SyslogEnabled.IsPresent) { $properties.Add("syslogEnabled", $SyslogEnabled) }
    $rule = [PSCustomObject]$Properties

    $Rules += $rule

    try {
        $response = Set-MerakiNetworkApplianceCellularFirewallRules -Id $id, -Rules $Rules
        return $response
    }
    catch {
        throw $_
    }
}

function Remove-MerakiNetworkApplianceCellularFirewallRule() {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [int]$RuleIndex
    )

    $Rules = (Get-MerakiNetworkApplianceCellularFirewallRules -id $NetworkId).Rules
    $alRules = [System.Collections.ArrayList]$Rules

    $alRules.RemoveAt($RuleIndex)

    $newRules = $alRules.ToArray()

    if ($PSCmdlet.ShouldProcess('DELETE', "Cellular Firewall Rule at index $ruleIndex")) {
        try {
            $response = Set-MerakiNetworkApplianceCellularFirewallRules -Id $NetworkId -Rules $newRules
            return $response
        }
        catch {
            throw $_
        }
    }
}

#endregion

#region Firewalled Services
function Get-MerakiNetworkApplianceFirewalledServices() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Networkid')]
        [string]$Id
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/appliance/firewall/firewalledServices" -f $BaseURI, $Id
        $Network = Get-MerakiNetwork -networkID $Id
        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | Add-Member -MemberType NoteProperty -Name "NetworkId" -Value $Id
            $response | Add-Member -MemberType NoteProperty -Name "NetworkName" -Value $Network.Name
            return $response
        }
        catch {
            Throw $_
        }
    }
}
#endregion

#region L3 Firewall Rules
Function Get-MerakiApplianceL3FirewallRules() {
    [CmdletBinding()]
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
}

function Set-MerakiApplianceL3FirewallRules() {
    [CmdletBinding()]
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
        [psobject[]]$Rules,
        [switch]$PassThru
    )    

    Begin {
        $Headers = Get-Headers

        # The below statements are used if rules are being copied from another network/

        # Remove the RuleId property. This is added and used by this module and is not part of the Meraki configuration.
        if ($Rules[0].PSObject.Properties.Name -contains 'RuleId') {
            $Rules = $Rules | Select-Object -Property * -ExcludeProperty RuleId
        }

        # remove the default rule if it exists.
        $Rules = $Rules | Where-Object {$_.comment -ne 'Default rule'}
    }
    Process {
    
        $Uri = "{0}/networks/{1}/appliance/firewall/l3FirewallRules" -f $BaseUri, $id
        $_body = @{"rules" = $Rules}
        $body = $_body | ConvertTo-Json -Depth 5 -Compress

        try {
            $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            return $response.rules
        } catch {
            throw $_
        }
    }
}

function Add-MerakiApplianceL3FirewallRule() {
    [CmdletBinding()]
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

    Begin {
        $Headers = Get-Headers
    }
    
    Process {

        $Uri = "{0}/networks/{1}/appliance/firewall/l3FirewallRules" -f $BaseUri, $Id


        $Rules = Get-MerakiApplianceL3FirewallRules -id $Id | Select-Object * -ExcludeProperty RuleId

        # Remove the default rule
        $Rules = $Rules | Where-Object {$_.comment -ne "Default rule"}

        $NewRule = [PSCustomObject]@{
            policy = $policy
            comment = $Comment
            protocol = $Protocol
            destPort = $DestinationPort
            destCidr = $DestinationCIDR
            srcPort = $SourcePort
            srcCidr = $SourceCIDR
            syslogEnabled = $SyslogEnabled.IsPresent
        }
        $Rules += $NewRule
        
        $_Body = @{rules = $Rules}
        $body = $_body | ConvertTo-JSON -Depth 5 -Compress

        try {
            $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            return $response.rules
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
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory
        )]
        [string]$NetworkId,
        [int]$RuleId,
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

    $Uri = "{0}/networks/{1}/appliance/firewall/l3FirewallRules" -f $BaseUri, $NetworkId

    $Headers = Get-Headers

    $Rules = Get-MerakiApplianceL3FirewallRules -id $NetworkId

    # Remove the Default Rule
    $Rules = $Rules | Where-Object {$_.comment -ne "Default rule"}
    
    $Rule = $Rules | Where-Object {$_.RuleId -eq $RuleId}
    if (-not $Rule) {
        throw "Invalid Rule Id"
    }

    $Rules = $Rules | Where-Object {$_.RuleId -ne $RuleId}

    If ($Policy) {$Rule.policy = $Policy}
    if ($Comment) {$Rule.comment = $Comment}
    if ($Protocol) {$Rule.protocol = $Protocol}
    if ($SourceCIDR) {$Rule.srcCIDR - $SourceCIDR}
    if ($SourcePort) { $Rule.srcPort = $SourcePort}
    if ($DestinationCIDR) {$Rule.destCIDR = $DestinationCIDR}
    if ($DestinationPort) {$Rule.destPort = $DestinationPort}
    if ($SyslogEnabled) {$Rule.syslogEnabled = $SyslogEnabled}


    $Rules += $Rule

    # Remove the RuleId Property
    $newRules = $Rules | Select-Object * -ExcludeProperty RuleId

    $_Body = @{rules = $newRules}

    $body = $_Body | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response.rules  
    } catch {
        throw $_
    }

    <#
    .SYNOPSIS
    Update an existing level 3 firewall rule.
    .DESCRIPTION
    Update an existing Level 3 firewall rule on a meraki Appliance.
    .PARAMETER 
    #>
}

function Remove-MerakiApplianceL3FirewallRule() {
    [CmdletBinding(SupportsShouldProcess)]
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
    if ($PSCmdlet.ShouldProcess("Delete","Rule:$($Rule.Comment)")) {
        try {
            $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            return $response.rules
        } catch {
            throw $_
        }
    }
}
#endregion