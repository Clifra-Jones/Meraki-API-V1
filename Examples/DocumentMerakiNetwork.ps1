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
#       Description:    Folder to outpur the documentation. 2 folders are created underneath this folder, doc and json.
#                       The doc folder will contain a file called doc.xlsx. The jason filder will contain json files for each
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
    [string]$OutputFolder
)
$ErrorActionPreference = "Break"

Import-Module Meraki-API-V1
Import-Module ImportExcel
#$OutputFolder = Resolve-Path $OutputFolder

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
$document = Join-Path -Path $docPath -ChildPath "doc.xlsx"

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

$Worksheet = "Network"
$StartRow = 1
$StartColumn = 1
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
                            -StartRow $StartRow -StartColumn $StartColumn -Title "Network" @titleParams `
                            -AutoSize -NumberFormat Text -Passthru

$Network | ConvertTo-Json | Set-Content -Path "$jsonPath/network.json"             

$StartRow += ($networkProps | Select-Object Name).length + 3

$Devices = $Network | Get-MerakiNetworkDevices            
$Stacks = $Network | Get-MerakiNetworkSwitchStacks
$Appliances = $Devices |Where-Object {$_.Model -Like "MX*"}
$Switches = $Devices | Where-Object {$_.Model -like "MS*"}
$AccessPoints = $Devices | Where-Object {$_.Model -like "MR*"}
$ApplianceVLANS = $Network | Get-MerakiNetworkApplianceVLANS

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
                    -StartRow $StartRow -StartColumn $StartColumn -Title "Appliances" @titleParams -autoSize `
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
                                Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $startrow -StartColumn $StartColumn `
                                    -TableName "Uplinks" -Title "Appliance Uplinks" @titleParams -AutoSize -Numberformat text -PassThru
                                    $StartRow += $Uplinks.Count + 3
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
        $excel = $ApplianceVLANS | Select-Object Name, @{n="Appliance IP";e={$_.applianceIp}}, @{n="Subnet";e={$_.subnet}} | `
                                        Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -TableName "ApplianceVLANS" `
                                            -Startrow $StartRow -StartColumn $StartColumn -title "ApplianceVLANS" @titleParams -AutoSize -NumberFormat Text -passthru


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
        $excel = $AppliancePorts | Select-Object    @{n="Port Number";e={$_.number}}, `
                                                    @{n="Status";e={if ($_.enabled) {"Enabled"} Else {"Disabled"}}}, `
                                                    @{n="Type";e={$_.type}}, `
                                                    @{n="Drop Untagged Traffic";e={$_.dropUntaggedTraffic}}, `
                                                    @{n="VLAN";e={$vn=$_.vlan; $vlans.where({$_.Vlan -eq $vn}).name}} | `
                                    Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -TableName "AppliancePorts" `
                                        -StartRow $StartRow -StartColumn $StartColumn -Title "Per-port VLAN Settings" @titleParams -AutoSize -Numberformat Text -PassThru

        $AppliancePorts | ConvertTo-Json -Depth 100 | Set-Content -Path "$jsonPath/AppliancePorts.json"                            
                                    
        $script:StartRow += $AppliancePorts.Count + 3
    }

}

function DocumentApplianceStaticRoutes() {
    Write-Host "Documenting Appliance Statis Routes" -ForegroundColor Yellow
    $StaticRoutes = $Network | Get-MerakiNetworkApplianceStaticRoutes

    if ($StaticRoutes) {
        $excel = $StaticRoutes | Select-Object Enabled, Name, Subnet, @{n="GAteway IP";e={$_.gatewayIp}} | `
                                    Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $StartRow -StartColumn $StartColumn -TableName "StaticRoutes" `
                                        -Title "Static Routes" @titleParams -autoSize -NumberFormat Text -PassThru

        $StaticRoutes | ConvertTo-Json -Depth 100 | Set-Content -Path "$jsonPath/StaticRoutes.json"

        $script:StartRow += $StaticRoutes.count + 3
    }
}

function DocumentApplianceVLANDhcp() {
    Param(
        $ApplianceVLANS
    )
    Write-Host "Documenting Appliance VLANS" -ForegroundColor Yellow

    if ($ApplianceVLANS) {
        $ApplianceVLANS | ForEach-Object {
            $excel = $_ | Select-Object @{n="VLAN ID";e={$_.id}}, Subnet, `
                                        @{n="DHCP Handling";e={$_.dhcpHandling}}, `
                                        @{n="Lease Time";e={$_.dhcpLeaseTime}}, `
                                        @{n="Boot Options Enabled";e={$_.dhcpBootOPtionsEnabled}}, `
                                        @{n="DHCP Options";e={$_.dhcpOptions}} | `
                            Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $StartRow -StartColumn $StartColumn `
                                -TableName "DHCP$($_.id)" -Title "VLAN $($_.id) DHCP" @titleParams -AutoSize -Numberformat Text -PassThru
            $script:StartRow += $_.count + 3


            if ($_.reservedIpRanges -is [array] -and $_.reservedIpRanges.length -gt 0) {
                $excel = $_.reservedIpRanges | Select-Object    @{n="Start";e={$_.start}}, `
                                                                @{n="End";e={$_.end}}, `
                                                                @{n="Comment";e={$_.comment}} | `
                        Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $StartRow -StartColumn $StartColumn `
                                -TableName "RIPR$($_.Id)" -Title "Reserved IP Ranges" @titleParams -AutoSize -NumberFormat Text -PassThru

                $script:StartRow += $_.reservedIpRanges.count + 3
            }

            if ($_.fixedIpAssignments -is [array] -and $_.fixedIpAssignments.length -gt 0) {
                $excel = $_.fixedIpAssignments.PSObject.Properties | Select-Object @{n="Client Name";e={($_.value).Name}}, `
                                                                                    @{n="MAC Address";e={$_.Name}}, `
                                                                                    @{n="LAN IP";e={($_.value).ip}} | `
                        Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $StartRow -StartColumn $StartColumn `
                            -TableName "FIPA$($_.Id)" -Title "Reserved IP Ranges" @titleParams -AutoSize -NumberFormat Text -PassThru
                $script:StartRow += $_.fixedIpAssignments.count + 3
            }
        }
    }
}

function DocumentSwitches() {
    Param(
        $switches
    )
    Write-Host "Documenting Switches" -ForegroundColor Yellow
    if ($switches) {
        $excel = $switches | Sort-Object Name | Select-Object   @{n="Name";e={$_.Name}}, `
                                                                @{n="Model";e={$_.Model}}, `
                                                                @{n="Serial";e={$_.Serial}}, `
                                                                @{n="LAN IP";e={$_.lanIp}} | `
            Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $StartRow `
                -StartColumn $StartColumn -TableName "Switches" -Title "Switches" @titleParams -AutoSize -Numberformat Text -PassThru

        $script:StartRow += $switches.count + 3
    }


}

