# Meraki Organization functions
using namespace System.Collections.Generic

function Set-MerakiAPI() {
    [CmdletBinding()]
    Param(
        [string]$APIKey,
        [string]$OrgID,
        [string]$ProfileName,
        [switch]$SecureKey
    )
    
    function Set-MerakiSecret() {
        Param(
            [string]$APIKey
        )
        $SecretIn = @{
            Version = 1
            APIKey = $APIKey
        }
        $Secret = $SecretIn | ConvertTo-Json

        $Params = @{
            Name = "MerakiAPI"
            Secret = $Secret
        }

        Set-Secret @Params
    }

    $configPath = "{0}/.meraki" -f $HOME
    $configFile = "{0}/config.json" -f $configPath

    if (-not (Test-Path -Path $configFile)) {
        if (-not $APIKey) {
            $APIKey = Read-Host -Prompt "API Key: "
        }   

        if ($APIKey) {
            if ($SecureKey) {
                $config = @{
                    APIKey = "Secure"
                }
                
                $Params = @{
                    APIKey = $APIKey
                }
                
                Set-MerakiSecret @Params                
            } else {
                $config = @{
                    APIKey = $apiKey
                }
            }
         } else {
            Throw "APIKey required if config file does not exist!"
        } 
        if ((-not $OrgId) -and (-not $profileName)) {
            $orgs = Get-MerakiOrganizations -APIKey $APIKey
            
            $config.Add('profiles', @{default = $orgs[0].Id})
            foreach ($org in $orgs) {
                $config.profiles.Add($org.name, $org.id)
            }
        } else {
            if (-not $profileName) {
                $config.Add('profiles',@{default = $OrgID})
            } else {
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
            If ($config.APIKey -eq 'Secure') {
                $ConfigKey = (Get-Secret -Name 'MerakiAPI' -AsPlainText | ConvertFrom-JSON).APIKey
            } Else {
                $ConfigKey = $Config.APIKey
            }
            If ($ConfigKey -ne $APIKey) {
                Write-Host "The APIKey you entered does not match the APIKey in the config file. This will overwrite the existing config file! Continue? [y/N]: " -NoNewline -ForegroundColor Yellow                
                $response = Read-Host 
                if ($response -eq "y") {
                    if ($SecureKey) {
                        $config = @{
                            $APIKey = "Secure"
                        }

                        $VaultName = (Get-SecretVault | Select-Object -First 1).Name
                        If ($VaultName) {
                            Write-Host "Checking $VaultName for existing Meraki Secret" -ForegroundColor Yellow
                            $Secret = Get-SecretInfo -Vault $VaultName | Where-Object {$_.Name -eq 'MerakiAPI'}
                            If ($Secret) {
                                Write-Host "MerakiAPI secret already exists, Do you want to overwrite? [y/N]: " -NoNewline -ForegroundColor Yellow
                                $response = Read-Host
                                if ($response -ne 'y') {
                                    Write-Host "Aborting!"
                                    exit
                                }
                            }
                        }
                        
                        Set-MerakiSecret -APIKey $APIKey

                    } else {
                        $config = @{
                            APIKey = $APiKey
                        }
                    }
                } else {
                    Throw "Aborting!"
                }
            } else {
                if ($SecureKey) {
                    $Config.APIKey = "Secure"
                    
                    Set-MerakiSecret -APIKey $APIKey 
                }
            }
        } else {
            if ($SecureKey) {
                $APIKey = $config.APIKey
                $config.APIKey = "Secure"
                                
                Set-MerakiSecret -APIKey $APIKey 

                if (-not (Test-Path -Path $configPath)) {
                    [void](New-Item -Path $configPath -ItemType:Directory)
                }

                $config | ConvertTo-Json | Out-File -FilePath $configFile
                return 
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
    .PARAMETER SecureKey
    Save the API key to the a secret Vault.
    If this parameter is provided alone, your existing API key will be stored in the secret vault and the configuration changed
    to support the secure key. The config.json file will no longer contain your key in clear text.
    If you do not have a secrets vault registered you must register on using the New-MerakiSecretsVault function.
    If your Secrets Management configuration requires a password you will only eed to enter the password when issuing the first command.
    The vault will remain unlocked for the remainder of the PowerShell session.    
    .NOTES
    If the OrgID and profileName parameters are omitted named profiles will be created based on the Organization names pulled from Meraki.
    This approach may not be the best as most of the time these names will have multiple words and spaces and just be too long.
    .EXAMPLE
    Create the default profile
    PS> Set-MerakiAPI -APIKey 'EXAMPLEGDTE63534HD74BD93847' -OrgId 123456
    .EXAMPLE
    Create a Named Profile.
    Set-MerakiAPI -OrgId 987458 -ProfileName USNetwork
    .EXAMPLE
    Create a secure key profile.
    Set-MerakiAPI -APIKey 'EXAMPLE88fhjryh4666drfe9207' -OrgId 123456 -SecureKey
    .EXAMPLE
    Convert your existing configuration to use the Secure Key Store.
    Set-MerakiAPI -SecureKey     
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
    Optional Organizational ID. 
    .PARAMETER profileName
    Optional Profile name.
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



function Get-MerakiOrganizationConfigTemplate () {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
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
        $Uri = "{0}/organizations/{1}/configTemplates" -f $BaseURI, $OrgID
        if ($Id) {
            $Uri = "{0}/{1}" -f $Uri, $Id
        }

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
    Optional Organization ID.
    .PARAMETER profileName
    Optional Profile Name
    .OUTPUTS
    A configuration template object.
    #>
}

Set-Alias -Name GMOrgTemplates -value Get-MerakiOrganizationConfigTemplate -Option ReadOnly
Set-Alias -Name Get-MerakiOrganizationConfigTemplates -Value Get-MerakiOrganizationConfigTemplate

function Get-MerakiOrganizationDevices() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [string]$Filter,
        [int]$Pages,
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

    if ($Filter) {
        $Uri = "{0}?{1}" -f $Uri, $Filter
    }

    $Headers = Get-Headers

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
    Get organization Devices.
    .DESCRIPTION
    Get all devices in an organization.
    .PARAMETER Filter
    A string representing a filter to be applied to the returned objects.
    Valid filter properties are 'networkIds', 'productTypes', 'tags', 'tagFilterType', 'name', 'mac', 'serial', 'model', 'macs', 'serials', 
    'sensorMetrics', 'sensorAlertProfilesIds', 'models'.
    productTypes, tags, macs, serials, sensorMetrics, sensorAlertProfileIds, and models are arrays.
    See examples for constructing a filter string.
    .PARAMETER Pages
    The number of pages to return. Default is all pages.
    .PARAMETER OrgID
    Optional Organization Id..
    .PARAMETER profileName
    Optional Profile name.
    .OUTPUTS
    AN array of Meraki Device objects.
    .EXAMPLE
    To construct a valid filter specify the properties and valued separated by an '='. Each property/value set must be separated by an '&'.
    Array property names must be appended with '[]'.
    Values for array properties must be separated by a comma.

    $Filter = "productTypes=appliance,switch&networkIds=N_987654159756,N_159456159753"
    Get-MerakiOrganizationDevices -Filter $Filter
    #>
}

Set-Alias -Name GMOrgDevs -Value Get-MerakiOrganizationDevices -Option ReadOnly

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
    Optional Organization Id.
    .PARAMETER profileName
    Optional Profile Name.
    .OUTPUTS
    An array of Meraki Admin objects.
    #>
}

Set-Alias -Name GMOrgAdmins -Value Get-MerakiOrganizationAdmins -Option ReadOnly


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
    Optional Organization Id.
    .PARAMETER profileName
    Optional Profile Name
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

Set-Alias -Name GMOrgCC -Value Get-MerakiOrganizationConfigurationChanges -Option ReadOnly


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
    Optional Organization Id
    .PARAMETER profileName
    Optional Profile name
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
    <#
    .DESCRIPTION
    Updates a third party VPN peer for an Organization
    .PARAMETER Name
    The name of the VPN peer
    .PARAMETER Secret
    The shared secret with the VPN peer
    .PARAMETER IkeVersion
    The IKE version to be used for the IPsec VPN peer configuration. Defaults to '1' when omitted. Valid values are '1', '2'
    .PARAMETER IpsecPoliciesPreset
    One of the following available presets: 'default', 'aws', 'azure'. If this is provided, the 'ipsecPolicies' parameter is ignored.
    .PARAMETER LocalId
    The local ID is used to identify the MX to the peer. This will apply to all MXs this peer applies to.
    .PARAMETER PublicIp
    The public IP of the VPN peer.
    .PARAMETER PrivateSubnets
    The list of the private subnets of the VPN peer
    .PARAMETER RemoteId
    The remote ID is used to identify the connecting VPN peer. This can either be a valid IPv4 Address, FQDN or User FQDN.
    .PARAMETER NetworkTags
    A list of network tags that will connect with this peer. Use ['all'] for all networks. Use ['none'] for no networks. If not included, the default is ['all'].
    .PARAMETER IpsecPolicies
    Custom IPSec policies for the VPN peer. If not included and a preset has not been chosen, the default preset for IPSec policies will be used.
    This is ab object with the following properties:
    childLifetime: integer The lifetime of the Phase 2 SA in seconds.
    ikeLifetime: integer The lifetime of the Phase 1 SA in seconds.
    childAuthAlgo: array[] This is the authentication algorithms to be used in Phase 2. The value should be an array with one of the following algorithms: 'sha256', 'sha1', 'md5'
    childCipherAlgo: array[] This is the cipher algorithms to be used in Phase 2. The value should be an array with one or more of the following algorithms: 'aes256', 'aes192', 'aes128', 'tripledes', 'des', 'null'
    childPfsGroup: array[] This is the Diffie-Hellman group to be used for Perfect Forward Secrecy in Phase 2. The value should be an array with one of the following values: 'disabled','group14', 'group5', 'group2', 'group1'
    ikeAuthAlgo: array[] This is the authentication algorithm to be used in Phase 1. The value should be an array with one of the following algorithms: 'sha256', 'sha1', 'md5'
    ikeCipherAlgo: array[] This is the cipher algorithm to be used in Phase 1. The value should be an array with one of the following algorithms: 'aes256', 'aes192', 'aes128', 'tripledes', 'des'
    ikeDiffieHellmanGroup: array[] This is the Diffie-Hellman group to be used in Phase 1. The value should be an array with one of the following algorithms: 'group14', 'group5', 'group2', 'group1'
    ikePrfAlgo: array[] [optional] This is the pseudo-random function to be used in IKE_SA. The value should be an array with one of the following algorithms: 'prfsha256', 'prfsha1', 'prfmd5', 'default'. The 'default' option can be used to default to the Authentication algorithm.
    .PARAMETER OrgID
    Optional Organization Id.
    .PARAMETER profileName
    Optional Profile name.
    #>
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
    <#
    .DESCRIPTION
    Create a new organization third party VPN peer.
    .PARAMETER Name
    The name of the VPN peer
    .PARAMETER Secret
    The shared secret with the VPN peer
    .PARAMETER IkeVersion
    The IKE version to be used for the IPsec VPN peer configuration. Defaults to '1' when omitted. Valid values are '1', '2'
    .PARAMETER IpsecPoliciesPreset
    One of the following available presets: 'default', 'aws', 'azure'. If this is provided, the 'ipsecPolicies' parameter is ignored.
    .PARAMETER LocalId
    The local ID is used to identify the MX to the peer. This will apply to all MXs this peer applies to.
    .PARAMETER PublicIp
    The public IP of the VPN peer.
    .PARAMETER PrivateSubnets
    The list of the private subnets of the VPN peer
    .PARAMETER RemoteId
    The remote ID is used to identify the connecting VPN peer. This can either be a valid IPv4 Address, FQDN or User FQDN.
    .PARAMETER NetworkTags
    A list of network tags that will connect with this peer. Use ['all'] for all networks. Use ['none'] for no networks. If not included, the default is ['all'].
    .PARAMETER IpsecPolicies
    Custom IPSec policies for the VPN peer. If not included and a preset has not been chosen, the default preset for IPSec policies will be used.
    This is ab object with the following properties:
    childLifetime: integer The lifetime of the Phase 2 SA in seconds.
    ikeLifetime: integer The lifetime of the Phase 1 SA in seconds.
    childAuthAlgo: array[] This is the authentication algorithms to be used in Phase 2. The value should be an array with one of the following algorithms: 'sha256', 'sha1', 'md5'
    childCipherAlgo: array[] This is the cipher algorithms to be used in Phase 2. The value should be an array with one or more of the following algorithms: 'aes256', 'aes192', 'aes128', 'tripledes', 'des', 'null'
    childPfsGroup: array[] This is the Diffie-Hellman group to be used for Perfect Forward Secrecy in Phase 2. The value should be an array with one of the following values: 'disabled','group14', 'group5', 'group2', 'group1'
    ikeAuthAlgo: array[] This is the authentication algorithm to be used in Phase 1. The value should be an array with one of the following algorithms: 'sha256', 'sha1', 'md5'
    ikeCipherAlgo: array[] This is the cipher algorithm to be used in Phase 1. The value should be an array with one of the following algorithms: 'aes256', 'aes192', 'aes128', 'tripledes', 'des'
    ikeDiffieHellmanGroup: array[] This is the Diffie-Hellman group to be used in Phase 1. The value should be an array with one of the following algorithms: 'group14', 'group5', 'group2', 'group1'
    ikePrfAlgo: array[] [optional] This is the pseudo-random function to be used in IKE_SA. The value should be an array with one of the following algorithms: 'prfsha256', 'prfsha1', 'prfmd5', 'default'. The 'default' option can be used to default to the Authentication algorithm.
    .PARAMETER OrgID
    Optional Organization Id.
    .PARAMETER profileName
    Optional Profile name.
    #>
}

function Get-MerakiOrganizationInventoryDevices() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [string]$Filter,
        [int]$Pages,
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

    if ($Filter) {
        $Uri = "{0}?{1}" -f $Uri, $Filter
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
        return $Results.ToArray()
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Get the organization device inventory 
    .PARAMETER Filter
    A string representing a filter for the returned objects.
    Valid filter properties are 'usedState', 'search', 'macs', 'networkIds', 'serials', 'models', 'orderNumbers', 'tags', 'tagFilterType', 'productTypes'.
    All properties are arrays except 'usedState', 'search', and 'tagFilterType'.
    The search property accepts a single value that will search against serial number, mac address, or model.
    Valid tagFilterType values are 'withAllTags' or 'withAnyTags'.
    Valid productTypes values are "appliance","camera","cellularGateway","secureConnect","sensor","switch","systemsManager",or "wireless".
    Valid usedState values are 'unused', 'used'.
    .PARAMETER OrgID
    Organization ID. If omitted used th default profile.
    .PARAMETER profileName
    Profile name to use. If omitted used th default profile.
    .OUTPUTS
    An array of inventory objects.
    .EXAMPLE
    To construct a valid filter specify the properties and valued separated by an '='. Each property/value set must be separated by an '&'.
    Array property names must be appended with '[]'.
    Values for array properties must be separated by a comma.

    $Filter = "productTypes[]=appliance,switch&usedState=unused"
    Get-MerakiOrganizationInventoryDevices -Filter $Filter
    #>
}

Set-Alias -Name GMOrgInvDevices -value Get-MerakiOrganizationInventoryDevices -Option ReadOnly

function Get-MerakiOrganizationInventoryDevice() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$Serial,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profile')]
        [string]$profileName        
    )

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

    $Uri = "{0}/organizations/{1}/inventory/devices/{2}" -f $BaseURI, $OrgID, $Serial

    try {
        $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
}

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
        $Query = "t0={0}" -f ($StartDate.ToString("0"))
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
        return $Results
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
    .PARAMETER OrgID
    Organization ID. If omitted used th default profile.
    .PARAMETER profileName
    Profile name to use. If omitted used th default profile.
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
    .PARAMETER OrgID
    Organization ID. If omitted used th default profile.
    .PARAMETER profileName
    Profile name to use. If omitted used th default profile.

    #>
}

