## Release Notes

### 11/14/2023

Updated calls to API endpoints that support paging. These function now use the Invoke-WebRequest cmdlet to pull data.
Paging is implemented to pull more data. See the module reference for these function for usage.

Fixed multiple spelling errors in the Module reference.

Added support for Level 3 Firewall Rules.

### 03/16/2023

Added the following functions
Set-MerakiNetworkApplianceSiteToSiteVpn

Added the following parameters to function Get-MerakiNetworks:

- PARAMETER IncludeTemplates
    Includes a configTemplate property containing the configuration template.
- PARAMETER ConfigTemplateId
    Get all networks bound to this template Id.
- PARAMETER IsBoundToConfigTemplate
    Get only networks bound to config templates.

### 11/10/2022

### Added the following functions

Get-MerakiNetworkClients
Get-MerakiDeviceClients
Get-MerakiNetworkApplianceDhcpSubnets
Get-MerakiOrganizationSecurityEvents
Get-MerakiNetworkClientApplicationUsage
Get-MerakiNetworkClientBandwidthUsage
Get-MerakiOrganizationSecurityEvents
Get-MerakiSwitchPortsStatus

See the Command Reference for more details.

### Replaced parameter set names with validation scripts

The error messages displayed when supplied parameters set violate parameter set names are very ambiguous.
They do not provide specific information to help understand what was wrong with the supplied parameters.
Also, for complex required parameter combinations, parameter set names become too cumbersome to create ans work properly.

Validation script are more concise and allow more meaningful error messages.

### Renamed parameters

On some functions, certain parameters were renamed.
StartTime, EndTime was renamed to StartDate, EndDate. This was done to reflect that the parameter is a Date Time parameter not just a time parameter.
TimeSpan was renamed to Days. As the value entered for this parameter is specified in Days ths makes more sense.

Aliases were created for these parameters so that the old names will still work.

### 07/28/2022

### Added support for named profiles

If you support multiple organizations you now interact with these organizations using named profiles.
Updated the Set-MerakiAPI function to support creating named profiles.
Added function Set-MerakiProfile, this function will set the default profile to the specified named profile.
All functions that utilize the Organization ID have an additional parameter named 'profileName' that will run the function
against the organization assigned to that profile.

If you have an existing configuration file importing the updated module will convert your configuration file to the new format that supports named profiles.

See Wiki for details.

### Added 2 new functions to the Content Filtering Functionality

Add-MerakiNetworkApplianceContentFilteringRules
Remove-MerakiNetworkApplianceContentFilteringRules

Both functions take the same parameters.
id: The network id of a meraki MX appliance
allowedURLPatterns: An array of allowed URLs to add/remove.
blockedURLPatterns: An array of blocked URLs to add/remove.
