## 07/28/2022

## Added support for named profiles

If you support multiple organizations you now interact with these organizations using named profiles.
Updated the Set-MerakiAPI function to support creating named profiles.
Added function Set-MerakiProfile, this function will set the default profile to the specified named profile.
All functions that utilize the Organization ID have an additional parameter named 'profileName' that will run the function
against the organization assigned to that profile.

If you have an existing configuration file importing the updated module will convert your configuration file to the new format that supports named profiles.

See Wiki for details.

## Added 2 new functions to the Content Filtering Functionality

Add-MerakiNetworkApplianceContentFilteringRules
Remove-MerakiNetworkApplianceContentFilteringRules

Both functions take the same parameters.
id: The network id of a meraki MX appliance
allowedURLPatterns: An array of allowed URLs to add/remove.
blockedURLPatterns: An arracy of blocked URLs to add/remove.
