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
}

Set-Alias GMNetCF -Value Get-MerakiNetworkContentFilteringRules -Option ReadOnly

<#
.Description
Update content filtering rules for a network
#>
function Update-MerakiNetworkApplianceContentFiltering() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$id,
        [Parameter(
            ParameterSetName = "values",
            Mandatory = $true
        )]
        [string[]]$allowedURLPatterns,
        [Parameter(
            Mandatory=$true,
            ParameterSetName = "values"            
        )]
        [string[]]$blockedURLPatterns,
        [Parameter(
            ParameterSetName = "values",
            Mandatory = $true
        )]
        [string[]]$blockedUrlCategories,
        [Parameter(
            Mandatory = $true, ParameterSetName = 'values'
        )]
        [string]$urlCategoryListSize,
        [Parameter(
            ParameterSetName = "object"
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
    
    $body = $psBody | ConvertTo-Json

    $response = Invoke-RestMethod -Method PUT -Uri $Uri -Body $body -Headers $Headers

    return  $response
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
            Write-Host "You must provide al least one fo the content filtering patterns" -ForegroundColor Red
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
}

Set-Alias -Name GMNetAppRoutes -Value Get-MerakiNetworkApplianceStaticRoutes -Option ReadOnly

<#
.Description
Retrieves all VLAN for a network.
#>
function Get-MerakiNetworkApplianceVLANS() {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$id,
        [switch]$NoProgress
    )
    Begin {
        $Headers = Get-Headers       
        $Uri = "{0}/networks/{1}/appliance/vlans" -f $BaseURI, $id
    }

    Process {
        return Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers 
    }
        
}

Set-Alias -Name GMNetAppVLANs -Value Get-MerakiNetworkApplianceVLANS -Option ReadOnly

<#
.Description
Retrieve a specific VLAN
#>
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

}

Set-Alias -name GMNetAppVLAN -Value Get-MerakiNetworkApplianceVLAN -Option ReadOnly

<#
.Description
Get Network Site-to-Site VPN Settings
#>
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
}

Set-Alias -Name GMAVpnStats -Value Get-MerakiNetworkApplianceVpnStats -Option ReadOnly
