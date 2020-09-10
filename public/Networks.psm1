#Meraki Network Functions

<#
.Description
Retrieves a specific Network
#>
function Get-MerakiNetwork() {
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [String]$networkID
    )
    $Uri = "{0}/networks/{1}" -f $BaseURI, $networkID
    $Headers = Get-Headers

    $Response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $Response
}

Set-Alias -Name GMNet -Value Get-MerakiNetwork -Option:ReadOnly

<#
.Description
Retrieves all devices for a Network
#>
function Get-MerakiNetworkDevices () {
    [cmdletbinding()]
    Param (
        [Parameter(
            Mandatory   = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $True)]
        [string]$id
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
    
        $Uri = "{0}/networks/{1}/devices" -f $BaseURI, $id
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
        return $response
    }
}

Set-Alias -Name GMNetDevs -Value Get-MerakiNetworkDevices -Option ReadOnly

<#
.Description
Get network events
#>
function Get-MerakiNetworkEvents() {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]    
        [string]$id,
        [Parameter(
            Mandatory = $true
        )]
        [productTypes]$ProductType,
        [string[]]$IncludedEventTypes,
        [string[]]$excludedEventTypes,
        [string]$deviceMac,
        [string]$deviceName,
        [string]$clientName,
        [string]$clientIP,
        [string]$clientMac,
        [string]$smDeviceName,
        [string]$smDeviceMac,
        [int]$perPage,
        [datetime]$startingAfter=0,
        [datetime]$endingBefore=0,
        [switch]$first,
        [switch]$last,
        [switch]$prev,
        [switch]$next
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/events" -f $BaseURI, $id

        if ($first -or $last -or $prev -or $next) {
            if ($first) {
                $startingAfter = $paging.first
                $endingBefore = 0
            } elseif ($last) {
                $startingAfter = 0
                $endingBefore = $paging.last
            } elseif ($next) {
                if ($paging.next -ne $paging.last) {
                    $startingAfter = $paging.next
                    $endingBefore = 0
                }
            } elseif ($prev) {
                If ($paging.prev -ne $paging.first) {
                    $endingbefore = $paging.prev
                    $startingAfter = 0
                }
            }            
        } else {
            $paging.first = $null
            $paging.last = $null
            $paging.prev = $null
            $paging.next = $null
        }

        $oBody = @{}
        If ($ProductType) {
            $oBody.Add("productType", $ProductType.ToString())
        }
        if ($IncludedEventTypes) {
            $oBody.Add("includedEventTypes", $IncludedEventTypes)
        }
        if ($excludedEventTypes) {
            $oBody.Add("excludedEventTypes", $excludedEventTypes)
        }
        if ($deviceMac) {
            $oBody.Add("deviceMac", $deviceMac)
        }
        if ($deviceName) {
            $oBody.Add("deviceMac", $deviceMac)
        }
        if ($clientName) {
            $oBody.Add("clientName", $clientName)
        }
        if ($clientIP) {
            $obody.add("clientIP", $clientIP)
        }
        if ($ClientMac) {
            $oBody.Add("clientMac", $ClientMac)
        }
        if ($smDeviceName) {
            $oBody.Add("smDeviceName", $smDeviceName)
        }
        if ($smDeviceMac) {
            $oBody.Add("smDeviceMac", $smDeviceMac)
        }
        if ($perPage) {
            $oBody.Add("perPage", $perPage)
        }
        if ($startingAfter.year -ne 1) {
            $oBody.add("startingAfter", "{0:s}" -f $startingAfter)
        }
        if ($endingBefore.year -ne 1) {
            $obody.add("endingAfter", "{0:s}" -f $endingBefore)
        }

        $body = $oBody | ConvertTo-Json

        $response = Invoke-RestMethod -Method GET -Uri $Uri -Body $body -Headers $Headers
        if ($first -or $last -or $prev -or $next) {
            $paging.prev = $response.pageStartAt
            $paging.next = $response.pageEndAt
        } else {
            $paging.first = $startingAfter
            if ($endingBefore) {
                $paging.last = $endingBefore
            } else {
                $paging.last = Get-Date
            }
            $paging.next = $response.pageEndAt
            $paging.prev = $response.pageStartAt
        }

        return $response.events | Sort-Object occurredAt
    }
}

Set-Alias -Name GMNetEvents -value Get-MerakiNetworkEvents -Option ReadOnly

<#
.Description
Get network event types
#>
function Get-MerakiNetworkEventTypes() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$id
    )

    $Uri = "{0}/networks/{1}/events/eventTypes" -f $BaseURI, $id
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
}

Set-Alias -Name GMNetET  Get-MerakiNetworkEventTypes -Option ReadOnly

