#passedHostName : Name of machine to monitor (defaults to localHost)
#serviceName: Name of service(s) to monitor (supports wildcards)
param([string]$passedHostName, [string]$serviceName)

$global:hostName = $null
$global:initialCursorPosition = $null
$global:listCursorHead = $null
$global:listSize = $null
$global:dividerLine = $null
$global:MINHEIGHT = 2 #Reserve space for the static text at the top
$global:MAXHEIGHT = 60 #Supports 58 (MAXHEIGHT - MINHEIGHT) services; if the scrollbar appears, it won't work, so restrict the size
$global:MAXWIDTH = 50 #Don't want the scroll bar to appear horizontally, so restrict the size

#Each time the function is called, get the list of services and enumerate
#Screen needs to be manually cleared or else text will appear to overlap
#Green: Service is running - Yellow: Service is in a transition state - Red: Service is stopped
function ListRefresh
{
	$color
	$x = 0
	$y = $global:listCursorHead.y
	$services = get-service -ComputerName $global:hostName $global:serviceName
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
	$Host.UI.RawUI.CursorPosition = $global:initialCursorPosition #Put the cursor back at the start of the list for the next iteration
}

#Called once per second, this function emits an event which prompts a list refresh
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

	$global:serviceName = $serviceName
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

#Resizes the console to fit the list of current services
function ResizeUI
{
	$UI = $Host.UI.RawUI
	$Width = $global:MAXWIDTH
	$Height = $global:listSize + 3 #Allocate space for 2 lines of static text at the top, 1 at the bottom
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

#Resizing the buffer will prevent the scrollbar from appearing if the height/width does not exceed the maximum screen height/width
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
