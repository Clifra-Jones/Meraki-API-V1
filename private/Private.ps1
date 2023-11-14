#Private Variables

$BaseURI = "https://api.meraki.com/api/v1"

$paging = @{
    next = $null
    prev = $null
    first = $null
    last = $null
}

#Private function
function Read-Config () {
    $ConfigPath = "$home/.meraki/config.json"
    $config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
    return $config
}

function ConvertTo-UTime () {
    Param(
        [datetime]$DateTime
    )

    $uTime = ([System.DateTimeOffset]$DateTime).ToUnixTimeMilliseconds() / 1000

    return $Utime
}

function ConvertFrom-UTime() {
    Param(
        [decimal]$Utime
    )

    [DateTime]$DateTime = [System.DateTimeOffset]::FromUnixTimeMilliseconds(1000 * $Utime).LocalDateTime

    return $DateTime
}

function Get-Headers() {
    $config = Read-Config
    $Headers = @{
        "Authorization" = "Bearer $($config.APIKey)"
        "Accept" = 'application/json'
        "Content-Type" = 'application/json'
    }
    return $Headers
}