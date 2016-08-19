# This is the address being pinged
$DestHostname = "8.8.8.8"
# This is the average ping one could expect from the local host to the DestHostName
$NomalPing = 17

# These values are simply to set the enviroment up
$50PctMore = $NomalPing * 1.5
$100PctMore = $NomalPing * 2
$150PctMore = $NomalPing * 2.5
$Dots = $10LineCount = $100LineCount = $OverallAvgPingCount = 0
$LastAvgPingCalculated = $LastAvg10PingLinesCalculated = $LastAvg100PingLinesCalculated = $OverallAvgPing = $NomalPing

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

while($true){
    $Ping = (New-Object System.Net.NetworkInformation.Ping).Send($DestHostname)

    if ($Dots -eq 0){
        Write-Host (Get-Date -UFormat "%H:%M:%S ") -NoNewline
    }
    if ($Dots -lt 60){
        if (($Ping.Status) -eq "Timeout" -or ($Ping.Status) -eq "TimedOut"){
            Write-Host "T" -NoNewline -ba Black -fo Red
        }
        else{
            if(($Ping.RoundtripTime) -lt $NomalPing){Write-Host "█" -NoNewline -ba Black -fo Green}
            if(($Ping.RoundtripTime) -ge $NomalPing -and ($Ping.RoundtripTime) -lt $50PctMore){Write-Host "█" -NoNewline -ba Black -fo White}
            if(($Ping.RoundtripTime) -ge $50PctMore -and ($Ping.RoundtripTime) -lt $100PctMore){Write-Host "█" -NoNewline -ba Black -fo Yellow}
            if(($Ping.RoundtripTime) -ge $100PctMore -and ($Ping.RoundtripTime) -lt $150PctMore){Write-Host "█" -NoNewline -ba Black -fo Red}
            if(($Ping.RoundtripTime) -ge $150PctMore){Write-Host "█" -NoNewline -ba Black -fo Magenta}
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
}

($OverallAvgPing / $OverallAvgPingCount)