Set-Alias -Name GMOFirmwareUpgrades -Value Get-MerakiOrganizationFirmwareUpgrades


function Get-MerakiOrganizationFirmwareUpgradesByDevice() {
    [CmdletBinding(DefaultParameterSetName='default')]
    Param(        
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
        
        $Uri = "{0}/organizations/{1}/firmware/upgrades/byDevice" -f $BaseURI, $OrgId
    }
    
    Process {

        if ($PerPage) {
            $Uri = "{0}?perPage={1}" -f $Uri, $PerPage
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
    Optional organization Id
    .PARAMETER ProfileName
    Optional profile name.
    .PARAMETER Pages
    Number of pages to return. Default is all.
    .PARAMETER PerPage
    Number of entries per page.
    .PARAMETER OrgID
    Organization ID. If omitted used th default profile.
    .PARAMETER profileName
    Profile name to use. If omitted used th default profile.
    .OUTPUTS
    An array of firmware upgrade objects.
    #>
}

function Get-MerakiOrganizationDeviceUplinks() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [string]$Filter,
        [ValidateScript({$_ -is [int]})]
        [ValidateRange(3,1000)]
        [int]$PerPage,
        [ValidateScript({$_ -is [int]})]
        [int]$Pages,
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

        $Uri = "{0}/organizations/{1}/devices/uplinks/addresses/byDevice" -f $BaseURI, $OrgId

        if ($PerPage) {
            $Query = "?perPage={0}" -f $PerPage
        }

        If ($Filter) {
            if ($Query) {
                $Query = "{0}&" -f $Query
            } else {
                $Query = "?"
            }
            $Query = "{0}{1}" -f $Query, $Filter
        }

        $Uri = "{0}{1}" -f $Uri, $Query
    }

    Process {
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
    .PARAMETER Filter
    A string representing a filter for the returned objects.
    Valid properties are 'networkIds', 'productTypes', 'serials', 'tags', and 'tagFilterTypes'.
    All properties except 'tagFilterTypes are arrays. Arrays must be specified in the filter string with '[]'
    Valid productTypes are "appliance","camera","cellularGateway","secureConnect","sensor","switch","systemsManager", and "wireless".
    Valid tagFilterTypes as "withAllTags" and "withAnyTag".
    See Examples for building a filter string.
    .PARAMETER PerPage
    The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000
    .PARAMETER Pages
    Number of pages to return. Default is 1, 0 = all pages.
    .PARAMETER OrgId
    Organization Id to use.
    .PARAMETER ProfileName
    Named profile to use.
    .PARAMETER OrgID
    Organization ID. If omitted used th default profile.
    .PARAMETER profileName
    Profile name to use. If omitted used th default profile.
    .OUTPUTS
    An array of device uplink objects.
    .NOTES
    If no include parameters are given then all product typed are returned.
    If one or more include parameters are given then the results are restricted to those product types.
    .EXAMPLE
    To use the Filter property you must construct a valid filter string. A filter string is like a HTTP query string.
    To specify a filter string construct it with the property name and values. Array values must be separated by a comma.
    Property Names and values are case sensitive.

    $Filter = "productTypes[]=appliance,switch&networkIds[]=N_987548754,N_87589514"
    Get-MerakiOrganizationDeviceUplink -Filter $Filter
    #>
}

function Get-MerakiOrganizationDeviceStatus() {
    [CmdletBinding(DefaultParameterSetName='default')]
    Param(
        [string]$Filter,
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
        if ($Filter) {
            $Uri = "{0}?{1}" -f $Uri, $Filter
        }

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
            Get-MerakiNetworks -OrgID $OrgId | ForEach-Object {
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
    .PARAMETER Filter
    A string representing a filter for the returned objects.
    Valid filter properties are 'usedState', 'search', 'macs', 'networkIds', 'serials', 'models', 'orderNumbers', 'tags', 'tagFilterType', 'productTypes'.
    All properties are arrays except 'usedState', 'search', and 'tagFilterType'.
    The search property accepts a single value that will search against serial number, mac address, or model.
    Valid tagFilterType values are 'withAllTags' or 'withAnyTags'.
    Valid productTypes values are "appliance","camera","cellularGateway","secureConnect","sensor","switch","systemsManager",or "wireless".
    .PARAMETER OrgId
    The organization Id to use.
    .PARAMETER ProfileName
    The named profile to use.
    .OUTPUTS
    An array of device status objects
    .EXAMPLE
    To use the Filter property you must construct a valid filter string. A filter string is like a HTTP query string.
    To specify a filter string construct it with the property name and values. Array values must be separated by a comma.
    Property Names and values are case sensitive.

    $Filter = "productTypes[]=appliance,switch&networkIds[]=N_987548754,N_87589514"
    Get-MerakiOrganizationDeviceStatus -Filter $Filter
    #>
}

function Get-MerakiOrganizationApplianceVpnStatuses() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
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

function Get-MerakiOrganizationApplianceUplinkStatuses() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String]$networkId="*",
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String]$serial="*",
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName

    )
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
    } else {
        $config = Read-Config
    } 

    $Uri = "{0}/organizations/{1}/appliance/uplink/statuses" -f $BaseURI, $OrgID
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response | Where-Object {$_.networkID -like $networkID -and $_.serial -like $serial}
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Returns the Uplink status of Meraki Networks.
    .PARAMETER networkId
    Filters the output by network Id.
    .PARAMETER serial
    Filters the output by Appliance serial number. Partial serial number can be specified bu using the * wildcard. i.e. "*HG4U"
    .OUTPUTS
    An array of Meraki uplink objects.
    #>
}
Set-Alias -Name GMAppUpStat -value Get-MerakiOrganizationApplianceUplinkStatuses -Option ReadOnly
Set-Alias -Name Get-MerakiApplianceUplinkStatuses -value Get-MerakiOrganizationApplianceUplinkStatuses -Option ReadOnly


