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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

    return $response
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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

    return $response
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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

    return $response
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

function Get-NetworkWirelessClientConnectionStatus() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$Id,
        [Parameter(ParameterSetName = 'dates')]
        [ValidateScript({ $_ -is [datetime] })]
        [datetime]$StartDate,
        [Parameter(ParameterSetName = 'dates')]
        [ValidateScript({ $_ -is [datetime] })]
        [DateTime]$EndDate,
        [Parameter(ParameterSetName = 'days')]
        [ValidateScript({ $_ -is [int] })]
        [int]$Days,
        [ValidateSet('2.5', '5', '6')]
        [string]$Band,
        [string]$SSID,
        [ValidateScript({ $_ -is [int] })]
        [int]$VLAN,
        [string]$APTag
    )

    Begin {
        $Headers = Get-Headers

        Set-Variable -Name Query

        if ($StartDate) {
            $_startDate = "{0:s}" -f $StartDate
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
        if ($Band) {
            if ($Query) {
                $Query += "&"
            }
            $Query += "band={0}" -f $Band
        }
        if ($SSID) {
            if ($Query) {
                $Query += "&"
            }
            $Query += "ssid={0}" -f $SSID
        }
        if ($VLAN) {
            if ($Query) {
                $Query += "&"
            }
            $Query += "vlan={0}" -f $VLAN
        }
        if ($APTag) {
            if ($Query) {
                $Query += "&"
            }
            $Query += "apTag={0}" -f $APTag
        }
    }

    Process {
        $Uri = "{0}/network/{1}/wireless/clients/connectionStats" -f $BaseURI, $Id
        if ($Query) {
            $Usr += "?{0}" -f $Query
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
        [int]$DaysPast,
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
        [Int]$SsidNumber
    )

    Begin {
        $Headers = Get-Headers
        if ($DaysPast) {
            $Seconds = ([Timespan]::FromDays($DaysPast)).TotalSeconds    
            $qParams = "?timespan={0}" -f $Seconds
        }

        If ($Resolution) {
            if ($qParams) {
                $qParams = "{0}&" -f $qParams
            }
            else {
                $qParams = "{0}?" -f $qParams
            }
            $qParams = "{0}resolution={1}" -f $qParams, $Resolution
        }
        if ($AutoResolution) {
            if ($qParams) {
                $qParams = "{0}&" -f $qParams
            }
            else {
                $qParams = "{0}?" -f $qParams
            }
            $qParams = "{0}autoResolution=true" -f $qParams
        }
        if ($APTag) {
            if ($qParams) {
                $qParams = "{0}&" -f $qParams
            }
            else {
                $qParams = "{0}?" -f $qParams
            }
            $qParams = "{0}apTag={1}" -f $qParams, $APTag
        }
        if ($Band) {
            if ($qParams) {
                $qParams = "{0}&" -f $qParams
            }
            else {
                $qParams = "{0}?" -f $qParams
            }
            $qParams = "{0}band={1}" -f $qParams, $Band
        }
        if ($SsidNumber) {
            if ($qParams) {
                $qParams = "{0}&" -f $qParams
            }
            else {
                $qParams = "{0}?" -f $qParams
            }
            $qParams = "{0}ssid={1}" -f $qParams, $SsidNumber
        }
    }

    Process {

        $Uri = "{0}/networks/{1}/wireless/usageHistory" -f $BaseURI, $Id

        if ($ClientId) {
            if ($qParams) {
                $qParams = "{0}&" -f $qParams
            } else {
                $qParams = "{0}?" -f $qParams
            }
            $qParams = "{0}clientId={1}" -f $qParams, $ClientId
        }
        if ($Serial) {
            if ($qParams) {
                $qParams = "{0}&" -f $qParams
            } else {
                $qParams = "{0}?" -f $qParams
            }
            $qParams = "{0}deviceSerial={1}" -f $qParams, $Serial
        }

        $Uri = "{0}{1}" -f $Uri, $qParams
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
        [int]$DaysPast = 1,
        [ValidateSet(300, 600, 1200, 3600, 14400, 86400)]
        [int]$TimeResolution,
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
        [Int]$SsidNumber,
        [switch]$ExcludeNoData
    )

    Begin {
        $Headers = Get-Headers
        if ($DaysPast) {
            $Seconds = ([Timespan]::FromDays($DaysPast)).TotalSeconds    
            $qParams = "?timespan={0}" -f $Seconds
        }

        If ($Resolution) {
            if ($qParams) {
                $qParams = "{0}&" -f $qParams
            }
            else {
                $qParams = "{0}?" -f $qParams
            }
            $qParams = "{0}resolution={1}" -f $qParams, $Resolution
        }
        if ($AutoResolution) {
            if ($qParams) {
                $qParams = "{0}&" -f $qParams
            }
            else {
                $qParams = "{0}?" -f $qParams
            }
            $qParams = "{0}autoResolution=true" -f $qParams
        }
        if ($APTag) {
            if ($qParams) {
                $qParams = "{0}&" -f $qParams
            }
            else {
                $qParams = "{0}?" -f $qParams
            }
            $qParams = "{0}apTag={1}" -f $qParams, $APTag
        }
        if ($Band) {
            if ($qParams) {
                $qParams = "{0}&" -f $qParams
            }
            else {
                $qParams = "{0}?" -f $qParams
            }
            $qParams = "{0}band={1}" -f $qParams, $Band            
        }
        if ($Ssid) {
            if ($qParams) {
                $qParams = "{0}&" -f $qParams
            }
            else {
                $qParams = "{0}?" -f $qParams
            }            
            $qParams = "{0}ssid={1}" -f $qParams, $SsidNumber
        }
    }

    Process {
        $QueryParams=$null

        $Uri = "{0}/networks/{1}/wireless/dataRateHistory" -f $BaseURI, $Id

        if ($ClientId) {
            if ($qParams) {
                $QueryParams = "{0}&clientId={1}" -f $qParams, $ClientId
            } else {
                $QueryParams = "?clientId={0}" -f $ClientId
            }
        }
        if ($Serial) {
            if ($QueryParams) {
                $QueryParams = "{0}&deviceSerial={1}" -f $QueryParams, $Serial
            } else {
                if ($qParams) {
                    $QueryParams = "{0}&deviceSerial={1}" -f $qParams, $Serial
                } else {
                    $QueryParams = "?deviceSerial={0}" -f $Serial
                }
            }
        }

        $Uri = "{0}{1}" -f $Uri, $QueryParams

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