# Meraki Organization functions

<#
.Description
Creates a file in the user profile folder un the .meraki folder named config.json.
This file contains the users Meraki API Key and the default Organization ID
#>
function Set-MerakiAPI() {
    [CmdletBinding(DefaultParameterSetName="default")]
    Param(
        [string]$APIKey,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "profile"
        )]
        [Parameter(
            ParameterSetName = "default'"
        )]
        [string]$OrgID,
        [Parameter(
            ParameterSetName = "profile",
            Mandatory = $true
        )]
        [string]$profileName
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
    The best approach is to create the default profile with:
    PS> Set-MerakiAPI -APIKey 'GTR15Y124...' -OrgId 123456
    to create the defaul profile then create named profiles for your other organizations with:
    PS> Set-MerakiAPI -OrgID 456123 -profileName "otherOrg"
    You should set a named profile for your default just so you can easily switch between them.
    .EXAMPLE
    Create the default profile
    PS> Set-MerakiAPI -APIKey 'GDTE63534HD74BD93847' -OrgId 123456
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
    .PARAMETER profileName
    The Name of the profile to use.
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
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'orgid'
        )]
        [string]$OrgId,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "profileName"
        )]
        [string]$profileName
    )

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
    #>
}

Set-Alias -Name GMOrg -value Get-MerakiOrganization -Option ReadOnly


function Get-MerakiNetworks() {
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [Parameter(ParameterSetName = 'orgid')]
        [string]$OrdID,
        [Parameter(ParameterSetName = 'profilename')]
        [string]$profileName
    )
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

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
    <#
    .SYNOPSIS
    Get all Meraki Networks.
    .DESCRIPTION
    Get all Meraki networks in an organization.
    .PARAMETER OrdID
    The Organization ID.
    .PARAMETER profileName
    The profile name to use to get networks.
    #>
}

Set-Alias -Name GMNets -Value Get-MerakiNetworks -Option ReadOnly

function Get-MerakiOrganizationConfigTemplates() {
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [Parameter(ParameterSetName = 'orgid')]
        [String]$OrgID,
        [Parameter(ParameterSetName = 'profilename')]
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
    The Organization Id.
    .PARAMETER profileName
    The profile name to use to get the templates.
    #>
}

Set-Alias -Name GMOrgTemplates -value Get-MerakiOrganizationConfigTemplates -Option ReadOnly


function Get-MerakiOrganizationDevices() {
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [Parameter(ParameterSetName = 'orgId')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profilename')]
        [string]$profileName
    )

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
    The Organization Id.
    .PARAMETER profileName
    Profile name to use to get the devices.
    #>
}

Set-Alias GMOrgDevs -Value Get-MerakiOrganizationDevices -Option ReadOnly

function Get-MerakiOrganizationAdmins() {
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [Parameter(ParameterSetName = 'orgid')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profilename')]
        [string]$profileName
    )

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
    The Organization ID.
    .PARAMETER profileName
    The profile name to get admins with.
    #>
}

Set-Alias -name GMOrgAdmins -Value Get-MerakiOrganizationAdmins -Option ReadOnly


function Get-MerakiOrganizationConfigurationChanges() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(                
        [Parameter(ParameterSetName = 'orgid')]
        [Parameter(ParameterSetName = 'orgid2')]
        [string]$OrgID,        
        [Parameter(ParameterSetName = 'profilename')]
        [Parameter(ParameterSetName = 'profilename2')]
        [string]$profileName,
        [Parameter(ParameterSetName = 'orgid')]
        [Parameter(ParameterSetName = 'profilename')]
        [Parameter(ParameterSetName = 'StartEnd')]
        [ValidateScript({$_ -is [DateTime]})]
        [datetime]$StartTime,
        [Parameter(ParameterSetName = 'orgid')]
        [Parameter(ParameterSetName = 'profilename')]
        [Parameter(ParameterSetName = 'StartEnd')]
        [ValidateScript({$_ -is [DateTime]})]
        [DateTime]$EndTime,        
        [Parameter(ParameterSetName = 'orgid2')]
        [Parameter(ParameterSetName = 'profilename2')]
        [Parameter(ParameterSetName = 'TimeSpan')]
        [ValidateScript({$_ -is [int32]})]
        [Int]$TimeSpan,
        [ValidateScript({$_ -is [int]})]
        [int]$PerPage,
        [string]$NetworkID,
        [string]$AdminID
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
    The OPrganization Id.
    .PARAMETER profileName
    The profile name to use to get the changes.
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
    #>
    
}

Set-Alias -name GMOrgCC -Value Get-MerakiOrganizationConfigurationChanges -Option ReadOnly


function Get-MerakiOrganizationThirdPartyVPNPeers() {
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [Parameter(ParameterSetName = 'orgid')]
        [STRING]$OrgID,
        [Parameter(ParameterSetName = 'profileName')]
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

    $Uri = "{0}/organizations/{1}/appliance/vpn/thirdPartyVPNPeers" -f $BaseURI, $OrgID
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
    <#
    .SYNOPSIS
    Get Organization 3rd paty VPNs.
    .PARAMETER OrgID
    Organization ID.
    .PARAMETER profileName
    Profile Name to use.
    #>
}

Set-Alias -Name GMOrg3pVP -Value Get-MerakiOrganizationThirdPartyVPNPeers -Option ReadOnly


function Get-MerakiOrganizationInventoryDevices() {
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [Parameter(ParameterSetName = 'orgid')]
        [string]$OrgID,
        [Parameter(ParameterSetName = 'profilename')]
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

    $Uri = "{0}/organizations/{1}/inventoryDevices" -f $BaseURI, $OrgID
    $Headers = Get-Headers

    $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

    return $response
    <#
    .SYNOPSIS
    Get the organization device inventory 
    .PARAMETER OrgID
    Organization ID.
    .PARAMETER profileName
    Profile name to use.
    #>
}

Set-Alias -Name GMOrgInvDevices -value Get-MerakiOrganizationInventoryDevices -Option ReadOnly