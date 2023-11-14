#Meraki Device Functions

function Get-MerakiDevice() {
    [CmdletBinding()]
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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

    return $response
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
    [CmdletBinding()]
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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Body $body -Headers $Headers -PreserveAuthorizationOnRedirect

    return $response

    <#
    .SYNOPSIS 
    Starts the LED blinking on a Meraki Device.
    .PARAMETER serial
    Serial number of the device.
    .PARAMETER Duration
    Duration ios seconds to blink. Default = 20
    .PARAMETER Duty
    The duty cycle as percent active. Default = 50
    .PARAMETER Period
    The period in milliseconds. Default = 160
    #>
}
Set-Alias -Name StartMDevBlink -Value Start-MerakiDeviceBlink -Option ReadOnly

function Restart-MerakiDevice() {
    [CmdLetBinding()]
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

    $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

    if ($response.success) {
        return $true
    } else {
        return $false
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
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$serial,
        [ValidateScript(
            {
                $_ -le 31
            }
        )]
        [int]$Days=31
    )

    Begin {
        $Headers = Get-Headers
        $_body = @{}
        if ($Days) {
            $ts = [timespan]::FromDays($Days)
            $_body.Add("timespan", $ts.TotalSeconds)
        }
        $body = $_body | ConvertTo-Json -Compress
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
}

Set-Alias -Name GMDevClients -Value Get-MerakiDeviceClients -Option ReadOnly

function Get-MerakiDeviceApplianceUplinks() {
    [CmdletBinding()]
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
}