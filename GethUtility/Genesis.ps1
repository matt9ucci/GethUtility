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
		[uint64]$Epoch = 30000,
		[hashtable[]]$Alloc
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

	if ($Alloc) {
		$hashTable.alloc = @{}
		foreach ($a in $Alloc) {
			foreach ($key in $a.Keys) {
				$hashTable.alloc.Add($key, $a[$key])
			}
		}
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
.EXAMPLE
	New-GenesisAlloc -BuiltIn Ganache
#>
function New-GenesisAlloc {
	param (
		[Parameter(ParameterSetName = 'Custom', Position = 0, Mandatory)]
		[string[]]$Address,
		[Parameter(ParameterSetName = 'Custom', Position = 1)]
		[ValidateScript( { $_.Sign -ge 0 } )]
		[bigint]$Balance = 0,
		[Parameter(ParameterSetName = 'Custom', Position = 2)]
		[EtherUnit]$Unit = [EtherUnit]::Wei,

		[Parameter(ParameterSetName = 'BuiltIn')]
		[ValidateSet('Ganache')]
		[string]$BuiltIn
	)

	if ($PSCmdlet.ParameterSetName -eq 'BuiltIn') {
		switch ($BuiltIn) {
			Ganache {
				$Address = @(
					'90f8bf6a479f320ead074411a4b0e7944ea8c9c1'
					'ffcf8fdee72ac11b5c542428b35eef5769c409f0'
					'22d491bde2303f2f43325b2108d26f1eaba1e32b'
					'e11ba2b4d45eaed5996cd0823791e0c93114882d'
					'd03ea8624c8c5987235048901fb614fdca89b117'
					'95ced938f7991cd0dfcb48f0a06a40fa1af46ebc'
					'3e5e9111ae8eb78fe1cc3bb8915d5d461f3ef9a9'
					'28a8746e75304c0780e011bed21c72cd78cd535e'
					'aca94ef8bd5ffee41947b4585a84bda5a3d3da6e'
					'1df62f291b2e969fb0849d99d9ce41e2f137006e'
				)
				$Balance = 100
				$Unit = [EtherUnit]::Ether
			}
		}
	}

	$hashTable = @{}
	foreach ($a in $Address) {
		$hashTable[$a] = @{
			balance = [string](ConvertTo-Wei $Balance $Unit)
		}
	}
	$hashTable
}
