using namespace System.Collections.Generic
#Meraki Network Functions

#region Networks
function Get-MerakiNetwork() {
    [CmdletBinding(DefaultParameterSetName='default')]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [Alias('Id')]
        [String]$networkID
    )

    $Uri = "{0}/networks/{1}" -f $BaseURI, $networkID
    $Headers = Get-Headers

    try {
        $Response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $Response
    } catch {
        $Ex = $_ | Format-ApiException
        $PSCmdlet.ThrowTerminatingError($Ex)
    }
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
    [CmdletBinding(DefaultParameterSetName = 'default')]
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
        $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response        
    }
    catch {
        $Ex = $_ | Format-ApiException
        $PSCmdlet.ThrowTerminatingError($Ex)
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

function Remove-MerakiNetwork() {
    [CmdletBinding(
        SupportsShouldProcess, 
        DefaultParameterSetName = 'default',
        ConfirmIMpact = 'High'
    )]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id
    )

    $Headers = Get-Headers

    $URI = "{0}/networks/{1}" -f $BaseURI, $Id

    $Network = Get-MerakiNetwork -networkID $Id

    if ($PSCmdlet.ShouldProcess("Network $($Network.Name). This cannot be undone!", "DELETE")){
        try {
            $response = Invoke-RestMethod -Method Delete -Uri $Uri -Headers $Headers
            return $response
        } catch {
            $Ex = $_ | Format-ApiException
            $PSCmdlet.ThrowTerminatingError($Ex)
        }
    }

    <#
    .DESCRIPTION
    Removes a Meraki Network from the Organization. Devices will remain in the Organization's inventory.
    This is irreversible, all configuration data and client data will be lost.
    .PARAMETER Id
    The Network ID of the network to be deleted.
    #>
}

function Connect-MerakiNetworkToTemplate() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
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
        throw "Invalid ConfigTemplateId"
    }

    $_Body = @{
        "configTemplateId" = $ConfigTemplateId
        "autoBind" = $AutoBind.IsPresent
    }
    $body = $_Body | ConvertTo-Json -Compress
    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    }
    catch {
        $Ex = $_ | Format-ApiException
        $PSCmdlet.ThrowTerminatingError($Ex)
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
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'default',
        ConfirmImpact = 'High')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId,
        [switch]$RetainConfigs
    )

    $Header = Get-Headers

    $Uri = "{0}/networks/{1}/unbind" -f $BaseURI, $NetworkId

    if ($RetainConfigs.IsPresent) {
        $body = @{"retainConfigs" = "true"} | ConvertTo-Json -Compress
    }

    try {
        $NetworkName = (Get-MerakiNetwork -networkID $NetworkId).Name
        If ($PSCmdlet.ShouldProcess($NetworkName, 'UnBind')) {
            $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Header -Body $body -PreserveAuthorizationOnRedirect
            return $response
        }
    } catch {
        $Ex = $_ | Format-ApiException
        $PSCmdlet.ThrowTerminatingError($Ex)
    }
    <#
    .SYNOPSIS
    Disconnect a network from a template
    .DESCRIPTION 
    Disconnect a Meraki Network from a configuration template
    .PARAMETER NetworkId
    The ID of the network
    .PARAMETER RetainConfigs
    Optional boolean to retain all the current configs given by the template.
    .OUTPUTS
    A network object
    #>
}



function Split-MerakiNetwork() {
    [CmdletBinding(
        SupportsShouldProcess, 
        DefaultParameterSetName = 'default',
        ConfirmImpact = 'High')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NetworkId
    )

    $Header = Get-Headers

    $Uri = "{0}/networks/{1}/split" -f $BaseURI, $NetworkId

    $Network = Get-MerakiNetwork -networkID $NetworkId

    if ($PSCmdlet.ShouldProcess("Network $($Network.Name)", "Split")) {
        try {
            $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Header -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            $Ex = $_ | Format-ApiException
            $PSCmdlet.ThrowTerminatingError($Ex)
        }
    }
    <#
    .SYNOPSIS
    Split network into individual networks.
    .DESCRIPTION
    Split a combined network into individual networks for each type of device.
    .PARAMETER NetworkId
    The Id of then network.
    .OUTPUTS
    An array of network objects
    #>
}


