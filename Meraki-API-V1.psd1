#
# Module manifest for module 'Meraki-API-V1'
#
# Generated by: Cliff Williams
#
# Generated on: 9/8/2020
#
# Copyright Balfour Beatty US
#

@{

# Script module or binary module file associated with this manifest.
RootModule = '.\Meraki-API-V1.psm1'

# Version number of this module.
ModuleVersion = '1.1.5'


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
Description = 'Powershell module to use with the Meraki API to manage your Meraki Organization. 
This module now supports storing API keys in a secure Secret store. 
This is a large update. Please see the project site for more details.'

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
RequiredModules = @(
    'Microsoft.PowerShell.SecretManagement',
    'Microsoft.PowerShell.SecretStore'
)

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
ScriptsToProcess = @('./public/public.ps1')

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    'Add-MerakiApplianceCellularFirewallRule',
    'Add-MerakiApplianceContentFilteringRules',
    'Add-MerakiApplianceDelegatedStaticPrefix',
    'Add-MerakiApplianceFirewallNatRule',
    'Add-MerakiApplianceInboundCellularFirewallRule',
    'Add-MerakiApplianceInboundFirewallRule',
    'Add-MerakiApplianceL3FirewallRule',
    'Add-MerakiApplianceL7FirewallRule',
    'Add-MerakiApplianceStaticRoute',
    'Add-MerakiApplianceVlan',
    'Add-MerakiNetwork',
    'Add-MerakiSwitchAccessControlEntry',
    'Add-MerakiSwitchAccessPolicy',
    'Add-MerakiSwitchLAG',
    'Add-MerakiSwitchPortSchedule',
    'Add-MerakiSwitchQosRule',
    'Add-MerakiSwitchRoutingInterface',
    'Add-MerakiSwitchRoutingStaticRoute',
    'Add-MerakiSwitchStackRoutingInterface',
    'Add-MerakiSwitchStackSwitch',
    'Connect-MerakiNetworkToTemplate',
    'Disconnect-MerakiNetworkFromTemplate',
    'Get-MerakiApplianceCellularFirewallRules',
    'Get-MerakiApplianceClientSecurityEvents',
    'Get-MerakiApplianceContentFiltering',
    'Get-MerakiApplianceContentFilteringCategories',
    'Get-MerakiApplianceDelegatesStaticPrefix',
    'Get-MerakiApplianceDelegatesStaticPrefixes',
    'Get-MerakiApplianceDhcpSubnets',
    'Get-MerakiApplianceFirewalledServices',
    'Get-MerakiApplianceFirewallNatRules',
    'Get-MerakiApplianceInboundCellularFirewallRules',
    'Get-MerakiApplianceInboundFirewallRules',
    'Get-MerakiApplianceL3FirewallRules',
    'Get-MerakiApplianceL7ApplicationCategories',
    'Get-MerakiApplianceL7FirewallRules',
    'Get-MerakiAppliancePort',
    'Get-MerakiAppliancePorts',
    'Get-MerakiApplianceSecurityIntrusion',
    'Get-MerakiApplianceSecurityMalwareSettings',
    'Get-MerakiApplianceSingleLan',
    'Get-MerakiApplianceSiteToSiteVPN',
    'Get-MerakiApplianceStaticRoutes',
    'Get-MerakiApplianceVLAN',
    'Get-MerakiApplianceVLANS',
    'Get-MerakiDevice',
    'Get-MerakiDeviceApplianceUplinks',
    'Get-MerakiDeviceClients',
    'Get-MerakiNetwork',
    'Get-MerakiNetworkClientApplicationUsage',
    'Get-MerakiNetworkClientBandwidthUsage',
    'Get-MerakiNetworkClients',
    'Get-MerakiNetworkDevices',
    'Get-MerakiNetworkEvents',
    'Get-MerakiNetworkEventTypes',
    'Get-MerakiNetworks',
    'Get-MerakiNetworkSwitchStacks',
    'Get-MerakiNetworkTraffic',
    'Get-MerakiOrganization',
    'Get-MerakiOrganizationAdmins',
    'Get-MerakiOrganizationApplianceUplinkStatuses',
    'Get-MerakiOrganizationApplianceVpnStats',
    'Get-MerakiOrganizationApplianceVpnStatuses',
    'Get-MerakiOrganizationConfigTemplate',
    'Get-MerakiOrganizationConfigTemplates',
    'Get-MerakiOrganizationConfigurationChanges',
    'Get-MerakiOrganizationDevices',
    'Get-MerakiOrganizationDeviceStatus',
    'Get-MerakiOrganizationDeviceUplinks',
    'Get-MerakiOrganizationFirmwareUpgrades',
    'Get-MerakiOrganizationFirmwareUpgradesByDevice',
    'Get-MerakiOrganizationInventoryDevices',
    'Get-MerakiOrganizations',
    'Get-MerakiOrganizationSecurityEvents',
    'Get-MerakiOrganizationThirdPartyVpnPeers',
    'Get-MerakiSSID',
    'Get-MerakiSSIDs',
    'Get-MerakiSwitchAccessControlList',
    'Get-MerakiSwitchAccessPolicies',
    'Get-MerakiSwitchAccessPolicy',
    'Get-MerakiSwitchLAG',
    'Get-MerakiSwitchPort',
    'Get-MerakiSwitchPortSchedules',
    'Get-MerakiSwitchPortsPacketCounters',
    'Get-MerakiSwitchPortsStatus',
    'Get-MerakiSwitchQosRule',
    'Get-MerakiSwitchQosRules',
    'Get-MerakiSwitchQosRulesOrder',
    'Get-MerakiSwitchRoutingInterface',
    'Get-MerakiSwitchRoutingInterfaceDHCP',
    'Get-MerakiSwitchRoutingInterfaces',
    'Get-MerakiSwitchRoutingMulticast',
    'Get-MerakiSwitchRoutingOspf',
    'Get-MerakiSwitchRoutingStaticRoute',
    'Get-MerakiSwitchStack',
    'Get-MerakiSwitchStackRoutingInterface',
    'Get-MerakiSwitchStackRoutingInterfaceDHCP',
    'Get-MerakiSwitchStackRoutingInterfaces',
    'Get-MerakiSwitchStackRoutingStaticRoute',
    'Get-MerakiWirelessAirMarshal',
    'Get-MerakiWirelessDataRateHistory',
    'Get-MerakiWirelessStatus',
    'Get-MerakiWirelessUsageHistory',
    'Get-MerakiNetworkClientConnectionStats',
    'Merge-MerakiOrganizationNetworks',
    'New-MerakiOrganization',
    'New-MerakiOrganizationThirdPartyVpnPeer',
    'New-MerakiSecretsVault'
    'New-MerakiSwitchStack',
    'Remove-MerakiApplianceCellularFirewallRule',
    'Remove-MerakiApplianceContentFilteringRules',
    'Remove-MerakiApplianceDelegatedStaticPrefix',
    'Remove-MerakiApplianceFirewallNatRule',
    'Remove-MerakiApplianceInboundCellularFirewallRule',
    'Remove-MerakiApplianceInboundFirewallRule',
    'Set-MerakiApplianceL3FirewallRules'
    'Remove-MerakiApplianceL3FirewallRule',
    'Set-MerakiApplianceL7FirewallRules'
    'Remove-MerakiApplianceL7FirewallRule',
    'Remove-MerakiApplianceVlan',
    'Remove-MerakiNetwork',
    'Remove-MerakiNetworkDevice',
    #'Remove-MerakiSwitchAccessControlEntry',
    #'Remove-MerakiSwitchAccessPolicy',
    #'Remove-MerakiSwitchLAG',
    #'Remove-MerakiSwitchPortSchedule',
    #'Remove-MerakiSwitchQosRule',
    'Remove-MerakiSwitchRoutingInterface',
    'Remove-MerakiSwitchStack',
    'Remove-MerakiSwitchStackRoutingInterface',
    'Remove-MerakiSwitchStackRoutingStaticRoute',
    'Remove-MerakiSwitchStackSwitch',
    'Remove-MerakiSwitchStaticRoute',
    'Reset-MerakiSwitchPorts',
    'Restart-MerakiDevice',
    'Set-MerakiAPI',
    'Set-MerakiApplianceCellularFirewallRule',
    'Set-MerakiApplianceCellularFirewallRules',
    'Set-MerakiApplianceDelegatedStaticPrefix',
    'Set-MerakiApplianceFirewallNatRule',
    'Set-MerakiApplianceFirewallNatRules',
    'Set-MerakiApplianceInboundCellularFirewallRule',
    'Set-MerakiApplianceInboundCellularFirewallRules',
    'Set-MerakiApplianceInboundFirewallRule',
    'Set-MerakiApplianceInboundFirewallRules',
    'Set-MerakiApplianceL3FirewallRule',
    'Set-MerakiApplianceL3FirewallRules',
    'Set-MerakiApplianceL7FirewallRule',
    'Set-MerakiApplianceL7FirewallRules',
    'Set-MerakiAppliancePort',
    #'Set-MerakiApplianceSecurityIntrusion',
    #'Set-MerakiApplianceSecurityMalwareSettings',
    'Set-MerakiApplianceSingleLan',
    'Set-MerakiApplianceSiteToSiteVpn',
    'Set-MerakiApplianceStaticRoute',
    'Set-MerakiApplianceVLAN',
    'Set-MerakiDevice',
    'Set-MerakiNetwork',
    'Set-MerakiOrganization',
    #'Set-MerakiOrganizationThirdPartyVpnPeer',
    'Set-MerakiProfile',
    #'Set-MerakiSwitchAccessControlEntry',
    #'Set-MerakiSwitchAccessPolicy',
    #'Set-MerakiSwitchLAG',
    #'Set-MerakiSwitchPort',
    #'Set-MerakiSwitchPortSchedule',
    #'Set-MerakiSwitchQosRule',
    #'Set-MerakiSwitchQosRuleOrder',
    'Set-MerakiSwitchRoutingInterface',
    'Set-MerakiSwitchRoutingInterfaceDhcp',
    #'Set-MerakiSwitchRoutingMulticast',
    #'Set-MerakiSwitchRoutingOspf',
    'Set-MerakiSwitchRoutingStaticRoute',
    'Set-MerakiSwitchStackRoutingInterface',
    'Set-MerakiSwitchStackRoutingInterfaceDhcp',
    'Set-MerakiSwitchStackRoutingStaticRoute',
    #'Split-MerakiNetwork',
    'Start-MerakiDeviceBlink',
    #'Submit-MerakiDeviceClaim',
    'Update-MerakiApplianceContentFiltering'
    'Get-MerakiDeviceLldpCdp',
    'Get-MerakiOrganizationInventoryDevice',
    'Get-MerakiOrganizationDeviceAvailabilityChangeHistory',
    'Get-MerakiOrganizationDeviceAvailability',
    'Get-MerakiApplianceSecurityEvents'

)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @(`
   'GMNetDev',
    'StartMDevBlink',
    'RestartMD',
    'GMDevClients',
    'GMNet',
    'GMNetDevs',
    'GMNetEvents',
    'GMNetET',
    'GMNetEvents',
    'GMNetClientAppUsage',
    'GMNetCltBWUsage',
    'GMOrgs',
    'GMOrg',
    'GMNets',
    'GMOrgTemplates',
    'GMOrgDevs',
    'GMOrgAdmins',
    'GMOrgCC',
    'GMOrg3pVP',
    'GMOrgInvDevices',
    'GMNetSecEvents',
    'GMOFirmwareUpgrades',
    'GMAppUpStat',
    'Get-MerakiApplianceUplinkStatuses',
    'GMAVpnStats',
    'GMOAVpnStats',
    'Get-MerakiNetworkApplianceVpnStats',
    'GMNetAppCFCats',
    'GMNetCF',
    'UMNetAppCF',
    'AddMNetAppCFR',
    'RemoveMNetAppCfr',
    'GMAppPorts',
    'GMNetAppRoutes',
    'GMNetAppVLANs',
    'GMNetAppVLAN',
    'SetMNAppVLAN',
    'GMNetAppSSVpn',
    'GMNetAppDhcpSubnet',
    'GMNetSWStRoutInts',
    'GMSWStackRoutInt',
    'AddMSSRteInt',
    'RemoveMSStackRouteInt',
    'SetMSStkRteInt',
    'GMSwStRoutStatic',
    'SetMNSSRteStRoute',
    'RSWStkRteInt',
    'GMSwStRoutIntDHCP',
    'Get-MerakiSwitchStackRoutingInterfacesDHCP',
    'UMSStkRteIntDhcp',
    'GMSWRoutInts',
    'GMSWRoutInt',
    'AddMSRouteInt',
    'SetMSRteInt',
    'GMSWRoutIntDHCP',
    'SetMSRteIntDHCP',
    'GMSWRoutStatic',
    'GMNetSWLag',
    'GMNetSWStacks',
    'Get-MerakiNetworkSwitchStack',
    'GMSwStack',
    'New-MerakiSwitchStack',
    'AMSSSwitch',
    'GMSwPorts',
    'GMSwPort',
    'GMDevSwPort',
    'Get-MerakiDeviceSwitchPort',
    'RMSWPorts',
    'GMSWPortStatus',
    'GMSWPortsPacketCntrs',
    'GMSWACL',
    'AMSWAce',
    'RMSWAce',
    'GMSSIDs',
    'GMSSID',
    'GMWirelessStat',
    'Get-MerakiNetworkSwitchStacks',
    'Get-MerakiNetworkApplianceVLANS',
    'Get-MerakiNetworkApplianceStaticRoutes',
    'Get-MerakiSwitchStackRoutingInterfaces',
    'Get-MerakiSwitchStackRoutingStaticRoutes',
    'Get-MerakiSwitchRoutingInterfaces',
    'Get-MerakiNetworkSwitchLAG',
    'Get-MerakiSwitchPorts'
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
        Tags = @('Meraki')

        # A URL to the license for this module.
        LicenseUri = 'https://opensource.org/license/ms-pl-html/'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/Clifra-Jones/Meraki-API-V1'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = './docs/releaseNotes.md'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        ExternalModuleDependencies = @(
            'Microsoft.PowerShell.SecretManagement',
            'Microsoft.PowerShell.SecretStore'
        )

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://clifra-jones.github.io/Meraki-API-V1/docs/reference.html'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

