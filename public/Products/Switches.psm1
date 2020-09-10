#Meraki Switch Functions

function Get-MerakiSwitchRoutingInterfaces() {
    [CmdLetBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$serial
    )

    $Uri - "{0}/devices/{1}/switch/routing/interfaces" -f $BaseUri, $serial
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
}

Set-Alias -Name GMSWRoutInts -value Get-MerakiSwitchRoutingInterfaces -Options ReadOnly

function Get-MerakiSwitchRoutingInterface() {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true            
        )]
        [String]$serial,        
        [Parameter(
            Mandatory = $true
        )]
        [TypeName]$interfaceId
    )

    $Uri = "{0}/devices/{1}/switch/routing/interfaces/{2}" -f $BaseUri, $serial, $interfaceId
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Mestod GET -Uri $Uri -Headers $Headers`

    return $response
}

Set-Alias -Name GMSWRoutInt -Value = Get-MerakiSwitchRoutingInterface -Options ReadOnly

function Get-MerakiSwitchRoutingInterfaceDHCP() {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true            
        )]
        [String]$serial,
        [Parameter(
            Mandatory = $true
        )]
        [String]$interfaceId
    )

    $Uri = "{0}/devices/{1}/switch/routing/interface/{2}/dhcp" -f $BaseUri, $serial, $interfaceId
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
}

Set-Alias GMSWRoutIntDHCP -value Get-MerakiSwitchRoutingInterfaceDHCP -options ReadOnly

function Get-MerakiSwitchRoutingStaticRoutes() {
    [CmdLetBinding()]
    Param(
        #Parameter Help
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String]$serial        
    )

    $Uri = "{0}/devices/{1}/switch/routing/statisRoutes" -f $BaseUri, $serial
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
}

Set-Alias -Name GMSWRoutStatic -value Get-MerakiSwitchRoutingStaticRoutes -Options ReadOnly

function Get-MerakiNetworkSwitchLAG() {
    [CmdLetBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]$id
    )

    $Uri = "{0}/networks/{1}/switch/linkAggregation" -f $BaseUri, $Id
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
}

Set-Alias -Name GMSWLag -value Get-MerakiSwitchLAG -Options ReadOnly

function Get-MerakiNetworkSwitchStacks() {
    [CmdLetBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String]$id
    )

    $Uri = "{0}/networks/{1}/switch/stacks"
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
}

Set-Alias -Name GMNetSWStacks -Value Get-MerakiNetworkSwitchStacks -Option ReadOnly

<#
.Description
Retrieve Switch Port settigs for a switch
#>
function Get-MerakiSwitchPorts() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$serial
    )

    $Headers = Get-Headers
    $responses = New-Object System.Collections.Generic.List[psobject]
    if ($input.Length -eq 0) {
        $Uri = "{0}/devices/{1}/switch/ports" -f $BaseURI, $serial
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
        return $response
    } 
    $input | ForEach-Object {
        if ($input.model -like "MS*") { 
            $Uri = "{0}/devices/{1}/switch/ports" -f $BaseURI, $input.serial
            $deviceName = $input.name
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
            $response | ForEach-Object {
            $_ | add-member  -MemberType NoteProperty -Name "Device" -Value $deviceName
            }        
            $responses.Add($response)        
        }
    }
    return $responses.ToArray()
}

Set-Alias GMDevSwPorts -Value Get-MerakiDeviceSwitchPorts -Option ReadOnly

function Reset-MerakiSwitchPorts() {
    [CmdLetBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String]$serial,
        [Parameter(
            Mandatory = $true
        )]
        [string[]]$ports
    )

    $Uri = "{0}/devices/{1}/devices/ports/cycle"
    $Headers = Get-Headers

    $psBody = @{}
    $psBody.Add("ports", $ports)

    $body = $psBody | ConvertTo-JSON

    $response = Invoke-RestMethod -Method POST -Uri $Uri -body $body -header $Headers

    return $response
}

Set-Alias -Name RMSWPorts -Value Reset-MerakiSwitchPorts -Options ReadOnly  