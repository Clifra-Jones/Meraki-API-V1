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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $headers

    return $response    
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
        [ValidateScript(
            {
                if ($ContentFilteringRules) {
                    throw "The blockedURLPatterns parameter cannot be used with the ContentFilteringRules parameter."
                } elseif (-not $_) {
                        throw "The blockedURLPatterns parameter is require if the ContentFilteringRules parameter is omitted."
                } elseif ((-not $aloowedURLPatterns) -or (-not $blockedUrlCategories) -or (-not $urlCategoryListSize)) {
                    throw "The blockedUrlPatterns parrameter requires the allowedURLPatterns and blockedUrlCategories parameters "
                } else {
                    $true
                }
            }

        )]
        [string[]]$blockedURLPatterns,
        [ValidateScript(
            {
                if ($ContentFilteringRules) {
                    throw "The blockedUrlCategories parameter cannot be used with the ContentFilteringRules parameter."
                } elseif(-not $_) {
                        throw "The blockedUrlCategories parameter is required if the ContentFilteringRules parameter is omitted."
                } elseif ((-not $allowedURLPatterns) -or (-not $blockedUrlCategories) -or (-not $urlCategoryListSize)) {
                    throw "The blockedUrlCategories parrameter requires the allowedURLPatterns and blockedURLPatterns parameters "
                } else {
                    $true
                }
            }

        )]
        [string[]]$blockedUrlCategories,
        [ValidateScript(
            {
                if ($ContentFilteringRules) {
                    throw "The urlCategoryListSize parameter cannot be used with the ContentFilteringRules parameter."
                } elseif ((-not $allowedURLPatterns) -or (-not $blockedUrlCategories) -or (-not $blockedUrlCategories)) {
                    throw "The UrlCategoriesListSize parameter requires the allowedURLPatterns, blockedURLPatterns, and blockedUrlCategories parameters "
                } else {
                    $true
                }
            }            
        )]
        [ValidateSet('topSites','fullList')]
        [string]$urlCategoryListSize,
        [ValidateScript(
            {
                if ($allowedURLPatterns -or $blockedURLPatterns -or $blockedUrlCategories -or $urlCategoryListSize) {
                    throw "The parameter ContentFilteringRules cannot be used with the allowedURLPatterns, blockedURLPatterns, blockedURLCategories -or urlCategoriesList parameters"
                } else {
                    $true
                }
            }
        )]
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
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Body $body -Headers $Headers
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
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
        return $response
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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
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
        $response =  Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers 
        return $response
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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
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
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body
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
            $response = Invoke-RestMethod -Method DELETE -Uri $Uri -Headers $Headers
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

    if ($DhcpRelayServerIPs -and ($DhcpHandling -ne "Relay DHCP to another Server")) {
        Write-Host Throw "Parameter DhcpRelayServers is not valid with DhcpHandling = 'Relay DHCP to another Server'" -ForegroundColor Red
        return
    }
    
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

    $_body = {}
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
        $_body.Add("dnsNameServers", $DnsNameServers)
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
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body
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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
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
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $Body
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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response | Where-Object {$_.networkID -like $networkID -and $_.serial -like $serial}
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
        [int]$perPage=100,
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

        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
        
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
            $response = Invoke-RestMethod -Method GET -Uri $Url -Headers $Headers
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
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
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
        $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body
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

function Remove-MerakiNetworkAplianceCelularFirewallRule() {
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
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers
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