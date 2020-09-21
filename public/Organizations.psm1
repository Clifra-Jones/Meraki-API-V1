# Meraki Organization functions

<#
.Description
Creates a file in the user profile folder un the .meraki folder named config.json.
This file contains the users Meraki API Key and the default Organization ID
#>
function Set-MerakiAPI() {
    Param(
        [string]$APIKey,
        [string]$OrgID
    )

    if (-not $APIKey) {
        $APIKey = Read-Host -Prompt "API Key: "
    }

    if (-not $OrgID) {
        $OrgID = Read-Host -Prompt  "Organization ID"
    }

    $objConfig = @{
        APIKey = $APIKey
        OrgID = $OrgID
    }
    
    $configPath = "{0}/.meraki" -f $HOME

    if (-not (Test-Path -Path $configPath)) {
        New-Item -Path $configPath -ItemType:Directory
    }

    $objConfig | ConvertTo-Json | Out-File -FilePath "$configPath/config.json"
}

<#
.Description
Retrieves the Organization nformation thet the provided Meraki API Key has access to. This will retrieve the Organization ID.
#>
function Get-MerakiOrganizations() {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$APIKey
    )

    $Uri = "{0}/organizations" -f $BaseURI
    
    $Headers = @{
        "X-Cisco-Meraki-API-Key" = $APIKey
        "Content-Type" = 'application/json'
    }
    
    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
    
    return $response

}

Set-Alias -Name GMOrgs -Value Get-MerakiOrganizations -Option ReadOnly

function Get-MerakiOrganization() {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$OrgId
    )

    $Uri = "{0}/organizations/{1}" -f $OrgId
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
}

Set-Alias -Name GMOrg -value Get-MerakiOrganization -Option ReadOnly


<#
.Description
Retrieves all Networks for a Meraki Organization
#>
function Get-MerakiNetworks() {
    $config = Read-Config
    $Uri = "{0}/organizations/{1}/networks" -f $BaseURI, $config.OrgID
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
}

Set-Alias -Name GMNets -Value Get-MerakiNetworks -Option ReadOnly

<#
.Description
Get Organization Configuration Templates
#>
function Get-MerakiOrganizationConfigTemplates() {
    Param(
        [String]$OrgID
    )

    if (-not $OrgID) {
        $config = Read-Config
        $OrgID = $config.OrgID
    }

    $Uri = "{0}/organizations/{1}/configTemplates" -f $BaseURI, $OrgID
    $headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $headers

    return $response
}

Set-Alias -Name GMOrgTemplates -value Get-MerakiOrganizationConfigTemplates -Option ReadOnly

<#
.Description
Retrieves all devices in an organization
#>
function Get-MerakiOrganizationDevices() {
    Param(
        [string]$OrgID
    )

    If (-not $OrgID) {
        $config = Read-Config
        $OrgID = $config.OrgID
    }

    $Uri = "{0}/organizations/{1}/devices" -f $BaseURI, $config.OrgID
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
}

Set-Alias GMOrgDevs -Value Get-MerakiOrganizationDevices -Option ReadOnly

<#
.Description
Get Organization Admins
#>
function Get-MerakiOrganizationAdmins() {
    Param(
        [string]$OrgID
    )

    If (-not $orgID) {
        $config = Read-Config
        $OrgID = $config.OrgID
    }

    $Uri = "{0}/organizations/{1}/admins" -f $BaseURI, $OrgID
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $uri -Headers $Headers

    return $response
}

Set-Alias -name GMOrgAdmins -Value Get-MerakiOrganizationAdmins -Option ReadOnly

<#
.Description
Get Organization configuration Changes
#>
function Get-MerakiOrganizationConfigurationChanges() {
    [CmdletBinding(DefaultParameterSetName = 'TimeSpan')]
    Param(                 
        [string]$OrgID,
        [Parameter(ParameterSetName = 'StartEnd')]
        [ValidateScript({$_ -as [DateTime]})]
        [datetime]$StartTime,
        [Parameter(ParameterSetName = 'StartEnd')]
        [ValidateScript({$_ -as [DateTime]})]
        [DateTime]$EndTime,
        [Parameter(ParameterSetName = 'TimeSpan')]
        [ValidateScript({$_ -as [long]})]
        [long]$TimeSpan,
        [ValidateScript({$_ -as [int]})]
        [int]$PerPage,
        [string]$NetworkID,
        [string]$AdminID
    )
    
    If (-not $OrgID) {
        $config = Read-Config
        $OrgID = $config.OrgID
    }

    $Uri = "{0}/organizations/{1}/configurationChanges" -f $BaseURI, $OrgID
    $Headers = Get-Headers

    $psBody = @{}
    if ($StartTime) {
        $T0 = "{0:s}" -f $StartTime
        $psBody.Add("t0", $T0)
    }

    if ($EndTime) {
        $T1 = "{0:s}" -f $EndTime
        $psBody.add("t1", $T1)
    }

    if ($TimeSpan) {
        $seconds = [timespan]::FromDays($timespan).TotalSeconds
        $psBody.Add("timespan", $seconds)
    }

    if ($PerPage) {
        $psBody.Add("perPage", $PerPage)
    }

    if ($NetworkID) {
        $psBody.Add("networkId", $NetworkID)
    }

    if ($AdminID) {
        $psBody.Add("adminId", $AdminID)
    }

    $Body = $psBody | ConvertTo-Json

    $response = Invoke-RestMethod -Method GET -Uri $Uri -body $Body -Headers $Headers

    return $response
    
}

Set-Alias -name GMOrgCC -Value Get-MerakiOrganizationConfigurationChanges -Option ReadOnly

<#
.Description
Get organization thrid party VPN peers
#>
function Get-MerakiOrganizationThirdPartyVPNPeers() {
    [CmdletBinding()]
    Param(
        [STRING]$OrgID
    )

    if (-not $OrgID) {
        $config = Read-Config
        $OrgId = $config.OrgID
    }

    $Uri = "{0}/organizations/{1}/thirdPartyVPNPeers" -f $BaseURI, $OrgID
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
}

Set-Alias -Name GMOrg3pVP -Value Get-MerakiOrganizationThirdPartyVPNPeers -Option ReadOnly

<#
.Description
Get organization inventory
#>
function Get-MerakiOrganizationInventory() {
    Param(
        [string]$OrgID
    )

    if (-not $OrgID) {
        $config = Read-Config
        $OrgID = $config.OrgID
    }

    $Uri = "{0}/organizations/{1}/inventory" -f $BaseURI, $OrgID
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
}

Set-Alias -Name GMOrgInv -Value Get-MerakiOrganizationInventory -Option ReadOnly
