# Meraki Organization functions
using namespace System.Collections.Generic

function Set-MerakiAPI() {
    [CmdletBinding()]
    Param(
        [string]$APIKey,
        [string]$OrgID,
        [string]$ProfileName
    )
    
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
    Sets up the configuration file. This can be the initial configuration or creating named profiles.
    .PARAMETER APIKey
    Your Meraki API key. If a configuration file exists and this key does not match the key in the file a 
    new file will be created overwriting the existing file.
    .PARAMETER OrgID
    The ID of an organization to add to the profile.    
    .PARAMETER profileName
    The name of the profile to create. If omitted the OrgID is set as the default profile.
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
        [string]$APIKey
    )

    $Uri = "{0}/organizations" -f $BaseURI
    
    If ($APIKey) {
        $Headers = @{
            "X-Cisco-Meraki-API-Key" = $APIKey
            "Content-Type" = 'application/json'
        }
    } else {
        $Headers = Get-Headers
    }

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
        
        return $response
    } catch {
        throw $_
    }
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
    [CmdLetBinding(DefaultParameterSetName = 'default')]
    Param (
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profile')]
        [string]$profileName
    )
<# 
    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        return
    }
 #>
    if (-not $OrgID) {
        $config = Read-Config
        if ($profileName) {
            $OrgId = $config.profiles.$profileName
            if (-not $OrgId) {
                throw "Invalid profile name!"
            }
        } else {
            $OrgId = $config.profiles.default
            if (-not $OrgId) {
                throw "There is no default profile. You must use the -OrgId parameter and supply the Organization Id."
            }
        }
    }
    $Uri = "{0}/organizations/{1}" -f $BaseURI, $OrgId
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
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
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
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
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$ManagementName,
        [string]$ManagementValue,
        [switch]$ApiEnabled,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profile')]
        [string]$profileName
    )
<# 
    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        return
    }
 #>
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
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
        return $response
    }
    catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Update an organization
    .DESCRIPTION
    Update a Meraki Organization
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
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [string]$ConfigTemplateId,
        [switch]$IsBoundToConfigTemplate,
        [switch]$IncludeTemplates,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profile')]
        [string]$profileName
    )

<# 
    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        return
    }
 #>
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
    if ($ConfigTemplateId){
        $Uri = "{0}?configTemplateId=" -f $Uri, $ConfigTemplateId
    }

    If ($IsBoundToConfigTemplate.IsPresent) {
        if ($Uri.Contains("?")) {
            $Uri = "{0}&isBoundToConfigTemplate=true" -f $Uri
        } else {
            $Uri = "{0}?isBoundToConfigTemplate=false" -f $Uri
        }
    }

    $Headers = Get-Headers
    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
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
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string[]]$ProductTypes,
        [string]$TimeZone,
        [string]$Notes,
        [string[]]$Tags,
        [string]$CopyFromNetworkId, 
        [Parameter(ParameterSetName = 'org')]       
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profile')]
        [string]$profileName
    )
<# 
    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        return
    }
 #>
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
        $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
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
    Optional Organizational ID. if this parameter is not provided the default Organization ID will be retrieved from the settings file.
    If this parameter is provided it will override the default Organization ID in the settings file.
    .OUTPUTS
    An object containing the new network.
    #>
}

#endregion

function Get-MerakiOrganizationConfigTemplates() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'default')]
        [string]$profileName
    )
<# 
    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        return
    } #>
    
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

    try{
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <# 
    .SYNOPSIS
    Get the Organization Configuration Templates
    .DESCRIPTION
    Get the configuration templates for a given organization.
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
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('TemplateId')]
        [string]$Id,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profile')]
        [string]$profileName
    )

    Begin {
        If ($OrgId -and $profileName) {
            Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
            return
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
    }

    Process {
        $Uri = "{0}/organizations/{1}/configTemplates/{2}" -f $BaseURI, $OrgID, $Id

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        }
        catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Retrieve a configuration Template
    .DESCRIPTION
    Retrieves the configuration template designated by the provided template Id.
    .PARAMETER Id
    The ID of the template to retrieve.
    .PARAMETER OrgID
    The Organization ID. Of omitted this is puled from the default configuration.
    .PARAMETER profileName
    The saved profile name to use. Cannot be used ith the OrgId parameter.
    .OUTPUTS
    A configuration template object.
    #>
}