#endregion
function Get-MerakiNetworkDevices () {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param (
        [Parameter(
            Mandatory   = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $True)]
        [Alias('NetworkId')]
        [string]$id
    )

    Begin {

        $Headers = Get-Headers
    }

    Process {
    
        $Uri = "{0}/networks/{1}/devices" -f $BaseURI, $id
        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            $Ex = $_ | Format-ApiException
            $PSCmdlet.ThrowTerminatingError($Ex)
        }
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
    [CmdletBinding(DefaultParameterSetName = 'default')]
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
        [string[]]$ExcludedEventTypes,
        [string]$deviceMac,
        [string]$deviceName,
        [string]$deviceSerial,
        [string]$clientName,
        [string]$clientIP,
        [string]$clientMac,
        [string]$smDeviceName,
        [string]$smDeviceMac,
        [ValidateScript({$_ -is [int]})]
        [ValidateRange(3,1000)]
        [int]$PerPage,
        [int]$Pages = 1
    )

    Begin {

        $Headers = Get-Headers

        # Product Type is a required query.
        $Query = "?productType={0}" -f $ProductType

        if ($PerPage) {
            if ($Query) {$Query += '&'}
            $Query = "{0}perPage={1}" -f $Query, $PerPage
        }

        if ($IncludedEventTypes) {
            if ($Query) {$Query += '&'}
            $Query = "{0}includedEventTypes[]={1}" -f $Query, ($IncludedEventTypes -join ',')
        }

        if ($ExcludedEventTypes) {
            if ($Query) {$Query += '&'}
            $Query = "{0}excludedEventTypes[]={1}" -f $Query, ($ExcludedEventTypes -join ',')
        }

        if ($deviceMac) {
            if ($Query) {$Query += '&'}
            $Query = "{0}deviceMac={1}" -f $Query, $deviceMac
        }

        if ($deviceSerial) {
            if ($Query) {$Query += '&'}
            $Query = "{0}deviceSerial={1}" -f $Query, $deviceSerial
        }

        if ($clientIP) {
            if ($Query) {Query += '&'} 
            $Query = "{0}deviceIP={1}" -f $Query, $deviceSerial
        }

        if ($smDeviceMac) {
            if ($Query) {$Query += '&'}
            $Query = "{0}smDeviceMac={1}" -f $Query, $smDeviceMac
        }

        if ($smDeviceName) {
            if ($Query) {$Query += '&'}
            $Query = "{0}smDeviceName={1}" -f $Query, $smDeviceName
        }

        $Results = [List[PsObject]]::New()
    }

    Process {
        $Uri = "{0}/networks/{1}/events{2}" -f $BaseURI, $id, $Query

        try {
            $response = Invoke-WebRequest -Method GET -Uri $Uri -Body $body -Headers $Headers -PreserveAuthorizationOnRedirect
            [List[PsObject]]$result = ($response.Content | ConvertFrom-Json).Events
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
                        [List[PsObject]]$result = ($response.Content | ConvertFrom-Json).Events
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

            return $Results.ToArray() | Sort-Object occurredAt
        } catch {
            $Ex = $_ | Format-ApiException
            $PSCmdlet.ThrowTerminatingError($Ex)
        }
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
    Pull the first page.
    .PARAMETER last
    Pull the last page.
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
    [CmdletBinding(DefaultParameterSetName = 'default')]
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

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        $Ex = $_ | Format-ApiException
        $PSCmdlet.ThrowTerminatingError($Ex)
    }
    <#
    .SYNOPSIS
    Returns all event types supported by this network.
    .PARAMETER id
    The network ID.
    .OUTPUTS 
    An array of event type objects.
    #>
}

Set-Alias -Name GMNetET -Value Get-MerakiNetworkEventTypes -Option ReadOnly

