# .Description Document a Meraki Network
#
<# 
    .Synopsis 
        This script produces an Excel worksheet documenting all aspects of a Meraki network.
        It also export JSON files of each configuration.
#>
# Parameters 
#       NetworkName:
#       Type: String
#       Description: The full network name
#
#   id:
#       Type: String
#       Description: Network ID
#
#   OutputFolder"
#       Type: String
#       Description:    Folder to output the documentation. 2 folders are created underneath this folder, doc and json.
#                       The doc folder will contain a file called doc.xlsx. The jason folder will contain json files for each
#                       configuration i.e. network.json. These files could used to restore a network configuration.
#
[CmdletBinding(DefaultParameterSetName='NetworkName')]
Param(
    [Parameter(
        ParameterSetName='NetworkName',
        Position=0,
        Mandatory=$true
    )]
    [String]$NetworkName,
    [Parameter(
        ParameterSetName='id',
        Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=0
    )]
    [string]$id,
    [Parameter(
        Mandatory = $true
    )]
    [string]$OutputFolder,
    [switch]$ExcludeAppliances,
    [switch]$ExcludeSwitches,
    [switch]$ExcludeAccessPoints
)
$ErrorActionPreference = "Break"

Import-Module Meraki-API-V1
Import-Module ImportExcel

$savedWarningPreferrence = $Global:WarningPreference
$Global:WarningPreference = 'SilentlyContinue'

if ($NetworkName) {
    $Network = Get-MerakiNetworks | Where-Object {$_.Name -eq $NetworkName}    
} else {
    $Network = Get-MerakiNetwork -networkId $id
}

If (-not $Network) {
    Throw "Network not found"
    exit
}
Write-Host $Network.Name -ForegroundColor Yellow

$OutputFolder = "{0}/{1}" -f $OutputFolder, ($Network.name)

If (-not (Test-Path -Path $outputFolder)) {
    $OutputFolder = (New-Item -ItemType Directory -Path $OutputFolder).FullName
} else {
    $OutputFolder = (Get-Item -Path $OutputFolder)
}
If (-not(Test-Path -Path (Join-Path -Path $OutputFolder -ChildPath '*'))) {
    $docPath = (New-Item -ItemType Directory -Path $OutputFolder -Name "doc").FullName
    $jsonPath = (New-Item -ItemType Directory -Path $OutputFolder -Name "json").FullName
} else {
    $docPath = Join-Path -Path $OutputFolder -ChildPath "doc"
    $jsonPath = Join-Path -Path $outputFolder -ChildPath "json"
}
$document = Join-Path -Path $docPath -ChildPath "$($Network.name).xlsx"

if (Test-Path -Path $document) {
    Remove-Item $document
}


$titleParams = @{
    TitleBold=$true;
    TitleSize=12;

}

$TableParams = @{
    BorderColor="black";
    BorderRight="thin";
    BorderLeft="thin";
    BorderTop="thin";
    BorderBottom="thin";
    FontSize=9
}


$Worksheet = $Network.Name
$script:StartRow = 1
$script:StartColumn = 1
$excel = Export-Excel -Path $document -Worksheet $WorkSheet -PassThru
$networkItems = [PSCustomObject]@{
    Name = $Network.Name
    OrganizationID = $Network.OrganizationID
    TimeZone = $network.timeZone
    ProductTypes = $Network.productTypes -join ","
}

$networkProps = $networkItems.PSObject.Properties