function Get-MerakiOrganizationDevices() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profile')]
        [string]$profileName
    )
<# 
    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        return
    }
 #>
    If (-not $OrgID) {
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

    $Uri = "{0}/organizations/{1}/devices" -f $BaseURI, $OrgID
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Get organization Devices.
    .DESCRIPTION
    Get all devices in an organization.
    .PARAMETER OrgID
    The Organization Id. If omitted uses the default profile.
    .PARAMETER profileName
    Profile name to use to get the devices. If omitted uses the default profile.
    .OUTPUTS
    AN array of Meraki Device objects.
    #>
}

Set-Alias GMOrgDevs -Value Get-MerakiOrganizationDevices -Option ReadOnly

function Get-MerakiOrganizationAdmins() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profile')]
        [string]$profileName
    )
<# 
    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        return
    }
 #>    
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

    try {
        $response = Invoke-RestMethod -Method GET -Uri $uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    }catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Get Organization Admins.
    .PARAMETER OrgID
    The Organization ID. If omitted uses the default profile.
    .PARAMETER profileName
    The profile name to get admins with. If omitted used the default profile.
    .OUTPUTS
    An array of Meraki Admin objects.
    #>
}

Set-Alias -name GMOrgAdmins -Value Get-MerakiOrganizationAdmins -Option ReadOnly


function Get-MerakiOrganizationConfigurationChanges() {
    [CmdletBinding(DefaultParameterSetName='default')]
    Param(       
        [Parameter(ParameterSetName = 'dates')]
        [Parameter(ParameterSetName = 'datesWithOrg')]
        [Parameter(ParameterSetName = 'datesWithProfile')]
        [ValidateScript({$_ -is [DateTime]})]
        [Alias('StartTime')]
        [datetime]$StartDate,

        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithProfile', Mandatory)]
        [ValidateScript({$_ -is [DateTime]})]
        [Alias('EndTime')]
        [DateTime]$EndDate,

        [Parameter(ParameterSetName = 'days', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithProfile', Mandatory)]
        [ValidateScript({$_ -is [int32]})]
        [Alias('TimeSpan')]
        [ValidateRange(0,31)]
        [Int]$Days,

        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,1000)]
        [int]$PerPage,

        [ValidateScript({$_ -is [int]})]
        [ValidateRange(0,1000)]
        [int]$Pages = 1,
        
        [string]$NetworkID,
        
        [string]$AdminID,
        
        [Parameter(ParameterSetName = 'org', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [string]$OrgID,

        [Parameter(ParameterSetName = 'profile', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithProfile', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithProfile', Mandatory)]
        [string]$ProfileName
    )

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

    $Results = [List[PsObject]]::New()

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

    try {
        $response = Invoke-WebRequest -Method GET -Uri $Uri -body $Body -Headers $Headers -PreserveAuthorizationOnRedirect
        [List[PsObject]]$result = $response.Content | ConvertFrom-Json
        if ($result) {
            $Results.AddRange($result)
        }
        $page = 1
        if ($Pages -ne 1) {
            $done = $false
            do {
                if ($response.RelationLink['next']) {
                    $Uri = $response.RelationLink['next']
                    $response = Invoke-WebRequest -Method GET -Uri $Uri -Headers $Headers
                    [List[PsObject]]$result = $response.Content | ConvertFrom-Json
                    if ($result) {
                        $Results.AddRange($result)
                    }
                    $page += 1
                    if ($page -gt $Pages) {
                        $done = $true
                    }
                } else {
                    $done = $true
                }
            } until ($done)
        }

        return $Result.ToArray()
     } catch {
        throw $_
     }
    <#
    .SYNOPSIS 
    Get Organization Configuration Changes
    .DESCRIPTION
    Gets configuration changes made to an organization's network.
    .PARAMETER OrgID
    The Organization Id. If omitted used th default profile.
    .PARAMETER profileName
    The profile name to use to get the changes. If omitted used th default profile.
    .PARAMETER StartTime
    The start time to pull changes.
    .PARAMETER EndTime
    The end time to pull changes.
    .PARAMETER Days
    Number of days to pull changes
    .PARAMETER PerPage
    Number of records to pull per page.
    .PARAMETER Pages
    Number of pages to retrieve. 0 = all pages. Default is 1.
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
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profile')]
        [string]$profileName
    )
<# 
    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        return
    }
 #>
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
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
    
        return $response.peers 
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Get Organization 3rd party VPNs.
    .PARAMETER OrgID
    Organization ID. If omitted used th default profile.
    .PARAMETER profileName
    Profile Name to use. If omitted used th default profile.
    .OUTPUTS
    An array of VPN-peer objects.
    #>
}