function Get-MerakiOrganizationApplianceVpnStats() {
    [cmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$id,
        [ValidateSet({$_ -is [int]})]
        [int]$perPage=100,
        [ValidateSet({$_ -is [int]})]
        [int]$TimeSpan=5,
        [switch]$Summarize,
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
        } else {
            $config = Read-Config
        } 


        $Headers = Get-Headers
        $config = read-config
        if ($profileName) {
            $OrgID = $config.profiles.$profileName
            if (-not $OrgId) {
                throw "Invalid profile name!"
            }A string representing a filter for the returned objects.
            Valid filter properties are 'usedState', 'search', 'macs', 'networkIds', 'serials', 'models', 'orderNumbers', 'tags', 'tagFilterType', 'productTypes'.
            All properties are arrays except 'usedState', 'search', and 'tagFilterType'.
            The search property accepts a single value that will search against serial number, mac address, or model.
            Valid tagFilterType values are 'withAllTags' or 'withAnyTags'.
            Valid productTypes values are "appliance","camera","cellularGateway","secureConnect","sensor","switch","systemsManager",or "wireless".
        } else {
            $OrgID = $config.profiles.default
        }

        class vpnPeer {
            [string]$networkID
            [string]$networkName
            [string]$peerNetworkId
            [string]$peerNetworkName
            [int]$receivedKilobytes
            [int]$sentKilobytes
        }

        class summaryVpnPeer {
            [string]$networkID
            [string]$networkName
            [int]$totalReceivedKilobytes
            [int]$totalSentKilobytes
        }
    }

    Process {
        $Network = Get-MerakiNetwork -networkID $id

        $Uri = "{0}/organizations/{1}/appliance/vpn/stats" -f $BaseURI, $OrgID

        $TimeSpan_Seconds = (New-TimeSpan -Days $TimeSpan).TotalSeconds

        $Uri = "{0}?perPage={1}&networkIds%5B%5D={2}&timespan={3}" -f $Uri, $TimeSpan, $id, $TimeSpan_Seconds

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            
            $peers = $response.merakiVpnPeers
            $PeerNetworks = New-object System.Collections.Generic.List[psobject]
            foreach ($peer in $peers) {
                $P = [vpnPeer]::New()
                $P.networkID = $id
                $P.networkName = $Network.name
                $P.peerNetworkId = $peer.networkId
                $P.peerNetworkName = $peer.networkName
                $P.receivedKilobytes = $peer.usageSummary.receivedInKilobytes
                $P.sentKiloBytes = $peer.usageSummary.sentInKilobytes

                $PeerNetworks.Add($P)
            }
            $vpnPeers = $PeerNetworks.ToArray()

            if ($Summarize) {   
                $summary = [summaryVpnPeer]::New()
                $summary.networkID = $id
                $Summary.networkName = $Network.name
                $summary.totalReceivedKilobytes = ($vpnPeers | Measure-Object -Property receivedKilobytes -Sum).Sum
                $summary.totalSentKilobytes = ($vpnPeers | Measure-Object -Property sentKilobytes -Sum).Sum            

                return $summary
            } else {
                $vpnPeers
            }
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Returns VPN statistics for the given organization network.
    .PARAMETER id
    The Network Id.
    .PARAMETER perPage
    The number of entries per page returned. Acceptable range is 3 - 300. Default is 300.
    .PARAMETER TimeSpan
    Number of seconds to return data for. default = 5.
    .PARAMETER Summarize
    Summarize the statistics,
    AN array op VPN peer objects or a summary object.
    .PARAMETER OrgId
    Optional Organization Id.
    .PARAMETER ProfileName
    Optional Profile Name
    #>
}

