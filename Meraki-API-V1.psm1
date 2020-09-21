#Root module for Meraki API Version 1

$global:BaseURI = "https://api.meraki.com/api/v1"

$global:paging = @{
    next = $null
    prev = $null
    first = $null
    last = $null
}


#Private function
function global:Read-Config () {
    $ConfigPath = "$($env:USERPROFILE)/.meraki/config.json"
    $config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
    return $config
}

function global:ConvertTo-UTime () {
    Param(
        [datetime]$DateTime
    )

    $uTime = ([System.DateTimeOffset]$DateTime).ToUnixTimeMilliseconds() / 1000

    return $Utime
}

function global:ConvertFrom-UTime() {
    Param(
        [decimal]$Utime
    )

    [DateTime]$DateTime = [System.DateTimeOffset]::FromUnixTimeMilliseconds(1000 * $Utime).LocalDateTime

    return $DateTime
}

function global:Get-Headers() {
    $config = Read-Config
    $Headers = @{
        "X-Cisco-Meraki-API-Key" = $config.APIKey
        "Content-Type" = 'application/json'
    }
    return $Headers
}
