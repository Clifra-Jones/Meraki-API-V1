# Meraki Organization functions


function Set-MerakiAPI() {
    [CmdletBinding()]
    Param(
        [string]$APIKey,
        [string]$OrgID,
         [string]$ProfileName
    )
 
    if ($OrgID -and (-not $ProfileName)) {
        Write-Host "The parameter ProfileName must be used with the OrdId parameter." -ForegroundColor Red
        exit
    }
    
    $configPath = "{0}/.meraki" -f $HOME
    $configFile = "{0}/config.json" -f $configPath

    if (-not (Test-Path -Path $configFile)) {
        if (-not $APIKey) {
            $APIKey = Read-Host -Prompt "API Key: "
        }   

        if (-not $APIKey) {
            Throw "APIKey required if config file does not exist!"
        }
        if ((-not $OrgId) -and (-not $profileName)) {
            $orgs = Get-MerakiOrganizations -APIKey $APIKey
            $config = @{
                APIKey = $apiKey
            }
            $config.Add('profiles', @{default = $orgs[0].Id})
            foreach ($org in $orgs) {
                $config.profiles.Add($org.name, $org.id)
            }
        } else {
            if (-not $profileName) {
                $config = @{
                    APIKey = $APIKey
                }
                $config.Add('profiles',@{default = $OrgID})
            } else {
                $config = @{
                    APIKey = $apiKey
                }
                $config.Add('profiles',@{})
                $config.profiles.Add($profileName, $OrgID)
            }
        }
    } else {
        # Read config into an object
        $oConfig = Get-Content -Raw -Path $configFile | ConvertFrom-Json
        # Convert the object to a hash table
        $config = $oConfig | ConvertTo-HashTable

        if ($APIKey) {
            If ($config.APIKey -ne $APIKey) {
                Write-Host "The APIKey you entered does not match the APIKey in the config file. This will overwrite the existing config file!" -ForegroundColor Yellow
                $response = ($R = read-host "Continue? [Y/n]:") ? $R : 'Y'
                if ($response-eq "Y") {
                    $config = @{
                        APIKey = $APiKey
                    }
                } else {
                    Throw "Aborting!"
                }
            }
        }
        if ((-not $OrgID) -and (-not $profileName)) {
            $response = ($R = read-host "Overwrite Profiles from organization names? [Y/n]:") ? $R : 'Y'
            if ($response -eq 'Y') {
                $orgs = Get-MerakiOrganizations -APIKey $config.APIKey
                $config.Add('profiles', @{default = $orgs[0].Id})
                foreach ($org in $orgs) {
                    $config.profiles.Add($org.name, $org.Id)
                }
            }
        } else {
            if (-not $profileName) {
                if ($config.profiles.default) {
                    $config.profiles.default = $orgId
                } else {
                    $config.profiles.Add('default', $orgId)
                }
            } else {
                if ($config.profiles.$profileName) {
                    $config.profiles.$profileName = $OrgId
                } else {
                    $config.profiles.Add($profileName, $OrgId)
                }
            }
        }
    }
    
    if (-not (Test-Path -Path $configPath)) {
        [void](New-Item -Path $configPath -ItemType:Directory)
    }

    $config | ConvertTo-Json | Out-File -FilePath $configFile
    <#
    .SYNOPSIS 
    Set the configuration file.
    .DESCRIPTION
    Sets up the configuration file. this can be the initial configuration or creating named profiles.
    .PARAMETER APIKey
    Your Meraki API key. If a configuration file exists and this key does not match the key in the file a 
    new file will be created overwriting the existing file.
    .PARAMETER OrgID
    The ID of an organization to add to the profile.    
    .PARAMETER profileName
    The name of the profile to create. If ommitted the OrgID is set as the default profile.
    .NOTES
    If the OrgID and profileName parameters are omitted named profiles will be created based on the Organization names pulled from Meraki.
    This approach may not be the best as most of the time these names will have multiple words and spaces and just be too long.
    .EXAMPLE
    Create the default profile
    PS> Set-MerakiAPI -APIKey 'GDTE63534HD74BD93847' -OrgId 123456
    .EXAMPLE
    Create a Named Profile.
    Set-MerakiAPI -OrgId 123456 -ProfileName USNetwork
    #>
}

