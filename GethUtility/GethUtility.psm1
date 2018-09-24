. $PSScriptRoot\Enum.ps1
. $PSScriptRoot\Private.ps1

[string]$DefaultDataDirectory = '.\GUData'

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
#>
function Start-Client {
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[hashtable]$Option = @{}
	)

	if (!$Option.ContainsKey('datadir')) {
		$Option.Add('datadir', $DefaultDataDirectory)
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

<#
.LINK
	geth params package https://github.com/ethereum/go-ethereum/tree/master/params
.LINK
	EIP-150 https://github.com/ethereum/EIPs/blob/master/EIPS/eip-150.md
.LINK
	EIP-155 (chainId) https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
.LINK
	EIP-158 https://github.com/ethereum/EIPs/blob/master/EIPS/eip-158.md
#>
function New-GenesisJson {
	param (
		[ValidateScript( { 0 -le $_ })]
		[long]$ChainId = 1337,
		[string]$Coinbase,
		[ValidateScript( { 0x20000 -le $_ })]
		[long]$Difficulty = 0x20000,
		[string]$ExtraData,
		[ValidateScript( { 5000 -le $_ })]
		[uint64]$GasLimit = 4712388,
		[string]$MixHash = 0,
		[uint64]$Nonce = 0x42,
		[uint64]$Timestamp = (Get-Date -UFormat %s),
		[Parameter(ParameterSetName = 'Clique')]
		[uint64]$Period = 1,
		[Parameter(ParameterSetName = 'Clique')]
		[uint64]$Epoch = 30000
	)

	$hashTable = [ordered]@{
		config     = [ordered]@{
			chainId        = $ChainId
			homesteadBlock = 0
			eip150Block    = 0
			eip155Block    = 0
			eip158Block    = 0
			byzantiumBlock = 0
		}
		difficulty = [string]$Difficulty
		gasLimit   = [string]$GasLimit
		mixHash = '0x{0}' -f $MixHash.PadLeft(64, '0')
		nonce      = '0x{0:X16}' -f $Nonce
		timestamp  = [string]$Timestamp
		alloc      = @{}
	}

	if ($Coinbase) {
		$hashTable.coinbase = $Coinbase
	}

	if ($ExtraData) {
		$hashTable.extraData = $ExtraData
	}

	if ($PSCmdlet.ParameterSetName -eq 'Clique') {
		$hashTable.config.clique = [ordered]@{}
		$hashTable.config.clique.period = $Period
		$hashTable.config.clique.epoch = $Epoch
	}

	$hashTable | ConvertTo-Json
}

function Initialize-DataDirectory {
	param (
		[string]$Directory = $DefaultDataDirectory,
		[string]$GenesisPath = '.\genesis.json'
	)

	geth --datadir $Directory init $GenesisPath
}