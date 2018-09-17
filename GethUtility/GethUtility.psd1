@{

RootModule           = 'GethUtility'
ModuleVersion        = '0.0.0.180917'
CompatiblePSEditions = @('Core')
GUID                 = '900b8ec0-0862-47d6-b85f-fae136cf6a39'
Author               = 'Masatoshi Higuchi'
CompanyName          = 'N/A'
Copyright            = '(c) Masatoshi Higuchi. All rights reserved.'
Description          = 'PowerShell module for Go Ethereum (geth)'
PowerShellVersion    = '6.0'

FunctionsToExport = @()
CmdletsToExport   = @()
VariablesToExport = @()
AliasesToExport   = @()

PrivateData = @{ PSData = @{
	Tags         = @('ethereum', 'geth')
	LicenseUri   = 'https://github.com/matt9ucci/GethUtility/blob/master/LICENSE'
	ProjectUri   = 'https://github.com/matt9ucci/GethUtility'
	ReleaseNotes = 'Initial release'
} }

DefaultCommandPrefix = 'Geth'

}
