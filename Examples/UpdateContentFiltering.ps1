[CmdletBinding(DefaultParameterSetName='NetworkName')]
Param(
    [Parameter(
        Mandatory = $true,
        ParameterSetName = 'Name'
    )]
    [String] $networkName,    
    [Parameter(
        Mandatory = $true,
        ParameterSetName = 'ID'
    )]
    [String] $networkId,
    [Parameter(
        Mandatory = $true,
        ParameterSetName = 'All'
    )]
    [switch] $All,
    [Parameter(
        Mandatory = $true,
        ParameterSetName = 'Template'
    )]
    [switch] $Templates,
    [String[]] $allowURL,
    [String[]] $blockedURL,
    [string[]] $blockedURLCategories
)

If ($All) {
    $Networks = Get-MerakiNetworks
} else {
    if ($Templates) {
        $Networks = Get-MerakiOrganizationConfigTemplates
    } else {
        if ($networkId) {
            $Networks = @()
            $Networks += Get-MerakiNetwork -networkID $networkId
        } else {
            $Networks = @()
            $Networks += Get-MerakiNetwork | Where-Object {$_.Name -eq $networkName}
        }
    }
}

If ( (-not $AllowURL) -and (-not $DenyURL)) {
    $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
        [System.Management.Automation.ParameterBindingException]'At least one of AllowURL and DenyURL must be provided', 
            'MissingRequiredParameter',
            [System.Management.Automation.ErrorCategory]::InvalidArgument, $null)
    )
}

$contentFiltering = Get-MerakiNetworkApplianceContentFiltering -id $networkId

If ($AllowURL) {
    $contentFiltering.AllowUrlPatterns += $AllowURL
}

If ($blockedURL) {
    $contentFiltering.blockedUrlPatterns += $blockedURL
}

If ($blockedURLCategories) {
    $contentFiltering.blockedUrlCategories += $blockedURLCategories
}


Update-MerakiNetworkApplianceContentFiltering -id $networkId -ContentFilteringRules $contentFiltering