function DocumentSwitchStacks() {
    Param(
        $Stacks
    )
    Write-Host "Documenting Switch Stacks" -ForegroundColor Yellow

    if ($stacks) {
        $Stacks | ConvertTo-Json -Depth 100 | Set-Content -Path "$jsonPath/Stacks.json"
        $switchStacks = @()
        foreach ($Stack in $Stacks) {
            $StackMembers = ''
            $stack.serials | foreach-Object {
                $device = Get-MerakiDevice $_
                $StackMembers += "{0}`r`n" -f $device.Name
            }
            $swStack = [PSCustomObject]@{
                StackName = $Stack.Name
                StackMembers = $StackMembers
            }   
            $switchStacks += $swStack
        }

        $excel = $switchStacks | Select-Object @{n="Stack Name";e={$_.StackName}}, @{n="Stack Members";e={$_.StackMembers}} | `
                Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $StartRow -StartColumn $StartColumn `
                    -TableName "SwitchStacks" -Title "Switch Stacks" @titleParams -AutoSize -Numberformat Text -PassThru
        $excel.Workbook.Worksheets[$WorkSheet].Tables["SwitchStacks"] | Set-ExcelRange -WrapText -VerticalAlignment Top -AutoSize

        $script:StartRow += $switchStacks.count + 3
            
        $Stackinterfaces = @()
        foreach ($stack in $Stacks) {
            $interfaces = Get-MerakiSwitchStackRoutingInterfaces -networkId $Network.Id -Id $stack.Id
            If ($interfaces) {
                $Interfaces | foreach-Object {
                    $_ | Add-Member -MemberType:NoteProperty -Name "StackId" -Value $stack.Id
                    $_ | Add-Member -MemberType:NoteProperty -Name "StackName" -Value $stack.Name
                }
                $Stackinterfaces += $Interfaces
            }
        }

        $excel = $Stackinterfaces | Select-Object   @{n="Switch/Stack";e={$_.StackName}}, `
                                                    @{n="Name";e={$_.Name}}, `
                                                    @{n="Subnet";e={$_.subnet}}, `
                                                    @{n="IP";e={$_.interfaceIp}}, `
                                                    @{n="VLAN";e={$_.vlanId}}, `
                                                    @{n="Default Gateway";e={$_.defaultGateway}} | `
                Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $StartRow `
                    -StartColumn $StartColumn -TableName "StackInterfaces" -Title "Stack Interfaces" `
                        @titleParams -AutoSize -Numberformat Text -Passthru

        $Stackinterfaces | ConvertTo-Json -Depth 100 | Set-Content -Path "$jsonPath/StackInterfaces.json"
        
        $script:StartRow += $Stackinterfaces.count + 3  

        $StaticRoutes = $Stacks | Get-MerakiSwitchStackRoutingStaticRoutes -networkId $Network.Id


        $excel = $StaticRoutes | Select-Object  @{n="Stack";e={$_.stack}}, `
                                                @{n="Name";e={$_.name}}, `
                                                @{n="Subnet";e={$_.subnet}}, `
                                                @{n="Next Hop IP";e={$_.nextHopIp}}, `
                                                @{n="Advertise via OSPF?";e={$_.advertiseViaOspfEnabled}}, `
                                                @{n="Preferred ocer OSPF routes";e={$_.preferOverOspfRoutesEnabled}} | `
                        Export-Excel -ExcelPackage $excel -WorksheetName $WorkSheet -Startrow $StartRow -StartColumn $StartColumn `
                            -TableName "StackStaticRoutes" -Title "Static Routes" @titleParams -AutoSize -NumberFormat Text -PassThru    
                            
        $script:StartRow += $StaticRoutes.count + 3
                            
        $interfaceDHCP = $Stacks |ForEach-Object {Get-MerakiSwitchStackRoutingInterfacesDHCP -networkId $network.ID -id $_.Id} 
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
                        Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $StartRow -StartColumn $StartColumn `
                            -TableName $tableName -Title "Interface DHCP" @titleParams -AutoSize -NumberFormat Text -PassThru
            $script:startRow += 5

            if ($_.dhcpMode -eq 'dhcpServer') {
                $x += 1
                $tableName = ("intRIPS{0}" -f $x).toString()
                if ($_.reservedIpRanges -is [array] -and $_.reservedIpRanges.length -gt 0) {
                    $excel = $_.reservedIpRanges | Select-Object Start, End, Comment | `
                        Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $StartRow -StartColumn $StartColumn `
                            -TableName $tableName -Title "Reserved IP Ranges" @titleParams -AutoSize -Numberformat Text -PassThru
                    $script:startRow += $_.reservedIpRanges.Length + 3
                }
                $tableName = ("intFIPA{0}" -f $x).ToString()
                if ($_.fixedIpAssignments -is [array] -and $_.fixedIpAssignments.Length -gt 0) {
                    $excel = $_.fixedIpAssignments.PSObject.Properties | Select-Object @{n="Client Name";e={($_.value).Name}}, `
                                                                                        @{n="MAC Address";e={$_.Name}}, `
                                                                                        @{n="IP Address";e={($_.value).ip}} |
                        Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $StartRow -StartColumn $StartColumn `
                            -TableName $tableName -Title "Fixed IP Assignments" @titleParams -AutoSize -Numberformat Text -PassThru
                    
                    $script:StartRow += $_.fixedIpAssignments.length + 3
                }
            }
        }
        
        $interfaceDHCP | Set-Content -Path "$jsonPath/StackInterfaceDHCP.json"
    }
}


function DocumentNonStackSwitches() {
    Param(
        $switches,
        $Stacks
    )
    Write-Host "Documenting Non-Statck Switches" -ForegroundColor Yellow
    #Gather any switches that are not part of stacks
    $nonStackSwitches = @()
    $found = $false
    If ($Stacks) {
        $Switches | foreach-Object {
            foreach ($Stack in $Stacks) {
                if ($stack.serials -contains $_.serial) {
                    $found = $true
                }            
            }
            If (-not $found) {
                $nonStackSwitches += $_
            }
        }
    } else {
        $nonStackSwitches = $switches
    }
    #Non-Stack Switches
    $nonStackSwitchInterfaces = @()
    if ($nonStackSwitches) {
        foreach($switch in $nonStackSwitches) {            
            $interfaces = Get-MerakiSwitchRoutingInterfaces -serial $switch.serial
            if ($interfaces) {
                $interfaces | ForEach-Object {
                    $_ | Add-Member -MemberType:NoteProperty -Name "serial" -value $switch.serial
                    $_ | Add-Member -MemberType:NoteProperty -Name "switchName" -value $Switch.Name
                }
                $nonStackSwitchInterfaces += $interfaces
            }
        }

        if ($nonStackSwitchInterfaces.count -gt 0) {
                $excel = $nonStackSwitchInterfaces | Select-Object  @{n="Switch";e={$_.switchName}}, `
                                                                    @{n="Name";e={$_.name}}, `
                                                                    @{n="Subnet";e={$_.subnet}}, `
                                                                    @{n="Interface IP";e={$_.interfaceIp}}, `
                                                                    @{n="VLAN ID";e={$_.vlanId}}, `
                                                                    @{n="Default Gateway";e={$_.defaultGateway}} | `
                                            Export-Excel -ExcelPackage $excel -WorkSheetName $WorkSheet -StartRow $startRow -StartColumn $StartColumn `
                                                -TableName "nonStInterfaces" -Title "Non-Stack Interfaces" @titleParams -AutoSize -NumberFormat Text -PassThru
                $script:StartRow += $nonStackSwitchInterfaces.count + 1
                $nonStackSwitches | ConvertTo-Json -Depth 100 | Set-Content "$jsonPath/SwitchInterfaces.json"
        }
        $StaticRoutes = $nonStackSwitches | Get-MerakiSwitchRoutingStaticRoutes
        
        if ($StaticRoutes) {
            $excel = $StaticRoutes | Select-Object  @{n="Switch";e={$_.switch}}, `
                                                    @{n="Name";e={$_.name}}, `
                                                    @{n="Subnet";e={$_.subnet}}, `
                                                    @{n="Interface IP";e={$_.intrfaceIp}}, `
                                                    @{n="VLAN ID";e={$_.vlanId}}, `
                                                    @{n="Default Gateway";e={$_.defaultGateway}} | `
                                        Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $StartRow -StartColumn $StartColumn `
                                            -TableName "nonStStaticRoutes" -Title "Non-Stack Static Routes" @titleParams -AutoSize -NumberFormat Text -PassThru

            $script:StartRow += $StaticRoutes.Count + 3

            $StaticRoutes | ConvertTo-Json -Depth 100 | Set-Content "$jsonPath/switchStaticRoutes.json"
        }

        if ($nonStackSwitchInterfaces) {
            $interfaceDHCP = $nonStackSwitchInterfaces  | foreach-Object {Get-MerakiSwitchStackRoutingInterfacesDHCP -serial $_.serial -interfaceId $_.interfaceId}
            $x=0
            $interfaceDHCP | Where-Object {$_.dhcpMode -eq 'dhcpServer'} | foreach-Object {
                $tableName = ("nsdhcp{0}" -f $x).toString()
                $excel = $_ | Select-Object @{n="Interface Name";e={$_.interfaceName}}, `
                                            @{n="DHCP Mode";e={$_.dhcpMode}}, `
                                            @{n="DNS Name Servers";e={$_.dnsCustomNameServers}}, `
                                            @{n="Boot Options Enabled";e={$_.bootOptionsEnabled}}, `
                                            @{n="Boot Next Server";e={$_.bootNextServer}}, `
                                            @{n="Boot Filename";e={$_.bootFileName}} | `
                            Export-Excel -ExcelPackage $excel -WorksheetName $WorkSheet -StartRow $StartRow -StartColumn $StartColumn `
                                -TableName $TableName -Title "Interface DHCP" @TableParams -AutoSize -Numberformat Text -PassThru
                $script:StartRow += 4
                
                if ($_.reservedIpRanges -is [array] -and $_.reservedIpRanges.length -gt 0) {
                    $tableName = ("intRIPS{0}" -f $x).ToString()
                    $excel = $_.reservedIpRanges | Select-Object Start, End, Commect | `
                        Export-Excel -ExcelPackage $Excel -WorksheetName $worksheet -StartRow $StartRow -StartColumn $StartColumn `
                            -TableName $tableName -title "Reserved IP Ranges" @titleParams -AutoSize -Numberformat Text -PassThru                    
                    $script:StartRow = $_.reservedIpRanges.length + 3
                }
            }
        }
        If ($nonStackSwitchInterfaces) {
            $excel = $nonStackSwitchInterfaces | Select-Object  @{n="Switch";e={$_.switchName}}, `
                                                                @{n="Name";e={$_.name}}, `
                                                                @{n="Subnet";e={$_.subnet}}, `
                                                                @{n="Interface IP";e={$_.interfaceIp}}, `
                                                                @{n="VLAN ID";e={$_.vlanId}}, `
                                                                @{n="Default Gateway";e={$_.defaultGateway}} | `
                                        Export-Excel -ExcelPackage $excel -WorkSheetName $WorkSheet -StartRow $startRow -StartColumn $StartColumn `
                                            -TableName "nonStInterfaces" -Title "Non-Stack Interfaces" @titleParams -AutoSize -NumberFormat Text -PassThru
            $script:StartRow += $nonStackSwitchInterfaces.count + 3
            $nonStackSwitches | ConvertTo-Json -Depth 100 | Set-Content "$outputFolder\JSON\SwitchInterfaces.json"

            $StaticRoutes = $nonStackSwitches | Get-MerakiSwitchRoutingStaticRoutes            

            $excel = $StaticRoutes | Select-Object  @{n="Switch";e={$_.switch}}, `
                                                    @{n="Name";e={$_.name}}, `
                                                    @{n="Subnet";e={$_.subnet}}, `
                                                    @{n="Interface IP";e={$_.intrfaceIp}}, `
                                                    @{n="VLAN ID";e={$_.vlanId}}, `
                                                    @{n="Default Gateway";e={$_.defaultGateway}} | `
                                        Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $StartRow -StartColumn $StartColumn `
                                            -TableName "nonStStaticRoutes" -Title "Non-Stack Static Routes" @titleParams -AutoSize -NumberFormat Text -PassThru

            $script:StartRow += $StaticRoutes.Count + 3

            $StaticRoutes | ConvertTo-Json -Depth 100 | Set-Content "$outputFolder\JSON\switchStaticRoutes.json"

            $interfaceDHCP = $nonStackSwitchInterfaces  | foreach-Object {Get-MerakiSwitchRoutingInterfaceDHCP -serial $_.serial -interfaceId $_.interfaceId}
            $x=0
            $interfaceDHCP | Where-Object {$_.dhcpMode -eq 'shcpServer'} | foreach-Object {
                $tableName = ("nsdhcp{0}" -f $x).toString()
                $excel = $_ | Select-Object @{n="Interface Name";e={$_.interfaceName}}, `
                                            @{n="DHCP Mode";e={$_.dhcpMode}}, `
                                            @{n="DNS Name Servers";e={$_.dnsCustomNameServers}}, `
                                            @{n="Boot Options Enabled";e={$_.bootOptionsEnabled}}, `
                                            @{n="Boot Next Server";e={$_.bootNextServer}}, `
                                            @{n="Boot Filename";e={$_.bootFileName}} | `
                            Export-Excel -ExcelPackage $excel -WorksheetName $WorkSheet -StartRow $StartRow -StartColumn $StartColumn `
                                -TableName $TableName -Title "Interface DHCP" @TableParams -AutoSize -Numberformat Text -PassThru
                $script:StartRow += 4
                
                if ($_.reservedIpRanges -is [array] -and $_.reservedIpRanges.length -gt 0) {
                    $tableName = ("intRIPS{0}" -f $x).ToString()
                    $excel = $_.reservedIpRanges | Select-Object Start, End, Commect | `
                        Export-Excel -ExcelPackage $Excel -WorksheetName $worksheet -StartRow $StartRow -StartColumn $StartColumn `
                            -TableName $tableName -title "Reserved IP Ranges" @titleParams -AutoSize -Numberformat Text -PassThru                    
                    $script:StartRow = $_.reservedIpRanges.length + 3
                }
                if ($_.fixedIpAssignments -is [array] -and $_.fixedIpAssignments.Length -gt 0) {
                    $tableName = ("intFIPA{0}" -f $x).ToString()
                    $excel = $_.fixedIpAssignments.PSObject.Properties | Select-Object  @{n="Client Name";e={($_.value).Name}}, `
                                                                                        @{n="MAC Address";e={$_.Name}} `
                                                                                        @{n="IP Address";e={($_.value).ip}} | `
                        Export-Excel -ExcelPackage $excel -WorksheetName $Worksheet -StartRow $StartRow -StartColumn $StartColumn `
                            -TableName $TableName -Title "Fixed IP Assignments" @titleParams -AutoSize -Numberformat Text -PassThru
                    $script:StartRow += $_.fixedIpAssignments.length + 3
                }
                $interfaceDHCP | ConvertTo-Json -Depth 100 | Set-Content "$outputFolder\JSON\switchInterfaceDhcp.json"
            }
            $interfaceDHCP | ConvertTo-Json -Depth 100 | Set-Content "$jsonPath/switchInterfaceDhcp.json"
        }
    }
}

function DocumentSwitchLAGs() {
    Write-Host "Documenting Switch LAGS" -ForegroundColor Yellow
    $Lags = $Network | Get-MerakiNetworkSwitchLAG
    If ($Lags) {
        $excel = $Lags | Select-Object  @{n="Lag Number";e={$_.lagNumber}}, `
                                        Switch, Port, @{N="Name";e={$_.portName}} | `
                            Export-Excel -ExcelPackage $excel -WorkSheetName $Worksheet -StartRow $StartRow -StartColumn $StartColumn `
                                -TableName "LinkAggregations" -Title "Link Aggregations" -AutoSize -NumberFormat Text -PassThru
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
                    Export-Excel -ExcelPackage $excel -WorkSheetName $WorkSheet -StartRow $StartRow -StartColumn $StartColumn `
                        -TableName "Ports" -Title "Switch Ports" @titleParams -Autosize -NumberFormat Text -PassThru
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
                    Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -StartRow $StartRow `
                        -StartColumn $StartColumn -TableName "AccessPoints" -Title "Access Points" @titleParams -AutoSize -Numberformat Text -PassThru

        $AccessPoints | ConvertTo-JSON -Depth 100| Set-Content "$jsonPath/AccessPoints.json"

        $script:StartRow += $AccessPoints.count + 3

        $SSIDs = $Network | Get-MerakiSSIDs
        if ($SSIDs) {
            $excel = $SSIDs | Select-Object @{n="Name";e={$_name}}, `
                                            @{n="SSID Number";e={$_.number}}, `
                                            @{n="Status";e={if($_.enabled){"Enabled"}else{"Disabled"}}}, `
                                            @{n="Splash Page";e={$_.splashPage}}, `
                                            @{n="SSID Admin Accessible";e={$_.ssidAdminAccessible}}, `
                                            @{n="Authication Mode";e={$_.authMode}}, `
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
                Export-Excel -ExcelPackage $excel -WorksheetName $worksheet -Startrow $StartRow -StartColumn $StartColumn `
                    -TableName "SSIDS" -Title "SSIDs" @titleParams -AutoSize -NumberFormat Text -PassThru
            $SSIDs | ConvertTo-Json -Depth 100| Set-Content "$jsonPath/SSIDs.json"
        }
    }    
}

DocumentAppliances $Appliances
DocumentUplinks $Network
DocumentApplianceVLANs $ApplianceVLANS
DocumentAppliancePorts $Network
DocumentApplianceStaticRoutes $Network
DocumentApplianceVLANDhcp  $ApplianceVLANS
DocumentSwitches $switches
DocumentSwitchStacks $stacks
DocumentNonStackSwitches -switches $switches -stacks $stacks
DocumentSwitchLags $network                   
DocumentSwitchPorts  $switches 
DocumentAccessPoints $AccessPoints

if ($IsWindows) {
    Close-ExcelPackage $excel -Show                        
} else {
    if ($IsLinux) {        
        Close-ExcelPackage $excel        
        $msg = "Open {0} in yur prefered speadsheep application." -f $document
        Write-Host $msg
        Write-Host "LibreOffice calc will lose most of the formatting."
        Write-Host "WPS Office Spreadsheet will retain all the formatting"
    } else {
        #MacOS, I have no MAC to test on yet.
    }
}