Set-Alias -Name GMAVpnStats -Value Get-MerakiOrganizationApplianceVpnStats -Option ReadOnly
Set-Alias -Name GMOAVpnStats -Value Get-MerakiOrganizationApplianceVpnStats -Option ReadOnly
set-Alias -Name Get-MerakiNetworkApplianceVpnStats -Value Get-MerakiOrganizationApplianceVpnStats

function Merge-MerakiOrganizationNetworks() {
    [CmdletBinding(
        SupportsShouldProcess, 
        DefaultParameterSetName = 'default',
        ConfirmImpact = 'High'
    )]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [string]$EnrollmentString,
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
        } else {
            $config = Read-Config
        } 

        $Networks = [List[string]]::New()

        $Header = Get-Headers
        $Uri = "{0}/organizations/{1}/networks/combine" -f $BaseURI, $OrgID
   }

    Process {
        $Networks.Add($Id)
    }

    End {

        $_Body = @{
            "name" = $Name
            "networkIds" = ($Networks.ToArray())
        }
        if ($EnrollmentString) { $_Body.Add("enrollmentString", $EnrollmentString) }

        $body = $_Body | ConvertTo-Json -Compress

        if ($PSCmdlet.ShouldProcess('Merge',"Networks $($Networks -join ',')")) {
            try {
                $response = Invoke-RestMethod -Method POST -Uri $Uri -Headers $Header -Body $Body -PreserveAuthorizationOnRedirect
                return $response
            } catch {
                throw $_
            }
        }
    }
    <#
    .SYNOPSIS
    Combine multiple Meraki networks into a single network.
    .PARAMETER Id
    The ID of the networks to combine. You should pass an array of network objects to combine those networks.
    .PARAMETER Name
    The name of the combined network.
    .PARAMETER NetworkIds
    A list of the network IDs that will be combined. 
    If an ID of a combined network is included in this list, the other networks in the list will be grouped into that network.
    .PARAMETER EnrollmentString
    A unique identifier which can be used for device enrollment or easy access through the Meraki SM Registration page or the Self Service Portal. 
    Please note that changing this field may cause existing bookmarks to break. All networks that are part of this combined network will have their enrollment string appended by '-network_type'. 
    If left empty, all existing enrollment strings will be deleted.
    .PARAMETER OrgId
    Optional Organization Id
    .PARAMETER ProfileName
    Optional Profile name.    
    .OUTPUTS
    A network object
    #>
}