function Set-MerakiProfile () {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$profileName
    )
    $configFile = "{0}/.meraki/config.json" -f $home
    $Config = Get-Content -Path $configFile | ConvertFrom-Json | ConvertTo-HashTable

    $orgID = $Config.profiles.$profileName
    if (-not $OrgId) {
        throw "Invalid profile name!"
    }
    Set-MerakiAPI -OrgID $orgID -profileName 'default'
    <#
    .SYNOPSIS
    Set the default profile to the specified named profile.
    .DESCRIPTION
    Use this function to set the default profile for all subsequent command. 
    This changes the organization ID of the default profile so any future commands will use this profile even after closing out of PowerShell.
    .PARAMETER profileName
    The name of the profile to use.
    #>
}


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
    <#
    .SYNOPSIS 
    Get Meraki Organizations
    .DESCRIPTION
    Get all Meraki Organizations your API Key has access to.
    .PARAMETER APIKey
    Meraki API Key.
    #>
}

Set-Alias -Name GMOrgs -Value Get-MerakiOrganizations -Option ReadOnly

function Get-MerakiOrganization() {
    [CmdLetBinding(DefaultParameterSetName = 'none')]
    Param (
        [string]$OrgID,
        [string]$profileName
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgId = $config.profiles.$profileName
            if (-not $OrgId) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgId = $config.profile.default
            if (-not $OrgId) {
                throw "There is no default profile. You must use the -OrgId parameter and supply the Organization Id."
            }
        }
    }
    $Uri = "{0}/organizations/{1}" -f $BaseURI, $OrgId
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
    <#
    .SYNOPSIS 
    Get Meraki Organization
    .PARAMETER OrgId
    The organization ID
    .PARAMETER profileName
    Use the profile name to get organization.
    .OUTPUTS
    A Meraki organization Object
    #>
}

Set-Alias -Name GMOrg -value Get-MerakiOrganization -Option ReadOnly

function New-MerakiOrganization() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$ManagementName,
        [string]$ManagementValue
    )

    $Headers = Get-Headers

    $Uri = "{0}/organizations" -f $BaseURI

    $_Body = @{
        name = $Name
    }

    If ($ManagementName) {
        $_Body.Add("management", @{
            details = @(
                @{
                    "name" = $ManagementName
                    "value" = $
                }
            )
        })
    }
    $body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body
        return $response
    }
    catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Create an organization
    .DESCRIPTION 
    Create a new Meraki Organization
    .PARAMETER Name
    The name of the organization
    .PARAMETER ManagementName
    Name of the management system
    .PARAMETER ManagementValue
    Value of the management system
    #>
}

function Set-MerakiOrganization() {
    [CmdletBinding()]
    Param(
        [string]$OrgID,
        [string]$profileName,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$ManagementName,
        [string]$ManagementValue,
        [switch]$ApiEnabled        
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    if (-not $orgID) {
        $config = Read-Config
        if ($profileName) {
            $orgID = $config.profiles.$profileName
            if (-not $orgID) {
                throw "Invalid profile name!"
            }
        } else {
            $orgID = $config.profiles.default
        }
    }
    $Uri = "{0}/organizations/{1}" -f $BaseURI, $orgID

    $Headers = Get-Headers

    $_Body = @{
        name = $Name        
    }
    if ($ManagementName) {
        $_Body.Add("management", @{
            details = @(
                @{
                    name = $ManagementName
                    value = $ManagementValue
                }
            )
        })        
    }
    if ($ApiEnabled) {
        $_Body.Add("api", @{
            "enabled" = $ApiEnabled.IsPresent
        })
    }

    $body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body
        return $response
    }
    catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Update an organization
    .DESCRIPTION
    Update a erwki Organization
    .PARAMETER OrgID
    The organization Id
    .PARAMETER profileName
    The saved profile name
    .PARAMETER Name
    The name of the organization
    .PARAMETER ManagementName
    Name of the management data
    .PARAMETER ManagementValue
    Value of the management data
    .PARAMETER ApiEnabled
    If present, enable the access to the Cisco Meraki Dashboard API
    .OUTPUTS
    A Meraki organization object
    #>
}

