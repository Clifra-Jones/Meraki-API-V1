# Public enums  and variables

enum CategoryListSize {
    topSites;
    fullList
}

enum productTypes{
    wireless;
    appliance;
    switches;
    systemManager;
    camera;
    cellularGateway
}

if (Test-Path "$home/.meraki/config.json") {
    $oldconfig = Get-Content "$home/.meraki/config.json" | ConvertFrom-Json
    if (-not $oldconfig.profiles) {
        Write-Host "Converting existing configuration file!"
        $newConfig = @{
            APIKey = $oldconfig.APIKey
            profiles = @{
                default = $oldConfig.OrgId
            }
        }
        Move-Item "$home/.meraki/config.json" "$home/.meraki/oldconfig.json"
        $newConfig | ConvertTo-Json | Set-Content -Path "$home/.meraki/config.json"
    }
}