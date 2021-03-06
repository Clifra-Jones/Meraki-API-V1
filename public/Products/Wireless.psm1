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
}

Set-Alias -Name GMSSIDs -Value Get-MerakiSSIDs -Option ReadOnly

function Get-MerakiSSID() {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$networkId,
        [Parameter(Madatory = $true)]
        [Int]$number
    )

    $Uri = "[0]/networks/{1}/wireless/ssids/{2}" -f $BaseURI, $networkId, $number
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
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
}

Set-Alias -Name GMWirelessStat -Value Get-MerakiWirelessStatus