#region Organization Networks
function Get-MerakiNetworks() {
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [string]$OrgID,
        [string]$profileName,
        [string]$ConfigTemplateId,
        [switch]$IsBoundToConfigTemplate,
        [switch]$IncludeTemplates
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    if (-not $orgID) {
        $config = Read-Config
        if ($profileName) {
            $orgID = $config.profiles.$profileName
            if (-not $orgID) {
                throw "Invalid profile name!"
            }
        } else {
            $orgID = $config.profiles.default
        }
    }
    $Uri = "{0}/organizations/{1}/networks" -f $BaseURI, $orgID
    if ($ConfigTeplateId){
        $Uri = "{0}?configTemplateId=" -f $Uri, $ConfigTemplateId
    }

    If ($IsBoundToConfigTemplate.IsPresent) {
        if ($Uri.Contains("?")) {
            $Uri = "{0}&isBoundToConfigTemplate=true" -f $Uri
        } else {
            $Uri = "{0}?isBoundToConfigTemplate=true" -f $Uri
        }
    }

    $Headers = Get-Headers
    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
        If ($IncludeTemplates.IsPresent) {
            $templates = @{}
            Get-MerakiOrganizationConfigTemplates | ForEach-Object {
                $templates.Add($_.id, $_)
            }
            foreach ($network in $response) {
                If ($Network.isBoundToConfigTemplate) {
                    $template = $templates[$Network.configTemplateId]
                    $response[$response.IndexOf($Network)] | Add-Member -MemberType NoteProperty -Name "configTemplate" -Value $template
                }
            }
        } 
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Get all Meraki Networks.
    .DESCRIPTION
    Get all Meraki networks in an organization.
    .PARAMETER OrgID
    The Organization ID.
    .PARAMETER profileName
    The profile name to use to get networks.
    .PARAMETER IncludeTemplates
    Includes a configTemplate property containing the configuration template.
    .PARAMETER ConfigTemplateId
    Get all networks bound to this template Id.
    .PARAMETER IsBoundToConfigTemplate
    Get only networks bound to config templates.
    .OUTPUTS
    An array of Meraki network objects.
    #>
}

Set-Alias -Name GMNets -Value Get-MerakiNetworks -Option ReadOnly

function Add-MerakiNetwork() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string[]]$ProductTypes,
        [string]$TimeZone,
        [string]$Notes,
        [string[]]$Tags,
        [string]$CopyFromNetworkId,        
        [string]$OrgID,
        [string]$profileName
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    if (-not $orgID) {
        $config = Read-Config
        if ($profileName) {
            $orgID = $config.profiles.$profileName
            if (-not $orgID) {
                throw "Invalid profile name!"
            }
        } else {
            $orgID = $config.profiles.default
        }
    }

    $Headers = Get-Headers
    $Uri = "{0}/organizations/{1}/networks"

    $_Body = @{
        name = $Name
        productTypes = $ProductTypes
    }
    if ($TimeZone) { $_Body.Add("timeZone", $TimeZone) }
    if ($Notes) { $_Body.Add("notes", $Notes) }
    if ($Tags) { $_Body.Add("tags", $Tags) }
    if ($CopyFromNetworkId) { $_Body.Add("copyFromNetworkId", $CopyFromNetworkId) }

    $body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body
        return $response        
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS 
    Create a network
    .DESCRIPTION
    Create a network in an organization
    .PARAMETER Name
    The name of the network
    .PARAMETER ProductTypes
    The product type(s) of the new network. If more than one type is included, the network will be a combined network.
    .PARAMETER TimeZone
    Time zone name from the ICANN tz database
    .PARAMETER Notes
    Add any notes or additional information about this network here.
    .PARAMETER Tags
    A list of tags to be applied to the network
    .PARAMETER CopyFromNetworkId
    The ID of the network to copy configuration from. Other provided parameters will override the copied configuration, except type which must match this network's type exactly.
    .PARAMETER OrgId
    Optional Organizational ID. if this parameter is notprovided the default Organization ID will be retrieved from the settings file.
    If this prameter is provided it will override the default Organization ID in the settings file.
    .OUTPUTS
    An object containing thenew network.
    #>
}

