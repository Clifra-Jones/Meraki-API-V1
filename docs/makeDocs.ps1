Import-Module $PSScriptRoot/../Meraki-API-V1.psd1

& "$home/Repos/psDoc/src/psDoc.ps1" -moduleName Meraki-API-V1 -Style HTML-Types -outputDir "$PSScriptRoot" -fileName "reference.html"
