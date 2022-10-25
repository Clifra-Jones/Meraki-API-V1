
![Balfour Logo](https://www.balfourbeattyus.com/Balfour-dev.allata.com/media/content-media/2017-Balfour-Beatty-Logo-Blue.svg?ext=.svg)

# Meraki-API-V1

This module allows you to interact and manage your Meraki network using Powershell.
This module uses the Version 1 REST API.

**This is the most recent module. You should use this module as opposed to the V0 module**

**The V0 module will still work but lacks many features found here**

[**Module Referrence**](https://clifra-jones.github.io/Meraki-API-V1/docs/referrence.html)

[**Release notes**](https://clifra-jones.github.io/Meraki-API-V1/docs/releaseNotes.md)

## INSTALLATION

**NOTE**: This module will eventually be published to the Powershell Gallery once significant testing has been done.

## Windows

**NOTE** This module has only been tested with PowerShell Core 6.0 and higher. Functionality with Windows PowerShell cannot be assured.

## Powershell Core 6 or 7

User Scope Install (preferred)

**Command Prompt**

```bash
cd %UserProfile%\Documents\PowerShell\Modules
```

**Powershell**

```powershell
cd $env:USERPROFILE\Documents\PowerShell\Modules
```

Clone the repository

```bash
git clone https://github.com/Clifra-Jones/Meraki-API-V1.git
```

## System Scope Install

***Command Prompt***

Open an elevated command prompt

```bash
cd %PROGRAMFILES%\PowerShell\7\modules
```

**Powershell**

```powershell
cd $env:PROGRAMFILES\Documents\PowerShell\Modules
```

```bash
git clone https://github.com/Clifra-Jones/Meraki-API-V1.git
```

# Linux/Mac

User Scope Install (preferred)

```bash
cd ~/.local/share/powershell/Modules
```

System Scope Install

```bash
cd /usr/local/share/powershell/Modules
```

clone the repository

```bash
sudo git clone https://github.com/Clifra-Jones/Meraki-API-V1.git
```

## ZIP FILE INSTALLATION

Same as above, just make a directory called Meraki-API-V1 in one of the above folders and unzip the file into that directory.

# USAGE

API Access must be enabled on your Meraki Dashboard.

You will need to have a Meraki API key. You can get your key by logging into your Meraki Dashboard, go to your profile and generate your API key.
Save this key in a safe place.

Once you have your API key you need to obtain the Organization ID for the Organizations you have access to. You can do this with the Get-MerakiOrganizations function.

Open Powershell
```powershell
Import-Module Meraki-API
Get-MerakiOrganizations -APIKey '{key string}'
```

Configure your user profile to use the API.

You must configure your profile to use the API module. To do this use the Set-MerakiAPI function.

```powershell
Set-MerakiAPI -APIKey '{key string}' -OrgID 'XXXXXX'
```

```powershell
Set-MerakiAPI -APIKey '{key string}' -OrgId 'XXXXXX' -ProfileName 'ProfileName'
```

This will create the file .meraki/config.json in your user profile.

See the command reference for additional information on functions, syntax, and examples.