function Merge-MerakiNetworks() {
    [CmdletBinding()]
    Param(
        [string]$OrgID,
        [string]$profileName,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string[]]$NetworkIds,
        [string]$EnrollmentString
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    if (-not $orgID) {
        $config = Read-Config
        if ($profileName) {
            $orgID = $config.profiles.$profileName
            if (-not $orgID) {
                throw "Invalid profile name!"
            }
        } else {
            $orgID = $config.profiles.default
        }
    }
    $Uri = "{0}/organizations/{1}/networks" -f $BaseURI, $orgID
    $Headers = Get-Headers

    $_Body = @{
        name = $Name
        networkIds = $NetworkIds
    }

    if ($EnrollmentString) { $_Body.Add("enrollmentString", $EnrollmentString) }

    $body = $_Body | ConvertTo-Json -Depth 4 -Compress

    try {
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers -$Headers -Body $body
        return $response
    } catch {
        throw $_
    }
}
#endregion

function Get-MerakiOrganizationConfigTemplates() {
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [string]$OrgID,
        [string]$profileName
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }
    
    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }
    }

    $Uri = "{0}/organizations/{1}/configTemplates" -f $BaseURI, $OrgID
    $headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $headers

    return $response
    <# 
    .SYNOPSIS
    Get the Organization Configuration Templates
    .DESCRIPTION
    Get the cpnfiguration templates for a given organization.
    .PARAMETER OrgID
    The Organization Id. If omitted uses the default profile.
    .PARAMETER profileName
    The profile name to use to get the templates.
    .OUTPUTS
    An array of Meraki configuration template objects.
    #>
}

Set-Alias -Name GMOrgTemplates -value Get-MerakiOrganizationConfigTemplates -Option ReadOnly

function Get-MerakiOrganizationConfigTemplate () {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateId,
        [string]$OrgID,
        [string]$profileName
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }
    }

    $Headers = Get-Headers

    $Uri = "{0}/organizations/{1}/configTemplates/{2}" -f $BaseURI, $OrgID, $TemplateId

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
        return $response
    }
    catch {
        throw $_
    }

}

function Get-MerakiOrganizationDevices() {
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [string]$OrgID,
        [string]$profileName
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    If (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profilename
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }
    }

    $Uri = "{0}/organizations/{1}/devices" -f $BaseURI, $OrgID
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
    <#
    .SYNOPSIS
    Get organization Devices.
    .DESCRIPTION
    Get all devices in an organization.
    .PARAMETER OrgID
    The Organization Id. If ommitted uses the default profile.
    .PARAMETER profileName
    Profile name to use to get the devices. If ommitted uses the default profile.
    .OUTPUTS
    AN array of Meraki Device objects.
    #>
}

Set-Alias GMOrgDevs -Value Get-MerakiOrganizationDevices -Option ReadOnly

