<#
.EXAMPLE
	Start-Client @{
		datadir = "$HOME\GethTestData"
		rpc = $true
		rpcapi = 'db,eth,net,shh,web3'
	}
#>
function Start-Client {
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[hashtable]$Option
	)

	$optionString = foreach ($key in $Option.Keys) {
		if ($Option[$key] -eq $true) {
			'--{0}' -f $key
		} elseif ($Option[$key] -eq $false) {
			# ignore
		} else {
			'--{0} "{1}"' -f $key, $Option[$key]
		}
	}

	$command = "geth $($optionString -join ' ')"

	if ($WhatIfPreference) {
		Write-Host ("[WhatIf] Invoking the command: {0}" -f $command)
	} else {
		Write-Host ("Invoking the command: {0}" -f $command)
		Invoke-Expression $command
	}
}
