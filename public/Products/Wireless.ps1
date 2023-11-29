using namespace System.Collections.Generic
# Wireless Functions

function Get-MerakiSSIDs() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('NetworkId')]
        [string]$id
    )

    $Uri = "{0}/networks/{1}/wireless/ssids" -f $BaseURI, $id
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Returns the Wireless SSIDs for a Meraki Network.
    .PARAMETER id
    The network Id.
    .OUTPUTS
    An array of Meraki SSID objects.
    #>
}

Set-Alias -Name GMSSIDs -Value Get-MerakiSSIDs -Option ReadOnly

function Get-MerakiSSID() {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$networkId,
        [Parameter(Mandatory = $true)]
        [Int]$number
    )

    $Uri = "[0]/networks/{1}/wireless/ssids/{2}" -f $BaseURI, $networkId, $number
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS 
    Returns a Meraki SSID for a network.
    .PARAMETER networkId
    The network ID.
    .PARAMETER number
    The SSID Number.
    .OUTPUTS
    A Meraki SSID Object.
    #>
}

Set-Alias -Name GMSSID -Value Get-MerakiSSID -Option ReadOnly

function Get-MerakiWirelessStatus() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$serial
    )

    $Uri = '{0}/devices/{1}/wireless/status' -f $BaseURI, $serial
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Returns the status of a Meraki Access Point.
    .PARAMETER serial
    The serial number of the Access Point.
    .OUTPUTS
    A Meraki Access Point status object.
    #>
}

Set-Alias -Name GMWirelessStat -Value Get-MerakiWirelessStatus

