#
# Module manifest for module 'Meraki-API-V1'
#
# Generated by: Cliff Williams
#
# Generated on: 9/8/2020
#

@{

# Script module or binary module file associated with this manifest.
RootModule = '.\Meraki-API-V1.psm1'

# Version number of this module.
ModuleVersion = '0.0.3'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '794ac708-5ac6-4ce3-8bcf-f1d79978e66a'

# Author of this module
Author = 'Cliff Williams'

# Company or vendor of this module
CompanyName = 'Balfour Beatty US'

# Copyright statement for this module
Copyright = '(c) Balfour Beatty US All rights reserved.'

# Description of the functionality provided by this module
# Description = ''

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '6.0'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
ScriptsToProcess = @('./public/public.ps1')

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @(`
    './public/Organizations.psm1', `
    './public/Networks.psm1', `
    './public/Devices.psm1', `
    './public/Products/Appliances.psm1', `
    './public/Products/Switches.psm1', `
    './public/Products/Wireless.psm1'
)

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(`
    'Get-MerakiOrganizations', 
    'Get-MerakiOrganization', 
    'Get-MerakiNetworks', 
    'Get-MerakiOrganizationConfigTemplates', 
    'Get-MerakiOrganizationDevices', 
    'Get-MerakiOrganizationAdmins', 
    'Get-MerakiOrganizationConfigurationChanges',
    'Get-MerakiOrganizationThirdPartyVPNPeers',
    'Get-MerakiNetwork', 
    'Get-MerakiNetworkDevices', 
    'Get-MerakiNetworkEvents', 
    'Get-MerakiNetworkEventTypes', 
    'Get-MerakiNetworkApplianceContentFilteringCategories', 
    'Update-MerakiNetworkApplianceContentFiltering', 
    'Get-MerakiAppliancePorts', 
    'Get-MerakiNetworkApplianceStaticRoutes', 
    'Get-MerakiNetworkApplianceVLANS', 
    'Get-MerakiNetworkApplianceVLAN', 
    'Get-MerakiNetworkApplianceSiteToSiteVPN', 
    'Get-MerakiApplianceUplinkStatuses', 
    'Get-MerakiDevice', 
    'Start-MerakiDeviceBlink', 
    'Restart-MerakiDevice', 
    'Get-MerakiNetworkApplianceContentFilteringCategories', 
    'Get-MerakiNetworkApplianceContentFiltering', 
    'Update-MerakiNetworkApplianceContentFiltering', 
    'Get-MerakiAppliancePorts', 
    'Get-MerakiNetworkApplianceStaticRoutes', 
    'Get-MerakiNetworkApplianceVLANS', 
    'Get-MerakiNetworkApplianceVLAN', 
    'Get-MerakiNetworkApplianceSiteToSiteVPN', 
    'Get-MerakiApplianceUplinkStatuses', 
    'Get-MerakiSwitchRoutingInterfaces',
    'Get-MerakiSwitchRoutingInterface', 
    'Get-MerakiSwitchRoutingInterfaceDHCP', 
    'Get-MerakiSwitchRoutingStaticRoutes', 
    'Get-MerakiNetworkSwitchLAG', 
    'Get-MerakiNetworkSwitchStacks', 
    'Get-MerakiSwitchPorts', 
    'Reset-MerakiSwitchPorts', 
    'Set-MerakiAPI', 
    'Get-MerakiSSIDs', 
    'Get-MerakiSSID', 
    'Get-MerakiWirelessStatus', 
    'Get-MerakiSwitchStackRoutingInterface', 
    'Get-MerakiSwitchStackRoutingInterfaces', 
    'Get-MerakiSwitchStackRoutingInterfaceDHCP', 
    'Get-MerakiSwitchStackRoutingInterfacesDHCP', 
    'Get-MerakiSwitchStackRoutingInterfacesDHCP',
    'Get-MerakiNetworkSwitchStack', 
    'Get-MerakiSwitchStackRoutingStaticRoutes', 
    'Get-MerakiDeviceSwitchPort',
    'Get-MerakiNetworkApplianceVpnStats',
    'Get-MerakiOrganizationInventoryDevices',
    'Add-MerakiNetworkApplianceContentFilteringRules',
    'Remove-MerakiNetworkApplianceContentFilteringRules',
    'Set-MerakiProfile'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @(`
    'StartMDevBlink','GMDev','GMOrgs','GMOrg','GMNets','GMOrgTemplates','GMOrgDevs','GMOrgAdmins', `
    'GMOrgCC','GMOrg3pVP','GMOrgInv','GMNet','GMNetDevs','GMNetEvents','GMNetET','GMNetAppCFCats', 'GMOrgInvDevices', `
    'GMNetCF','UMNetAppCF','GMAppPorts', 'GMNetAppRoutes', 'GMNetAppVLANs','GMNetAppVLAN', 'GMSwStackRoutInt', 'GMDevSwPort', `
    'GMNetAppSSVpn','GMAppUpStat', 'GMSWRoutInts','GMSWRoutInt','GMSWRoutIntDHCP','GMSWRoutStatic','GMSwStRoutIntsDHCP','GMSwStRoutIntDHCP', 'RemoveMNetAppCfr',
    'GMNetSWLag','GMNetSWStacks','GMDevSwPorts','RMSWPorts','GMSSIDs','GMSSID','GMWirelessStat','GMNetSWStRoutInts','GMSwStack','GMSwStRoutStatic','GMAVpnStats', 'AddMNetAppCFR'
)

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

