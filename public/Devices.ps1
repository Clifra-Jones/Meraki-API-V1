#Meraki Device Functions

<#
.Description
Retrieves a specific Device
#>
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
}

Set-Alias -Name GMNetDev -Value Get-MerakiNetworkDevice -Option ReadOnly

<#
.Description
Blink Network Device LEDs
#>
function Start-MerakiDeviceBlink() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$networkId,
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

    return $response
}

Set-Alias -Name RestartMD -Value Restart-MerakiDevice -Option ReadOnly