$excel = $networkProps | Select-Object @{n="Property";e={$_.Name}}, Value | `
                Export-Excel -ExcelPackage $excel -WorkSheetName $Worksheet -TableName "Network" `
                            -StartRow $script:StartRow -StartColumn $script:StartColumn -Title "Network" @titleParams `
                            -AutoSize -NumberFormat Text -PassThru 

$Network | ConvertTo-Json | Set-Content -Path "$jsonPath/network.json"             

$script:StartRow += ($networkProps | Select-Object Name).length + 3

$Devices = $Network | Get-MerakiNetworkDevices            
$Stacks = $Network | Get-MerakiNetworkSwitchStacks
$Appliances = $Devices |Where-Object {$_.Model -Like "MX*"}
$Switches = $Devices | Where-Object {$_.Model -like "MS*"}
$AccessPoints = $Devices | Where-Object {$_.Model -like "MR*"}
if ($Devices.Where({$_.model -like "MX*"}).Count -gt 0) {
    $ApplianceVLANS = $Network | Get-MerakiNetworkApplianceVLANS
}

function DocumentAppliances() {
    Param(
        $Appliances
    )
    Write-Host "Documenting Appliances" -ForegroundColor Yellow
    if ($Appliances) {
        $tblAppliances = $Appliances |Select-Object Name, Model, Serial, `
                                                    @{n="WAN IP 1";e={$_.wan1Ip}}, `
                                                    @{n="WAN IP 2";e={$_.wan2Ip}}, `
                                                    @{n="Firmware";e={$_.firmware}}, `
                                                    @{n="Address";e={$_.Address}}, `
                                                    @{n="MAC Address";e={$_.mac}}, `
                                                    @{n="Tags";e={$_.tags -join " "}} 

        $excel = $tblAppliances | Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -TableName "appliances" `
                    -StartRow $script:StartRow -StartColumn $script:StartColumn -Title "Appliances" @titleParams -autoSize `
                    -PassThru -NumberFormat Text

        $Appliances | ConvertTo-Json -Depth 100 | Set-Content -Path "$jsonPath/Appliances.json" 

        $script:StartRow += $Appliance.count + 4
    }
}

Function DocumentUplinks() {
    Param(
        $Network
    )
    Write-Host "Documenting Uplinks" -ForegroundColor Yellow
    $uplinks = (Get-MerakiApplianceUplinkStatuses -networkId $Network.Id).uplinks
    If ($uplinks) {
        $excel = $uplinks | Select-Object   @{n="Interface";e={$_.Interface}}, `
                                            @{n="Status";e={$_.status}}, `
                                            @{n="IP";e={$_.ip}}, `
                                            @{n="Gateway";e={$_.gateway}}, `
                                            @{n="Primary DNS";e={$_.primaryDns}}, `
                                            @{n="Secondary DNS";e={$_.secondaryDns}}, `
                                            @{n="IP Assigned By";e={$_.ipAssignedBy}} | `
                                Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                                    -TableName "Uplinks" -Title "Appliance Uplinks" @titleParams -AutoSize -NumberFormat text -PassThru                                    
        $script:StartRow += $Uplinks.Count + 3

        $uplinks | ConvertTo-Json -Depth 100| Set-Content -Path "$jsonPath/uplinks.json"
    }
}

function DocumentApplianceVLANs() {
    Param(
        $ApplianceVLANS
    )
    Write-Host "Documenting Appliance VLANs" -ForegroundColor Yellow
    if ($ApplianceVLANS) {
        $excel = $ApplianceVLANS | Select-Object @{Name="VLAN ID";Expression={$_.Id}}, `
                                                Name, `
                                                @{Name="Appliance IP";Expression={$_.applianceIp}}, `
                                                @{n="Subnet";e={$_.subnet}} | `
                                        Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -TableName "ApplianceVLANS" `
                                            -StartRow $script:StartRow -StartColumn $script:StartColumn -title "ApplianceVLANS" @titleParams `
                                            -AutoSize -NumberFormat Text -PassThru


        $ApplianceVLANS | ConvertTo-Json -Depth 100 | Set-Content -path "$jsonPath/ApplianceVLANS.json"  

        $script:StartRow += $ApplianceVLANS.Count + 3
    }
}