Function New-MerakiSecretsVault() {
    [CmdletBinding()]
    Param (
        [ValidateSet('Password', 'none')]
        [string]$Authentication,
        [ValidateSet('Prompt','none')]
        [string]$Interaction
    )

    $CurrentConfig = Get-SecretStoreConfiguration | Where-Object {$_.Scope -eq "CurrentUser"}

    $Params = @{}

    if ($Authentication) {
        if ($Authentication -ne $CurrentConfig.Authentication) {
            $Params.Add("Authentication",$Authentication)
        }
    }

    if ($Interaction) {
        if ($Interaction -ne $CurrentConfig.Interaction) {
            $Params.Add("Interaction", $Interaction)
        }
    }

    if ($Params.Count -gt 0) {
        Set-SecretStoreConfiguration -Scope CurrentUser @Params
    }

    $Vaults = Get-SecretVault
    if ($Vaults) {
        if ($vaults.ModuleName -contains 'Microsoft.PowerShell.SecretStore') {
            Write-Host "There is currently an existing Vault register for module $($Vault.ModuleName)." -ForegroundColor Yellow
            Write-Host "The secretStore vault currently always operates in the logged user scope." -ForegroundColor Yellow
            Write-Host "Registering SecretStore multiple times with different names just results in duplication of teh same store," -ForegroundColor Yellow
            Write-Host "This vault will be used to store the secrets." -ForegroundColor Yellow            
         }
    } else {
        Register-SecretVault -Name "LocalVault" -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault -AllowClobber

        Write-Host "Vault 'LocalVault' created." -ForegroundColor Yellow 
    }

    <#
    .DESCRIPTION
    Created a local Secret vault to store secrets.
    .PARAMETER Authentication
    Specifies how to authenticate access to the SecretStore. The value must be Password or None. 
    If specified as None, the cmdlet enables access to the SecretStore without a password. The default authentication is Password.
    .PARAMETER Interaction
    Specifies whether the SecretStore should prompt a user when they access it. If the value is Prompt, the user is prompted for their 
    password in interactive sessions when required. If the value is None, the user is not prompted for a password. If the value is None 
    and a password is required, the cmdlet requiring the password throws a error.
    .NOTES
    Setting Authentication to 'none' is less secure than 'password'. Specifying 'none' may be useful for automated tasks where prompting
    for password is not practical. Authentication should always be set to 'password' for interactive sessions.
    If you set a password, you should set -Interaction to 'Prompt' otherwise an error will occur.
    
    Secret Store only uses the local user scope. Registering Secret Store multiple times only results in duplication of the same store,
    This module does not support vaults registered with a different module.
    Secrets will ALWAYS be stored in the default vault!
    #>
}

