#Meraki Network Functions

#region Networks
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

function Set-MerakiNetwork() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$TimeZone,
        [string]$Notes,
        [string[]]$Tags,
        [string]$EnrollmentString
    )

    $Headers = Get-Headers
    
    $Uri = "{0}/networks/{1}" -f $BaseURI, $NetworkId

    $_body = @{}
    if ($Name) { $_body.Add("name", $Name) }
    if ($TimeZone) { $_body.Add("timeZone", $TimeZone) }
    if ($Notes) { $_body.Add("notes", $Notes) }
    if ($Tags) { $_body.Add("tags", $Tags) }
    if ($EnrollmentString) { $_body.Add("enrollmentString", $EnrollmentString) }

    $body = $_body | ConvertTo-Json -Depth 5 -Compress
    try {
        $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body
        return $response        
    }
    catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Modify a network
    .DESCRIPTION
    Modify settings on a Meraki Network
    .PARAMETER NetworkId
    The ID of the network
    .PARAMETER Name
    The name of the network
    .PARAMETER TimeZone
    The timezone of the network. For a list of allowed timezones
    .PARAMETER Notes
    Add any notes or additional information about this network here
    .PARAMETER Tags
    A list of tags to be applied to the network
    .PARAMETER EnrollmentString
    A unique identifier which can be used for device enrollment or easy access through the Meraki SM Registration page or the Self Service Portal. 
    Please note that changing this field may cause existing bookmarks to break.
    .OUTPUTS
    A network object
    #>
}

function Connect-MerakiNetworkToTemplate() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [Parameter(Mandatory = $true)]
        [string]$ConfigTemplateId,
        [switch]$AutoBind
    )

    $Headers = Get-Headers

    $Uri = $"{0}/networks/{1}/bind" -f $NetworkId

    $Template = Get-MerakiOrganizationConfigTemplate -ConfigTemplateId $ConfigTemplateId

    if (-not $Template) {
        throw "Invalue ConfigTemplateId"
    }

    $_Body = @{
        "configTemplateId" = $ConfigTemplateId
        "autoBind" = $AutoBind.IsPresent
    }
    $body = $_Body | ConvertTo-Json -Compress
    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -Body $body
        return $response
    }
    catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Connect a template to a network
    .DESCRIPTION
    Connect a Meraki network to a configuration template
    .PARAMETER NetworkId
    The Id of the network to connect
    .PARAMETER ConfigTemplateId
    The Id of the configuration template
    .PARAMETER AutoBind
    Optional boolean indicating whether the network's switches should automatically bind to profiles of the same model. 
    Defaults to false if left unspecified. This option only affects switch networks and switch templates. 
    Auto-bind is not valid unless the switch template has at least one profile and has at most one profile per switch model.
    .OUTPUTS
    A network object
    #>
}

function Disconnect-MerakiNetworkFromTemplate() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [switch]$RetainConfigs
    )

    $Header = Get-Headers

    $Uri = "{0}/networks/{1}/unbind" -f $BaseURI, $NetworkId
    $body = @{"retainConfigs" = $RetainConfigs.IsPresent} | ConvertTo-Json -Compress

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Header -Body $body
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Disconnect a network from a template
    .DESCRIPTION 
    Disconnect a Meraki Network from a configuration template
    .PARAMETER NetworkId
    The ID of the network
    .PARAMETER RetainConfigs
    Optional boolean to retain all the current configs given by the template
    .OUTPUTS
    A network object
    #>
}

