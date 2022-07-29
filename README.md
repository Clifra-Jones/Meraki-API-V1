
# Meraki-API-V1

## This is the most recent module. You should use this module as opposed to the V0 module.
## The V0 module will still work but lacks many features found here.

## 07/28/2022
## Added support for named profiles
If you support multiple organizations you now interact with these organizations using named profiles.
Updated the Set-MerakiAPI function to support creating named profiles.
Added function Set-MerakiProfile, this function will set the default profile to the specified named profile.
All functions that utilize the Organization ID have an additional parameter named 'profileName' that will run the function
against the organization assigned to that profile.
See Wiki for details.


## Added 2 new functions to the Content Filtering Functionality.
Add-MerakiNetworkApplianceContentFilteringRules
Remove-MerakiNetworkApplianceContentFilteringRules

Both functions take the same parameters.
id: The network id of a meraki MX appliance
allowedURLPatterns: An array of allowed URLs to add/remove.
blockedURLPatterns: An arracy of blocked URLs to add/remove.


## INSTALLATION

**NOTE**: This module will eventually be published to the Powershell Gallery once significant testing has been done.

## Windows

**NOTE** This module has only been tested with PowerShell Core 6.0 and higher. Functionality with Windows PowerShell cannot be assured.

## Powershell Core 6 or 7

User Scope Install (preferred)

### Command Prompt

>cd %UserProfile%\Documents\PowerShell\Modules

>git clone https://github.com/Clifra-Jones/Meraki-API-V1.git

### Powershell

>cd $env:USERPROFILE\Documents\PowerShell\Modules

>git clone https://github.com/Clifra-Jones/Meraki-API-V1.git

## System Scope Install

### Command Prompt

Open an elevated command prompt

>cd %PROGRAMFILES%\PowerShell\7\modules

>git clone https://github.com/Clifra-Jones/Meraki-API.git

# Linux/Mac

### User Scope Install

>cd ~/.local/share/powershell/Modules

>git clone https://github.com/Clifra-Jones/Meraki-API-V1.git

### System Scope Install

>cd /usr/local/share/powershell/Modules

>sudo git clone https://github.com/Clifra-Jones/Meraki-API-V1.git

## ZIP FILE INSTALLATION

Same as above, just make a directory called Meraki-API-V1 in one of the above folders and unzip the file into that directory.

# USAGE

API Access must be enabled on your Meraki Dashboard.

You will need to have a Meraki API key. You can get your key by logging into your Meraki Dashboard, go to your profile and generate your API key.
Save this key in a safe place.

Once you have your API key you need to obtain the Organization ID for the Organizations you have access to. You can do this with the GetMerakiOrganizations function.

Open Powershell
>Import-Module Meraki-API

>Get-MerakiOrganizations -APIKey '{key string}'

Configure your user profile to use the API.

You must configure your profile to use the API module. To do this use the Set-MerakiAPI function.

>Set-MerakiAPI -APIKey '{key string}' -OrgID 'XXXXXX'

This will create the file .meraki/config.json in your user profile. 

## See Wiki for documentation.