function Get-MerakiOrganizationDeviceAvailability() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [string]$Filter,
        [int]$Pages,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

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
    } else {
        $config = Read-Config
    } 

    $Headers = Get-Headers

    $Uri = "{0}/organizations/{1}/devices/availabilities" -f $BaseURI, $OrgId

    if ($Filter) {
        $Uri = "{0}?{1}" -f $Uri, $Filter            
    }

    $Result = [List[PsObject]]::New()

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
    <#
    .DESCRIPTION 
    List the availability information for devices in an organization. The data returned by this endpoint is updated every 5 minutes.
    .PARAMETER Filter
    A string representing a filter for the returned objects.
    Valid filter properties are 'usedState', 'search', 'macs', 'networkIds', 'serials', 'models', 'orderNumbers', 'tags', 'tagFilterType', 'productTypes'.
    All properties are arrays except 'usedState', 'search', and 'tagFilterType'.
    The search property accepts a single value that will search against serial number, mac address, or model.
    Valid tagFilterType values are 'withAllTags' or 'withAnyTags'.
    Valid productTypes values are "appliance","camera","cellularGateway","secureConnect","sensor","switch","systemsManager",or "wireless".
    .PARAMETER Pages
    NUmber of pages top return. Default is all pages.
    .PARAMETER OrgId
    Organization ID to return devices for.
    .PARAMETER ProfileName
    Saved profile name.
    .EXAMPLE
    To use the Filter property you must construct a valid filter string. A filter string is like a HTTP query string.
    To specify a filter string construct it with the property name and values. Array values must be separated by a comma.
    Property Names and values are case sensitive.

    $Filter = "productTypes[]=appliance,switch&networkIds[]=N_987548754,N_87589514"
    Get-MerakiOrganizationDeviceAvailability -Filter $Filter
    #>
}

function Get-MerakiOrganizationDeviceAvailabilityChangeHistory() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [string]$Filter,
        [int]$Pages,
        [Parameter(ParameterSetName = 'org')]
        [string]$OrgId,
        [Parameter(ParameterSetName = 'profile')]
        [string]$ProfileName
    )

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
    } else {
        $config = Read-Config
    } 

    $Headers = Get-Headers

    $Uri = "{0}/organizations/{1}/devices/availabilities/changeHistory" -f $BaseURI, $OrgId

    if ($Filter) {
        $Uri = "{0}?{1}" -f $Uri, $Filter
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
