Properties {
    $ModuleName = (Get-Item $PSScriptRoot\*.psd1)[0].BaseName

    $Exclude = @(
        'psake.ps1',
        '.git',
        '.publish',
        '.vscode'
    )
    $TempDir = "$home/tmp"
    $PublishDir = "$TempDir\publish\$ModuleName"
}

Task default -depends Build

Task Publish -depends Build {
    $NugetKey = (Get-Secret -Name NuGetKey -AsPlainText | ConvertFrom-Json).NuGetKey

    Publish-Module -Path $PublishDir -NuGetApiKey $NugetKey -WhatIf
}

Task Build -depends Clean {
    Copy-Item "$PSScriptRoot\*" -Destination $PublishDir -Exclude $Exclude -Recurse -Container
}

Task Clean -depends Init {
    Remove-Item "$PublishDir\*" -Recurse -Force
}

Task Init {
    if (-not (Test-Path $TempDir)) {
        New-Item -ItemType Directory $TempDir
    }
    if (-not (Test-Path $PublishDir)) {
        New-Item -ItemType Directory $PublishDir
    }
}

