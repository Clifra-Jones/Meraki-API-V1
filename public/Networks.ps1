#Meraki Network Functions

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
    <#
    .SYNOPSIS
    Returns a Meraki Network.
    .PARAMETER networkID
    The ID of the network.
    .OUTPUTS
    A Meraki network object.
    #>
}

Set-Alias -Name GMNet -Value Get-MerakiNetwork -Option:ReadOnly

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
    <#
        .SYNOPSIS
        Get the Network Devices for a Network.
        .PARAMETER id
        The Network ID.
        .OUTPUTS
        An array of network devices.
    #>
}

Set-Alias -Name GMNetDevs -Value Get-MerakiNetworkDevices -Option ReadOnly


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
        [ValidateSet('wireless','appliance','switches','systemManager','camera','cellularGateway')]
        [string]$ProductType,
        [string[]]$IncludedEventTypes,
        [string[]]$excludedEventTypes,
        [string]$deviceMac,
        [string]$deviceName,
        [string]$deviceSerial,
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
            $oBody.Add("productType", $ProductType)
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
        if ($deviceSerial) {
            $oBody.Add("deviceSerial", $deviceSerial)
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
    <#
    .SYNOPSIS
    Returns Network Event.
    .Description
    Returns network events for this network.
    .PARAMETER id
    The network Id.
    .PARAMETER ProductType
    The product type to pull events for.
    .PARAMETER IncludedEventTypes
    An array of event types to include.*
    .PARAMETER excludedEventTypes
    An array of event types to exclude.*
    .PARAMETER deviceMac
    Filter results by Mac Address
    .PARAMETER deviceName
    Filter results by device name.
    .PARAMETER deviceSerial
    Filter results by device serial number.
    .PARAMETER clientName
    Filter results bu client name.
    .PARAMETER clientIP
    Filter results by client IP.
    .PARAMETER clientMac
    Filter results by client MAC.
    .PARAMETER smDeviceName
    Filter device bu System Manager device name.
    .PARAMETER smDeviceMac
    Filter results by System Manager device MAC.
    .PARAMETER perPage
    Number of entries per page. 3-1000, default = 10.
    .PARAMETER startingAfter
    Date time to pull events after.
    .PARAMETER endingBefore
    Date time to pull events before.
    .PARAMETER first
    Pull the forst page.
    .PARAMETER last
    Pull ther last page.
    .PARAMETER prev
    Pull the previous page.
    .PARAMETER next
    Pull the next page.
    .OUTPUTS
    An array of Meraki event objects.
    .NOTES
    Event types supported by this network can by retrieved by using the Get-MerakiNetworkEventTypes function.
    .EXAMPLE
    Get content filtering network events for a network.
    PS> Get-MerakiNetworks |{$_.Name -like "Dallas"} | Get-MerakiNetworkEvents -includedEventTypes 'cf_block' -ProductType appliance
    .EXAMPLE
    Get network events for a specific client
    PS> Get-MerakiNetworkEvents -clientName 'DALJohnDoe'
    .EXAMPLE
    Paging:
    The maximum number of events you can retrieve per call is 1000. There are many events and 1000 events may only span a time period of a few minutes. 
    To retrieve more events you can use subsequent function calls with the paging parameters.
    In the following command we retrieve the the content filtering events for the Dallas network for the month of June.
    PS> Get-MerakiNetworks |{$_.Name -like "Dallas"} | Get-MerakiNetworkEvents -includedEventTypes 'cf_block' -ProductType appliance -startingAfter "06/01/2020" -endingBefore "06/30/2020" -pageSize 50
    .EXAMPLE
    This call will retrieve the first 50 events that meet the time span specified. 
    There are significantly more events that meet this criteria. 
    To retrieve the next page of events reissue the call and append the -next paging parameter.
    PS>Get-MerakiNetworks |{$_.Name -like "Dallas"} | Get-MerakiNetworkEvents -includedEventTypes 'cf_block' -ProductType appliance -startingAfter "06/01/2020" -endingBefore "06/30/2020" -pageSize 50 -next
    #>
}

Set-Alias -Name GMNetEvents -value Get-MerakiNetworkEvents -Option ReadOnly


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
    <#
    .SYNOPSIS
    Returns all event types supported by this network.
    .PARAMETER id
    The network ID.
    .OUTPUTS 
    An array of event type objects.
    #>
}

Set-Alias -Name GMNetET  Get-MerakiNetworkEventTypes -Option ReadOnly

