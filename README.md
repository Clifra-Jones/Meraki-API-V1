# Meraki-API-V1

This module allows you to interact and manage your Meraki network using Powershell.
This module uses the Version 1 REST API.

!!!Note
    The majority of the function in this module are read (Get-) functions.
    I have not had the opportunity to test these as our Meraki Organization is in production.

    The code for most of the writable function is in the source code. They are disabled in the Module Manifest. You can test them by uncommenting the function name int he module Manifest. I hold no responsibility is you damage you Meraki Organization. You are warned!

[Module Reference](https://clifra-jones.github.io/Meraki-API-V1/docs/reference.html)

[Release notes](https://clifra-jones.github.io/Meraki-API-V1/docs/releaseNotes.md)

## INSTALLATION

```powershell
Install-Module Meraki-API-V1
```

## USAGE

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

See the module reference for additional information on functions, syntax, and examples.