function Merge-MerakiNetworks() {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [strng[]]$NetworkIds,
        [string]$EnrollmentString,
        [ValidateScript(
            {
                if ($profileName) {
                    throw "The OrgId parameter cannot be used with the ProfileName parameter."
                } else {
                    $true
                }
            }
        )]
        [string]$OrgID,
        [ValidateScript(
            {
                if ($OrgID) {
                    throw "The ProfileName parameter cannot be used with the OrgId parameter."
                } else {
                    $true
                }
            }
        )]
        [string]$profileName
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

    $Header = Get-Headers

    $Uri = "{0}/organizations/{1}/networks/combine" -f $BaseURI, $OrgID

    $_Body = @{
        "name" = $Name
        "networkIds" = $NetworkIds
    }
    if ($EnrollmentString) { $_Body.Add("enrollmentString", $EnrollmentString) }

    $body = $_Body | ConvertTo-Json -Compress

    if ($PSCmdlet.ShouldProcess('Merge',"Networks $($Networks -join ',')")) {
        try {
            $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Header -Body $Body
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Combine multiple networks into a single network.
    .DESCRIPTION
    Combine multipl Meraki networks into a single network.
    .PARAMETER Name
    The name of the combined network.
    .PARAMETER NetworkIds
    A list of the network IDs that will be combined. 
    If an ID of a combined network is included in this list, the other networks in the list will be grouped into that network.
    .PARAMETER EnrollmentString
    A unique identifier which can be used for device enrollment or easy access through the Meraki SM Registration page or the Self Service Portal. 
    Please note that changing this field may cause existing bookmarks to break. All networks that are part of this combined network will have their enrollment string appended by '-network_type'. 
    If left empty, all exisitng enrollment strings will be deleted.
    .PARAMETER OrgID
    The Organization ID
    .PARAMETER profileName
    The saved Profile name.
    .OUTPUTS
    A network object
    #>
}

function Split-MerakiNetwork() {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId
    )

    $Header = Get-Headers

    $Uri = "{0}/networks/{1}/split" -f $BaseURI, $NetworkId

    $Network = Get-MerakiNetwork -networkID $NetworkId

    if ($PSCmdlet.ShouldProcess('Split',"Network $($Network.NAme)")) {
        try {
            $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Header 
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Split network into individual networks
    .DESCRIPTION
    Split a combined network into individual networks for each type of device
    .PARAMETER NetworkId
    The Id of then network
    .OUTPUTS
    An array of network objects
    #>
}


#endregion
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
        [ValidateScript({$_ -is [int]})]
        [int]$perPage,
        [ValidateScript({$_ -is [datetime]})]
        [datetime]$startingAfter=0,
        [ValidateScript({$_ -is [datetime]})]
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

function Get-MerakiNetworkClients () {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("NetworkId")]
        [string]$id,
        [ValidateScript(
            {
                if ($Days) {
                    throw "The StartDate prameter cannot be used with the Days parameter."
                }
                if (-not $EndDate) {
                    throw "The EndDate parameter must be supplied with the StartDate parameter."
                }
            }
        )]
        [datetime]$StartDate,
        [ValidateScript(
            {
                if ($Days) {
                    throw "The EndDate parameter cannot be used with the Days parameter."
                }
                if (-not $StartDate) {
                    throw "The StartDate parameter must be supplied with the EndDate parameter."
                }
            }
        )]
        [datetime]$EndDate,
        [ValidateScript(
            {
                if ($StartDate -or $EndDate) {
                    throw "The Days parameter cannot be used witht he StartDate or EndDate parameter"
                }
            }
        )]
        [ValidateSet({$_ -is [int]})]
        [int]$Days,
        [string]$Statuses,
        [string]$Mac,
        [string]$IP,
        [string]$OS,
        [string]$Description,
        [string]$VLAN,
        [string[]]$recentDeviceConnections
    )
    Begin {
        $Headers = Get-Headers
        Set-Variable -Name Query 
        if ($StartDate) {
            $_startDate = "{0:s}" -f $StartDate
            $Query += "t0={0}" -f $_startDate
        }
        if ($endDate) {
            $_endDate = "{0:s}" -f $endDate
            if ($Query) {
                $Query += "&"
            }
            $Query += "t1={0}" -f $_endDate
        }
        if ($Days) {
            $TS = [Timespan]::FromDays($Days)
            if ($Query) {
                $Query += "&"
            }
            Query += "timespan={0}" -f ($TS.TotalSeconds)
        }
        if ($Statuses) {
            if ($Query) {
                $Query += "&"
            }
            $Query += "statuses={0}" -f $Statuses
        }
        if ($Mac) {
            if ($Query) {
                $Query += "&"
            }
            $Query += "mac={0}" -f $Mac
        }
        if ($IP) {
            if ($Query) {
                $Query += "&"
            }
            $Query += "ip={0}" -f $IP
        }
        if ($OS) {
            if ($Query) {
                $Query += "&"
            }
            $Query += "os={0}" -f $OS
        }
        if ($Description) {
            if ($Query) {
                $Query += "&"
            }
            $Query += "description={0}" -f $Description
        }
        if ($VLAN) {
            if ($Query) {
                $Query += "&"
            }
            $Query += "vlan={0}" -f $VLAN
        }
        if ($recentDeviceConnections) {
            if ($Query) {
                $Query += "&"
            }
            $Query += "recentDeviceConnections={0}" -f $recentDeviceConnections
        }
   }

    
    Process {
        $Uri = "{0}/networks/{1}/clients" -f $BaseURI, $Id
        if ($Query) {
            $Uri += "?{0}" -f $Query
        }
        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers
            $response | ForEach-Object {
                if ($null -eq $_.description) {
                    $_.description = $_.mac
                }
            }
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS 
    Returns clients connections to the Network.
    .DESCRIPTION
    Returns a collection of client objects that are or have connected to the network withing the given time period.
    .PARAMETER id
    The network Id.
    .PARAMETER StartDate
    The starting date to retrieve client connections (Cannot be more than 31 days from today)
    .PARAMETER EndDate
    The ending date to retrieve client connections (cannot be more than 31 days from today)
    .PARAMETER Days
    Number of days back from today to retrieve cleint connections. If specified do not specify StartDate or EndDate (cannot be more than 31 days from today)
    .PARAMETER Statuses
    Filters clients based on status. Can be one of 'Online' or 'Offline'.
    .PARAMETER Mac
    Filters clients based on a partial or full match for the mac address field.
    .PARAMETER IP
    Filters clients based on a partial or full match for the ip address field
    .PARAMETER OS
    Filters clients based on a partial or full match for the os (operating system) field.
    .PARAMETER Description
    Filters clients based on a partial or full match for the description field.
    .PARAMETER VLAN
    Filters clients based on the full match for the VLAN field.
    .PARAMETER recentDeviceConnections
    Filters clients based on recent connection type. Can be one of 'Wired' or 'Wireless'.
    .OUTPUTS
    A collection of client objects.
    #>
}

Set-Alias GMNetClients -Value Get-MerakiNetworkClients -Option ReadOnly

function Get-MerakiNetworkClientApplicationUsage() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [string[]]$Clients,
        [int]$SSIDNumber,
        [ValidateScript(
            {
                if ($Days) {
                    throw "The StartDate parameter cannot be used with the Days parameter."
                }
                if (-not $EndDate) {
                    throw "The EndDate parameter must be provided with the StartDate parameter."
                }
            }
        )]
        [DateTime]$StartDate,
        [ValidateScript(
            {
                if ($Days) {
                    throw "The Days parameter cannot be used with teh EndDate parameter."
                }
                if (-not $StartDate) {
                    throw "The StartDate parameter must be provided with the EndDate parameter"
                }
            }
        )]
        [DateTime]$EndDate,
        [ValidateScript({$_ -is [int]})]
        [int]$Days,
        [ValidateScript({$_ -is [int]})]
        [int]$PerPage
    )

    Begin {
        $Headers = Get-Headers
        
        $Query = $null

        if ($Clients) {
            $_clients = $Clients -join ","
            $Query += "clients={0}" -f $_clients
        } else {
            $Query += "clients="
        }
        if ($SSIDNumber) {
            if ($Query) {
                $Query += "&"
            }
            $Query += "ssidNumber={0}" -f $SSIDNumber
        }
        if ($StartDate) {
            $_startDate = "{0:s}" -f $StartDate
            if ($Query) {
                $Query += "&"
            }
            $Query = "t0={0}" -f $_startDate
        }
        if ($EndDate) {
            $_endDate = "{0:s}" -f $EndDate
            if ($Query) {
                $Query += "&"
            }
            $Query += "t1={0}" -f $_endDate
        }
        if ($Days) {
            $ts = [timespan]::FromDays($Days)
            if ($Query) {
                $Query += "&"
            }
            $Query += "timespan={0}" -f ($ts.TotalSeconds)
        }
        if ($PerPage) {
            if ($Query) {
                $Query += "&"
            }
            $Query += "perPage={0}" -f $PerPage
        }
    }

    Process {
        $Uri = "{0}/networks/{1}/clients/applicationUsage" -f $BaseURI, $Id
        if ($Query) {
            $Uri += "?{0}" -f $Query
        }

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
            return $response
        } catch {
            throw $_
        }
    }

    <#
    .SYNOPSIS
    Return the application usage data for clients.
    .DESCRIPTION
    Return the application usage data for clients. Usage data is in kilobytes. 
    Clients can be identified by client keys or either the MACs or IPs depending on whether the network uses Track-by-IP.
    .PARAMETER Id
    The Network Id.
    .PARAMETER Clients
    A array of client keys, MACs or IPs.
    .PARAMETER SSIDNumber
    An SSID number to include. If not specified, eveusage histories application usagents for all SSIDs will be returned.
    .PARAMETER StartDate
    The starting date to retrieve date (Cannot be more than 31 days before today).
    .PARAMETER EndDate
    The ending date to retrieve data (Cann<#Do this if a terminating exception happens#>ot ne more than 31 days before today).
    .PARAMETER Days
    Number of days before to day to retrieve date. (Cannot be more than 31 days before today). Default is 1 day.
    .PARAMETER PerPage
    The number of entries per page returned. Acceptable range is 3 - 1000.
    .OUTPUTS
    An array of application usage statistics.
    #>
}

