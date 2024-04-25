using namespace System.Collections.Generic
# Wireless Functions

#region SSIDs

function Get-MerakiSSID() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('NetworkId')]
        [string]$Id,
        [Int]$Number
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "[0]/networks/{1}/wireless/ssids" -f $BaseURI, $networkId

        if ($Number) {
            $Uri = "{0}/{1}" -f $Uri, $Number
        }

        try {
            $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name 'NetworkId' -Value NetworkId
            }

            return $response
        } catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS 
    Returns a Meraki SSID for a network.
    .PARAMETER networkId
    The network ID.
    .PARAMETER number
    The SSID Number.
    .OUTPUTS
    A Meraki SSID Object.
    #>
}

Set-Alias -Name Get-MerakiSSIDs -Value Get-MerakiSSID -Option ReadOnly
Set-Alias -Name GMSSIDs -Value Get-MerakiSSID -Option ReadOnly
Set-Alias -Name GMSSID -Value Get-MerakiSSID -Option ReadOnly

function Set-MerakiSSID() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [int]$Number,
        [string]$Name,

        [ValidateSet('open', 'open-enhanced', 'psk', 'open-with-radius', 'open-with-nac', '8021x-meraki', '8021x-nac', '8021x-radius', '8021x-google', '8021x-localradius', 'ipsk-with-radius', 'ipsk-without-radius', 'ipsk-with-nac')]
        [string]$AuthMode,

        [ValidateSet('wep', 'wpa')]
        [ValidateScript({
            $_ -and $AuthMode -eq 'psk'
        })]
        [string]$EncryptionMode,

        [ValidateSet('WPA1 only', 'WPA1 and WPA2', 'WPA2 only', 'WPA3 Transition Mode', 'WPA3 only', 'WPA3 192-bit Security')]
        [ValidateScript({
            $_ -and $EncryptionMode -eq 'wpa'
        },ErrorMessage = "Parameter WpaEncryptionMode is on valid when Parameter EncryptionMode is set to 'wpa'")]
        [string]$WpaEncryptionMode,

        [ValidateSet('NAT mode', 'Bridge mode', 'Layer 3 roaming', 'Ethernet over GRE', 'Layer 3 roaming with a concentrator', 'VPN')]
        [string]$IpAssignmentMode,

        [ValidateSet({
            $_ -and $IpAssignmentMode -eq 'Bridge mode'
        })]
        [switch]$LanIsolationEnabled,
        
        [ValidateScript({
            $_ -and $AuthMode -eq 'psk'
        }, ErrorMessage = "Parameter PassKey is only valid when Parameter AuthMode is set to 'psk'")]
        
        [string]$PassKey,
        
        [ValidateSet({
            $_ -and ($IpAssignmentMode -in 'Layer 3 roaming with a concentrator','VPN')
        }, ErrorMessage = "Parameter VlanId is only valid when parameter IpAssignmentMode is set to 'Layer 3 roaming with a concentrator' or 'VPN'")]
        [int]$VLanId,
        
        [ValidateScript({
            $_ -and ($IpAssignmentMode -in 'Bridge mode','Layer 3 roaming')
        }, ErrorMessage = "Parameter DefaultVlanId is only valid when parameter IpAssignmentMode is set to'Bridge mode' or 'Layer 3 roaming'")]
        [int]$DefaultVlanId,

        [switch]$Dot11wEnabled,
        [ValidateScript({
            $_ -and $Dot11wEnabled.IsPresent
        }, ErrorMessage = "Parameter Dot11wRequired is only valid if parameter Dot11wEnabled is present")]
        [switch]$Dot11wRequired,

        [switch]$Dot11rEnabled,
        [switch]$Dot11rRequired,

        [ValidateSet('None', 'Click-through splash page', 'Billing', 'Password-protected with Meraki RADIUS', 'Password-protected with custom RADIUS', 'Password-protected with Active Directory', 'Password-protected with LDAP', 'SMS authentication', 'Systems Manager Sentry', 'Facebook Wi-Fi', 'Google OAuth', 'Sponsored guest', 'Cisco ISE', 'Google Apps domain')]        
        [string]$SplashPage,
        [string[]]$SplashGuestSponsorDomains,

        [switch]$WalledGardenEnabled,
        [string[]]$WalledGardenRanges,

        [int]$PerClientBandwidthLimitDown,
        [int]$PerClientBandwidthLimitUp,
        [int]$PerSsidBandwidthLimitDown,
        [int]$PerSsidBandwidthLimitUp,

        [int]$RadiusAccountInterimInterval,

        [ValidateScript({
            $_ -and ( ($AuthMode -eq 'open-with-radius') -and $LanIsolationEnabled )
        }, ErrorMessage = "Parameter RadiusGuestVLANId only valie when parameter AuthMode - set to 'open-with-radius' and parameter LanIsolationEnabled is provided.")]
        [int]$RadiusGuestVlanId,

        [ValidateRange(1,5)]
        [int]$RadiusServerAttemptsLimit,

        [ValidateRange(1,10)]
        [int]$RadiusServerTimeout,

        [ValidateSet('Dual band operation', '5 GHz band only', 'Dual band operation with Band Steering')]
        [string]$BandSelection,

        [ValidateScript({
            $_ -and ($IpAssignmentMode -in 'Layer 3 roaming with a concentrator','VPN')
        }, ErrorMessage = "Parameter ConcentratorNetworkId in only valid when parameter IpAssignmentMode is set to 'Layer 3 roaming with a concentrator' or 'VPN'.")]
        [string]$ConcentratorNetworkId,

        [ValidateSet('access disabled', 'access enabled')]
        [string]$EnterpriseAdminAccess,

        [ValidateSet('Filter-Id', 'Reply-Message', 'Airespace-ACL-Name', 'Aruba-User-Role')]
        [string]$RadiusAttributeForGroupPolicies,

        [string]$RadiusAuthenticationNasId,
        [string]$RadiusCalledStationId,

        [ValidateSet('Deny access', 'Allow access')]
        [string]$RadiusFailoverPolicy,

        [switch]$RadiusFallBackEnabled,

        [ValidateSet('Strict priority order', 'Round robin')]
        [string]$RadiusLoadBalancingPolicy,

        [ValidateScript({
            $_ -and $IpAssignmentMode -eq 'vpn'
        }, ErrorMessage="Parameter SecondaryConcentratorNetworkId is only valid when the parameter IpAssignmentMode is set to 'vpn'")]
        [string]$SecondaryConcentratorNetworkId,

        [switch]$AdultContentFilteringEnabled,
        [switch]$AvailableOnAllAPs,

        [ValidateScript({
            $_ -and $IpAssignmentMode -eq 'vpn'
        }, ErrorMessage = "Parameter DisassociateClientOnVpnFailover is only valid when parameter IpAssignmentMode is set to 'vpn'")]
        [switch]$DisassociateClientOnVpnFailover,

        [switch]$Disabled,
        
        [switch]$MandatoryDHCPEnabled,
        [switch]$RadiusAccountingEnabled,
        [switch]$RadiusCoaEnabled,
        [ValidateScript({
            $_ -and ($AuthMode -eq 'open' -and $IpAssignmentMode -ne 'NAT mode')
        }, ErrorMessage = "Parameter RadiusGuestVlanEnabled is only valid when AUthMode is set to 'open' and IpAssignmentMode is not set to 'NAT Mode'")]
        [switch]$RadiusGuestVlanEnabled,
        [ValidateScript({
            $_ -and $IpAssignmentMode -ne 'NAT mode'
        }, ErrorMessage = "Parameter RadiusOverride is only valid when parameter IpAssignmentMode is set to 'NAT mode")]
        [switch]$RadiusOverride,
        [switch]$RadiusProxyEnabled,
        [switch]$RadiusTestingEnabled,

        [switch]$UseVlanTagging,

        [switch]$Hidden,

        [ValidateSet(1,2,5.5,6,9,11,12,18,24,36,48,54)]
        [number]$MinBitRate,

        [string[]]$AvailableTags,

        [ValidateScript({
            $_ -and $SplashPage -eq 'Password-protected with Active Directory'
        }, ErrorMessage = "Parameter ActiveDirectory is only valid when parameter SplashPage is set to 'Password-protected with Active Directory'")]
        [PsObject]$ActiveDirectory,

        [PsObject]$DnsRewrite,

        [PsObject]$Gre,

        [ValidateScript({
            $_ -and $SplashPage -eq 'Password-protected with LDAP'
        }, ErrorMessage = "Parameter LDAP is only valid when parameter SplashPage is set to 'Password-protected with LDAP'")]
        [PsObject]$LDAP,

        [ValidateScript({
            $_ -and $AuthMode -eq '8021x-localradius'
        }, ErrorMessage = "Parameter LocalRadius is only valid when parameter AUthMode is set to '8021x-localradius'")]
        [PsObject]$LocalRadius,

        [PsObject]$NamedVlans,

        [ValidateScript({
            $_ -and $SplashPage -eq 'Google OAuth'
        }, ErrorMessage = "Parameter OAuth is only valid when parameter SplashPage is set to 'Google OAuth")]
        [PsObject]$OAuth,

        [switch]$SpeedBurstEnabled,

        [ValidateScript({
            $_ -and $IpAssignmentMode -in 'Bridged mode','Layer 3 roaming'
        }, ErrorMessage = "Parameter ApTagsAndVlanIds is only valid when parameter IpAssignmentMode is set to 'Bridged mode' or 'Later 3 roaming'")]
        [PsObject]$ApTagsAndVlanIds,

        [ValidateScript({
            $_ -and ($AuthMode -in 'open-with-radius', '8021x-radius', 'ipsk-with-radius' -and $RadiusAccountingEnabled.IsPresent)
        }, ErrorMessage = "Parameter RadiusAccountingServers is only valid when parameter AuthMode is set to 'open-with-radius', '8021x-radius' or 'ipsk-with-radius' and parameter RadiusAccountingEnabled is provided")]
        [PsObject]$RadiusAccountingServers,

        [ValidateScript({
            $_ -and $AuthMode -in 'open-with-radius', '8021x-radius', 'ipsk-with-radius'
        }, ErrorMessage = "Parameter RadiusServers is only valid when parameter AuthMode is set to 'open-with-radius', '8021x-radius' or 'ipsk-with-radius'")]
        [PsObject]$RadiusServers
    )

    Begin {
        $Headers = Get-Headers

        $_Body = @{}

        if ($Name) {
            $_Body.Add("Name", $Name)
        }
        if ($AuthMode) {
            $_Body.Add("authMode", $AuthMode)
        }
        if ($EncryptionMode) {
            $_Body.Add("encryptionMode", $EncryptionMode)
        }
        if ($WpaEncryptionMode) {
            $_Body.Add("wpaEncryptionMode", $WpaEncryptionMode)
        }
        if ($IpAssignmentMode) {
            $_Body.Add("ipAssignmentMode", $IpAssignmentMode)
        }
        if($LanIsolationEnabled) {
            $_Body.Add("lanIsolationEnabled",$true)
        }
        if($PassKey) {
            $_Body.Add("psk",$PassKey)
        }
        if ($VlanId) {
            $_Body.Add("vlanId", $VLanId)
        }
        if ($DefaultVlanId) {
            $_Body.Add("defaultVlanId", $DefaultVlanId)
        }
        if ($Dot11wEnabled.IsPresent) {
            $_Body["dot11w"].enabled = $true
            if ($Dot11wRequired.IsPresent) {
                $_Body["dot11w"].required = $true
            }
        }
        if ($Dot11rEnabled.IsPresent) {
            $_Body["dot11r"].enabled = $true
            if ($dot11r.IsPresent) {
                $_Body["dot11r"].required = $true
            }
        }
        if ($SplashPage) {
            $_Body.Add("SplashPage",$SplashPage)
        }
        if ($SplashGuestSponsorDomains) {
            $_Body.Add("splashGuestSponsorsDomains", $SplashGuestSponsorDomains)
        }
        if($WalledGardenEnabled.IsPresent) {
            $_Body.Add("walledGardenEnabled", $true)
        }
        if ($WalledGardenRanges) {
            $_Body.Add("walledGardenRanges", $WalledGardenRanges)
        }
        if ($PerClientBandwidthLimitDown) {
            $_Body.Add("perClientBandwidthLimitDown", $PerClientBandwidthLimitDown)
        }
        if ($PerClientBandwidthLimitUp)  {
            $_Body.Add("perClientBandwidthLimitUp", $PerClientBandwidthLimitUp)
        }
        if ($PerSsidBandwidthLimitDown) {
            $_Body.Add("perSsidBandwidthLimitDown", $PerSsidBandwidthLimitDown)
        }
        if ($PerSsidBandwidthLimitUp) {
            $_Body.Add("perSsidBandwidthLimitUp", $PerSsidBandwidthLimitUp)
        }
        if ($RadiusAccountInterimInterval) {
            $_Body.Add("radiusAccountInterimInterval", $RadiusAccountInterimInterval)
        }
        if ($RadiusGuestVlanId) {
            $_Body.Add("radiusGuestVlanId", $RadiusGuestVlanId)
        }
        if ($RadiusServerAttemptsLimit) {
            $_Body.Add("radiusServerAttemptsLimit", $RadiusServerAttemptsLimit)
        }
        if ($RadiusServerTimeout) {
            $_Body.Add("radiusServerTimeout", $RadiusServerTimeout)
        }
        if ($BandSelection) {
            $_Body.Add("bandSelection", $BandSelection)
        }
        if ($ConcentratorNetworkId) {
            $_Body.Add("concentratorNetworkId", $ConcentratorNetworkId)
        }
        if ($EnterpriseAdminAccess) {
            $_Body.Add("enterpriseAdminAccess", $EnterpriseAdminAccess)
        }
        if ($RadiusAttributeForGroupPolicies) {
            $_Body.Add("radiusAttributeForGroupPolicies", $RadiusAttributeForGroupPolicies)
        }
        if ($RadiusAuthenticationNasId) {
            $_Body.Add("radiusAuthenticationNasId", $RadiusAuthenticationNasId)
        }
        if ($RadiusCalledStationId) {
            $_Body.Add("radiusCalledStationId", $RadiusCalledStationId)
        }
        if ($RadiusFailoverPolicy) {
            $_Body.Add("radiusFailoverPolicy", $RadiusFailoverPolicy)
        }
        if ($RadiusLoadBalancingPolicy) {
            $_Body.Add("radiusLoadBalancingPolicy", $RadiusLoadBalancingPolicy)
        }
        if ($SecondaryConcentratorNetworkId) {
            $_Body.Add("secondaryConcentratorNetworkId", $SecondaryConcentratorNetworkId)
        }
        if ($AdultContentFilteringEnabled) {
            $_Body.Add("adultContentFilteringEnabled", $true)
        }
        if ($AvailableOnAllAPs) { 
            $_Body.Add("availableOnAllAPs", $true)
        }
        if ($DisassociateClientOnVpnFailover) {
            $_Body.Add("disassociateClientOnVpnFailover", $true)
        }
        if ($Disabled) {
            $_Body.Add("enabled", $false) 
        } else {
            $_Body.Add("enabled", $true)
        }
        if ($MandatoryDHCPEnabled) {
            $_Body.Add("mandatoryDHCPEnabled", $true)
        }
        if ($RadiusAccountingEnabled) {
            $_Body.Add("radiusAccountingEnabled", $true)
        }
        if ($RadiusCoaEnabled) {
            $_Body.Add("radiusCoaEnabled", $true)
        }
        if ($RadiusGuestVlanEnabled) {
            $_Body.Add("radiusGuestVlanEnabled", $true)
        }
        if ($RadiusOverride) {
            $_Body.Add("radiusOverride", $true)
        }
        if ($RadiusProxyEnabled) {
            $_Body.Add("radiusProxyEnabled", $true)
        }
        if ($RadiusTestingEnabled) {
            $_Body.Add("radiusTestingEnabled", $true)
        }
        if ($UseVlanTagging) {
            $_Body.Add("useVlanTagging", $true)
        }
        if ($Hidden) {
            $_Body.Add("visible", $false)
        }
        if ($MinBitRate) {
            $_Body.Add("minBitRate", $MinBitRate)
        }
        if ($AvailableTags) {
            $_Body.Add("availableTags", $AvailableTags)
        }
        if ($ActiveDirectory) {
            $_Body.Add("activeDirectory", $ActiveDirectory)
        }
        if ($DnsRewrite) {
            $_Body.Add("dnsRewrite", $DnsRewrite)
        }
        if ($Gre) {
            $_Body.Add("gre", $Gre)
        }
        if ($LDAP) {
            $_Body.Add("Ldap", $LDAP)
        }
        if ($LocalRadius) {
            $_Body.Add("localRadius", $LocalRadius)
        }
        if ($NamedVlans) {
            $_Body.Add("namedVlans", $NamedVlans)
        }
        if ($OAuth) {
            $_Body.Add("oauth", $OAuth)
        }
        if ($SpeedBurstEnabled) {
            $_Body["speedBurst"].enabled = true
        }
        if ($ApTagsAndVlanIds) {
            $_Body.Add("apTagsAndVlanIds", $ApTagsAndVlanIds)
        }
        if ($RadiusAccountingServers) {
            $_Body.Add("radiusAccountingServers", $RadiusAccountingServers)
        }
        if ($RadiusServers) {
            $_Body.Add("radiusServers", $RadiusServers)
        }

        $body = $_Body | ConvertTo-Json -Depth 10 -Compress
    }

    Process {
        $Uri = "{0}/networks/{1}/wireless/ssids/{2}" -f $BaseURI, $Id, $Number

        try {
            $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Update the attributes of an MR SSID
    .PARAMETER Id
    The Id of the network.
    .PARAMETER Number
    The number of the SSID.
    .PARAMETER Name
    The Name of the SSID
    .PARAMETER AuthMode
    The association control method for the SSID ('open', 'open-enhanced', 'psk', 'open-with-radius', 'open-with-nac', '8021x-meraki', '8021x-nac', '8021x-radius', '8021x-google', '8021x-localradius', 'ipsk-with-radius', 'ipsk-without-radius' or 'ipsk-with-nac')
    .PARAMETER EncryptionMode
    The psk encryption mode for the SSID ('wep' or 'wpa'). This param is only valid if the authMode is 'psk'
    .PARAMETER WpaEncryptionMode
    The types of WPA encryption. ('WPA1 only', 'WPA1 and WPA2', 'WPA2 only', 'WPA3 Transition Mode', 'WPA3 only' or 'WPA3 192-bit Security')
    .PARAMETER IpAssignmentMode
    The client IP assignment mode ('NAT mode', 'Bridge mode', 'Layer 3 roaming', 'Ethernet over GRE', 'Layer 3 roaming with a concentrator' or 'VPN')
    .PARAMETER LanIsolationEnabled
    Boolean indicating whether Layer 2 LAN isolation should be enabled or disabled. Only configurable when ipAssignmentMode is 'Bridge mode'.
    .PARAMETER PassKey
    The passkey for the SSID. This param is only valid if the authMode is 'psk'
    .PARAMETER VLanId
    VLAN ID of the RADIUS Guest VLAN. This param is only valid if the authMode is 'open-with-radius' and addressing mode is not set to 'isolated' or 'nat' mode
    .PARAMETER DefaultVlanId
    The default VLAN ID used for 'all other APs'. This param is only valid when the ipAssignmentMode is 'Bridge mode' or 'Layer 3 roaming'
    .PARAMETER Dot11wEnabled
    Whether Protected Management Frames (802.11w) is enabled
    .PARAMETER Dot11wRequired
    Whether Protected Management Frames (802.11w) is required
    .PARAMETER Dot11rEnabled
    Whether 802.11r us enabled
    .PARAMETER Dot11rRequired
    Whether 802.11r is required
    .PARAMETER SplashPage
    The type of splash page for the SSID ('None', 'Click-through splash page', 'Billing', 'Password-protected with Meraki RADIUS', 'Password-protected with custom RADIUS', 'Password-protected with Active Directory', 'Password-protected with LDAP', 'SMS authentication', 'Systems Manager Sentry', 'Facebook Wi-Fi', 'Google OAuth', 'Sponsored guest', 'Cisco ISE' or 'Google Apps domain'). This attribute is not supported for template children.
    .PARAMETER SplashGuestSponsorDomains
    Array of valid sponsor email domains for sponsored guest splash type.
    .PARAMETER WalledGardenEnabled
    Allow access to a configurable list of IP ranges, which users may access prior to sign-on.
    .PARAMETER WalledGardenRanges
    Specify your walled garden by entering an array of addresses, ranges using CIDR notation, domain names, and domain wildcards (e.g. '192.168.1.1/24', '192.168.37.10/32', 'www.yahoo.com', '*.google.com']). Meraki's splash page is automatically included in your walled garden.
    .PARAMETER PerClientBandwidthLimitDown
    The download bandwidth limit in Kbps. (0 represents no limit.)
    .PARAMETER PerClientBandwidthLimitUp
    The upload bandwidth limit in Kbps. (0 represents no limit.)
    .PARAMETER PerSsidBandwidthLimitDown
    The total download bandwidth limit in Kbps. (0 represents no limit.)
    .PARAMETER PerSsidBandwidthLimitUp
    The total upload bandwidth limit in Kbps. (0 represents no limit.)
    .PARAMETER RadiusAccountInterimInterval
    The interval (in seconds) in which accounting information is updated and sent to the RADIUS accounting server.
    .PARAMETER RadiusGuestVlanId
    VLAN ID of the RADIUS Guest VLAN. This param is only valid if the authMode is 'open-with-radius' and addressing mode is not set to 'isolated' or 'nat' mode
    .PARAMETER RadiusServerAttemptsLimit
    The maximum number of transmit attempts after which a RADIUS server is failed over (must be between 1-5).
    .PARAMETER RadiusServerTimeout
    The amount of time for which a RADIUS client waits for a reply from the RADIUS server (must be between 1-10 seconds).
    .PARAMETER BandSelection
    The client-serving radio frequencies of this SSID in the default indoor RF profile. ('Dual band operation', '5 GHz band only' or 'Dual band operation with Band Steering')
    .PARAMETER ConcentratorNetworkId
    The concentrator to use when the ipAssignmentMode is 'Layer 3 roaming with a concentrator' or 'VPN'.
    .PARAMETER EnterpriseAdminAccess
    Whether or not an SSID is accessible by 'enterprise' administrators ('access disabled' or 'access enabled')
    .PARAMETER RadiusAttributeForGroupPolicies
    Specify the RADIUS attribute used to look up group policies ('Filter-Id', 'Reply-Message', 'Airespace-ACL-Name' or 'Aruba-User-Role'). Access points must receive this attribute in the RADIUS Access-Accept message
    .PARAMETER RadiusAuthenticationNasId
    The template of the NAS identifier to be used for RADIUS authentication (ex. $NODE_MAC$:$VAP_NUM$).
    .PARAMETER RadiusCalledStationId
    The template of the called station identifier to be used for RADIUS (ex. $NODE_MAC$:$VAP_NUM$).
    .PARAMETER RadiusFailoverPolicy
    This policy determines how authentication requests should be handled in the event that all of the configured RADIUS servers are unreachable ('Deny access' or 'Allow access')
    .PARAMETER RadiusFallBackEnabled
    Whether or not higher priority RADIUS servers should be retried after 60 seconds.
    .PARAMETER RadiusLoadBalancingPolicy
    This policy determines which RADIUS server will be contacted first in an authentication attempt and the ordering of any necessary retry attempts ('Strict priority order' or 'Round robin')
    .PARAMETER SecondaryConcentratorNetworkId
    The secondary concentrator to use when the ipAssignmentMode is 'VPN'. If configured, the APs will switch to using this concentrator if the primary concentrator is unreachable. This param is optional. ('disabled' represents no secondary concentrator.)
    .PARAMETER AdultContentFilteringEnabled
    Whether or not adult content will be blocked
    .PARAMETER AvailableOnAllAPs
    Boolean indicating whether all APs should broadcast the SSID or if it should be restricted to APs matching any availability tags. Can only be false if the SSID has availability tags.
    .PARAMETER DisassociateClientOnVpnFailover
    Disassociate clients when 'VPN' concentrator failover occurs in order to trigger clients to re-associate and generate new DHCP requests. This param is only valid if ipAssignmentMode is 'VPN'.
    .PARAMETER Disabled
    The SSID is disabled, enabled if omitted.
    .PARAMETER MandatoryDHCPEnabled
    If true, Mandatory DHCP will enforce that clients connecting to this SSID must use the IP address assigned by the DHCP server. Clients who use a static IP address won't be able to associate.
    .PARAMETER RadiusAccountingEnabled
    Whether or not RADIUS accounting is enabled. This param is only valid if the authMode is 'open-with-radius', '8021x-radius' or 'ipsk-with-radius'
    .PARAMETER RadiusCoaEnabled
    If true, Meraki devices will act as a RADIUS Dynamic Authorization Server and will respond to RADIUS Change-of-Authorization and Disconnect messages sent by the RADIUS server.
    .PARAMETER RadiusGuestVlanEnabled
    Whether or not RADIUS Guest VLAN is enabled. This param is only valid if the authMode is 'open-with-radius' and addressing mode is not set to 'isolated' or 'nat' mode
    .PARAMETER RadiusOverride
     If true, the RADIUS response can override VLAN tag. This is not valid when ipAssignmentMode is 'NAT mode'.
     .PARAMETER RadiusProxyEnabled
     If true, Meraki devices will proxy RADIUS messages through the Meraki cloud to the configured RADIUS auth and accounting servers.
     .PARAMETER RadiusTestingEnabled
     If true, Meraki devices will periodically send Access-Request messages to configured RADIUS servers using identity 'meraki_8021x_test' to ensure that the RADIUS servers are reachable.
    .PARAMETER UseVlanTagging
    Whether or not traffic should be directed to use specific VLANs. This param is only valid if the ipAssignmentMode is 'Bridge mode' or 'Layer 3 roaming'
    .PARAMETER Hidden
    Do not advertise the SSID.
    .PARAMETER MinBitRate
    The minimum bitrate in Mbps of this SSID in the default indoor RF profile. ('1', '2', '5.5', '6', '9', '11', '12', '18', '24', '36', '48' or '54')
    .PARAMETER AvailableTags
    Accepts a list of tags for this SSID. If availableOnAllAps is false, then the SSID will only be broadcast by APs with tags matching any of the tags in this list.
    .PARAMETER ActiveDirectory
    The current setting for Active Directory. Only valid if splashPage is 'Password-protected with Active Directory'
    Object schema:
    credentials: object
        (Optional) The credentials of the user account to be used by the AP to bind to your Active Directory server. The Active Directory account should have permissions on all your Active Directory servers. Only valid if the splashPage is 'Password-protected with Active Directory'.
            logonName: string The logon name of the Active Directory account.
            password: string The password to the Active Directory user account.
    servers*: array[]
        The Active Directory servers to be used for authentication.
        port: integer (Optional) UDP port the Active Directory server listens on. By default, uses port 3268.
        host*: string IP address (or FQDN) of your Active Directory server.
    .PARAMETER DnsRewrite
    DNS rewrite settings
    Object schema:
    enabled: boolean Boolean indicating whether or not DNS server rewrite is enabled. If disabled, upstream DNS will be used
    dnsCustomNameservers: array[] User specified DNS servers (up to two servers)
    .PARAMETER Gre
    Ethernet over GRE settings
    Object schema:
    key: integer Optional numerical identifier that will add the GRE key field to the GRE header. Used to identify an individual traffic flow within a tunnel.
    concentrator*: object The EoGRE concentrator's settings
    host*: string The EoGRE concentrator's IP or FQDN. This param is required when ipAssignmentMode is 'Ethernet over GRE'.
    .PARAMETER LDAP
    The current setting for LDAP. Only valid if splashPage is 'Password-protected with LDAP'.
    Object schema:
    baseDistinguishedName: string The base distinguished name of users on the LDAP server.
    credentials: object (Optional) The credentials of the user account to be used by the AP to bind to your LDAP server. The LDAP account should have permissions on all your LDAP servers.
        distinguishedName: string The distinguished name of the LDAP user account (example: cn=user,dc=meraki,dc=com).
        password: string The password of the LDAP user account.
    serverCaCertificate: object The CA certificate used to sign the LDAP server's key.
        contents: string The contents of the CA certificate. Must be in PEM or DER format.
    servers*: array[] The LDAP servers to be used for authentication.
        port*: integer UDP port the LDAP server listens on.
        host*: string IP address (or FQDN) of your LDAP server.
    .PARAMETER LocalRadius
    The current setting for Local Authentication, a built-in RADIUS server on the access point. Only valid if authMode is '8021x-localradius'.
    Object schema:
    cacheTimeout: integer The duration (in seconds) for which LDAP and OCSP lookups are cached.
    certificateAuthentication: object The current setting for certificate verification.
        ocspResponderUrl: string (Optional) The URL of the OCSP responder to verify client certificate status.
        enabled: boolean Whether or not to use EAP-TLS certificate-based authentication to validate wireless clients.
        useLdap: boolean Whether or not to verify the certificate with LDAP.
        useOcsp: boolean Whether or not to verify the certificate with OCSP.
            clientRootCaCertificate: object The Client CA Certificate used to sign the client certificate.
                contents: string The contents of the Client CA Certificate. Must be in PEM or DER format.
        passwordAuthentication: object The current setting for password-based authentication.
            enabled: boolean Whether or not to use EAP-TTLS/PAP or PEAP-GTC password-based authentication via LDAP lookup.
    .PARAMETER NamedVlans
    Named Vlan Settings
    Object schema
    radius: object RADIUS settings. This param is only valid when authMode is 'open-with-radius' and ipAssignmentMode is not 'NAT mode'.
        guestVlan: object Guest VLAN settings. Used to direct traffic to a guest VLAN when none of the RADIUS servers are reachable or a client receives access-reject from the RADIUS server.
            name: string RADIUS guest VLAN name.
            enabled: boolean Whether or not RADIUS guest named VLAN is enabled.
        tagging: object VLAN tagging settings. This param is only valid when ipAssignmentMode is 'Bridge mode' or 'Layer 3 roaming'.
            defaultVlanName: string The default VLAN name used to tag traffic in the absence of a matching AP tag.
            enabled: boolean Whether or not traffic should be directed to use specific VLAN names.
            byApTags: array[] The list of AP tags and VLAN names used for named VLAN tagging. If an AP has a tag matching one in the list, then traffic on this SSID will be directed to use the VLAN name associated to the tag.
                vlanName: string VLAN name that will be used to tag traffic.
                tags: array[] List of AP tags.
    .PARAMETER OAuth
    The OAuth settings of this SSID. Only valid if splashPage is 'Google OAuth'.
        allowedDomains:array[] (Optional) The list of domains allowed access to the network.
    .PARAMETER SpeedBurstEnabled
    Is speed burst enabled.
    .PARAMETER ApTagsAndVlanIds
    The list of tags and VLAN IDs used for VLAN tagging. This param is only valid when the ipAssignmentMode is 'Bridge mode' or 'Layer 3 roaming'
    Object schema:
    vlanId: integer Numerical identifier that is assigned to the VLAN
    tags: array[] Array of AP tags
    .PARAMETER RadiusAccountingServers
    The RADIUS accounting 802.1X servers to be used for authentication. This param is only valid if the authMode is 'open-with-radius', '8021x-radius' or 'ipsk-with-radius' and radiusAccountingEnabled is 'true'
    Object schema:
    port: integer Port on the RADIUS server that is listening for accounting messages
    caCertificate: string Certificate used for authorization for the RADSEC Server
    host*: string IP address (or FQDN) to which the APs will send RADIUS accounting messages
    secret: string Shared key used to authenticate messages between the APs and RADIUS server
    radsecEnabled: boolean Use RADSEC (TLS over TCP) to connect to this RADIUS accounting server. Requires radiusProxyEnabled.
    .PARAMETER RadiusServers
    The RADIUS 802.1X servers to be used for authentication. This param is only valid if the authMode is 'open-with-radius', '8021x-radius' or 'ipsk-with-radius'
    Object schema:
    openRoamingCertificateId: integer The ID of the Openroaming Certificate attached to radius server.
    port: integer UDP port the RADIUS server listens on for Access-requests
    caCertificate: string Certificate used for authorization for the RADSEC Server
    host*: string IP address (or FQDN) of your RADIUS server
    secret: string RADIUS client shared secret
    radsecEnabled: boolean Use RADSEC (TLS over TCP) to connect to this RADIUS server. Requires radiusProxyEnabled.
    .OUTPUTS
    An SSID object
    #>
}

