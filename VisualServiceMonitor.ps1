param([string]$passedHostName)

$global:hostName = $null
$global:initialCursorPosition = $null
$global:listCursorHead = $null
$global:listSize = $null
$global:dividerLine = $null
$global:MINHEIGHT = 2
$global:MAXHEIGHT = 47
$global:MAXWIDTH = 50

function ListRefresh
{
	$color
	$x = 0
	$y = $global:listCursorHead.y
	$services = get-service -ComputerName $global:hostName dataonline*
	if($services.Count -ne $global:listSize)
	{
		CLEAR
		Write-Host "Services : $global:hostName"
		Write-Host $global:dividerLine
		$global:listSize = $services.Count
		ResizeUI
	}

	foreach($s in $services)
	{
		if($s.status -eq 'stopped') {$color = "red"}
		elseif ($s.status -eq 'StartPending' -or $s.status -eq 'StopPending') {$color = "yellow"}
		elseif ($s.status -eq 'running') {$color = "green"}
		else {$color = "white"}

		$cursor = $global:listCursorHead
		$cursor.x = $x
		$cursor.y = $y
		$Host.UI.RawUI.CursorPosition = $cursor
		Write-Host -NoNewLine -foregroundcolor 'white' '--'
		Write-Host -NoNewLine -foregroundcolor $color $s.servicename
		$y++
	}
	Write-Host
	Write-Host $global:dividerLine -nonewline
	$Host.UI.RawUI.CursorPosition = $global:initialCursorPosition
}

function ListLoop 
{
	Register-EngineEvent -SourceIdentifier RefreshServiceList -Forward
	while($true)
	{
		$null = New-Event -SourceIdentifier RefreshServiceList
		sleep -s 1
	}
}

function Initialize
{
	CLEAR
	if ([string]::IsNullOrEmpty($passedHostName))
	{
		$global:hostName = "localHost"
	}
	else
	{
		$global:hostName = $passedHostName
	}
	$line = ,'=' * ($global:MAXWIDTH/2)
	$global:dividerLine = $line
	$global:initialCursorPosition = $Host.UI.RawUI.CursorPosition

	Write-Host "Server : $global:hostName"
	Write-Host $global:dividerLine

	$global:listCursorHead = $Host.UI.RawUI.CursorPosition
	$global:listSize = @(Get-service -ComputerName $global:hostName dataonline*).Count
	
	$Host.UI.RawUI.WindowTitle = "DataOnline Service Monitor ($global:hostName)"
	$Host.UI.RawUI.CursorSize = 0
	ResizeUI
}


function ResizeUI
{
	$UI = $Host.UI.RawUI
	$Width = $global:MAXWIDTH
	$Height = $global:listSize + 3
	if($Height -lt $global:MINHEIGHT) {$Height = $global:MINHEIGHT}
	if($Height -gt $global:MAXHEIGHT) {$Height = $global:MAXHEIGHT}
	
	if($Height -lt $UI.WindowSize.Height -or $Width -lt $UI.WindowSize.Width)
	{
		ResizeWindow $Height $Width
		ResizeBuffer $Height $Width
	}
	else
	{
		ResizeBuffer $Height $Width
		ResizeWindow $Height $Width
	}
}

function ResizeBuffer($Height, $Width)
{
	$BufferSize = $Host.UI.RawUI.BufferSize
	$BufferSize.Height = $Height
	$BufferSize.Width = $Width
	$Host.UI.RawUI.BufferSize = $BufferSize
}
function ResizeWindow($Height, $Width)
{
	$WindowSize = $Host.UI.RawUI.WindowSize
	$WindowSize.Height = $Height
	$WindowSize.Width = $Width
	$Host.UI.RawUI.WindowSize = $WindowSize
}

Initialize
function global:prompt {" "}
$listRefreshEvent = Register-EngineEvent -SourceIdentifier RefreshServiceList -Action ${function:ListRefresh}
$null = Start-Job -Name 'RefreshList' ${function:ListLoop}


