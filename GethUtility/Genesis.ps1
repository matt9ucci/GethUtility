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
