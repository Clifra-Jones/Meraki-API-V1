# Root module for Meraki API Version 1

# Dot source the function files.
. $PSScriptRoot/private/Private.ps1
. $PSScriptRoot/public/Organizations.ps1
. $PSScriptRoot/public/Networks.ps1
. $PSScriptRoot/public/Devices.ps1
. $PSScriptRoot/public/Products/Appliances.ps1
. $PSScriptRoot/public/Products/Switches.ps1
. $PSScriptRoot/public/Products/Wireless.ps1

function ConvertTo-HashTable() {
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