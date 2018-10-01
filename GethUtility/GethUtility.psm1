. $PSScriptRoot\Enum.ps1
. $PSScriptRoot\Private.ps1
. $PSScriptRoot\Genesis.ps1

$DefaultDataDirectory = '.\GUData'
$StandardApi = @(
	'db'
	'eth'
	'net'
	'shh'
	'web3'
)
$ManagementApi = @(
	'admin'
	'debug'
	'miner'
	'personal'
	'txpool'
)

<#
.SYNOPSIS
	Starts geth.
.EXAMPLE
	Start-Client
	# Starts geth by using the GethUtility's default data directory (.\GUData)
.EXAMPLE
	Start-Client @{
		datadir = "$HOME\GethTestData"
		rpc = $true
		rpcapi = 'db,eth,net,shh,web3'
	}
.EXAMPLE
	Start-Client -Rpc Standard
	# Enable HTTP-RPC APIs except for Management APIs
.LINK
	JSON RPC https://github.com/ethereum/wiki/wiki/JSON-RPC
.LINK
	Management APIs https://github.com/ethereum/go-ethereum/wiki/Management-APIs
#>
function Start-Client {
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[hashtable]$Option = [ordered]@{},
		[ValidateSet('All', 'Default', 'Management', 'Standard')]
		[string]$Rpc
	)

	if (!$Option.ContainsKey('datadir')) {
		$Option.Add('datadir', $DefaultDataDirectory)
	}
	if (!$Option.ContainsKey('networkid')) {
		$Option.Add('networkid', 1337)
	}

	if ($Rpc) {
		if (!$Option.ContainsKey('rpc')) {
			$Option.Add('rpc', $true)
		}
		if (!$Option.ContainsKey('rpcapi')) {
			switch ($Rpc) {
				'All' { $Option.Add('rpcapi', ($StandardApi + $ManagementApi) -join ',') }
				'Default' { <# not specified #> }
				'Management' { $Option.Add('rpcapi', $ManagementApi -join ',') }
				'Standard' { $Option.Add('rpcapi', $StandardApi -join ',') }
			}
		}
	}

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

<#
.SYNOPSIS
	Connects to geth.
.EXAMPLE
	Connect-Client
	# Connects to geth over IPC
.EXAMPLE
	Connect-Client -Rpc
.EXAMPLE
	Connect-Client localhost 8545
#>
function Connect-Client {
	[CmdletBinding(DefaultParameterSetName = 'Ipc', SupportsShouldProcess)]
	param (
		[Parameter(ParameterSetName = 'Ipc')]
		[switch]$Ipc = $true,
		[Parameter(ParameterSetName = 'Rpc')]
		[switch]$Rpc = $true,
		[Parameter(ParameterSetName = 'RpcCustom', Position = 0)]
		[string]$RpcHost = 'localhost',
		[Parameter(ParameterSetName = 'RpcCustom', Position = 1)]
		[uint16]$RpcPort = 8545
	)

	$command = switch ($PSCmdlet.ParameterSetName) {
		Ipc { if ($Ipc) { "geth attach ipc://./pipe/geth.ipc" } }
		Rpc { if ($Rpc) { "geth attach rpc:http://localhost:8545" } }
		RpcCustom { "geth attach rpc:http://${RpcHost}:$RpcPort" }
	}

	if ($WhatIfPreference) {
		Write-Host ("[WhatIf] Invoking the command: {0}" -f $command)
	} else {
		Write-Host ("Invoking the command: {0}" -f $command)
		Invoke-Expression $command
	}
}

<#
.SYNOPSIS
	Returns $(geth help) output as Hashtable.
#>
function Get-HelpHashtable {
	[hashtable]$help = @{ CategoryText = @{} }
	[string[]]$helpLines = geth help
	for ($i = 0; $i -lt $helpLines.Count; $i++) {
		$line = $helpLines[$i].Trim()
		switch -Regex ($line) {
			'^[A-Z].*:$' {
				$categoryText = $line.TrimEnd(':')
				$category = (Get-Culture).TextInfo.ToTitleCase($categoryText.ToLower()) -replace ' ', ''
				$help[$category] = @{}
				$help['CategoryText'][$category] = $categoryText
				break
			}
			'^-' {
				$match = ($line | Select-String '^(?<Long>--[\w.]*)(\,\s)?(?<Short>(-\w)?)\s?(?<Argument>"?\w*"?)\s*(?<Description>.*)').Matches[0]
				$help[$category][$match.Groups['Long'].Value.TrimStart('--')] = @{
					Long        = $match.Groups['Long'].Value
					Short       = $match.Groups['Short'].Value
					Argument    = switch ($match.Groups['Argument'].Value) {
						{ $_.Trim('"') -as [decimal] } { 'Decimal'; break }
						{ $_ -match '\S+' } { 'String'; break }
						Default { 'Switch'; break }
					}
					Description = $match.Groups['Description'].Value
				}
				break
			}
			'.+' {
				if ($category -eq 'Commands') {
					$match = ($line | Select-String '^(?<Command>[\w.]*)(\,\s)?(?<Short>\w?)\s*(?<Description>.*)').Matches[0]
					$help[$category][$match.Groups['Command'].Value] = @{
						Command     = $match.Groups['Command'].Value
						Short       = $match.Groups['Short'].Value
						Description = $match.Groups['Description'].Value
					}
				} else {
					if ($help[$category]['Message']) {
						$help[$category]['Message'] += "`n$line"
					} else {
						$help[$category]['Message'] = $line
					}
				}
			}
			Default {
				Write-Debug ('Ignored Line [{0:D3}][{1}]' -f ($i + 1), $line)
			}
		}
	}

	$help
}

function Initialize-DataDirectory {
	param (
		[string]$Directory = $DefaultDataDirectory,
		[string]$GenesisPath = '.\genesis.json'
	)

	geth --datadir $Directory init $GenesisPath
}