Set-Alias -Name GMNetClientAppUsage -Value Get-MerakiNetworkClientApplicationUsage -Option ReadOnly

function Get-MerakiNetworkClientBandwidthUsage() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('NetworkId')]
        [string]$id,
        [ValidateScript(
            {
                if ($Days) {
                    throw "The StartTime parameter cannot be used with the Days parameter."
                }
                if (-not $EndTime) {
                    throw "The EndTime parameter must be used with the StartTime parameter"
                }
            }
        )]
        [ValidateScript({$_ -is [datetime]})]
        [datetime]$StartTime,
        [ValidateScript(
            {
                if ($Days) {
                    throw "The Days paramegter cannot be used with the EndTime parameter."
                }
                if (-not $StartTime) {
                    throw "The StartTime parameter must be used with teh EndTime parameter."
                }
            }
        )]
        [ValidateScript({$_ -is [datetime]})]
        [datetime]$EndTime,
        [ValidateSet(
            {
                if ($StartTime -or $EndTime) {
                    throw "The Days Parameter dannot be used withteh StartTime and EndTime parameters."
                }
            }
        )]
        [ValidateScript({$_ -is [int]})]
        [int]$Days,
        [ValidateScript({$_ -is [int]})]
        [int]$perPage
    )

    Begin {
        $Headers = Get-Headers

        Set-Variable -Name Query

        if ($StartTime) {
            $_startTime = "{0:s}" -f $StartTime
            $Query += "t0={0}" -f $_startTime            
        }
        if ($EndTime) {
            $_endTime = "{0:s}" -f $EndTime
            if ($Query) {
                $Query += "&"
            }
            $Query += "t1={0}" -f $_endTime
        }
        if ($Days) {
            if ($Query) {
                $Query += "&"
            }
            $ts = [timespan]::FromDays($Days)
            $Query += "timespan={0}" -f ($ts.TotalSeconds)
        }
        if ($perPage) {
            if ($Query) {
                $Query += "&"
            }
            $Query += "perPage={0}" -f $perPage
        }
    }

    Process {
        $Uri = "{0}/networks/{1}/clients/bandwidthUsageHistory" -f $BaseURI, $Id

        if ($Query) {
            $Uri += "?{0}" -f $Query
        }

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Returns traffic consumption rates for all clients.
    .DESCRIPTION
    Returns a timeseries of total traffic consumption rates for all clients on a network within a given timespan, in megabits per second.
    .PARAMETER id
    Network Id
    .PARAMETER StartTime
    The beginning of the timespan for the data. Must be no more than 31 days from today.
    .PARAMETER EndTime
    The end time for the data. Must be nomore than 31 dats after StartTime.
    .PARAMETER Days
    Number fo days prior to today to return data.
    .PARAMETER perPage
    The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
    .OUTPUTS
    Am array of useage statistics.
    #>
}