function Get-MerakiSSIDIdentityPsk() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$Number,
        [string]$IdentityPskId
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}/wireless/ssids/{2}/identityPsks" -f $BaseURI, $Id, $Number
        if ($IdentityPskId) {
            $Uri = "{0}/{1}" -f $Uri, $IdentityPskId
        }

        Try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            $response | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name NetworkId -Value $Id
                $_ | Add-Member -MemberType NoteProperty -Name Number -Value $Id
            }
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Return an Identity PSK.
    .PARAMETER Id
    The Id of the Network
    .PARAMETER Number
    The SSID number.
    .PARAMETER IdentityPskId
    The ID of the Identity PSK. If omitted returns all Identity PSKs for this SSID.
    .OUTPUTS
    An Identity PSK objects or an array of Identity PSK objects.
    #>
}

function Add-MerakiSsidIdentityPsk() {
    [CmdletBinding()]
    Param (
         [Parameter(
                Mandatory,
                ValueFromPipelineByPropertyName
            )]
            [Alias('NetworkId')]
            [string]$id,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$Number,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$GroupPolicyId,
        [secureString]$Passphrase,
        [DateTime]$ExpiresAt
    )

    Begin {
        $Headers = Get-Headers

        $_Body = @{
            name            = $Name
            groupPolicyId   = $GroupPolicyId
        }

        if ($Passphrase) {
            $pPhrase = ConvertFrom-SecureString -SecureString $Passphrase -AsPlainText
            $_Body.Add("passPhrase", $pPhrase)
        }

        if ($ExpiresAt) {
            $ExpiresAt_str = $ExpiresAt.ToString("MM/dd/yyyy, hh:mm:ss tt")
            $_Body.Add("expiresAt", $ExpiresAt_str)
        }

        $body = $_Body | ConvertTo-Json -Compress
    }

    Process {
        $Uri = "{0}/networks/{1}/wireless/ssids/{2}/identityPsks" -f $BaseUri, $Id, $Number
        
        try {
            $response = Invoke-RestMethod -Method Post -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            $response | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name NetworkId -Value $Id
                $_ | Add-Member -MemberType NoteProperty -Name Number -Value $Number
            }
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION 
    Create an Identity PSK
    .PARAMETER id
    Net Id of the Network.
    .PARAMETER Number
    The SSID number.
    .PARAMETER Name
    The name of the Identity PSK.
    .PARAMETER GroupPolicyId
    The group policy to be applied to clients.
    .PARAMETER Passphrase
    The passphrase for client authentication. If left blank, one will be auto-generated.
    This must be passed as a secure string. To create a secure string:
    $securePassPhrase = ConvertTo-SecureString -String 'myp@ssPhr@s3!' -AsPlainText -Force
    .PARAMETER ExpiresAt
    Timestamp for when the Identity PSK expires. Will not expire if left blank.
    .OUTPUTS
    An SSID Identity PSK object.    
    #>
}

function Set-MerakiSsidIdentityPsk() {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$Number,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$IdentityPskId,
        [string]$Name,
        [string]$GroupPolicyId,
        [SecureString]$PassPhrase,
        [datetime]$expiresAt
    )

    Begin {
        $Headers = Get-Headers

        $_Body = @{}

        if ($Name) {$_Body.Add("name", $Name)}
        if($GroupPolicyId) {$_Body.Add("groupPolicyId", $GroupPolicyId)}
        if ($PassPhrase) {
            $pPhase = ConvertFrom-SecureString -SecureString $PassPhrase -AsPlainText
            $_Body.Add("passPhrase",$pPhase)
        }
        if ($expiresAt) {
            $expiresAt_str = $expiresAt.ToString("MM/dd/yyyy, hh:mm:ss tt")
            $_Body.Add("expiresAt", $expiresAt_str)
        }

        $body = $_Body | ConvertTo-Json -Compress        
    }

    Process {
        $Uri = "{0}/networks/{1}/wireless/ssids/{2}/identityPsks/{3}" -f $BaseUri, $Id, $Number, $IdentityPskId

        try {
            $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $body -PreserveAuthorizationOnRedirect
            $response | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name 'NetworkId' -Value $Id
                $_ | Add-Member -MemberType NoteProperty -Name 'Number' -Value $Number
            }
            return $response
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Update an Identity PSK
    .PARAMETER Id
    The Id of the network.
    .PARAMETER Number
    The SSID number.
    .PARAMETER IdentityPskId
    The ID of the Identity PSK to update
    .PARAMETER Name
    The name of the Identity PSK.
    .PARAMETER GroupPolicyId
    The group policy to be applied to clients.
    .PARAMETER PassPhrase
    The passphrase for client authentication
    This must be passed as a secure string. To create a secure string:
    $securePassPhrase = ConvertTo-SecureString -String 'myp@ssPhr@s3!' -AsPlainText -Force
    .PARAMETER expiresAt
    Timestamp for when the Identity PSK expires.
    .OUTPUTS
    An Identity PSK object.
    #>
}

function Remove-MerakiSsidIdentityPsk() {
    [CmdletBinding(
        SupportsShouldProcess, 
        ConfirmImpact = 'high'
    )]
    Param (
        [Parameter(Mandatory)]
        [string]$NetworkId,
        [Parameter(Mandatory)]
        [int]$Number,
        [Parameter(Mandatory)]
        [string]$IdentityPskId
    )

    Begin {
        $Headers = Get-Headers
    }

    Process {
        $Uri = "{0}/networks/{1}}/wireless/ssids/{2}/identityPsks/{3}" -f $BaseURI, $Id, $Number, $IdentityPskId
        $SsidName = (Get-MerakiSSID -Id $id -Number $Number).Name
        $NetworkName = (Get-MerakiNetwork -networkID $id).Name
        if ($PSCmdlet.ShouldProcess("Identity PSK with ID: $IdentityPskId from SSID: $SsidName, in network $NetworkName", "Delete")) {
            try {
                $response = Invoke-RestMethod -Method Delete -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
                return $response
            } catch {
                throw $_
            }
        }
    }
    <#
    .DESCRIPTION 
    Delete an Identity PSK
    .PARAMETER NetworkId
    The Id of the network.
    .PARAMETER Number
    The SSID number.
    .PARAMETER IdentityPskId
    The Identity PSK Id.    
    #>
}
#endregion

function Get-MerakiWirelessStatus() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$serial
    )

    $Uri = '{0}/devices/{1}/wireless/status' -f $BaseURI, $serial
    $Headers = Get-Headers

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect

        return $response
    } catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Returns the status of a Meraki Access Point.
    .PARAMETER serial
    The serial number of the Access Point.
    .OUTPUTS
    A Meraki Access Point status object.
    #>
}

