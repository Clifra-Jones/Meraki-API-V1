#Private Variables

$script:BaseURI = "https://api.meraki.com/api/v1"

#Private function
function Read-Config () {
    $ConfigPath = "$home/.meraki/config.json"
    $config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json

    if ($config.APIKey -eq "Secure") {
         $Secret = Get-Secret -Name "MerakiAPI" -AsPlainText | ConvertFrom-Json
         $config.APIKey = $Secret.APIKey
    }

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

function Format-ApiError {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ErrorResponse
    )
    
    # First, try to determine if this is JSON
    $isJson = $false
    $errorObject = $null
    
    try {
        $errorObject = $ErrorResponse | ConvertFrom-Json
        $isJson = $true
    }
    catch {
        # Not valid JSON, treat as plain text
        $isJson = $false
    }
    
    if ($isJson) {
        # Handle various JSON error formats
        $formattedErrors = @()
        
        # Format 1: { "errors": ["message1", "message2"] }
        if ($errorObject.errors -and $errorObject.errors.Count -gt 0) {
            foreach ($errorMessage in $errorObject.errors) {
                $formattedErrors += Format-ErrorMessage -Message $errorMessage
            }
        }
        # Format 2: { "error": "single message" }
        elseif ($errorObject.error) {
            $formattedErrors += Format-ErrorMessage -Message $errorObject.error
        }
        # Format 3: { "message": "error message" }
        elseif ($errorObject.message) {
            $formattedErrors += Format-ErrorMessage -Message $errorObject.message
        }
        # Format 4: { "detail": "error detail" }
        elseif ($errorObject.detail) {
            $formattedErrors += Format-ErrorMessage -Message $errorObject.detail
        }
        # Format 5: Direct object with error properties
        elseif ($errorObject.PSObject.Properties.Name -contains 'status' -or 
                 $errorObject.PSObject.Properties.Name -contains 'code') {
            $errorParts = @()
            if ($errorObject.status) { $errorParts += "Status: $($errorObject.status)" }
            if ($errorObject.code) { $errorParts += "Code: $($errorObject.code)" }
            if ($errorObject.message) { $errorParts += $errorObject.message }
            $formattedErrors += ($errorParts -join " - ")
        }
        else {
            # Fallback: convert entire object to readable format
            $formattedErrors += Format-ErrorMessage -Message ($errorObject | ConvertTo-Json -Compress)
        }
        
        return $formattedErrors
    }
    else {
        # Plain text error message
        return @(Format-ErrorMessage -Message $ErrorResponse)
    }
}

function Format-ErrorMessage {
    param([string]$Message)
    
    # Clean up unicode escape sequences
    $cleanMessage = $Message -replace '\\u0022', '"'
    $cleanMessage = $cleanMessage -replace '\\u0027', "'"
    $cleanMessage = $cleanMessage -replace '\\n', "`n"
    $cleanMessage = $cleanMessage -replace '\\t', "`t"
    
    # Add some structure for field validation errors
    if ($cleanMessage -match 'network\[.*?\]' -or $cleanMessage -match '\w+\[\w+\]\[\d+\]\[\w+\]') {
        $cleanMessage = $cleanMessage -replace '([\w\[\]]+)(\s+[A-Z])', "`n  Field: `$1`n  Error: `$2"
    }
    
    return $cleanMessage.Trim()
}

function Write-ApiError () {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'exception',
            ValueFromPipelineByPropertyName
        )]
        [System.Exception]$Exception,

        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'exception',
            ValueFromPipelineByPropertyName
        )]
        [System.Management.Automation.ErrorDetails]$ErrorDetails,
        
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'message'
        )]
        [string]$Message
    )

    If ($Exception) {
        $errorMessage = $Exception.Message
    } else {
        $errorMessage = $Message
    }
    if ($ErrorDetails) {
        $detailsMessage = $ErrorDetails.Message
        $formattedDetailsMessage = Format-ApiError -ErrorResponse $detailsMessage
    }
    $formattedMessage = Format-ApiError -ErrorResponse $errorMessage

    if ($env:MerakiAPI -eq 'dev') {
        Write-error -Message $formattedMessage 
        throw $_
    } else {
        Write-Host "API Error:" -ForegroundColor Red
        If ($formattedDetailsMessage) {
            Write-Host $formattedDetailsMessage -ForegroundColor Yellow
        }
        $formattedMessage | ForEach-Object {
            Write-Host $_ -ForegroundColor Yellow
        }
        exit
    }
}