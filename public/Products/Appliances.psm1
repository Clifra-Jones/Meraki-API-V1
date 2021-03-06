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
        [psObject]$blockedUrlCategories,
        [Parameter(
            Mandatory = $true, ParameterSetName = 'values'
        )]
        [string]$urlCategoryListSize,
        [Parameter(
            Mandatory = $true, ParameterSetName = "object"
        )]
        [psObject]$ContentFilteringRules
    )
    $Uri = "{0}/networks/{1}/appliance/contentFiltering" -f $BaseURI, $id
    $Headers = Get-Headers

    if ($ContentFilteringRules) {
        $allowedURLPatterns = $ContentFilteringRules.allowedUrlPatterns
        $blockedURLPatterns = $ContentFilteringRules.blockedUrlPatterns
        $blockedUrlCategories = $ContentFilteringRules.blockedUrlCategories
        $urlCategoryListSize = $ContentFilteringRules.urlCategoryListSize
    }


    $psBody = [PSCustomObject]@{
        allowedUrlPatterns = $allowedURLPatterns
        blockedUrlPatterns = $blockedURLPatterns
        blockedUrlCategories = $blockedUrlCategories | ForEach-Object {$_.id}
        urlCategoryListSize = $urlCategoryListSize
    }
    
    $body = $psBody | ConvertTo-Json

    $response = Invoke-RestMethod -Method PUT -Uri $Uri -Body $body -Headers $Headers

    return $response
}

Set-Alias -Name UMNetAppCF -value Update-MerakiNetworkContentFiltering -Option ReadOnly

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
        $Headers = Get-Headers       
        $VLANs = New-Object System.Collections.Generic.List[psobject]     
        $i = 1
        $count = $input.Count
        $input | ForEach-Object {
            $Uri = "{0}/networks/{1}//appliance/vlans" -f $BaseURI, $_.id
            If (-not $NoProgress) {
                Write-Progress -Activity "Getting VLANS for: " -Status $_.Name -PercentComplete ($i/$count*100)
            }
            try {
                $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers 
                if ($response.length) {                    
                    $response | ForEach-Object {
                        $VLANs.add($_)
                    }
                }
            } catch {
                #$_.Exception
            }
            $i += 1
        }
        Write-Progress -Completed -Activity "Get VLANS for:"
        return $VLANs.toArray()
    
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
    
    $Uri = "{0}/networks/{1}/appliance/vlans{2}" -f $BaseURI, $networkId, $id
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
        [string]$id
    )

    $Uri = "{0}/networks/{1}/siteToSiteVpn" -f $BaseURI, $id
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
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
        [String]$serial="*"
    )
    $config = Read-Config

    $Uri = "{0}/organizations/{1}/appliance/uplink/statuses" -f $BaseURI, $config.OrgID
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
        [switch]$Sumarize        
    )

    Begin {
        $Headers = Get-Headers
        $config = read-config
        $OrgID = $config.OrgID

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