function DocumentAppliancePorts() {
    Param(
        $Documents
    )
    Write-Host "Documenting Appliance Ports" -ForegroundColor Yellow
    $AppliancePorts = $Network | Get-MerakiAppliancePorts -ErrorAction SilentlyContinue
    if ($AppliancePorts) {
        $vlans = $Network | Get-MerakiNetworkApplianceVLANS
        $excel = $AppliancePorts | Select-Object    @{Name="Port Number";Expression={$_.number}}, `
                                                    @{Name="Status";Expression={if ($_.enabled) {"Enabled"} Else {"Disabled"}}}, `
                                                    @{Name="Type";Expression={$_.type}}, `
                                                    @{Name="Drop Untagged Traffic";Expression={$_.dropUntaggedTraffic}}, `
                                                    @{Name="VLAN ID";Expression={$_.vlan}}, `
                                                    @{Name="VLAN Name";Expression={$vn=$_.vlan; $vlans.where({$_.id -eq $vn}).name}} | `
                                    Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -TableName "AppliancePorts" `
                                        -StartRow $script:StartRow -StartColumn $script:StartColumn -Title "Per-port VLAN Settings" @titleParams `
                                        -AutoSize -NumberFormat Text -PassThru

        $AppliancePorts | ConvertTo-Json -Depth 100 | Set-Content -Path "$jsonPath/AppliancePorts.json"                            
                                    
        $script:StartRow += $AppliancePorts.Count + 3
    }

}

function DocumentApplianceStaticRoutes() {
    Write-Host "Documenting Appliance Static Routes" -ForegroundColor Yellow
    $StaticRoutes = $Network | Get-MerakiNetworkApplianceStaticRoutes

    if ($StaticRoutes) {
        $excel = $StaticRoutes | Select-Object Enabled, Name, Subnet, @{n="Next Hop";e={$_.gatewayIp}} | `
                                    Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn -TableName "StaticRoutes" `
                                        -Title "Static Routes" @titleParams -autoSize -NumberFormat Text -PassThru

        $StaticRoutes | ConvertTo-Json -Depth 100 | Set-Content -Path "$jsonPath/StaticRoutes.json"

        $script:StartRow += $StaticRoutes.count + 3
    }
}

function DocumentApplianceL3FirewallRules() {
    Param(
        $Network
    )

    Write-Host "Documenting Appliance Level 3 Firewall Rules" -ForegroundColor Yellow

    $Rules = $Network | Get-MerakiApplianceL3FirewallRules
    if ($Rules) {
        $excel = $Rules | Select-Object RuleId, Comment, Policy, Protocol, @{Name="Source";Expression={$_.srcCidr}}, `
                                @{Name="Src Port";Expression={$_.srcPort}}, @{Name="Destination";Expression={$_.destCidr}}, `
                                @{Name="Dst Port";Expression={$_.destPort}}, @{Name="Syslog Enabled";Expression={$_.syslogEnabled}} `
                                | Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn -TableName "l3FirewallRules" `
                                    -Title "Level 3 Firewall Rules" @titleParams -autoSize -NumberFormat Text -PassThru

    }

    $Rules | ConvertTo-Json -Depth 10 | Set-Content -Path "$jsonPath/L3FirewallRules.json"

    $script:StartRow += $Rules.Count + 3
}

function DocumentApplianceVLANDhcp() {
    Param(
        $ApplianceVLANS
    )
    Write-Host "Documenting Appliance VLAN DHCP" -ForegroundColor Yellow

    if ($ApplianceVLANS) {
        foreach ($ApplianceVLAN in $ApplianceVLANS) { 
            $excel = $ApplianceVlan | Select-Object @{Name="ID";Expression={$_.id}}, `
                                        @{Name="VLAN Name";Expression={$_.Name}}, `
                                        @{n="DHCP Handling";e={$_.dhcpHandling}}, `
                                        @{n="Lease Time";e={$_.dhcpLeaseTime}}, `
                                        @{n="Boot Options Enabled";e={$_.dhcpBootOptionsEnabled}}, `
                                        @{n="DNS Servers";e={$_.dnsNameservers}} | `
                            Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                                -TableName "DHCP$($_.id)" -Title "VLAN $($ApplianceVLAN.Name) DHCP" @titleParams -AutoSize -NumberFormat Text -PassThru
            $script:StartRow += 4
            
            if ($ApplianceVLAN.dhcpOptions) {
                $dhcpOptions = $ApplianceVLAN | Select-Object -ExpandProperty dhcpOptions

                $excel = $dhcpOptions | Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                    -Title "$($_.name) DHCP Options" @titleParams -AutoSize -NumberFormat Text -PassThru

                $script:StartRow += $dhcpOptions.Count + 3
            }

            if ($ApplianceVLAN.reservedIpRanges) {
                $reservedIpRanges = $applianceVLAN | Select-Object -ExpandProperty reservedIPRanges
                $excel = $reservedIpRanges | Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                                -Title "$($ApplianceVLAN.name) Reserved IP Ranges" @titleParams -AutoSize -NumberFormat Text -PassThru

                $script:StartRow += $reservedIpRanges.count + 4

            }

            if ($ApplianceVLAN.fixedIpAssignments) {
                $fixedIPs = $ApplianceVLAN | Select-Object -ExpandProperty fixedIpAssignments |ForEach-Object {
                    $_.psobject.Properties | Select-Object @{n="ClientName";e={$_.value.name }},@{N="MAC";e={$_.name}}, @{N="IP";e={$_.value.ip}} 
                }

                $excel = $fixedIps | Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                                -Title "$($ApplianceVLAN.name) Fixed IP Assignments" @titleParams -AutoSize -NumberFormat Text -PassThru

                $script:StartRow += $_.fixedIpAssignments.count + 4
            }
        }
    }
}