Set-Alias -Name GMWirelessStat -Value Get-MerakiWirelessStatus

function Get-MerakiNetworkClientConnectionStats() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$Id,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$ClientId,

        [ValidateScript({$_ -is [datetime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfiles', Mandatory)] 
        [datetime]$StartDate,

        [ValidateScript({$_ -is [datetime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfile', Mandatory)]
        [DateTime]$EndDate,

        [Parameter(ParameterSetName = 'days', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithProfile', Mandatory)]
        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,31)]
        [int]$Days,

        [ValidateSet('2.5', '5', '6')]
        [string]$Band,

        [ValidateRange(0,14)]
        [ValidateScript({$_ -is [int]})]
        [string]$SSID,

        [ValidateScript({ $_ -is [int] })]
        [ValidateRange(1,4096)]
        [int]$VLAN,

        [string]$APTag
    )

    Begin {

        $Headers = Get-Headers

        Set-Variable -Name Query

        if ($StartDate) {
            $Query = "t0={0}" -f ($StartDate.ToString("O"))
        }
        if ($EndDate) {
            if ($Query) {$Query += '&'}
            $Query = "{0}t1={1}" -f $Query, ($endDate.ToString("O"))
        }
        if ($Days) {
            if ($Query) {$Query += '&'}
            $Seconds = [timespan]::FromDays($Days).TotalSeconds
            $Query = "{0}timespan={1}" -f $Query, $Seconds
        }
        if ($Band) {
            if ($Query) {$Query += '&'}
            $Query = "{0}band={1}" -f $Query, $Band
        }
        if ($SSID) {
            if ($Query) {$Query += '&'}
            $Query = "{0}ssid={1}" -f $Query, $SSID
        }
        if ($VLAN) {
            if ($Query) {$Query += '&'}
            $Query = "{0}vlan={1}" -f $Query, $VLAN
        }
        if ($APTag) {
            if ($Query) {$Query += '&'}
            $Query = "{0}apTag={1}" -f $Query, $APTag
        }
    }

    Process {
        $Uri = "{0}/network/{1}/wireless/clients" -f $BaseURI, $Id
        if ($ClientId) {
            $Uri = "{0}/{2}/connectionStats" -f $Uri, $ClientId
        } else {
            $Uri = "{0}/connectionStats" -f $Uri
        }

        if ($Query) {
            $Uri = "{0}?{1}" -f $Uri, $Query
        }
        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            return $response
        }
        catch {
            throw $_
        }
    }
    <#
    .SYNOPSIS
    Returns aggregated connectivity info for a given client on this network. Clients are identified by their MAC.
    .DESCRIPTION
    Returns aggregated connectivity info for a given client on this network for the given time period, band, SSID VLAN of AP Tag.
    .PARAMETER Id
    The Network Id.
    .PARAMETER StartDate
    The starting date to return data. Must be no more that 7 days before today.
    .PARAMETER EndDate
    The ending date to return data. Must be no more than 7 days before today.
    .PARAMETER Days
    The number of days prior to today to return data. Must be no more that 7 days before today.
    .PARAMETER Band
    Filter results by band (either '2.4', '5' or '6'). Note that data prior to February 2020 will not have band information.
    .PARAMETER SSID
    Filter results by SSID.
    .PARAMETER VLAN
    Filter results by VLAN.
    .PARAMETER APTag
    Filter results by AP Tag.
    .OUTPUTS
    A collection of connectivity information objects.
    #>
}



function Get-MerakiWirelessAirMarshal() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$Id,
        [int]$Days
    )

    $Uri = "{0}/networks/{1}/wireless/airMarshal" -f $BaseURI, $id
    $Headers = Get-Headers

    if ($Days) {
        $Seconds = [TimeSpan]::FromDays($Days).TotalSeconds
        $Uri = "{0}?days={1}" -f $Uri, $Seconds
    }

    try {
        $response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
        return $response
    }
    catch {
        throw $_
    }

    <#
    .DESCRIPTION
    Returns Air Marshal scan results from a network.
    .PARAMETER Id
    The Id of the network.
    .PARAMETER Days
    Number of days prior to today to return data.
    #>
}

function Get-MerakiWirelessUsageHistory() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,

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

        [ValidateSet(300, 600, 1200, 3600, 14400, 86400)]
        [int]$Resolution,

        [switch]$AutoResolution,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [string]$ClientId,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Alias('DeviceSerial')]
        [string]$Serial,

        [string]$APTag,

        [ValidateSet('2.4', '5', '6')]
        [string]$Band,

        [ValidateSet(0,14)]
        [Int]$SsidNumber
    )

    Begin {
        $Headers = Get-Headers

        if ($StartDate) {
            $Query = "t0={0}" -f ($StartDate.ToString("O"))
        }

        if ($EndDate) {
            if ($Query) {$Query += '&'}
            $Query = "{0}t1={1}" -f $Query, ($EndDate.ToString("0"))
        }

        if ($Days) {
            if ($Query) {$Query += '&'}
            $Seconds = ([TimeSpan]::FromDays($DaysPast)).TotalSeconds    
            $Query = "{0}timespan={1}" -f $Query, $Seconds
        }

        If ($Resolution) {
            if ($Query) {$Query += "&"}
            $Query = "{0}resolution={1}" -f $Query, $Resolution
        }
        if ($AutoResolution) {
            if ($Query) {$Query += "&"}
            $Query = "{0}autoResolution=true" -f $Query
        }
        if ($APTag) {
            if ($Query) {$Query += "&"}
            $Query = "{0}apTag={1}" -f $Query, $APTag
        }
        if ($Band) {
            if ($Query) {$Query += "&"}
            $Query = "{0}band={1}" -f $Query, $Band
        }
        if ($SsidNumber) {
            if ($Query) {$Query += "&"}
            $Query = "{0}ssid={1}" -f $Query, $SsidNumber
        }

        if ($ClientId) {
            if ($Query) {$Query += "&"}
            $Query = "{0}clientId={1}" -f $Query, $ClientId
        }

        if ($Serial) {
            if ($Query) {$Query += "&"}
            $Query = "{0}serial={1}" -f $Query, $Serial
        }
    }
        
    Process {

        $Uri = "{0}/networks/{1}/wireless/usageHistory" -f $BaseURI, $Id

        if ($ClientId) {
            if ($Query) {$Query += "&"}
            $Query = "{0}clientId={1}" -f $Query, $ClientId
        }

        if ($Serial) {
            if ($Query) {$Query += "&"}
            $Query = "{0}deviceSerial={1}" -f $Query, $Serial
        }

        if ($Query) {
            $Uri = "{0}?{1}" -f $Uri, $Query
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
    .DESCRIPTION
    Return Access Point usage over time for a device or network client
    .PARAMETER Id
    The Id of the network.
    .PARAMETER StartDate
    The starting date to query data. Max 32 days prior to today.
    .PARAMETER EndDate
    The ending date to return data. can be a maximum of 31 days after StartDate.
    .PARAMETER Days
    NUmber of days prior to today to return data. Max 31 days prior to today.
    .PARAMETER Resolution
    The time resolution in seconds for returned data. The valid resolutions are: 300, 600, 1200, 3600, 14400, 86400. The default is 86400.
    .PARAMETER AutoResolution
    Automatically select a data resolution based on the given timespan; this overrides the value specified by the 'Resolution' parameter. The default setting is false.
    .PARAMETER ClientId
    Filter results by network client to return per-device AP usage over time inner joined by the queried client's connection history.
    .PARAMETER Serial
    Filter results by device. Requires the Band parameter.
    .PARAMETER APTag
    Filter results by AP tag; either :clientId or :deviceSerial must be jointly specified.
    .PARAMETER Band
    Filter results by band (either '2.4', '5' or '6').
    .PARAMETER SsidNumber
    Filter results by SSID number.
    #>
}

function Get-MerakiWirelessDataRateHistory() {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('NetworkId')]
        [string]$Id,
        [ValidateScript({$_ -is [datetime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfiles', Mandatory)]  
        [ValidateScript({
            ((Get-Date) - $_).Days -le 31
        })]
        [datetime]$StartDate,

        [ValidateScript({$_ -is [datetime]})]
        [Parameter(ParameterSetName = 'dates', Mandatory)]
        [Parameter(ParameterSetName = 'datesWithOrg', Mandatory)]
        [Parameter(ParameterSetName ='datesWithProfile', Mandatory)]
        [ValidateSet({
            ($_ - $StartDate).Days -le 31
        })]
        [datetime]$EndDate,

        [Parameter(ParameterSetName = 'days', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithOrg', Mandatory)]
        [Parameter(ParameterSetName = 'daysWithProfile', Mandatory)]
        [ValidateScript({$_ -is [int]})]
        [ValidateRange(1,31)]
        [int]$Days,

        [ValidateSet(300, 600, 1200, 3600, 14400, 86400)]
        [int]$Resolution,

        [switch]$AutoResolution,

        [string]$ClientId,
        [Alias('DeviceSerial')]
        [string]$Serial,
        [string]$APTag,

        [ValidateSet('2.4','5','6')]
        [string]$Band,
        [ValidateSet(0,24)]
        [Int]$SsidNumber,
        [switch]$ExcludeNoData
    )

    Begin {
        $Headers = Get-Headers
        if ($Days) {
            $Seconds = ([Timespan]::FromDays($DaysPast)).TotalSeconds    
            $Query = "timespan={0}" -f $Seconds
        }

        if ($StartDate) {
            if ($Query) {$Query += '&'}
            $Query = "{0}t0={1}" -f $Query, ($StartDate.ToSingle("O"))
        }

        if ($EndDate) {
            $Query = "{0}t1={1}" -f $Query, ($EndDate.ToString("O"))
        }

        if ($ClientId) {
            if ($Query) {$Query += '&'}
            $Query = "{0}clientId={1}" -f $Query, $ClientId
        }

        if ($Serial) {
            if ($Query) {$Query += '&'}
            $Query = "{0}deviceSerial={1}" -f $Query, $Serial
        }

        If ($Resolution) {
            if ($Query) {$Query += '&'}
            $Query = "{0}resolution={1}" -f $qParams, $Resolution
        }
        if ($AutoResolution) {
            if ($Query) {$Query += '&'}
            $Query = "{0}autoResolution=true" -f $Query
        }
        if ($APTag) {
            if ($Query) {$Query += '&'}
            $Query = "{0}apTag={1}" -f $Query, $APTag
        }
        if ($Band) {
            if ($Query) {$Query += '&'}
            $Query = "{0}band={1}" -f $Query, $Band            
        }
        if ($Ssid) {
            if ($Query) {$Query += '&'}
            $Query = "{0}ssid={1}" -f $Query, $SsidNumber
        }
    }

    Process {
        

        $Uri = "{0}/networks/{1}/wireless/dataRateHistory" -f $BaseURI, $Id

        if ($Query) {
            $Uri = "{0}{1}" -f $Uri, $Query
        }

        try {
            $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -PreserveAuthorizationOnRedirect
            if ($ExcludeNoData) {
                $result = $response |Where-Object {$null -ne $_.averageKbps -and $null -ne $_.downloadKbps -and $null -ne $_.uploadKbps}
            } else {
                $result = $response
            }
            $result | ForEach-Object {
                if ($Serial) {
                    $_ | Add-Member -MemberType NoteProperty -Name DeviceSerial -Value $Serial
                }
                if ($ClientId) {
                    $_ | Add-Member -MemberType NoteProperty -Name ClientId -Value $ClientId
                }
            }
            return $result
        } catch {
            throw $_
        }
    }
    <#
    .DESCRIPTION
    Return PHY data rates over time for a network, device, or network client
    .PARAMETER Id
    The Id of the network.
    .PARAMETER StartDate
    The starting date to query data. Max 32 days prior to today.
    .PARAMETER EndDate
    The ending date to return data. can be a maximum of 31 days after StartDate.
    .PARAMETER Days
    NUmber of days prior to today to return data. Max 31 days prior to today.
    .PARAMETER Resolution
    The time resolution in seconds for returned data. The valid resolutions are: 300, 600, 1200, 3600, 14400, 86400. The default is 86400.
    .PARAMETER AutoResolution
    Automatically select a data resolution based on the given timespan; this overrides the value specified by the 'resolution' parameter. The default setting is false.
    .PARAMETER ClientId
    Filter results by network client.
    .PARAMETER Serial
    Filter results by device.
    .PARAMETER APTag
    Filter results by AP tag.
    .PARAMETER Band
    Filter results by band (either '2.4', '5' or '6').
    .PARAMETER SsidNumber
    Filter results by SSID number.
    .PARAMETER ExcludeNoData
    Exclude items that have no data.
    #>
}