Set-Alias -Name GMNetCltBWUsage -Value Get-MerakiNetworkClientBandwidthUsage -Option ReadOnly

#Access control Lists

function Get-MerakiSwitchAccessControlList() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('NetworkId')]
        [string]$Id
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/switch/accessControlLists" -f $BaseURI, $Id

        try {
            $id = 1
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
            $response | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "Id" -Value $id
                $id += 1
            }
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Get Meraki switch ACLs
    .DESCRIPTION
    Retrieve Access control LIsts for Meraki Switches
    .PARAMETER Id
    The Network ID
    .OUTPUTS
    An array of ACL objects.
    #>
}

Set-Alias -Name GMSWACL -Value Get-MerakiSwitchAccessControlList

function Add-MerakiSwitchAccessControlEntry() {
    [CmdletBinding()]
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
        [string]$Comment
    )

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
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body
        $response | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "Id" -Value $id
            $Id += 1
        }
        return $response
    } catch {
        throw $_
    }
}

Set-Alias -Name AMSWAce -Value Add-MerakiSwitchAccessControlEntry

function Remove-MerakiSwitchAccessControlEntry() {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [int]$Id
    )

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/switch/accessControlList" -f $BaseURI, $NetworkId

    $Acl = (Get-MerakiSwitchAccessControlList -NetworkId $NetworkId).where({$_.comment -ne "Default rule"})

    $NewAcl = $Acl.Where({$_.Id -ne $id}) | Select-Object * -ExcludeProperty Id

    $body = $NewAcl | ConvertTo-Json -Depth 5 -Compress

    try {
        $Id = 1
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body
        $response | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "Id" -Value $Id
            $Id += 1
        }
        return $response
    } catch {

    }
}

Set-Alias -Name RMSWAce -value Remove-MerakiSwitchAccessControlEntry

function Set-MerakiSwitchAccessControlEntry() {
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
        [string]$Comment
    )

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
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body
        $response | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "Id" -Value Id
            $Id += 1
        }
        return $response
    } catch {
        Throw $_
    }
}