function Get-MerakiOrganizationAdmins() {
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [string]$OrgID,
        [string]$profileName
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }
    
    If (-not $orgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-noy $OrgID) { 
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }
    }

    $Uri = "{0}/organizations/{1}/admins" -f $BaseURI, $OrgID
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $uri -Headers $Headers

    return $response
    <#
    .SYNOPSIS
    Get Organization Admins.
    .PARAMETER OrgID
    The Organization ID. If ommitted uses the default profile.
    .PARAMETER profileName
    The profile name to get admins with. If ommitted used the default profile.
    .OUTPUTS
    An array of Meraki Admin objects.
    #>
}

Set-Alias -name GMOrgAdmins -Value Get-MerakiOrganizationAdmins -Option ReadOnly


function Get-MerakiOrganizationConfigurationChanges() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(                
        [string]$OrgID,
        [string]$profileName,        
        [ValidateScript({$_ -is [DateTime]})]
        [Alias('StartTime')]
        [datetime]$StartDate,
        [ValidateScript({$_ -is [DateTime]})]
        [Alias('EndTime')]
        [DateTime]$EndDate,        
        [ValidateScript({$_ -is [int32]})]
        [Alias('TimeSpan')]
        [Int]$Days,
        [ValidateScript({$_ -is [int]})]
        [int]$PerPage,
        [string]$NetworkID,
        [string]$AdminID
    )
 
    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrdId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    if ($Days) {
        if ($StartDate) {
            Write-Host "The Days parameter cannot be used with the StartDate parameter." -BackgroundColor Red
            exit
        }
        if ($EndDate) {
            Write-Host "The Days parameter cannot be used with the EndDate parameter." -BackgroundColor Red
            exit
        }
    }

    if ($StartDate -and (-not $EndDate)) {
        Write-Host "The EndDate Parameter is required with the StartDate Parameter." -BackgroundColor Red
        exit
    }

    if ($endDate -and (-not $StartDate)) {
        Write-Host "The StartDate parameter is required with the EndDate parameter." -BackgroundColor Red
        exit
    }

    If (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgId = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }
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
    <#
    .SYNOPSIS 
    Get Organization Configuration Changes
    .DESCRIPTION
    Gets configuration chenges made to an organization's network.
    .PARAMETER OrgID
    The Organization Id. If ommitted used th default profile.
    .PARAMETER profileName
    The profile name to use to get the changes. If ommitted used th default profile.
    .PARAMETER StartTime
    The start time to pull changes.
    .PARAMETER EndTime
    The end time to pull changes.
    .PARAMETER TimeSpan
    A timespan to pull changes.
    .PARAMETER PerPage
    Number of records to pull per page.
    .PARAMETER NetworkID
    Filter results by Network ID.
    .PARAMETER AdminID
    Filter results by Admin ID.
    .OUTPUTS
    An array of configuration change objects.
    .EXAMPLE
    Filter logs for last 10 days by Administrator.
    PS> Get-MerakiOrganizationAdmins | Where-Object {$_.Name -eq "John Doe"} | Get-MerakiOrganizationConfigurationChanges -TimeSpan 10
    .EXAMPLE
    Filter logs for changes to the Miami network that occurred between 6/1/2020 and 6/30/2020
    Get-MerakiNetworks | Where-Object {$_.Name -like "*Miami*"} | Get-MerakiOrganizationConfigurationChanges -StartTime "06/01/2020" -EndTime "06/30/2020"
    #>
    
}

Set-Alias -name GMOrgCC -Value Get-MerakiOrganizationConfigurationChanges -Option ReadOnly


function Get-MerakiOrganizationThirdPartyVpnPeers() {
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [string]$OrgID,
        [string]$profileName
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgId = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgId = $config.profiles.default
        }
    }

    $Uri = "{0}/organizations/{1}/appliance/vpn/thirdPartyVPNPeers" -f $BaseURI, $OrgID
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
    
        return $response.peers 
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Get Organization 3rd paty VPNs.
    .PARAMETER OrgID
    Organization ID. If ommitted used th default profile.
    .PARAMETER profileName
    Profile Name to use. If ommitted used th default profile.
    .OUTPUTS
    An array of VPN-peer objects.
    #>
}

