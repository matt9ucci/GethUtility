$DownloadListPathDefault = "$env:TEMP\GethUtility\DownloadList.xml"

<#
.SYNOPSIS
	Downloads geth releases list from Azure Blobstore.
.LINK
	Geth downloads page https://ethereum.github.io/go-ethereum/downloads/
.LINK
	REST API for list blobs https://docs.microsoft.com/en-us/rest/api/storageservices/list-blobs
#>
function Save-DownloadList {
	param (
		[string]$Path = $DownloadListPathDefault
	)

	$outDirectory = Split-Path $Path
	if (!(Test-Path $outDirectory)) {
		New-Item $outDirectory -ItemType Directory -Force
	}

	$uri = 'https://gethstore.blob.core.windows.net/builds?restype=container&comp=list'
	Invoke-WebRequest $uri -OutFile $Path -Verbose
}

<#
.SYNOPSIS
	Returns geth releases list as System.Xml.XmlElement.
.PARAMETER NoCache
	If specified, the function invokes Save-DownloadList and returns the response.
	If not specified, the function returns the cache of Save-DownloadList
#>
function Get-DownloadList {
	param (
		[switch]$NoCache,
		[switch]$Unstable,
		[switch]$Asc,

		[ValidateSet('darwin', 'linux', 'windows')]
		[string]
		$Os
	)

	if ($NoCache -or !(Test-Path $DownloadListPathDefault)) {
		Save-DownloadList
	}

	$result = [xml](Get-Content $DownloadListPathDefault) | Select-Xml -XPath '//Blob' | ForEach-Object Node
	if (!$Unstable) {
		$result = $result | Where-Object Name -NotLike "*-unstable-*"
	}
	if (!$Asc) {
		$result = $result | Where-Object Name -NotLike "*.asc"
	}
	if ($Os) {
		$result = $result | Where-Object Name -Like "*-${Os}-*"
	}
	$result
}
