#Meraki Appliance Functions

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

Set-Alias GMNetAppCFCats -Value Get-MerakiNetworkContentFilteringCategories -Option ReadOnly

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

Set-Alias GMNetCF -Value Get-MerakiNetworkContentFilteringRules -Option ReadOnly

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

Set-Alias -Name UMNetAppCF -value Update-MerakiNetworkContentFiltering -Option ReadOnly

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
