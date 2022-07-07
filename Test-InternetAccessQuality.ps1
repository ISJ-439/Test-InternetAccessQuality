# Test-InternetAccessQuality

### Purpose: Test the internet connection for connection stability and latency, while logging the failures.
### Author: Adam T
### Version 1.1
### Last Modified Date: Jul 6th 2022
### Notes: Average ping has been adjusted for the initial pings, this was done so the false data did not 
###        interfere, initial values may still be off slightly based on the proper expected ping values 
###        being set. Comments, output data and spacing are improved as well. 


#################### Variables ####################

# This is the address being pinged.
# Remote site with bad connectivity, packet loss and high jitter: 103.99.174.5 (335 avg) or 103.99.174.24 (425 avg)
# Rock solid ping: 8.8.8.8 (<10ms avg)
[string]$DestHostname = "8.8.8.8"

# This is the average ping one could expect from the local host to the DestHostName.
[int]$NomalPing = 25

# This is the location of the logging folder.
[string]$LoggingFolder = "C:\Temp"

# Determine if logging is needed, will log timeouts and the 100 line average (every 6000 pings)
[bool]$LoggingEnabled = $true

# Determine the delay between pings in ms, 0 is none.
[int]$InterPingDelay = 100

# Determine if graphical display is used (uses a large amount as GPU resources below as 500ms interveral), timeouts/averages will still be shown.
[bool]$GraphPings = $true

# Remove averaging variables from possible previous session
Remove-Variable LastAvgPingCalculated,LastAvg10PingLinesCalculated,LastAvg100PingLinesCalculated,OverallAvgPing -ErrorAction SilentlyContinue

