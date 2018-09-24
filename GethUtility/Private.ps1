<#
.SYNOPSIS
	Converts a value to Wei.
.EXAMPLE
	ConvertTo-Wei 100 Ether
#>
function ConvertTo-Wei {
	param (
		[Parameter(Mandatory)]
		[bigint]$Value,
		[Parameter(Mandatory)]
		[EtherUnit]$Unit
	)

	[bigint]::Multiply($Value, [bigint]::Pow(10, $Unit))
}
