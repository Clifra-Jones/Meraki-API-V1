# Wireless Functions

function Get-MerakiSSIDs() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$id
    )

    $Uri = "{0}/networks/{1}/wireless/ssids" -f $BaseURI, $id
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

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