function Get-MerakiNetworkClients () {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("NetworkId")]
        [string]$id,

        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,31)]
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'timeparts'
        )]
        [decimal]$Days,

        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,24)]
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'timeparts'
        )]
        [int]$Hours,

        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,60)]
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'timeparts'
        )]
        [int]$Minutes,

        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,60)]
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'timeparts'
        )]
        [int]$Seconds,

        [ValidateScript(
            {
                $value = New-Object System.TimeSpan
                [timespan]::TryParse($_, [ref]$value)
            }, ErrorMessage = 'String is not a valid time span'
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'timespan'
        )]
        [string]$TimeSpan,

        [ValidateScript({$_ -is [int]})]
        [int]$PerPage,

        [ValidateScript({$_ -is [int]})]
        [ValidateRange(0,1000)]
        [int]$Pages = 1,

        [ValidateSet("Offline","Online")]
        [string]$Statuses,

        [ValidateScript({$_ -match "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})|([0-9a-fA-F]{4}\\.[0-9a-fA-F]{4}\\.[0-9a-fA-F]{4})$"})]
        [string]$Mac,

        [ValidateScript({$_ -match "\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z"})]
        [string]$IP,

        [string]$PskGroup,
        [string]$OS,
        [string]$Description,

        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,4096)]
        [string]$VLAN,

        [string[]]$recentDeviceConnections,

        [switch]$ToLocalTime
    )
    Begin {          

        $Results = [List[PsObject]]::New()
        $Headers = Get-Headers
        Set-Variable -Name Query 
        if ($StartDate) {
            $Query += "t0={0}" -f ($_startDate.ToString("O"))
        }
        if ($endDate) {
            if ($Query) {$Query += "&"}
            $Query = "{0}t1={1}" -f $Query, ($EndDate.ToString("O"))
        }

        $tsSeconds = 0

        if ($Days) {
            $tsSeconds = [TimeSpan]::FromDays($Days).TotalSeconds
            # if ($Query) {$Query += "&"}
            # $Query = "{0}timespan={1}" -f $Query, $Seconds
        }

        if ($Hours) {
            $tsSeconds +=  [timespan]::FromHours($hours).TotalSeconds
        }

        if ($Minutes) {
            $tsSeconds += [timespan]::FromMinutes($Minutes).TotalSeconds
        }

        if ($Seconds) {
            $tsSeconds += $seconds
        }

        if ($TimeSpan) {
            $tsSeconds = [timespan]::Parse($timespan).TotalSeconds
        }

        if ($tsSeconds -gt 0) {
            if ($query) { $Query += "&"}
            $Query = "{0}timespan={1}" -f $Query, $tsSeconds
        }

        if ($Statuses) {
            if ($Query) {$Query += "&"}
            $Query = "{0}statuses={1}" -f $Query, $Statuses
        }
        if ($Mac) {
            if ($Query) {$Query += "&"}
            $Query = "{0}mac={1}" -f $Query, $Mac
        }
        if ($IP) {
            if ($Query) {$Query += "&"}
            $Query = "{0}ip={1}" -f $Query, $IP
        }
        if ($OS) {
            if ($Query) {$Query += "&"}
            $Query = "{0}os={1}" -f $Query, $OS
        }
        if ($Description) {
            if ($Query) {$Query += "&"}
            $Query = "{0}description={1}" -f $query, $Description
        }
        if ($VLAN) {
            if ($Query) {$Query += "&"}
            $Query = "{0}vlan={1}" -f $Query, $VLAN
        }
        if ($recentDeviceConnections) {
            if ($Query) {$Query += "&"}
            $Query = "{0}recentDeviceConnections={1}" -f $Query, $recentDeviceConnections
        }

        if ($PerPage) {
            if ($Query) {$Query += "&"}
            $Query = "{0}perPage={1}" -f $Query, $PerPage
        }
    
   }
    
    Process {
        $Uri = "{0}/networks/{1}/clients" -f $BaseURI, $Id
        if ($Query) {
            $Uri += "?{0}" -f $Query
        }
        try {            
            #$response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers
            $response = Invoke-WebRequest -Method Get -Uri $Uri -Headers $Headers
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
                        $response = Invoke-WebRequest -Method Get -Uri $Uri -Headers $Headers
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

        } catch {
            $Ex = $_ | Format-ApiException
            $PSCmdlet.ThrowTerminatingError($Ex)
        }
    }

    End {
        $Results | ForEach-Object {
            if ($null -eq $_.description) {
                $_.description = $_.mac
            }
            $_ | Add-Member -MemberType NoteProperty -Name NetworkId -Value $id
            $_ | Add-Member -MemberType NoteProperty -Name ClientId -Value $_.id
        }
        if ($ToLocalTime) {
            $Results | ForEach-Object {
                $_.firstSeen = $_.firstSeen.ToLocalTime()
                $_.lastSeen = $_.lastSeen.ToLocalTime()
            }
        }
        return $Results.ToArray()
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
    Number of days back from today to retrieve client connections. If specified do not specify StartDate or EndDate (cannot be more than 31 days from today)
    .PARAMETER PerPage
    Sets the number of items returned per page. 
    .PARAMETER Pages
    Sets the number of pages returned. Default is 1, 0 returns all pages.
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
    .PARAMETER PskGroup
    Filters clients based on partial or full match for the iPSK name field.
    .OUTPUTS
    A collection of client objects.
    #>
}