Set-Alias -Name GMOrg3pVP -Value Get-MerakiOrganizationThirdPartyVPNPeers -Option ReadOnly

function Set-MerakiOrganizationThirdPartyVpnPeer() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Secret,
        [ValidateSet('1', '2')]
        [string]$IkeVersion,
        [ValidateSet('default', 'aws', 'azure')]
        [string]$IpsecPoliciesPreset,
        [string]$LocalId,
        [string]$PublicIp,
        [Parameter(Mandatory = $true)]
        [string[]]$PrivateSubnets,
        [string]$RemoteId,
        [string[]]$NetworkTags = 'all',
        [PSObject]$IpsecPolicies,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profile')]
        [string]$profileName
    )
<# 
    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        return
    }
 #>
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

    if ($IkeVersion) { $Peers[$Name].ikeVersion = $IkeVersion }
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
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $Body -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
}

function New-MerakiOrganizationThirdPartyVpnPeer() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Secret,
        [ValidateSet('1', '2')]
        [string]$IkeVersion,
        [ValidateSet('default', 'aws', 'azure')]
        [string]$IpsecPoliciesPreset,
        [string]$LocalId,
        [string]$PublicIp,
        [Parameter(Mandatory = $true)]
        [string[]]$PrivateSubnets,
        [string]$RemoteId,
        [string[]]$NetworkTags = 'all',
        [PSObject]$IpsecPolicies,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profile')]
        [string]$profileName
    )
<# 
    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrdIf and ProfileName cannot be used together!" -ForegroundColor Red
        exit
    }
 #>
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
    if ($IkeVersion) { $Peer.Add("ikeVersion", $IkeVersion) }
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
        $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $Body -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        Throw $_
    }
}

function Get-MerakiOrganizationInventoryDevices() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profile')]
        [string]$profileName
    )
<# 
    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        return
    }
 #>
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

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Get the organization device inventory 
    .PARAMETER OrgID
    Organization ID. If omitted used th default profile.
    .PARAMETER profileName
    Profile name to use. If omitted used th default profile.
    .OUTPUTS
    An array of inventory objects.
    #>
}

Set-Alias -Name GMOrgInvDevices -value Get-MerakiOrganizationInventoryDevices -Option ReadOnly

