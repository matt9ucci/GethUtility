. $PSScriptRoot\..\GethUtility\Enum.ps1
. $PSScriptRoot\..\GethUtility\Private.ps1

Describe 'ConvertTo-Wei' {
	Context "from Ether" {
		It "returns Wei" {
			ConvertTo-Wei 1 Ether | Should Be ([bigint]::Pow(10, 18))
			ConvertTo-Wei 100 Ether | Should Be ([bigint]::Pow(10, 20))
			ConvertTo-Wei 1E+18 Ether | Should Be ([bigint]::Pow(10, 36))
		}
	}
	Context "from Finney" {
		It "returns Wei" {
			ConvertTo-Wei 1 Finney | Should Be ([bigint]::Pow(10, 15))
			ConvertTo-Wei 100 Finney | Should Be ([bigint]::Pow(10, 17))
			ConvertTo-Wei 1E+18 Finney | Should Be ([bigint]::Pow(10, 33))
		}
	}
	Context "from Szabo" {
		It "returns Wei" {
			ConvertTo-Wei 1 Szabo | Should Be ([bigint]::Pow(10, 12))
			ConvertTo-Wei 100 Szabo | Should Be ([bigint]::Pow(10, 14))
			ConvertTo-Wei 1E+18 Szabo | Should Be ([bigint]::Pow(10, 30))
		}
	}
	Context "from Wei" {
		It "returns Wei" {
			ConvertTo-Wei 1 Wei | Should Be 1
			ConvertTo-Wei 100 Wei | Should Be 100
			ConvertTo-Wei 1E+18 Wei | Should Be 1E+18
		}
	}
}