Set-Alias -Name GMOrg3pVP -Value Get-MerakiOrganizationThirdPartyVPNPeers -Option ReadOnly

function Set-MerakiOrganizationThirdPartyVpnPeer() {
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [string]$OrgID,
        [string]$profileName,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Secret,
        [ValidateSet('1', '2')]
        [string]$IkeVerson,
        [ValidateSet('default', 'aws', 'azure')]
        [string]$IpsecPoliciesPreset,
        [string]$LocalId,
        [string]$PublicIp,
        [Parameter(Mandatory = $true)]
        [string[]]$PrivateSubnets,
        [string]$RemoteId,
        [string[]]$NetworkTags = 'all',
        [PSObject]$IpsecPolicies
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgId = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgId = $config.profiles.default
        }
    }

    $Headers = Get-Headers

    $Uri = "{0}/organizations/{1}/appliance/vpn/thirdPartyVPNPeers" -f $BaseURI, $OrgID

    $Peers = @{}
    Get-MerakiOrganizationThirdPartyVpnPeers | ForEach-Object {
        $Peers.Add($Name, $_)
    }

    if (-not $Peers[$Name]) {
        throw "Peer $Name is not found!"
    }

    if ($IkeVerson) { $Peers[$Name].ikeVerson = $IkeVerson }
    if ($IpsecPoliciesPreset) { $Peers[$Name].IpsecPoliciesPreset = $IpsecPoliciesPreset } 
    if ($LocalId) { $Peers[$Name].localId = $LocalId }
    if ($publicIp) { $Peers[$Name].publicIp = $PublicIp }
    if ($RemoteId) { $Peers[$Name].remoteIp = $RemoteId }
    if ($Secret) { $Peers[$Name].secret = $Secret}
    if ($NetworkTags) { $Peer[$Name].networkTags = $NetworkTags }
    if ($PrivateSubnets) { $Peers[$Name].privateSubnets = $PrivateSubnets }
    if ($IpsecPolicies) { $Peer[$Name].ipsecPolicies = $IpsecPolicies}
        
    $NewPeers = $Peers.Values
    $_Body = @{
        peers = $NewPeers
    }

    $Body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $Body

        return $response
    } catch {
        throw $_
    }
}

function New-MerakiOrganizationThirdPartyVpnPeer() {
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [string]$OrgID,
        [string]$profileName,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Secret,
        [ValidateSet('1', '2')]
        [string]$IkeVerson,
        [ValidateSet('default', 'aws', 'azure')]
        [string]$IpsecPoliciesPreset,
        [string]$LocalId,
        [string]$PublicIp,
        [Parameter(Mandatory = $true)]
        [string[]]$PrivateSubnets,
        [string]$RemoteId,
        [string[]]$NetworkTags = 'all',
        [PSObject]$IpsecPolicies
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrdIf and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgId = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgId = $config.profiles.default
        }
    }

    $Headers = Get-Headers

    $Uri = "{0}/organizations/{1}/appliance/vpn/thirdPartyVPNPeers" -f $BaseURI, $OrgID

    $Peers = Get-MerakiOrganizationThirdPartyVPNPeers

    $Peer = @{
        name = $Name
        secret = $Secret
        privateSubnet = $PrivateSubnets
    }
    if ($IkeVerson) { $Peer.Add("ikeVersion", $IkeVerson) }
    if ($IpsecPoliciesPreset) { $Peer.Add("ipsecPoliciesPreset", $IpsecPoliciesPreset) }
    if ($LocalId) { $Peer.Add("localId", $LocalId) }
    if ($PublicIp) { $Peer.Add("publicIp", $PublicIp) }
    if ($RemoteId) { $Peer.Add("networkTags", $NetworkTags) }
    if ($IpsecPolicies) { $Peer.Add("ipsecPolicies", $IpsecPolicies) }

    $Peers += $Peer
    $_Body = @{
        peers = $Peers
    }

    $Body = $_Body | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $Body

        return $response
    } catch {
        Throw $_
    }
}