function Get-MerakiOrganizationSecurityEvents() {
    [CmdLetBinding(DefaultParameterSetName='Default')]
    Param(
        [ValidateScript({$_ -is [datetime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfiles', Mandatory)]                
        [datetime]$StartDate,

        [ValidateScript({$_ -is [datetime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfile', Mandatory)]
        [datetime]$EndDate,

        [Parameter(ParameterSetName = 'days', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithProfile', Mandatory)]
        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,31)]
        [int]$Days,

        [ValidateScript({$_ -is [int]})]
        [ValidateRange(3, 1000)]
        [int]$PerPage,

        [ValidateScript({$_ -is [int]})]
        [int]$Pages,

        [switch]$Descending,

        [Parameter(ParameterSetName = 'org', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [string]$OrgId,

        [Parameter(ParameterSetName = 'profile', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithProfile', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithProfile', Mandatory)]
        [string]$ProfileName
    )
    
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

    $Results = [List[PsObject]]::New()

    $Uri = "{0}/organizations/{1}/appliance/security/events" -f $BaseURI, $OrgId

    Set-Variable -Name Query
    if ($StartDate) {
        $Query = "t0={0}" -f ($StartDate.ToString(")"))
    }
    if ($EndDate) {
        if ($Query) {$Query += "&"}
        $Query = "{0}t1={0}" -f $Query, ($EndDate.ToString("O"))
    }
    if ($Days) {
        $Seconds = [TimeSpan]::FromDays($Days).TotalSeconds
        if ($Query) {$Query += "&"}
        $Query = "{0}timestamp={1}" -f $Seconds
    }
    if ($PerPage) {
        if ($Query) {$Query += "&"}
        $Query = "{0}perPage={1}" -f $Query, $PerPage
    }

    if ($Descending) {
        if ($Query) {$Query += '&'}
        $Query = "{0}sortOrder=descending" -f $Query
    }

    if ($Query) {
        $Uri = "{0}?{1}" -f $Uri, $Query
    }

    try {
        $response = Invoke-WebRequest -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
        [List[PsObject]]$result = $response.Content | ConvertFrom-Json
        if ($result) {
            $Results.AddRange($result)
        }
        $page = 1
        if ($Pages -ne 1) {
            $done = $false
            do {
                if ($response.RelationLink['next']) {
                    $Uri = $response.RelationLink['next']
                    $response = Invoke-WebRequest -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
                    [List[PsObject]]$result = $response.Content | ConvertFrom-Json
                    if ($result) {
                        $Results.AddRange($result)
                    }
                    $page += 1
                    if ($page -gt $Pages) {
                        $done = $true
                    }
                } else {
                    $done = $true
                }
            } until ($done)
        }
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
    Number of entries per page to retrieve. Acceptable range is 3-1000. Default is 100. NOTE: Paging is not implemented. 
    .OUTPUTS
    A collection of security event objects.
    #>
}

Set-Alias -Name GMNetSecEvents -Value Get-MerakiOrganizationSecurityEvents

function Get-MerakiOrganizationFirmwareUpgrades() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [switch]$IncludePending,
        [switch]$includeStarted,
        [switch]$IncludeCompleted,
        [switch]$IncludeCanceled,
        [switch]$IncludeSkipped,
        [switch]$IncludeAppliances,
        [switch]$IncludeCameras,
        [switch]$IncludeCellularGateways,
        [switch]$IncludeSensors,
        [switch]$IncludeSwitches,
        [switch]$IncludeSystemsManagers,
        [switch]$IncludeWireless,
        [ValidateScript({$_ -is [int]})]
        [ValidateSet(3, 1000)]
        [int]$PerPage,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {
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

        if ($PerPage) {
            $Query = "perPage={0}" -f $PerPage
        }

        $Statuses = [List[string]]::New()
        if ($IncludePending) {$Statuses.Add("pending")}
        if ($includeStarted) {$Statuses.Add("started")}
        if ($IncludeCanceled) {$Statuses.Add("started")}
        if ($IncludeSkipped) {$Statuses.Add("skipped")}
        if ($IncludeCompleted) {$Statuses.Add("completed")}
        
        if ($Statuses.Count -gt 0) {
            if ($Query) {$Query += "&"}
            $Query = "{0}status[]={1}" -f $Query, ($Statuses.ToArray() -join ',')            
        }

        $ProductTypes = [List[string]]::New()
        if ($IncludeAppliances) {$ProductTypes.Add("appliance")}
        if ($IncludeCameras) {$ProductTypes.Add("camera")}
        if ($IncludeCellularGateways) {$ProductTypes.Add("cellularGateway")}
        if ($IncludeSensors) {$ProductTypes.Add("sensors")}
        if ($IncludeSwitches) {$ProductTypes.Add("switch")}
        if ($IncludeSystemsManagers) {$ProductTypes.Add("systemsManager")}
        if ($IncludeWireless) {$ProductTypes.Add("wireless")}


        if ($ProductTypes.Count -gt 0) {
            if ($Query) {$Query += "&"} else {$Query += "?"}
            $Query = "{0}productTypes[]={1}" -f $Query, ($ProductTypes.ToArray() -join ",")
        }

    }

    Process{

        $Uri = "{0}/organizations/{1}/firmware/upgrades" -f $BaseURI, $OrgId

        if ($Query) {
            $URI = "{0}?{1}" -f $Uri, $Query
        }

        $Results = [List[PsObject]]::New()

        try {
            $response = Invoke-WebRequest -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            [List[PsObject]]$result = $response.Content | ConvertFrom-Json
            if ($result) {
                $Results.AddRange($result)
            }
            $page = 1
            if ($Pages -ne 1) {
                $done = $false
                do {
                    if ($response.RelationLink['next']) {
                        $Uri = $response.RelationLink['next']
                        $response = Invoke-WebRequest -Method Get -Uri $Uri -Headers $Header -PreserveAuthorizationOnRedirect
                        [List[PsObject]]$result = $response.Content | ConvertFrom-Json
                        if ($result) {
                            $Result.AddRange($result)
                        }
                        $page += 1
                        if ($page -gt $Pages) {
                            $done = $true
                        }
                    } else {
                        $done = $true
                    }
                } until ($done)
            }
            return $Results.ToArray()
        } catch {
            throw $_
        }
    }
        <#
    .SYNOPSIS
    Get firmware upgrade information.
    .DESCRIPTION
    Get firmware upgrade information for an organization
    .PARAMETER OrgId
    The Organization Id. If omitted the retrieved from the default profile.
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
    [CmdletBinding(DefaultParameterSetName='default')]
    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Serial,
        [string[]]$Macs,
        [string[]]$FirmwareUpgradeIds,
        [string[]]$FirmwareUpgradeBatchIds,
        [ValidateScript({$_ -is [int]})]
        [ValidateRange(3,1000)]
        [int]$PerPage,
        [ValidateScript({$_ -is [int]})]
        [int]$Pages=1,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )
<# 
    If ($OrgId -and $profileName) {
        Write-Host "The parameters OrgId and ProfileName cannot be used together!" -ForegroundColor Red
        return
    }
 #>
    Begin {
        $NetworkIds = [List[string]]::New()
        $Serials = [List[string]]::New()

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

        $Headers = Get-Headers

        if ($PerPage) {
            $Query = "perPage={0}" -f $PerPage
        }
        
        if ($Macs) {
            if ($Query) {$Query += '&'}
            $Query = "macs[]={0}" -f ($Macs -join ',')            
        }

        if ($FirmwareUpgradeIds) {
            if ($Query) {$Query += '&'}
            $Query = "{0}firmwareUpgradeIds[]={1}" -f $Query, ($FirmwareUpgradeIds -join ',')            
        }

        if ($FirmwareUpgradeBatchIds) {
            if ($Query) {$Query += '&'}
            $Query = "{0}firmwareUpgradeBatchIds[]={1}" -f $Query, $FirmwareUpgradeBatchIds
        }
        
        $Uri = "{0}/organizations/{1}/firmware/upgrades/byDevice" -f $BaseURI, $OrgId
    }
    
    Process {
        if ($Id) {
            $NetworkIds.Add($Id)
        }
    
        if ($Serial) {
            $Serials.Add($Serial)
        }
    }

    End {

        if ($NetworkIds.Count -gt 0) {
            if ($Query) {$Query += '&'}
            $Query = "{0}networkIds[]={1}" -f $Query, ($NetworkIds.ToArray() -join ',')
        }

        if ($Serials.Count -gt 0) {
            if ($Query) {$Query += "&"}
            $Query = "{0}serials[]={1}" -f $Query, ($Serials.ToArray() -join ',')
        }

        if ($Query) {
            $Uri = "{0}?{1}" -f $Uri, $Query
        }

        $Results = [List[PsObject]]::New()

        Try {
            $response = Invoke-WebRequest -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            [List[PsObject]]$result = $response.Content | ConvertFrom-Json
            if ($result) {
                $Results.AddRange($result)
            }
            $page = 1
            if ($Pages -ne 1) {
                $done = $false
                do {
                    if ($response.RelationLink['next']) {
                        $Uri = $response.RelationLink['next']
                        $response = Invoke-WebRequest -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
                        [List[PsObject]]$result = $response.Content | ConvertFrom-Json
                        if ($result) {
                            $Results.AddRange($result)
                        }
                        $page += 1
                        if ($page -gt $Pages) {
                            $done = $true
                        }
                    } else {
                        $done = $true
                    }
                } until ($done)
            }

            return $Results.ToArray()
        } catch {
            throw $_
        }
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
    .PARAMETER PerPage
    Number of entries per page.
    .PARAMETER Id
    An array of network Ids to retrieve upgrades for
    .PARAMETER Serial
    An array of serials to retrieve upgrades for
    .PARAMETER Macs
    An array of MAC Addresses to retrieve upgrades for
    .PARAMETER FirmwareUpgradeIds
    An array of Upgrade Ids to retrieve upgrades for
    .PARAMETER FirmwareUpgradeBatchIds
    An array of Firmware Upgrade Batch Ids to retrieve upgrades for
    .OUTPUTS
    An array of firmware upgrade objects.
    #>
}

#region OrganizationThirdPartyVpnPeers

function Get-MerakiOrganizationDeviceUplinks() {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Serial,
        [ValidateScript({$_ -is [int]})]
        [ValidateRange(3,1000)]
        [int]$PerPage,
        [ValidateScript({$_ -is [int]})]
        [int]$Pages,
        [switch]$IncludeAppliances,
        [switch]$IncludeCameras,
        [switch]$IncludeCellularGateways,
        [switch]$IncludeSensors,
        [switch]$IncludeSwitches,
        [switch]$IncludeSystemsManagers,
        [switch]$IncludeWireless,
        [string[]]$Tags,
        [ValidateSet("withAllTags","withAnyTags")]
        [string]$TagFilterType,
        [string]$OrgId,
        [string]$ProfileName
    )

    Begin {
        $Headers = Get-Headers
        $NetworkIds = [List[string]]::New()
        $Serials = [List[string]]::New()

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
        if ($PerPage) {
            $Query = "?perPage={0}" -f $PerPage
        }

        $ProductTypes = [List[string]]::New()
        if ($IncludeAppliances) {$ProductTypes.Add("appliance")}
        if ($IncludeCameras) {$ProductTypes.Add("camera")}
        if ($IncludeCellularGateways) {$ProductTypes.Add("cellularGateway")}
        if ($IncludeSensors) {$ProductTypes.Add("sensors")}
        if ($IncludeSwitches) {$ProductTypes.Add("switch")}
        if ($IncludeSystemsManagers) {$ProductTypes.Add("systemsManager")}
        if ($IncludeWireless) {$ProductTypes.Add("wireless")}

        if ($ProductTypes.Count -gt 0) {
            if ($Query) {$Query += "&"} else {$Query += "?"}
            $Query = "{0}productTypes[]={1}" -f $Query, ($ProductTypes.ToArray() -join ',')
        }

        if ($Tags) {
            if ($Query) {$Query += "&"} else {$Query += "?"}
            $Query = "{0}tags[]={1}" -f $Query, ($Tags -join ',')
            if ($TagFilterType) {
                $Query = "{0}&tagFilterType={1}" -f $Query, $TagFilterType
            }
        }

        $Uri = "{0}/organizations/{1}/devices/uplinks/addresses/byDevice" -f $BaseURI, $OrgId
    }

    Process {
        if ($id) {
            $NetworkIds.Add($Id)
        }

        if ($Serial) {
            $Serials.Add($Serial)
        }
    }

    End {

        if ($NetworkIds.Count -gt 0) {
            if ($Query) {$Query += "&"} else {$Query += "?"}
            $Query = "{0}networkIds[]={1}" -f $Query, ($NetworkIds.ToArray() -join ',')
        }

        if ($Serials.Count -gt 0) {
            if ($Query) {$Query += "&"} else {$Query += "?"}
            $Query = "{0}serials[]={1}" -f $Query, ($NetworkIds.ToArray() -join ',')
        }

        if ($Query) {
            $Uri = "{0}{1}" -f $Uri, $Query
        }
        $Results = [List[PsObject]]::New()

        try {
            $response = Invoke-WebRequest -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            [List[PsObject]]$result = $response.Content | ConvertFrom-Json
            if ($result) {
                $Results.AddRange($result)
            }
            $page = 1
            if ($Pages -ne 1) {
                $done = $false
                do {
                    if ($response.RelationLink['next']) {
                        $Uri = $response.RelationLink['next']
                        $response = Invoke-WebRequest -Method Get -Uri $Uri -Headers $Headers
                        [List[PsObject]]$result = $response.Content | ConvertFrom-Json
                        if ($result) {
                            $Results.AddRange($result)
                        }
                        $page += 1
                        if ($page -gt $Pages) {
                            $done = $true
                        }
                    } else {
                        $done = $true
                    }
                } until ($done)
            }

            $Networks = @{}
            Get-MerakiNetworks | ForEach-Object{
                $Networks.Add($_.id, $_.name)
            }
            $Results | ForEach-Object {
                $NetworkName = $Networks[$_.network.id]
                $_.network | Add-Member -MemberType NoteProperty -Name Name -Value $NetworkName 
            }
            return $Results.ToArray()
        } catch {
            throw $_
        }
    }
        <#
        .SYNOPSIS
        List the current uplink addresses for devices in an organization.
        .DESCRIPTION
        List the current uplink addresses for devices in an organization. This can be filtered by
        Networks, Product Types, Serials, and Tags.
        .PARAMETER Id
        Optional parameter to filter device uplinks by network ID. 
        .PARAMETER Serial
        Optional parameter to filter device uplinks by device product types.
        .PARAMETER PerPage
        The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000
        .PARAMETER Pages
        Number of pages to return. Default is 1, 0 = all pages.
        .PARAMETER IncludeAppliances
        Include Appliances
        .PARAMETER IncludeCameras
        Include Cameras
        .PARAMETER IncludeCellularGateways
        Include Cellular Gateways
        .PARAMETER IncludeSensors
        Include Sensors
        .PARAMETER IncludeSwitches
        Include Switches
        .PARAMETER IncludeSystemsManagers
        Include Systems Managers
        .PARAMETER IncludeWireless
        Include Wireless
        .PARAMETER Tags
        An optional parameter to filter devices by tags. The filtering is case-sensitive.
        .PARAMETER TagFilterType
        An optional parameter of value 'withAnyTags' or 'withAllTags' to indicate whether to return devices which contain ANY or ALL of the included tags. If no type is included, 'withAnyTags' will be selected.
        .PARAMETER OrgId
        Organization Id to use.
        .PARAMETER ProfileName
        Named profile to use.
        .OUTPUTS
        An array of device uplink objects.
        .NOTES
        If no include parameters are given then all product typed are returned.
        If one or more include parameters are given then the results are restricted to those product types.
        #>
}

function Get-MerakiOrganizationDeviceStatus() {
    [CmdletBinding(DefaultParameterSetName='default')]
    Param(
        [Alias('NetworkId')]
        [string]$Id,
        [string]$Serial,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'Profile')]
        [string]$ProfileName
    )

    Begin {
        $Headers = Get-Headers
        #$NetworkIds = [List[string]]::New()
        #$Serials = [List[string]]::New()

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
        
        $Uri = "{0}/organizations/{1}/devices/statuses" -f $BaseUri, $OrgId

    }

    Process {

        $Params = @{
            Method = "Get"
            Uri = $Uri
            Headers = $Headers
        }

        $Results = [List[PsObject]]::New()

        try {
            $response = Invoke-WebRequest @Params -PreserveAuthorizationOnRedirect
            $Results = $response.Content | ConvertFrom-Json
            
            $Networks = @{}
            Get-MerakiNetworks | ForEach-Object {
                $Networks.Add($_.Id, $_)                
            }
            $Results | ForEach-Object {
                $NetworkName = $Networks[$_.NetworkId].Name
                $_ | Add-Member -MemberType NoteProperty -Name "NetworkName" -Value $NetworkName
            }
            return $Results
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    List the status of every Meraki device in the organization.
    .DESCRIPTION
    List the status of every Meraki device in the organization. Can be filtered by Network or Serial number.
    .PARAMETER Id
    The ID of the Network to retrieve device status from.
    .PARAMETER Serial
    Then serial number of the device to retrieve status from.
    .PARAMETER OrgId
    The organization Id to use.
    .PARAMETER ProfileName
    The named profile to use.
    .OUTPUTS
    An array of device status objects
    #>
}

function Get-MerakiOrganizationApplianceVpnStatuses() {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('NetworkId')]
        [string]$id,
        [ValidateScript({$_ -is [int]})]
        [ValidateSet(3,300)]
        [int]$PerPage,
        [ValidateScript({$_ -is [int]})]
        [int]$Pages = 1,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

    Begin {
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

        $NetworkIds = [List[String]]::New()

        if ($PerPage) {
            $Query = "?perPage={0}" -f $PerPage
        }

        $Uri = "{0}/organizations/{1}/appliance/vpn/statuses" -f $BaseURI, $OrgId
    }

    Process {
        if ($id) {
            $NetworkIds.Add($Id)
        }
    }

    End {
        $Results = [List[PsObject]]::New()

        if ($NetworkIds.Count -gt 0) {
            if ($Query) {$Query += "&"} else {$Query += "?"}
            $Query = "{0}networkIds[]={1}" -f $Query, ($NetworkIds.ToArray() -join ',')
        }

        try {
            $response = Invoke-WebRequest -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            [List[PsObject]]$result = $response.Content | ConvertFrom-Json
            if ($result) {
                $Results.AddRange($result)
            }
            $page = 1
            if ($Pages -ne 1) {
                $done = $false
                do {
                    if ($response.RelationLink['next']) {
                        $Uri = $response.RelationLink['next']
                        $response = Invoke-WebRequest -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
                        [List[PsObject]]$result = $response.Content | ConvertFrom-Json
                        if ($result) {
                            $Results.AddRange($result)
                        }
                        $page += 1
                        if ($page =gt $Pages) {
                            $done = $true
                        }
                    } else {
                        $done = $true
                    }
                 } until ($done)
            }
            return $Results.ToArray()
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS 
    List VPN status for networks in an organization
    .DESCRIPTION
    Show VPN status for networks in an organization. can be filtered by Networks.
    .PARAMETER id
    The network ID to get VPN status for.
    .PARAMETER PerPage
    The number of entries per page returned. Acceptable range is 3 - 300. Default is 300.
    .PARAMETER Pages
    The number of pages to return. Default is 1, 0 = return all pages.
    .PARAMETER OrgId
    The organization to use.
    .PARAMETER ProfileName
    The named profile to use.
    .OUTPUTS
    An array of VPN statuses.
    #>
}