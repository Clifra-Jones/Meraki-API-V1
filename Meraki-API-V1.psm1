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
    $ConfigPath = "$home/.meraki/config.json"
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

function global:ConvertTo-HashTable() {
    [CmdletBinding()]
    [OutputType('hashtable')]
    Param(
        [Parameter(ValueFromPipeline)]
        $inputObject        
    )
    process{
        if ($null -eq $inputObject) {
            return $null
        }
        if ($inputObject -is [System.Collections.IEnumerable] -and $inputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $inputObject) {
                    ConvertTo-HashTable -inputObject $object
                }
            )
            Write-Output -NoEnumerate $collection
        } elseIf($inputObject -is [psobject]) {
            $hash = @{}
            foreach ($property in $inputObject.psObject.properties) {
                if ($property.Value -is [psobject]) {
                    $hash[$property.name] = ConvertTo-Hashtable -inputObject $Property.value
                } else {
                    $hash[$property.Name] = $property.Value
                }
            }
            $hash
        } elseif ($inputObject -is [hashtable]) {
            $inputObject
        } else {
            ConvertTo-Hashtable -inputObject $inputObject
        }
    }
}