function Get-MerakiOrganizationInventoryDevices() {
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [string]$OrgID,
        [string]$profileName
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Uri = "{0}/organizations/{1}/inventoryDevices" -f $BaseURI, $OrgID
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
    <#
    .SYNOPSIS
    Get the organization device inventory 
    .PARAMETER OrgID
    Organization ID. If ommitted used th default profile.
    .PARAMETER profileName
    Profile name to use. If ommitted used th default profile.
    .OUTPUTS
    An array of inventory objects.
    #>
}

Set-Alias -Name GMOrgInvDevices -value Get-MerakiOrganizationInventoryDevices -Option ReadOnly

function Get-MerakiOrganizationSecurityEvents() {
    [CmdLetBinding(DefaultParameterSetName='Default')]
    Param(
        [string]$OrgId,
        [string]$ProfileName,
        [ValidateScript({$_ -is [datetime]})]
        [datetime]$StartDate,
        [ValidateScript({$_ -is [datetime]})]
        [datetime]$EndDate,
        [int]$Days,
        [ValidateRange(3, 1000)]
        [int]$PerPage
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    if ($Days) {
        if ($StartDate) {
            Write-Host "The Days parameter cannot be used with the StartDate parameter." -BackgroundColor Red
            exit
        }
        if ($EndDate) {
            Write-Host "The Days parameter cannot be used with the EndDate parameter." -BackgroundColor Red
            exit
        }
    }

    if ($StartDate -and (-not $EndDate)) {
        Write-Host "The EndDate Parameter is required with the StartDate Parameter." -BackgroundColor Red
        exit
    }

    if ($endDate -and (-not $StartDate)) {
        Write-Host "The StartDate parameter is required with the EndDate parameter." -BackgroundColor Red
        exit
    }

    $Headers = Get-Headers
    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Uri = "{0}/organizations/{1}/appliance/security/events" -f $BaseURI, $OrgId

    Set-Variable -Name Query
    if ($StartDate) {
        $_startDate = "{0:s}" -f $StartDate
        $Query += "t0={0}" -f $_startDate
    }
    if ($EndDate) {
        $_endDate = "{0:s}" -f $EndDate
        if ($Query) {
            $Query += "&"
        }
        $Query += "t1={0}" -f $_endDate
    }
    if ($Days) {
        $ts = [timespan]::FromDays($Days)
        if ($Query) {
            $Query += "&"
        }
        $Query += "timestamp={0}" -f ($ts.TotalSeconds)
    }
    if ($PerPage) {
        if ($Query) {
            $Query += "&"
        }
        $Query += "perPage={0}" -f $PerPage
    }

    if ($Query) {
        $Uri = "?{0}" -f $Query
    }

    try {
        $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Returns security event for the organization.
    .DESCRIPTION
    Returns a collection of security event objects for the given organization. Events can be filtered by dates or timespan.
    .PARAMETER OrgId
    The Organization ID. If omitted and a profile is not specified the default organization is used. Cannot be used with the profile parameter.
    .PARAMETER ProfileName
    Retrieve the Organization Id from the named profile. Cannot be used with the OrgId parameter
    .PARAMETER StartDate
    The starting date to retrieve data. Cannot be more than 365 days prior to today.
    .PARAMETER EndDate
    The ending date to retrieve data. cannot be more than 365 days after StartDate.
    .PARAMETER Days
    The number if days back from today to retrieve data, Cannot be more than 365.
    .PARAMETER PerPage
    Number of entries per page to retrieve. Acceptable range is 3-1000. Default is 100. NOTE: Paging is not immplemented. 
    .OUTPUTS
    A collection of security event objects.
    #>
}

Set-Alias -Name GMNetSecEvents -Value Get-MerakiOrganizationSecurityEvents

function Get-MerakiOrganizationFirmwareUpgrades() {
    [CmdletBinding()]
    Param(
        [string]$OrgId,
        [string]$ProfileName,
        [string]$Status,
        [string]$ProductType
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgID) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgID = $config.profiles.default
        }        
    }

    $Headers = Get-Headers

    Set-Variable -name Query

    if ($Status) {
        $Query = "status={0}" -f $Status
    }
    if ($ProductType) {
        if ($Query) {
            $Query += "&"
        }
        $Query += "productType={0}" -f $ProductType
    }

    $Uri = "{0}/organizations/{1}/firmware/upgrades" -f $BaseURI, $OrgId
    if ($Query) {
        $URI += "?{0}" -f $Query
    }

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Get firmware upgrade information.
    .DESCRIPTION
    Get firmware upgrade information for an organization
    .PARAMETER OrgId
    The Organization Id. If ommitted the retrieved from the default profile.
    .PARAMETER ProfileName
    The profile to retrieve the the Organization ID from.
    .PARAMETER Status
    Filter by this status.
    .PARAMETER ProductType
    Filter by this product type.
    #>
}