Set-Alias -Name GMNetClients -Value Get-MerakiNetworkClients -Option ReadOnly

function Get-MerakiNetworkClientApplicationUsage() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('NetworkId')]
        [string]$Id,

        [string]$Clients,

        [ValidateScript({$_ -is [int]})]
        [ValidateRange(0,14)]
        [int]$SSIDNumber,

        [ValidateScript({$_ -is [DateTime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfiles', Mandatory)]  
        [DateTime]$StartDate,

        [ValidateScript({$_ -is [DateTime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfiles', Mandatory)] 
        [DateTime]$EndDate,

        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,31)]
        [Parameter(ParameterSetName = 'days', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithProfile', Mandatory)]
        [int]$Days,

        [ValidateScript({$_ -is [int]})]
        [ValidateSet(3,1000)]
        [int]$PerPage,

        [ValidateScript({$_ -is [int]})]
        [int]$Pages = 1
    )

    Begin {      

        $Headers = Get-Headers
        
        if ($PerPage) {
            $Query = "perPage={0}" -f $perPage
        }

        if ($Clients) {
            if ($Query) {$Query += '&'}
            $Query = "{0}clients = {1}" -f $Query, $Clients 
        }
    
        if ($SSIDNumber) {
            if ($Query) {$Query += "&"}
            $Query = "{0}ssidNumber={1}" -f $Query, $SSIDNumber
        }
        if ($StartDate) {
            if ($Query) {$Query += "&"}
            $Query = "{0}t0={1}" -f $Query, ($startDate.ToString("O"))
        }
        if ($EndDate) {
            if ($Query) {$Query += "&"}
            $Query = "{0}t1={1}" -f $Query, ($EndDate.ToString("O"))
        }
        if ($Days) {
            $Seconds = [timespan]::FromDays($Days).TotalSeconds
            if ($Query) {$Query += "&"}
            $Query = "{0}timespan={1}" -f $Query, $Seconds
        }
        if ($PerPage) {
            if ($Query) {$Query += "&"}
            $Query = "{0}perPage={1}" -f $Query, $PerPage
        }

        $Results = [List[PsObject]]::New()
    }

    Process {
        $Uri = "{0}/networks/{1}/clients/applicationUsage" -f $BaseURI, $Id
        if ($Query) {
            $Uri = "{1}?{1}" -f $Uri, $Query
        }

        try {
            $response = Invoke-WebRequest -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            [List[PsObject]]$result = $response.Content | ConvertFrom-Json
            if ($result) {
                $Result.AddRange($result)
            }
            $Pages
            if ($Pages -ne 1) {
                $done = $false
                do {
                    if ($response.RelationLink['next']) {
                        $Uri = $response.RelationLink['next']
                        $response = Invoke-WebRequest -Method Get -Uri $Uri -Header $Headers -PreserveAuthorizationOnRedirect
                        [List[PsObject]]$result = $response.Content | ConvertFrom-Json
                        if ($result) {
                            $Results.Add($result)
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
            return $Results.ToArray()
        } catch {
            $Ex = $_ | Format-ApiException
            $PSCmdlet.ThrowTerminatingError($Ex)
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
    An SSID number to include. If not specified, usage histories application usage for all SSIDs will be returned.
    .PARAMETER StartDate
    The starting date to retrieve date (Cannot be more than 31 days before today).
    .PARAMETER EndDate
    The ending date to retrieve data (Cannot be more than 31 days after today).
    .PARAMETER Days
    Number of days before to day to retrieve date. (Cannot be more than 31 days before today). Default is 1 day.
    .PARAMETER PerPage
    The number of entries per page returned. Acceptable range is 3 - 1000.
    .PARAMETER ClientId
    A list of client keys, MACs or IPs separated by comma.
    .PARAMETER Pages
    Number of pages to return. Default is all.
    .OUTPUTS
    An array of application usage statistics.
    #>
}

Set-Alias -Name GMNetClientAppUsage -Value Get-MerakiNetworkClientApplicationUsage -Option ReadOnly

function Get-MerakiNetworkClientBandwidthUsage() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('NetworkId')]
        [string]$id,

        [ValidateScript({$_ -is [DateTime]})]
        [Alias('StartTime')]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfiles', Mandatory)]  
        [datetime]$StartDate,

        [ValidateScript({$_ -is [DateTime]})]
        [Alias('EndTime')]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfiles', Mandatory)] 
        [datetime]$EndDate,

        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,31)]
        [Parameter(ParameterSetName = 'days', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithProfile', Mandatory)]
        [int]$Days,

        [ValidateScript({$_ -is [int]})]
        [ValidateRange(3,1000)]
        [int]$perPage,

        [ValidateScript({$_ -is [int]})]
        [Int]$Pages

    )

    Begin {

        $Headers = Get-Headers

        Set-Variable -Name Query

        if ($StartDate) {            
            $Query = "t0={0}" -f ($StartDate.ToString("O"))
        }
        if ($EndDate) {
            if ($Query) {$Query += "&"}
            $Query = "{0}t1={1}" -f $Query, ($EndDate.ToString("O"))
        }
        if ($Days) {
            if ($Query) {$Query += "&"}
            $Seconds = [TimeSpan]::FromDays($Days).TotalSeconds
            $Query = "{0}timespan={1}" -f $Query, $Seconds
        }
        if ($perPage) {
            if ($Query) {$Query += "&"}
            $Query = "{0}perPage={1}" -f $Query, $perPage
        }

        $Results = [List[PsObject]]::New()
    }

    Process {
        $Uri = "{0}/networks/{1}/clients/bandwidthUsageHistory" -f $BaseURI, $Id

        if ($Query) {
            $Uri = "{0}?{1}" -f $Uri, $Query
        }

        try {
            $response = Invoke-WebRequest -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
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
            return $Results.ToArray()
        } catch {
            $Ex = $_ | Format-ApiException
            $PSCmdlet.ThrowTerminatingError($Ex)
        }
    }
    <#
    .SYNOPSIS
    Returns traffic consumption rates for all clients.
    .DESCRIPTION
    Returns a time series of total traffic consumption rates for all clients on a network within a given timespan, in megabits per second.
    .PARAMETER id
    Network Id
    .PARAMETER StartDate
    The beginning of the timespan for the data. Must be no more than 31 days from today.
    .PARAMETER EndDate
    The end time for the data. Must be no more than 31 days after StartTime.
    .PARAMETER Days
    Number fo days prior to today to return data.
    .PARAMETER perPage
    The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
    .PARAMETER Pages
    Number of pages to return. Default is all.
    .OUTPUTS
    Am array of usage statistics.
    #>
}

Set-Alias -Name GMNetCltBWUsage -Value Get-MerakiNetworkClientBandwidthUsage -Option ReadOnly

function Get-MerakiNetworkTraffic() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,

        [ValidateScript({$_ -is [DateTime]})]
        [Alias('StartTime')]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfiles', Mandatory)]  
        [datetime]$StartDate,

        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,31)]
        [Parameter(ParameterSetName = 'days', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithProfile', Mandatory)]
        [int]$Days,

        [ValidateSet('combined', 'wireless', 'switch', 'appliance')]
        [string]$DeviceType = 'combined'
    )

    Begin {

        if ($Days) {
            $Seconds = [TimeSpan]::FromDays($Days).TotalSeconds
            $Query = "timespan={0}" -f $Seconds
        }

        if ($StartDate) {
            if ($Query) {$Query += '&'}
            $Query = "{0}t0={1}" -f $Query, ($StartDate.ToString("O"))
        }
    }

    Process {
        $Uri = "{0}/networks/{1}/traffic" -f $BaseURI, $Id

        if ($Query) {
            $Uri = "{0}?{1}" -f $Uri, $Query
        }

        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            $Ex = $_ | Format-ApiException
            $PSCmdlet.ThrowTerminatingError($Ex)
        }
    }
    <#
    .DESCRIPTION
    Return the traffic analysis data for this network. Traffic analysis with hostname visibility must be enabled on the network.
    .PARAMETER Id
    The Id of the network to retrieve the traffic.
    .PARAMETER StartDate
    The beginning date/time to retrieve the data. Maximum is 30 days prior to the current date.
    .PARAMETER Days
    Days prior to the current date to retrieve data. Cannot be more than 30 day prior to the current date.
    .PARAMETER DeviceType
    The device type to retrieve the data for. Defaults to 'combined'. When using 'combined', for each rule the data will come from the device type with the most usage.
    #>
}