# These values are simply to set the enviroment up
$50PctMore = $NomalPing * 1.5
$100PctMore = $NomalPing * 2
$150PctMore = $NomalPing * 2.5
$Dots = $10LineCount = $100LineCount = $OverallAvgPingCount = 0 # Zero the values used for counts
[float]$LastAvgPingCalculated = `
    [float]$LastAvg10PingLinesCalculated = `
    [float]$LastAvg100PingLinesCalculated = `
    [float]$OverallAvgPing = `
    [float]$AvgPing = `
    $null # Set the expected average to null to reduce error. 
[int]$CurrentHour = (Get-Date).Hour
[int]$TimeoutsThisHour = 0

#################### FUNCTIONS ####################

# Just a cheezy banner
function OutputBanner{
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
}

# Used to log activity
function OutputToLog([string]$f_Text){

    # Check if logging is enabled
    if($LoggingEnabled){

        # Verify the logging folder exists
        if(Test-Path "$LoggingFolder\Test-NetworkQualityLogs"){
            # Logging folder present, logging to file
            [string]$TimeStamp = Get-Date -UFormat "[%d-%m-%y %H:%M:%S] "
            "$TimeStamp $f_Text" | Out-File -LiteralPath "$LoggingFolder\Test-NetworkQualityLogs\$DestHostname.log" -Append
        }

        # The folder does not exist, creating it
        else{
            Write-Host "Creating logging folder..." -fo Yellow
            New-Item -Path "$LoggingFolder" -Name "Test-NetworkQualityLogs" -ItemType Directory
            # Continue logging
            [string]$TimeStamp = Get-Date -UFormat "[%d-%m-%y %H:%M:%S] "
            "$TimeStamp $f_Text" | Out-File -LiteralPath "$LoggingFolder\Test-NetworkQualityLogs\$DestHostname.log"
        }
    }
}

#################### MAIN CODE ####################

OutputBanner

# Setup logging folder if needed and inidcate start of script.
OutputToLog("============================= START =============================")

while($true){
    $Ping = (New-Object System.Net.NetworkInformation.Ping).Send($DestHostname)

    # Calulate if max ping is exceeded and set the value if so.
    if(($Ping.RoundtripTime) -gt $LineMaxPing){
        $LineMaxPing = $Ping.RoundtripTime
    }

    # If fresh line.
    if ($Dots -eq 0){
        Write-Host (Get-Date -UFormat "[%d-%m-%y %H:%M:%S] ") -NoNewline
    }

    # If line not full.
    if ($Dots -lt 60){
        if (($Ping.Status) -eq "Timeout" -or ($Ping.Status) -eq "TimedOut"){
            # Determine if the hour has changed for the Timouts per hour count
            if((Get-Date).Hour -ne $CurrentHour){
                $TimeoutsThisHour = 0
                $CurrentHour = (Get-Date).Hour
            }

            Write-Host "T" -NoNewline -ba Black -fo Red
            # Incriment the timeout count
            $TimeoutsThisHour++
            OutputToLog("Timeout to $DestHostname ($TimeoutsThisHour this hour)")
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
            }

            $AvgPing += $Ping.RoundtripTime
            $OverallAvgPing += $AvgPing
            $OverallAvgPingCount++
        }
    }

    # Add a dot count for line spacing.
    $Dots++

    # New line code.
    if ($Dots -eq 60){
        $AvgPingCalculated = ([math]::Round(($AvgPing/60),1))

        Write-Host " ~ Avg = " -NoNewline

        # Indicate Average Line Ping
        if($AvgPingCalculated -lt $NomalPing){Write-Host "$($AvgPingCalculated.ToString("0000.0"))" -NoNewline -ba Black -fo Green}
            elseif($AvgPingCalculated -ge $NomalPing -and $AvgPingCalculated -lt $50PctMore){Write-Host "$($AvgPingCalculated.ToString("0000.0"))" -NoNewline -ba Black -fo White}
            elseif($AvgPingCalculated -ge $50PctMore -and $AvgPingCalculated -lt $100PctMore){Write-Host "$($AvgPingCalculated.ToString("0000.0"))" -NoNewline -ba Black -fo Yellow}
            elseif($AvgPingCalculated -ge $100PctMore -and $AvgPingCalculated -lt $150PctMore){Write-Host "$($AvgPingCalculated.ToString("0000.0"))" -NoNewline -ba Black -fo Red}
            elseif($AvgPingCalculated -ge $150PctMore){Write-Host "$($AvgPingCalculated.ToString("0000.0"))" -NoNewline -ba Black -fo Magenta}
        Write-Host "  `t(" -NoNewline

        # If average line ping is lower or equal to last average line ping.
        if ($AvgPingCalculated -le ($LastAvgPingCalculated)){
            $PingChangeAmt = ([math]::Round(($AvgPingCalculated-$LastAvgPingCalculated),1))
            Write-Host $PingChangeAmt.ToString("0000.0") -ba Black -fo Green -NoNewline
            Write-Host "ms)   `t[Max Ping:" -NoNewline
            # Indicate Max Ping
            if($LineMaxPing -lt $NomalPing){Write-Host "$($LineMaxPing.ToString("0000.0"))" -NoNewline -ba Black -fo Green}
                elseif($LineMaxPing -ge $NomalPing -and $LineMaxPing -lt $50PctMore){Write-Host "$($LineMaxPing.ToString("0000.0"))" -NoNewline -ba Black -fo White}
                elseif($LineMaxPing -ge $50PctMore -and $LineMaxPing -lt $100PctMore){Write-Host "$($LineMaxPing.ToString("0000.0"))" -NoNewline -ba Black -fo Yellow}
                elseif($LineMaxPing -ge $100PctMore -and $LineMaxPing -lt $150PctMore){Write-Host "$($LineMaxPing.ToString("0000.0"))" -NoNewline -ba Black -fo Red}
                elseif($LineMaxPing -ge $150PctMore){Write-Host "$($LineMaxPing.ToString("0000.0"))" -NoNewline -ba Black -fo Magenta}
            Write-Host "]"
            
        }
        
        # If average line ping is greater than the last average line ping.
        if ($AvgPingCalculated -gt ($LastAvgPingCalculated)){
            $PingChangeAmt = ([math]::Round(($AvgPingCalculated-$LastAvgPingCalculated),1))
            Write-Host "+$($PingChangeAmt.ToString("0000.0"))" -ba Black -fo Red -NoNewline
            Write-Host "ms)   `t[Max Ping:" -NoNewline
            # Indicate Max Ping
            if($LineMaxPing -lt $NomalPing){Write-Host "$($LineMaxPing.ToString("0000.0"))" -NoNewline -ba Black -fo Green}
                elseif($LineMaxPing -ge $NomalPing -and $LineMaxPing -lt $50PctMore){Write-Host "$($LineMaxPing.ToString("0000.0"))" -NoNewline -ba Black -fo White}
                elseif($LineMaxPing -ge $50PctMore -and $LineMaxPing -lt $100PctMore){Write-Host "$($LineMaxPing.ToString("0000.0"))" -NoNewline -ba Black -fo Yellow}
                elseif($LineMaxPing -ge $100PctMore -and $LineMaxPing -lt $150PctMore){Write-Host "$($LineMaxPing.ToString("0000.0"))" -NoNewline -ba Black -fo Red}
                elseif($LineMaxPing -ge $150PctMore){Write-Host "$($LineMaxPing.ToString("0000.0"))" -NoNewline -ba Black -fo Magenta}
            Write-Host "]"
        }

        $LastAvgPingCalculated = $AvgPingCalculated
        $Avg10PingLines += $AvgPingCalculated
        $Avg100PingLines += $AvgPingCalculated
        $AvgPing = 0
        $Dots = 0
        $LineMaxPing = 0
        $10LineCount++
        $100LineCount++
    }

    # 10 line average print-out.
    if ($10LineCount -eq 10){
        $Avg10PingLinesCalculated = ([math]::Round(($Avg10PingLines/10),1))
        Write-Host "10 Line Average Change = " -NoNewline -ba Black -fo Yellow
        OutputToLog("10 Line Average $Avg10PingLinesCalculated ms")

        if ($Avg10PingLinesCalculated -le ($LastAvg10PingLinesCalculated)){
            $10PingChangeAmt = ([math]::Round(($Avg10PingLinesCalculated-$LastAvg10PingLinesCalculated),3))
            Write-Host $10PingChangeAmt -ba Black -fo Green -NoNewline
            Write-Host "ms ($($Avg10PingLinesCalculated.ToString("0000.0")))" -ba Black -fo Yellow
        }

        if ($Avg10PingLinesCalculated -gt ($LastAvg10PingLinesCalculated)){
            $10PingChangeAmt = ([math]::Round(($Avg10PingLinesCalculated-$LastAvg10PingLinesCalculated),3))
            Write-Host "+$10PingChangeAmt" -ba Black -fo Red -NoNewline
            Write-Host "ms ($($Avg10PingLinesCalculated.ToString("0000.0")) ms)" -ba Black -fo Yellow

        } 

        $LastAvg10PingLinesCalculated = $Avg10PingLinesCalculated
        $Avg10PingLines = 0
        $10LineCount = 0
    }

    # 100 line average print-out.
    if ($100LineCount -eq 100){
        $Avg100PingLinesCalculated = ([math]::Round(($Avg100PingLines/100),1))
        Write-Host "100 Line Average Change = " -NoNewline -ba Black -fo Yellow
        OutputToLog("100 Line Average $Avg100PingLinesCalculated ms")

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

    # Delay to prevent flooding.
    Start-Sleep -Mil $InterPingDelay 
}