# function DocumentSwitches() {
#     Param(
#         $switches
#     )
#     Write-Host "Documenting Switches" -ForegroundColor Yellow
#     if ($switches) {
#         $excel = $switches | Sort-Object Name | Select-Object   @{n="Name";e={$_.Name}}, `
#                                                                 @{n="Model";e={$_.Model}}, `
#                                                                 @{n="Serial";e={$_.Serial}}, `
#                                                                 @{n="LAN IP";e={$_.lanIp}} | `
#             Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $script:StartRow `
#                 -StartColumn $script:StartColumn -TableName "Switches" -Title "Switches" @titleParams -AutoSize -NumberFormat Text -PassThru

#         $script:StartRow += $switches.count + 3
#     }


# }

Function ExportSwitches() {
    Param(
        $switches
    )

    $switches | ConvertTo-Json -Depth 10 | Set-Content -Path "$jsonPath/switches.json"
}

function DocumentSwitchStacks() {
    Param(
        $Stacks,
        $switches
    )
    Write-Host "Documenting Switch Stacks" -ForegroundColor Yellow

 
    if ($stacks) {
        $StackSwitches = $switches |Where-Object {$_.Serial -in $Stacks.serials}

        $Stacks | ConvertTo-Json -Depth 100 | Set-Content -Path "$jsonPath/Stacks.json"
    
        $excel = $STackSwitches | Select-Object @{Name="StackName";Expression={
                                                $Serial = $_.serial
                                                ($Stacks.Where({$serial -in $_.Serials})).Name }}, `
                                        @{Name="Switch";Expression={$_.Name}}, Serial, Model | `
                Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                    -Title "Switch Stacks" @titleParams -AutoSize -NumberFormat Text -PassThru

        #$excel.Workbook.Worksheets[$WorkSheet].Tables["SwitchStacks"] | Set-ExcelRange -WrapText -VerticalAlignment Top -AutoSize

        $Stacks | ConvertTo-Json -Depth 10 | Set-Content -Path "$jsonPath/SwitchStacks.json"

        $script:StartRow += $StackSwitches.count + 3
            
        $StackInterfaces = $Stacks | Get-MerakiSwitchStackRoutingInterfaces

        $excel = $StackInterfaces | Select-Object   @{n="Stack";e={$_.stackName}}, `
                                                    @{n="Name";e={$_.Name}}, `
                                                    @{n="Subnet";e={$_.subnet}}, `
                                                    @{n="IP";e={$_.interfaceIp}}, `
                                                    @{n="VLAN";e={$_.vlanId}}, `
                                                    @{n="OSPF Routing";Expression={
                                                        $_.ospfSettings.psobject.Properties | ForEach-Object{
                                                            "$($_.Name) = $($_.value)"
                                                        }
                                                     }}, `
                                                     @{n="Multicast Routing";Expression={$_.multicastRouting}} | `
                Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $script:StartRow `
                    -StartColumn $script:StartColumn -TableName "StackInterfaces" -Title "Stack Interfaces" `
                        @titleParams -AutoSize -NumberFormat Text -PassThru

        $StackInterfaces | ConvertTo-Json -Depth 100 | Set-Content -Path "$jsonPath/StackInterfaces.json"
        
        $script:StartRow += $StackInterfaces.count + 3  

        $StaticRoutes = $Stacks | Get-MerakiSwitchStackRoutingStaticRoutes -networkId $Network.Id


        $excel = $StaticRoutes | Select-Object  @{n="Stack";e={$_.stack}}, `
                                                @{n="Name";e={$_.name}}, `
                                                @{n="Subnet";e={$_.subnet}}, `
                                                @{n="Next Hop IP";e={$_.nextHopIp}}, `
                                                @{n="Advertise via OSPF?";e={$_.advertiseViaOspfEnabled}}, `
                                                @{n="Preferred over OSPF routes";e={$_.preferOverOspfRoutesEnabled}} | `
                        Export-Excel -ExcelPackage $excel -WorksheetName $WorkSheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                            -TableName "StackStaticRoutes" -Title "Static Routes" @titleParams -AutoSize -NumberFormat Text -PassThru    
                            
        $script:StartRow += $StaticRoutes.count + 3

        $StaticRoutes | ConvertTo-JSON -Depth 10 | Set-Content -Path "$jsonPath/StaticRoutes.json"
                            
        $interfaceDHCP = $StackInterfaces | Get-MerakiSwitchStackRoutingInterfaceDHCP
        $x=0
        $interfaceDHCP | Where-Object {$_.dhcpMode -eq 'dhcpServer'} | ForEach-Object {
            $tableName = ("dhcp{0}" -f $x).tostring()
            $excel = $_ | Select-Object @{n="Interface Name";e={$_.interfaceName}}, `
                                        @{n="DHCP Mode";e={$_.dhcpMode}}, `
                                        @{n="DNS Name Servers";e={$_.dnsNameServersOption}}, `
                                        @{n="Custom Name Servers";e={$_.dnsCustomNameServers -join ", "}}, `
                                        @{n="Boot Options Enabled";e={$_.bootOptionsEnabled}}, `
                                        @{n="Boot Next Server"; e={$_.bootNextServer}}, `
                                        @{n="Boot Filename";e={$_.bootFileName}} | `
                        Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                            -TableName $tableName -Title "Interface DHCP" @titleParams -AutoSize -NumberFormat Text -PassThru
            $script:startRow += 5

            if ($_.dhcpMode -eq 'dhcpServer') {
                $x += 1
                $tableName = ("intRIPS{0}" -f $x).toString()
                if ($_.reservedIpRanges -is [array] -and $_.reservedIpRanges.length -gt 0) {
                    $excel = $_.reservedIpRanges | Select-Object Start, End, Comment | `
                        Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                            -TableName $tableName -Title "Reserved IP Ranges" @titleParams -AutoSize -NumberFormat Text -PassThru
                    $script:startRow += $_.reservedIpRanges.Length + 3
                }

                $tableName = ("intFIPA{0}" -f $x).ToString()

                if ($_.fixedIpAssignments) {
                    $excel = $_.fixedIpAssignments.PSObject.Properties | Select-Object @{n="Client Name";e={($_.value).Name}}, `
                                                                                        @{n="MAC Address";e={$_.Name}}, `
                                                                                        @{n="IP Address";e={($_.value).ip}} |
                        Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                            -TableName $tableName -Title "Fixed IP Assignments" @titleParams -AutoSize -NumberFormat Text -PassThru
                    
                    $script:StartRow += $_.fixedIpAssignments.length + 3
                }
            }
        }            
    }
}

function DocumentNonStackSwitches() {
    Param(
        $switches,
        $Stacks
    )

    Write-Host "Documenting Non-Stack Switches" -ForegroundColor Yellow
    #Gather any switches that are not part of stacks
    $nonStackSwitches = $Switches | Where-Object {$_.Serial -notin $Stacks.serials}

    #write non stack switch table here.
    
    if ($NonStackSwitches) {
        $excel = $nonStackSwitches | Select-Object @{N="Switch Name";Expression={$_.Name}}, Serial, @{Name="LAN IP";Expression={$_.LanIp}}, Firmware | `
                    Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                        -Title "Stand Alone Switches" @titleParams -AutoSize -NumberFormat Text -PassThru
                    
        $script:StartRow += $nonStackSwitches.count +4

        $NonStackSwitchInterfaces = $nonStackSwitches | Get-MerakiSwitchRoutingInterfaces 
        if ($NonStackSwitchInterfaces) {
            $excel = $NonStackSwitchInterfaces | Sort-Object -Property switchName | `
                Select-Object @{Name="Switch";Expression={$_.switchName}}, @{Name="VLAN";Expression={$_.vlanid}}, `
                                Name, Subnet, @{Name="IP";Expression={$_.interfaceIp}}, `
                                @{Name="OSPF Routing";Expression={$_.ospfSettings.area}}, @{Name="Multicast Routing";Expression={$_.multicastRouting}} | `
                            Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                                -TableName "NonStackInterfaces" -Title "Stand Alone Switch Interfaces" @titleParams -AutoSize -NumberFormat Text -PassThru
        

            $NonStackSwitchInterfaces | ConvertTo-Json -Depth 10 | Set-Content "$jsonPath/nonStackSwitchInterfaces.json"
            $script:StartRow += $NonStackSwitchInterfaces.Count + 4
        }

        $StaticRoutes = $nonStackSwitches | Get-MerakiSwitchRoutingStaticRoutes
        
        if ($StaticRoutes) {
            $excel = $StaticRoutes | Select-Object  @{n="Switch";e={$_.switch}}, `
                                                    @{n="Name";e={$_.name}}, `
                                                    @{n="Subnet";e={$_.subnet}}, `
                                                    @{n="Next Hop";e={$_.nextHopIp}}, `
                                                    @{Name="Advertize via OSPF";Expression={$_.advertiseViaOspfEnabled}}, `
                                                    @{Name="Prefer over OSPF Routes";Expression={$_.preferOverOspfRoutesEnabled}} | `
                                        Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                                            -TableName "nonStStaticRoutes" -Title "Non-Stack Static Routes" @titleParams -AutoSize `
                                            -NumberFormat Text -PassThru

            $script:StartRow += $StaticRoutes.Count + 4

            $StaticRoutes | ConvertTo-Json -Depth 100 | Set-Content "$jsonPath/switchStaticRoutes.json"
        }

        #DHCP setting per interface
        if ($nonStackSwitchInterfaces) {
            foreach ($nonStackSwitchInterface in $nonStackSwitchInterfaces) {
                $InterfaceDHCP = $NonStackSwitchInterface | Get-MerakiSwitchRoutingInterfaceDHCP
                if ($InterfaceDHCP) {
                    $excel = $InterfaceDHCP | Select-Object @{Name="Switch";Expression={$_.switchName}}, `
                                                            @{Name="Name";Expression={$_.InterfaceName}}, `
                                                            @{Name = "DHCP Mode";Expression={$_.dhcpMode}}, `
                                                            @{Name="Lease Time";Expression={$_.dhcpLeaseTime}}, `
                                                            @{Name="Name Server Option";Expression={$_.dnsNameserversOption}}, `
                                                            @{Name="Custom Name Servers";Expression={$_.dnsCustomNameservers}}, `
                                                            @{Name="Boot Options Enabled";Expression={$_.bootOptionsEnabled}} | `
                                                Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                                                            -Title "Non-Stack Interface DHCP" @titleParams -AutoSize `
                                                            -NumberFormat Text -PassThru
                        $script:StartRow += $InterfaceDHCP.Count + 4

                    if ($InterfaceDHCP.$bootOptions) {                                                        
                        $bootOptions = $InterfaceDHCP | Select-Object -ExpandProperty dhcpOptions
                        $excel = $bootOptions | Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                                                    -Title "Interface DHCP Boot Options" @titleParams -AutoSize `
                                                    -NumberFormat Text -PassThru
                        $script:StartRow += $bootOptions.count + 4
                    }


                    If ($interfaceDHCP.reservedIpRanges) {
                        $reservedIpRanges = $InterfaceDHCP | Select-Object -ExpandProperty reservedIPRanges
                        $excel = $reservedIpRanges | Select-Object @{Name="Start";Expression={$_.Start}}, `
                                                                @{Name="End";Expression={$_.End}}, `
                                                                @{Name="Comment";Expression={$_.comment}} | `
                                                        Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                                                            -Title "Interface DHCP Reserved IP Ranges" @titleParams -AutoSize `
                                                            -NumberFormat Text -PassThru          
                        $script:StartRow += $reservedIpRanges.Count + 4
                    }
                
                    if ($InterfaceDHCP.fixedIpAssignments) {
                        $fixedIpAssignments = $InterfaceDHCP | Select-Object -ExpandProperty fixedIpAssignments
                        
                        $excel = $fixedIpAssignments.PSObject.Properties | Select-Object @{Name="Name";Expression={$_.fixedIpAssignments.name}}, `
                                                                                        @{Name="MAC";Expression={$_.fixedIpAssignments.mac}}, `
                                                                                        @{Name="IP";Expression={$_.fixedIpAssignments.ip}} |`
                                                                Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                                                                    -Title "Interface DHCP Fixed IP Assignments" @titleParams -AutoSize `
                                                                    -NumberFormat Text -PassThru  
                        $script:StartRow += $fixedIpAssignments.Count + 4
                    }
                    $InterfaceDHCP | ConvertTo-Json -Depth 20 | Set-Content -Path "$jsonPath/InterfaceDHCP.json"
                }
            }
        }
    }   
}

