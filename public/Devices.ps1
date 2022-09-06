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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

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

Set-Alias -Name GMNetDev -Value Get-MerakiNetworkDevice -Option ReadOnly

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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Body $body -Headers $Headers

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

    $response = Invoke-RestMethod -Method POST -Uri $Uri -Headera $Headers

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