function Get-NetworkWirelessClientConnectionStats() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$Id,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$ClientId,

        [ValidateScript({$_ -is [datetime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfiles', Mandatory)] 
        [datetime]$StartDate,

        [ValidateScript({$_ -is [datetime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfile', Mandatory)]
        [DateTime]$EndDate,

        [Parameter(ParameterSetName = 'days', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithProfile', Mandatory)]
        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,31)]
        [int]$Days,

        [ValidateSet('2.5', '5', '6')]
        [string]$Band,

        [ValidateRange(0,14)]
        [ValidateScript({$_ -is [int]})]
        [string]$SSID,

        [ValidateScript({ $_ -is [int] })]
        [ValidateRange(1,4096)]
        [int]$VLAN,

        [string]$APTag
    )

    Begin {
        $Headers = Get-Headers

        Set-Variable -Name Query

        if ($StartDate) {
            $Query = "t0={0}" -f ($StartDate.ToString("O"))
        }
        if ($EndDate) {
            if ($Query) {$Query += '&'}
            $Query = "{0}t1={1}" -f $Query, ($endDate.ToString("O"))
        }
        if ($Days) {
            if ($Query) {$Query += '&'}
            $Seconds = [timespan]::FromDays($Days).TotalSeconds
            $Query = "{0}timespan={1}" -f $Query, $Seconds
        }
        if ($Band) {
            if ($Query) {$Query += '&'}
            $Query = "{0}band={1}" -f $Query, $Band
        }
        if ($SSID) {
            if ($Query) {$Query += '&'}
            $Query = "{0}ssid={1}" -f $Query, $SSID
        }
        if ($VLAN) {
            if ($Query) {$Query += '&'}
            $Query = "{0}vlan={1}" -f $Query, $VLAN
        }
        if ($APTag) {
            if ($Query) {$Query += '&'}
            $Query = "{0}apTag={1}" -f $Query, $APTag
        }
    }

    Process {
        $Uri = "{0}/network/{1}/wireless/clients/connectionStats" -f $BaseURI, $Id
        if ($Query) {
            $Uri = "{0}?{1}" -f $Uri, $Query
        }
        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        }
        catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Returns aggregated connectivity info for this network, grouped by clients
    .DESCRIPTION
    Returns aggregated connectivity info for this network, grouped by clients for the given time period, band, SSID VLAN of AP Tag.
    .PARAMETER Id
    The Network Id.
    .PARAMETER StartDate
    The starting date to return data. Must be no more that 7 days before today.
    .PARAMETER EndDate
    The ending date to return data. Must be no more than 7 days before today.
    .PARAMETER Days
    The number of days prior to today to return data. Must be no more that 7 days before today.
    .PARAMETER Band
    Filter results by band (either '2.4', '5' or '6'). Note that data prior to February 2020 will not have band information.
    .PARAMETER SSID
    Filter results by SSID.
    .PARAMETER VLAN
    Filter results by VLAN.
    .PARAMETER APTag
    Filter results by AP Tag.
    .OUTPUTS
    A collection of connectivity information objects.
    #>
}

function Get-MerakiWirelessAirMarshal() {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$Id
    )

    $Uri = "{0}/networks/{1}/wireless/airMarshal" -f $BaseURI, $id
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
        return $response
    }
    catch {
        throw $_
    }
}

function Get-MerakiWirelessUsageHistory() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,

        [ValidateScript({$_ -is [datetime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfiles', Mandatory)]                
        [datetime]$StartDate,

        [ValidateScript({$_ -is [datetime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfile', Mandatory)]
        [datetime]$EndDate,

        [Parameter(ParameterSetName = 'days', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithProfile', Mandatory)]
        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,31)]
        [int]$Days,

        [ValidateSet(300, 600, 1200, 3600, 14400, 86400)]
        [int]$Resolution,

        [switch]$AutoResolution,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [string]$ClientId,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Alias('DeviceSerial')]
        [string]$Serial,

        [string]$APTag,

        [ValidateSet('2.4', '5', '6')]
        [string]$Band,

        [ValidateSet(0,14)]
        [Int]$SsidNumber,

        [Parameter(ParameterSetName = 'org', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [string]$OrgId,

        [Parameter(ParameterSetName = 'profile')]
        [Parameter(ParameterSetName = 'datesWithProfile')]
        [Parameter(ParameterSetName = 'daysWithProfile')]
        [string]$ProfileName
    )

    Begin {
        $Headers = Get-Headers

        if ($StartDate) {
            $Query = "t0={0}" -f ($StartDate.ToString("O"))
        }

        if ($EndDate) {
            if ($Query) {$Query += '&'}
            $Query = "{0}t1={1}" -f $Query, ($EndDate.ToString("0"))
        }

        if ($Days) {
            if ($Query) {$Query += '&'}
            $Seconds = ([TimeSpan]::FromDays($DaysPast)).TotalSeconds    
            $Query = "{0}timespan={1}" -f $Query, $Seconds
        }

        If ($Resolution) {
            if ($Query) {$Query += "&"}
            $Query = "{0}resolution={1}" -f $Query, $Resolution
        }
        if ($AutoResolution) {
            if ($Query) {$Query += "&"}
            $Query = "{0}autoResolution=true" -f $Query
        }
        if ($APTag) {
            if ($Query) {$Query += "&"}
            $Query = "{0}apTag={1}" -f $Query, $APTag
        }
        if ($Band) {
            if ($Query) {$Query += "&"}
            $Query = "{0}band={1}" -f $Query, $Band
        }
        if ($SsidNumber) {
            if ($Query) {$Query += "&"}
            $Query = "{0}ssid={1}" -f $Query, $SsidNumber
        }

        if ($ClientId) {
            if ($Query) {$Query += "&"}
            $Query = "{0}clientId={1}" -f $Query, $ClientId
        }

        if ($Serial) {
            if ($Query) {$Query += "&"}
            $Query = "{0}serial={1}" -f $Query, $Serial
        }
    }
        
    Process {

        $Uri = "{0}/networks/{1}/wireless/usageHistory" -f $BaseURI, $Id

        if ($ClientId) {
            if ($Query) {$Query += "&"}
            $Query = "{0}clientId={1}" -f $Query, $ClientId
        }

        if ($Serial) {
            if ($Query) {$Query += "&"}
            $Query = "{0}deviceSerial={1}" -f $Query, $Serial
        }

        if ($Query) {
            $Uri = "{0}?{1}" -f $Uri, $Query
        }

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        }
        catch {
            throw $_
        }               
    }
}

function Get-MerakiWirelessDataRateHistory() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [ValidateScript({$_ -is [datetime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfiles', Mandatory)]  
        [ValidateScript({
            ((Get-Date) - $_).Days -le 31
        })]
        [datetime]$StartDate,

        [ValidateScript({$_ -is [datetime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfile', Mandatory)]
        [ValidateSet({
            ($_ - $StartDate).Days -le 31
        })]
        [datetime]$EndDate,

        [Parameter(ParameterSetName = 'days', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithProfile', Mandatory)]
        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,31)]
        [int]$Days,

        [ValidateSet(300, 600, 1200, 3600, 14400, 86400)]
        [int]$TimeResolution,

        [switch]$AutoResolution,

        [string]$ClientId,
        [Alias('DeviceSerial')]
        [string]$Serial,
        [string]$APTag,

        [ValidateSet('2.4','5','6')]
        [string]$Band,
        [ValidateSet(0,24)]
        [Int]$SsidNumber,
        [switch]$ExcludeNoData,

        [Parameter(ParameterSetName = 'org', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [string]$OrgId,

        [Parameter(ParameterSetName = 'profile')]
        [Parameter(ParameterSetName = 'datesWithProfile')]
        [Parameter(ParameterSetName = 'daysWithProfile')]
        [string]$ProfileName
    )

    Begin {
        $Headers = Get-Headers
        if ($Days) {
            $Seconds = ([Timespan]::FromDays($DaysPast)).TotalSeconds    
            $Query = "timespan={0}" -f $Seconds
        }

        if ($StartDate) {
            if ($Query) {$Query += '&'}
            $Query = "{0}t0={1}" -f $Query, ($StartDate.ToSingle("O"))
        }

        if ($EndDate) {
            $Query = "{0}t1={1}" -f $Query, ($EndDate.ToString("O"))
        }

        if ($ClientId) {
            if ($Query) {$Query += '&'}
            $Query = "{0}clientId={1}" -f $Query, $ClientId
        }

        if ($Serial) {
            if ($Query) {$Query += '&'}
            $Query = "{0}deviceSerial={1}" -f $Query, $Serial
        }

        If ($Resolution) {
            if ($Query) {$Query += '&'}
            $Query = "{0}resolution={1}" -f $qParams, $Resolution
        }
        if ($AutoResolution) {
            if ($Query) {$Query += '&'}
            $Query = "{0}autoResolution=true" -f $Query
        }
        if ($APTag) {
            if ($Query) {$Query += '&'}
            $Query = "{0}apTag={1}" -f $Query, $APTag
        }
        if ($Band) {
            if ($Query) {$Query += '&'}
            $Query = "{0}band={1}" -f $Query, $Band            
        }
        if ($Ssid) {
            if ($Query) {$Query += '&'}
            $Query = "{0}ssid={1}" -f $Query, $SsidNumber
        }
    }

    Process {
        

        $Uri = "{0}/networks/{1}/wireless/dataRateHistory" -f $BaseURI, $Id

        if ($Query) {
            $Uri = "{0}{1}" -f $Uri, $Query
        }

        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            if ($ExcludeNoData) {
                $result = $response |Where-Object {$null -ne $_.averageKbps -and $null -ne $_.downloadKbps -and $null -ne $_.uploadKbps}
            } else {
                $result = $response
            }
            $result | ForEach-Object {
                if ($Serial) {
                    $_ | Add-Member -MemberType NoteProperty -Name DeviceSerial -Value $Serial
                }
                if ($ClientId) {
                    $_ | Add-Member -MemberType NoteProperty -Name ClientId -Value $ClientId
                }
            }
            return $result
        } catch {
            throw $_
        }
    }
}