Set-Alias -name GMOFirmwareUpgrades -Value Get-MerakiOrganizationFirmwareUpgrades


function Get-MerakiOrganizationFirmwareUpgradesByDevice() {
    [CmdletBinding()]
    Param(
        [string]$OrgId,
        [string]$ProfileName,
        [string[]]$NetworkIds,
        [string[]]$Serials,
        [string[]]$Macs,
        [string[]]$FirmwareUpgradeIds,
        [string[]]$FirmwareUpgradeBatchIds
    )

    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }

    $Headers = Get-Headers

    $Uri = "{0}/organizations/{1}/firmware/upgrades/byDevice" -f $BaseURI, $OrgId

    if ($NetworkIds) {
        $Uri = "{0}?networkIds={1}" -f $Uri, ($NetworkIds -join ",")
    }
    
    if ($Serials) {
        if ($Uri.Contains("?")) {
            $Uri = "{0}&" -f $Uri
        } else {
            $Uri = "{0}?" -f $Uri
        }
        $Uri = "{0}serials={1}" -f $Uri, ($serials -join ",")
    }

    if ($Macs) {
        if ($Uri.Contains("?")) {
            $Uri = "{0}&" -f $Uri
        } else {
            $Uri = "{0}?" -f $Uri
        }
        $Uri = "{0}macs={1}" -f $Uri, ($Macs -join ",")
    }

    if ($FirmwareUpgradeIds) {
        if ($Uri.Contains("?")) {
            $Uri = "{0}&" -f $Uri
        } else {
            $Uri = "{0}?" -f $Uri
        }
        $Uri = "{0}firmwareUpgradeIds={1}" -f $Uri, ($FirmwareUpgradeIds -join ",")
    }

    if ($FirmwareUpgradeBatchIds) {
        if ($Uri.Contains("?")) {
            $Uri = "{0}&" -f $Uri
        } else {
            $Uri = "{0}?" -f $Uri
        }
        $Uri = "{0}firmwareUpgradeBatchIds={1}" -f $Uri, ($FirmwareUpgradeBatchIds -join ",")
    }

    Try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Get firmware upgrades by Device
    .DESCRIPTION
    Get Meraki organization firmware upgrades by device
    .PARAMETER OrgId
    The organization Id
    .PARAMETER ProfileName
    The saved profile name.
    .PARAMETER NetworkIds
    An array of netword Ids to retrieve upgrades for
    .PARAMETER Serials
    An array of serials to retrieve upgrades for
    .PARAMETER Macs
    An array of MAC Addresses to retrieve upgrades for
    .PARAMETER FirmwareUpgradeIds
    An array of Upgrade Ids ro retrieve upgrades for
    .PARAMETER FirmwareUpgradeBatchIds
    An array of Firmware Upgrade Batch Ids to retrieve upgrades for
    .OUTPUTS
    An array of firmware upgrade objects.
    #>
}

#region OrganizationThirdPartyVpnPeers

