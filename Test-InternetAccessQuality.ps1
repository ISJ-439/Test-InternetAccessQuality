### Perpouse: Test the internet connection for connection stability and latency, while logging the failures.
### Author: Adam T
### Last Modified Date: Sept 15th 2016


#################### Variables ####################

# This is the address being pinged
[string]$DestHostname = "8.8.8.8"
# This is the average ping one could expect from the local host to the DestHostName.
[int]$NomalPing = 17
# This is the location of the logging folder.
[string]$LoggingFolder = "C:\Temp"
# Determine if logging is needed.
[bool]$LoggingEnabled = $true
# Determine the delay between pings in ms, 0 is none.
[int]$InterPingDelay = 100
# Determine if graphical display is used (uses a large amount as GPU resources below as 500ms interveral), timeouts/averages will still be shown.
[bool]$GraphPings = $false

# These values are simply to set the enviroment up
$50PctMore = $NomalPing * 1.5
$100PctMore = $NomalPing * 2
$150PctMore = $NomalPing * 2.5
$Dots = $10LineCount = $100LineCount = $OverallAvgPingCount = 0
$LastAvgPingCalculated = $LastAvg10PingLinesCalculated = $LastAvg100PingLinesCalculated = $OverallAvgPing = $NomalPing

#################### SCRIPT EXPLANATION ####################

# Just a cheezy banner
Write-Host "  _   _ ______ _________          ______  _____  _  __ "
Write-Host " | \ | |  ____|__   __\ \        / / __ \|  __ \| |/ / "
Write-Host " |  \| | |__     | |   \ \  /\  / / |  | | |__) | ' /  "
Write-Host " | .   |  __|    | |    \ \/  \/ /| |  | |  _  /|  <   "
Write-Host " | |\  | |____   | |     \  /\  / | |__| | | \ \| . \  "
Write-Host " |_|_\_|______|  |_|    _ \/  \/___\____/|_|__\_\_|\_\ "
Write-Host "  / __ \| |  | |  /\   | |    |_   _|__   __\ \   / /  "
Write-Host " | |  | | |  | | /  \  | |      | |    | |   \ \_/ /   "
Write-Host " | |  | | |  | |/ /\ \ | |      | |    | |    \   /    "
Write-Host " | |__| | |__| / ____ \| |____ _| |_   | |     | |     "
Write-Host "  \___\_\\____/_/ ___\_\______|_____|  |_|     |_|     "
Write-Host " |__   __|  ____|/ ____|__   __|                       "
Write-Host "    | |  | |__  | (___    | |                          "
Write-Host "    | |  |  __|  \___ \   | |                          "
Write-Host "    | |  | |____ ____) |  | |                          "
Write-Host "    |_|  |______|_____/   |_|                          "
Write-Host ""

Write-Host "Legend:"
Write-Host "█" -NoNewline -ba Black -fo Green
Write-Host " <= Expected"
Write-Host "█" -NoNewline -ba Black -fo White
Write-Host " 100% - 150% Expected"
Write-Host "█" -NoNewline -ba Black -fo Yellow
Write-Host " 150% - 200% Expected"
Write-Host "█" -NoNewline -ba Black -fo Red
Write-Host " 200% - 250% Expected"
Write-Host "█" -NoNewline -ba Black -fo Magenta
Write-Host " >= 250% Expected"
Write-Host "T" -NoNewline -ba Black -fo Red
Write-Host " Timeout (2000ms)"
Write-Host ""

#################### FUNCTIONS ####################

# Used to log activity
function OutputToLog([string]$f_Text){
    if($LoggingEnabled){
        if(Test-Path "$LoggingFolder\Test-NetworkQualityLogs"){
            # Logging folder present, logging to file
            [string]$TimeStamp = Get-Date -UFormat "[%d-%m-%y %H:%M:%S] "
            "$TimeStamp $f_Text" | Out-File -LiteralPath "$LoggingFolder\Test-NetworkQualityLogs\$DestHostname.log" -Append
        }
        else{
            # The folder does not exist, creating it
            Write-Host "Creating logging folder..." -fo Yellow
            New-Item -Path "$LoggingFolder" -Name "Test-NetworkQualityLogs" -ItemType Directory
            # Continue logging
            [string]$TimeStamp = Get-Date -UFormat "[%d-%m-%y %H:%M:%S] "
            "$TimeStamp $f_Text" | Out-File -LiteralPath "$LoggingFolder\Test-NetworkQualityLogs\$DestHostname.log"
        }
    }
}

#################### MAIN CODE ####################