function DocumentSwitchLAGs() {
    Write-Host "Documenting Switch LAGS" -ForegroundColor Yellow
    $Lags = $Network | Get-MerakiNetworkSwitchLAG
    If ($Lags) {
        $excel = $Lags | Select-Object  @{Name="Lag Number";Expression={$_.lagNumber}}, `
                                        Switch, Port, @{Name="Name";Expression={$_.portName}} | `
                            Export-Excel -ExcelPackage $excel -WorkSheetName $Worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                                -TableName "LinkAggregations" -Title "Link Aggregations" @titleParams -AutoSize -NumberFormat Text -PassThru
        $script:StartRow += $Lags.Count + 3
    }
    $Lags | ConvertTo-Json -Depth 100| Set-Content "$jsonPath/LAGS.json"
}

function DocumentSwitchPorts() {
    Param(
        $switches
    )
    Write-Host "Documenting Switch Ports" -ForegroundColor Yellow
    if ($Switches) {
        $ports = $switches | Get-MerakiSwitchPorts
        If ($ports) {
            $excel = $ports | Sort-Object switch | Select-Object Switch, Name, @{n="Port";e={$_.PortId}}, @{n="VLAN";e={$_.vlan}},@{n="Voice VLAN";e={$_.voiceVlan}} | `
                    Export-Excel -ExcelPackage $excel -WorkSheetName $WorkSheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                        -TableName "Ports" -Title "Switch Ports" @titleParams -AutoSize -NumberFormat Text -PassThru
        }
        $ports | ConvertTo-Json -Depth 100 | Set-Content "$jsonPath/switchPorts.json"
        $script:StartRow += $ports.count + 3
    }
}

function DocumentAccessPoints() {
    Param(
        $AccessPoints
    )
    Write-Host "Documenting Access Points" -ForegroundColor Yellow
    if ($AccessPoints) {
        $excel = $AccessPoints | Sort-Object Name | Select-Object   @{n="Name";e={$_.Name}}, `
                                                                    @{n="Model";e={$_.Model}}, `
                                                                    @{n="Serial";e={$_.Serial}}, `
                                                                    @{n="LAN IP";e={$_.lanIp}} | `
                    Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $script:StartRow `
                        -StartColumn $script:StartColumn -TableName "AccessPoints" -Title "Access Points" @titleParams -AutoSize -NumberFormat Text -PassThru

        $AccessPoints | ConvertTo-JSON -Depth 100| Set-Content "$jsonPath/AccessPoints.json"

        $script:StartRow += $AccessPoints.count + 3

        $SSIDs = $Network | Get-MerakiSSIDs
        if ($SSIDs) {
            $excel = $SSIDs | Select-Object @{n="Name";e={$_name}}, `
                                            @{n="SSID Number";e={$_.number}}, `
                                            @{n="Status";e={if($_.enabled){"Enabled"}else{"Disabled"}}}, `
                                            @{n="Splash Page";e={$_.splashPage}}, `
                                            @{n="SSID Admin Accessible";e={$_.ssidAdminAccessible}}, `
                                            @{n="Authentication Mode";e={$_.authMode}}, `
                                            @{n="Encryption Mode";e={$_.encryptionMode}}, `
                                            @{n="WPA Encryption Mode";e={$_.wpaEncryptionMode}}, `
                                            @{n="Radius Accounting Enabled";e={$_.radiusAccountingEnabled}}, `
                                            @{n="Radius Enabled";e={$_.radiusEnabled}}, `
                                            @{n="Radius Attribute For Group Policies";e={$_.radiusAttributeForGroupPolicies}}, `
                                            @{n="Radius Failover Policy";e={$_.radiusFailoverPolicy}}, `
                                            @{n="Radius Load Balancing Policy";e={$_.radiusLoadBalancingPolicy}}, `
                                            @{n="IP Assignment Mode";e={$_.ipAssignmentMode}}, `
                                            @{n="Use VLAN Tagging";e={$_.useVlanTagging}}, `
                                            @{n="Radius Override";e={$_.useRadiusOverride}}, `
                                            @{n="Minimum Bitrate";e={$_.minBitrate}},  `
                                            @{n="Band Selection";e={$_.bandSelection}}, `
                                            @{n="Per Client Bandwidth Limit Up";e={$_.perClientBandwidthLimitUp}}, `
                                            @{n="Per Client Bandwidth Limit Down";e={$_.perClientBandwidthLimitDown}},
                                            @{n="Visible";e={$_.visible}}, `
                                            @{n="Available On All Aps";e={$_.availableOnAllAps}}, `
                                            @{n="Availability Tags";e={$_.availabilityTags}}, `
                                            @{n="Per SSID Bandwidth Limit Up";e={$_.perSsidBandwidthLimitUp}}, `
                                            @{n="Per SSID Bandwidth Limit Down";e={$_.perSsidBandwidthLimitDown}}, `
                                            @{n="Mandatory DHCP Enabled";e={$_.mandatoryDhcpEnabled}} | `
                Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $script:StartRow -StartColumn $script:StartColumn `
                    -TableName "SSIDS" -Title "SSIDs" @titleParams -AutoSize -NumberFormat Text -PassThru
            $SSIDs | ConvertTo-Json -Depth 100| Set-Content "$jsonPath/SSIDs.json"
        }
    }    
}

If (-not $ExcludeAppliances) {
    DocumentAppliances $Appliances
    DocumentUplinks $Network
    DocumentApplianceVLANs $ApplianceVLANS
    DocumentAppliancePorts $Network
    DocumentApplianceStaticRoutes $Network
    DocumentApplianceL3FirewallRules $Network
    DocumentApplianceVLANDhcp  $ApplianceVLANS
}
if (-not $ExcludeSwitches) {
    ExportSwitches $switches
    DocumentSwitchStacks -Stacks $stacks -switches $Switches
    DocumentNonStackSwitches -switches $switches -stacks $stacks
    DocumentSwitchLags $network                   
    DocumentSwitchPorts  $switches 
}
If (-not $ExcludeAccessPoints) {
    DocumentAccessPoints $AccessPoints
}

$Global:WarningPreference = $savedWarningPreferrence

if ($IsWindows) {
    Close-ExcelPackage $excel -Show                        
} else {
    Close-ExcelPackage $excel        
    $msg = "Open {0} in yur preferred spreadsheet application." -f $document
    Write-Host $msg
    Write-Host "LibreOffice calc will lose most of the formatting."
    Write-Host "WPS Office Spreadsheet will retain all the formatting"
}
