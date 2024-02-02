#Meraki Device Functions

function Get-MerakiDevice() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$Serial
    )

    $Uri = "{0}/devices/{1}" -f $BaseURI, $Serial
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Returns a Meraki Device.
    .PARAMETER Serial
    The serial number of the device.
    .OUTPUTS
    A Meraki device object.
    #>
}

Set-Alias -Name GMNetDev -Value Get-MerakiDevice -Option ReadOnly

function Start-MerakiDeviceBlink() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$serial,
        [int]$Duration,
        [int]$Duty,
        [int]$Period
    )

    $Uri = "{0}/devices/{1}/blinkLeds" -f $BaseURI, $serial
    $Headers = Get-Headers

    $psBody = @{}
    if ($Duration) {
        $psBody.Add("duration", $Duration)
    }
    if ($Duty) {    
        $psBody.Add("duty", $Duty)
    }
    if ($Period) {
        $psBody.aDD("period", $Period)
    }
    $body = $psBody | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Body $body -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS 
    Starts the LED blinking on a Meraki Device.
    .PARAMETER serial
    Serial number of the device.
    .PARAMETER Duration
    Duration ios seconds to blink. Default = 20
    .PARAMETER Duty
    The duty cycle as percent active. Default = 50
    .PARAMETER ProfileName
    Optional Profile name.
    #>
}
Set-Alias -Name StartMDevBlink -Value Start-MerakiDeviceBlink -Option ReadOnly

function Restart-MerakiDevice() {
    [CmdLetBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]$serial
    )

    $Uri = "{0}/devices/{1}/reboot" -f $BaseURI, $serial
    $headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Restart a Meraki device.
    .PARAMETER serial
    The serial number of the device.
    .OUTPUTS
    True if successful, false if failed.
    #>
}

Set-Alias -Name RestartMD -Value Restart-MerakiDevice -Option ReadOnly

function Get-MerakiDeviceClients() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$serial,
        [ValidateScript({$_ -is [datetime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfiles', Mandatory)]                
        [datetime]$StartDate,

        [Parameter(ParameterSetName = 'days', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithProfile', Mandatory)]
        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,31)]
        [int]$Days
    )

    Begin {

        $Headers = Get-Headers

        if ($StartDate) {
            $Query = "t0={0}" -f ($StartDate.ToString("O"))
        }
        if ($Days) {
            if ($Query) {$Query += '&'}
            $Seconds = [TimeSpan]::FromDays($Days).TotalSeconds
            $Query = "{0}timespan={1}" -f $Query, $Seconds
        }
    }

    Process {
        $Uri = "{0}/devices/{1}/clients" -f $BaseURI, $serial
        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
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
    Returns clients associated with the device.
    .DESCRIPTION
    List the clients of a device, up to a maximum of a month ago. The usage of each client is returned in kilobytes. If the device is a switch, the switchport is returned; otherwise the switchport field is null.
    .PARAMETER serial
    The serial number of the device.
    .PARAMETER StartDate
    The starting date to retrieve data. Maximum 31 days prior to today.
    .PARAMETER Days
    Number of days prior to today to retrieve data. Maximum of 31 days prior to today.
    #>
}

Set-Alias -Name GMDevClients -Value Get-MerakiDeviceClients -Option ReadOnly

function Get-MerakiDeviceApplianceUplinks() {
    [CmdletBinding(DefaultParameterSetName)]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$Serial
    )

    $Headers = Get-Headers

    $Uri = "{0}/devices/{1}/appliance/uplinks/settings" -f $BaseURI, $Serial

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .DESCRIPTION
    Return the uplink settings for an MX appliance
    .PARAMETER Serial
    Serial number of the MX device.
    #>   
}

function Submit-MerakiDeviceClaim() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(Mandatory)]
        [string[]]$Serials
    )

    $Headers = Get-Headers

    $Uri = "{0}/networks/{1}/devices/claim" -f $BaseURI, $Id

    $_Body = @{
        serials = $Serials
    }

    $Body = $_Body | ConvertTo-Json -Depth 3 -Compress

    try {
        Invoke-RestMethod -Method Post -Uri $Uri -Headers $Headers -Body $Body
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Claim devices into a network.
    .DESCRIPTION
    This function wil claim the devices specified in the Serials parameter and then add them into the specified network.
    .PARAMETER Id
    The Network Id
    .PARAMETER Serials
    An array of serial numbers to claim into the network.

    #>
}

function Update-MerakiDevice {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$Serial,
        [string]$Name,
        [string]$floorPlanId,
        [string]$Notes,
        [string]$SwitchProfileId,
        [switch]$MoveMapMaker,
        [int]$Latitude,
        [int]$Longitude,
        [string[]]$Tags
    )

    $Headers = Get-Headers

    $Uri = "{0}/devices/{1}" -f $BaseURI, $Serial

    $_Body = @{}

    if ($Name) {$_Body.Add("name",$Name)}
    if ($floorPlanId) {$_Body.Add("floorPlanId", $floorPlanId)}
    if ($Notes) {$_Body.Add("notes", $Notes)}
    if ($SwitchProfileId) {"switchProfileId", $SwitchProfileId}
    if ($MoveMapMaker) {$_Body.Add("moveMapMaker", $MoveMapMaker)}
    if ($Latitude) {$_Body.Add("lat", $Latitude)}
    if ($Longitude) {$_Body.Add("lng", $Longitude)}
    if ($Tags) {$_Body.Add("tags", $Tags)}

    $body = $_Body | ConvertTo-Json -Depth 3 -Compress

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    } catch {
        throw $_
    }
    <#
    .DESCRIPTION
    Update the attributes of a Device.
    .PARAMETER Serial
    The serial number of the device.
    .PARAMETER Name
    The name of the device.
    .PARAMETER floorPlanId
    The floor plan to associate to this device. null disassociates the device from the floorplan.
    .PARAMETER Notes
    The notes for the device. String. Limited to 255 characters.
    .PARAMETER SwitchProfileId
    The ID of a switch template to bind to the device (for available switch templates, see the 'Switch Templates' endpoint). Use null to unbind the switch device from the current profile. For a device to be bindable to a switch template, it must (1) be a switch, and (2) belong to a network that is bound to a configuration template.
    .PARAMETER MoveMapMaker
    Whether or not to set the latitude and longitude of a device based on the new address. Only applies when lat and lng are not specified.
    .PARAMETER Latitude
    The latitude of a device
    .PARAMETER Longitude
    The longitude of a device
    .PARAMETER Tags
    An array of tags of a device
    .OUTPUTS
    A Device object.
    #>
}