while($true){
    $Ping = (New-Object System.Net.NetworkInformation.Ping).Send($DestHostname)

    if ($Dots -eq 0){
        Write-Host (Get-Date -UFormat "[%d-%m-%y %H:%M:%S] ") -NoNewline
    }
    if ($Dots -lt 60){
        if (($Ping.Status) -eq "Timeout" -or ($Ping.Status) -eq "TimedOut"){
            Write-Host "T" -NoNewline -ba Black -fo Red
            OutputToLog("Timeout to $DestHostname")
        }
        else{
            if(($Ping.RoundtripTime) -lt $NomalPing){
                if($GraphPings){Write-Host "█" -NoNewline -ba Black -fo Green}
            }
            elseif(($Ping.RoundtripTime) -ge $NomalPing -and ($Ping.RoundtripTime) -lt $50PctMore){
                if($GraphPings){Write-Host "█" -NoNewline -ba Black -fo White}
            }
            elseif(($Ping.RoundtripTime) -ge $50PctMore -and ($Ping.RoundtripTime) -lt $100PctMore){
                if($GraphPings){Write-Host "█" -NoNewline -ba Black -fo Yellow}
            }
            elseif(($Ping.RoundtripTime) -ge $100PctMore -and ($Ping.RoundtripTime) -lt $150PctMore){
                if($GraphPings){Write-Host "█" -NoNewline -ba Black -fo Red}
            }
            elseif(($Ping.RoundtripTime) -ge $150PctMore){
                if($GraphPings){Write-Host "█" -NoNewline -ba Black -fo Magenta}
                #OutputToLog("")
            }

            $AvgPing += $Ping.RoundtripTime
            $OverallAvgPing += $Ping.RoundtripTime
            $OverallAvgPingCount++
        }
    }
    $Dots++
    if ($Dots -eq 60){
        $AvgPingCalculated = ([math]::Round(($AvgPing/60),3))
        Write-Host " ~ Avg = $AvgPingCalculated (" -NoNewline
        if ($AvgPingCalculated -le ($LastAvgPingCalculated)){
            $PingChangeAmt = ([math]::Round(($AvgPingCalculated-$LastAvgPingCalculated),3))
            Write-Host $PingChangeAmt -ba Black -fo Green -NoNewline
            Write-Host "ms)"
        }
        if ($AvgPingCalculated -gt ($LastAvgPingCalculated)){
            $PingChangeAmt = ([math]::Round(($AvgPingCalculated-$LastAvgPingCalculated),3))
            Write-Host "+$PingChangeAmt" -ba Black -fo Red -NoNewline
            Write-Host "ms)" 
        }
        $LastAvgPingCalculated = $AvgPingCalculated
        $Avg10PingLines += $AvgPingCalculated
        $Avg100PingLines += $AvgPingCalculated
        $AvgPing = 0
        $Dots = 0
        $10LineCount++
        $100LineCount++
    }
    if ($10LineCount -eq 10){
        $Avg10PingLinesCalculated = ([math]::Round(($Avg10PingLines/10),3))
        Write-Host "10 Line Average Change = " -NoNewline -ba Black -fo Yellow
        if ($Avg10PingLinesCalculated -le ($LastAvg10PingLinesCalculated)){
            $10PingChangeAmt = ([math]::Round(($Avg10PingLinesCalculated-$LastAvg10PingLinesCalculated),3))
            Write-Host $10PingChangeAmt -ba Black -fo Green -NoNewline
            Write-Host "ms ($Avg10PingLinesCalculated)" -ba Black -fo Yellow
        }
        if ($Avg10PingLinesCalculated -gt ($LastAvg10PingLinesCalculated)){
            $10PingChangeAmt = ([math]::Round(($Avg10PingLinesCalculated-$LastAvg10PingLinesCalculated),3))
            Write-Host "+$10PingChangeAmt" -ba Black -fo Red -NoNewline
            Write-Host "ms ($Avg10PingLinesCalculated ms)" -ba Black -fo Yellow
        } 
        $LastAvg10PingLinesCalculated = $Avg10PingLinesCalculated
        $Avg10PingLines = 0
        $10LineCount = 0
    }
    if ($100LineCount -eq 100){
        $Avg100PingLinesCalculated = ([math]::Round(($Avg100PingLines/100),3))
        Write-Host "100 Line Average Change = " -NoNewline -ba Black -fo Yellow
        OutputToLog("100 Line Average $Avg100PingLines")
        if ($Avg100PingLinesCalculated -le ($LastAvg100PingLinesCalculated)){
            $100PingChangeAmt = ([math]::Round(($Avg100PingLinesCalculated-$LastAvg100PingLinesCalculated),3))
            Write-Host $100PingChangeAmt -ba Black -fo Green -NoNewline
            Write-Host "ms ($Avg100PingLinesCalculated ms)" -ba Black -fo Yellow
        }
        if ($Avg100PingLinesCalculated -gt ($LastAvg100PingLinesCalculated)){
            $100PingChangeAmt = ([math]::Round(($Avg100PingLinesCalculated-$LastAvg100PingLinesCalculated),3))
            Write-Host "+$100PingChangeAmt" -ba Black -fo Red -NoNewline
            Write-Host "ms ($Avg100PingLinesCalculated ms)" -ba Black -fo Yellow
        } 
        $LastAvg100PingLinesCalculated = $Avg100PingLinesCalculated
        $Avg100PingLines = 0
        $100LineCount = 0
    }
    Start-Sleep -Mil $InterPingDelay 
}
