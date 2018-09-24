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
		[ValidateScript( { 0 -le $_ } )]
		[long]$ChainId = 1337,
		[string]$Coinbase,
		[ValidateScript( { 0x20000 -le $_ } )]
		[long]$Difficulty = 0x20000,
		[string]$ExtraData,
		[ValidateScript( { 5000 -le $_ } )]
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
		mixHash    = '0x{0}' -f $MixHash.PadLeft(64, '0')
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

<#
.SYNOPSIS
	Creates genesis alloc as Hashtable.
.EXAMPLE
	New-GenesisAlloc 1df62f291b2e969fb0849d99d9ce41e2f137006e
.EXAMPLE
	New-GenesisAlloc 1df62f291b2e969fb0849d99d9ce41e2f137006e 100 Ether
#>
function New-GenesisAlloc {
	param (
		[Parameter(Mandatory)]
		[string]$Address,
		[ValidateScript( { $_.Sign -ge 0 } )]
		[bigint]$Balance = 0,
		[EtherUnit]$Unit = [EtherUnit]::Wei
	)

	$hashTable = @{}
	$hashTable[$Address] = @{
		balance = [string](ConvertTo-Wei $Balance $Unit)
	}

	$hashTable
}
