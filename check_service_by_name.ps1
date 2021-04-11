<#
.Synopsis
   Check-service-by-name.ps1 - let's check what's going on
.DESCRIPTION
   The script checks cpu and RAM usage by the service which name is given as the parameter
.EXAMPLE
   $PATH/check-service-by-name.ps1 -s <YOUR_SERVICE> -cpu_warn 10 -cpu_crit 20 -mem_warn 10 -mem_crit 20 -mem_warn_bytes 2000 -mem_crit_bytes 4000
   Check <YOUR_SERVICE> usage, alert if:
    - its cpu usage is greater than 10%
    - OR its RAM usage is greater than 10%
    - OR its RAM usage is greather than 2GB
 .NOTES
   Only service name parameter is required. If threshold parameters are not specified, script will always quit with OK status
#>

[CmdletBinding(DefaultParameterSetName='args')]
param (
    [Parameter()][string]$service,
    [Parameter()][double]$cpu_warn,
    [Parameter()][double]$cpu_crit,
    [Parameter()][double]$mem_warn,
    [Parameter()][double]$mem_crit,
    [Parameter()][double]$mem_warn_bytes,
    [Parameter()][double]$mem_crit_bytes
)

$EXIT_CODE=0
$USED_CPU = 0
$USED_MEMORY = 0
$TOTAL_MEMORY = 0
$SCRIPT_NAME = $MyInvocation.MyCommand.Name
$ERR_MESSAGE = ""               # Error message

function help() {
    Write-Host "
Script display memory usage of given service
Usage: $SCRIPT_NAME -service <service_name> [OPTIONS]
    
-service                                Image service name from tasklist powershell command without 'exe' suffix
-cpu_warn, mem_warn                     Warning threshold in %
-cpu_crit, mem_crit                     Critical threshold in %
-mem_warn_bytes, mem_crit_bytes         As above but in MB (additional limitation)
"
}

# Return total physical memory in Bytes
function get_total_memory {
    $total_mem = [math]::Round((Get-WMIObject Win32_ComputerSystem).TotalPhysicalMemory,0)
    return $total_mem
}

# Return CPU usage by service in %
function get_total_cpu {
    param (
        $f_service
    )
    $total = [double]::Parse(0)
    $NumberOfLogicalProcessors=(Get-WmiObject -class Win32_processor | Measure-Object -Sum NumberOfLogicalProcessors).Sum
    $cpu_values = (Get-Counter "\Process($f_service*)\% Processor Time").CounterSamples.CookedValue
    
    for ($val = 0; $val -lt $cpu_values.Count; $val++) {
        $total += $cpu_values[$val]
    }

    $cpu_usage = $total / $NumberOfLogicalProcessors

    return $cpu_usage
}

function get_mem_of_service() {
    $services_in_manager = tasklist.exe /fi "imagename eq $service.exe" /fo csv | Select-Object -Skip 1         # Returned fields: "Image Name","PID","Session Name","Session#","Mem Usage"(KB)
    $services_in_manager = $services_in_manager -split '\"'                                                     # Each field in new line
    
    # In case of no output return error code
    if (-not $services_in_manager) { return -1 }

    for ($service_CSV = $($services_in_manager.Count - 2); $service_CSV -lt $services_in_manager.Count; $service_CSV+=2) {
        $line = $services_in_manager[$service_CSV] -replace '[K]',''
        $memory = [double]::Parse($line)                                                                    # Used memory by service in kB
        $used_memory += $memory
    }
    return $used_memory * 1000
}

# Compare used memory with threshold values
function check_status_memory() {
    param (
        $f_mem,
        $f_warn,
        $f_crit,
        $f_total_mem,
        $f_warn_bytes,
        $f_crit_bytes
    )

    if ($f_mem -lt 0) { return 3 }

    # Convert mem (MB) to %
    $f_mem_percent = $f_mem * 100 / $f_total_mem

    if ( (($f_warn) -and ($f_mem_percent -ge $f_warn) -and ($f_mem_percent -lt $f_crit)) -or ( ($f_warn_bytes) -and ($f_mem -ge $f_warn_bytes) -and ($f_mem -lt $f_crit_bytes)) ) {
        return 1
    } elseif ( (($f_crit) -and ($f_mem_percent -ge $f_crit)) -or ( ($f_crit_bytes) -and ($f_mem -ge $f_crit_bytes) ) ) {
        return 2
    }
    return 0
}

# Operations in % scale
function check_status_cpu {
    param (
        $f_cpu_in_percent,
        $f_warn,
        $f_crit
    )
    if ( ($f_warn) -and ($f_cpu_in_percent -ge $f_warn) -and ($f_cpu_in_percent -lt $f_crit) ) {
        return 1
    } elseif ( ($f_crit) -and ($f_cpu_in_percent -ge $f_crit) ) {
        return 2
    }
    return 0
}

function check_status {
    param (
        $f_cpu_code,
        $f_mem_code
    )
    return (@($f_cpu_code, $f_mem_code) | Measure-Object -Max).Maximum        # Return maximum code
}


# Cast MB to B
$mem_crit_bytes *= (1000*1000)
$mem_warn_bytes *= (1000*1000)

# Main loop
If ($service) {
    $USED_MEMORY = get_mem_of_service
    $TOTAL_MEMORY = get_total_memory
    $USED_CPU = get_total_cpu $service

    $USED_MEMORY_MB = $USED_MEMORY/1000/1000
    $USED_MEMORY_PERC = $USED_MEMORY*100/$TOTAL_MEMORY

    $CPU_CODE = check_status_cpu $USED_CPU $cpu_warn $cpu_crit
    $MEM_CODE = check_status_memory $USED_MEMORY $mem_warn $mem_crit $TOTAL_MEMORY $mem_warn_bytes $mem_crit_bytes
    $EXIT_CODE = check_status $CPU_CODE $MEM_CODE

    if ($EXIT_CODE -eq 3) { $ERR_MESSAGE = "Service $service not found" } 
} else {
    $ERR_MESSAGE = help
    $EXIT_CODE = 3
}

# Exit code for Icinga with message
switch ($EXIT_CODE) {
    0 { Write-Host "[OK] - "$service": CPU: $([math]::Round($USED_CPU,4))%, RAM: $([math]::Round($USED_MEMORY_MB,2)) MB ($([math]::Round($USED_MEMORY_PERC,4))%) | Memory=$USED_MEMORY;;;0; Memory%=$($USED_MEMORY_PERC);;;0; CPU%=$USED_CPU;;;0"}
    1 { 
        if (($CPU_CODE -eq $EXIT_CODE) -and ($MEM_CODE -eq $EXIT_CODE)) { Write-Host "[WARNING] - "$service":  CPU: $([math]::Round($USED_CPU,4))% RAM: $($USED_MEMORY_MB) MB ($([math]::Round($USED_MEMORY_PERC,4))%) | Memory=$USED_MEMORY;;;1; Memory%=$($USED_MEMORY_PERC);;;1; CPU%=$USED_CPU;;;1" }
        elseif ($CPU_CODE -eq $EXIT_CODE) { Write-Host "[WARNING] - "$service":  CPU: $([math]::Round($USED_CPU,4))% | Memory=$USED_MEMORY;;;1; Memory%=$($USED_MEMORY_PERC);;;1; CPU%=$USED_CPU;;;1" }
        elseif ($MEM_CODE -eq $EXIT_CODE) { Write-Host "[WARNING] - "$service":  RAM: $([math]::Round($USED_MEMORY_MB,2)) MB ($([math]::Round($USED_MEMORY_PERC,4))%) | Memory=$USED_MEMORY;;;1; Memory%=$($USED_MEMORY_PERC);;;1; CPU%=$USED_CPU;;;0" }
    }
    2 { 
        if (($CPU_CODE -eq $EXIT_CODE) -and ($MEM_CODE -eq $EXIT_CODE)) { Write-Host "[CRITICAL] - "$service":  CPU: $([math]::Round($USED_CPU,4))% RAM: $($USED_MEMORY_MB) MB ($([math]::Round($USED_MEMORY_PERC,4))%) | Memory=$USED_MEMORY;;;2; Memory%=$($USED_MEMORY/$TOTAL_MEMORY);;;2; CPU%=$USED_CPU;;;2" }
        elseif ($CPU_CODE -eq $EXIT_CODE) { Write-Host "[CRITICAL] - "$service": CPU: $([math]::Round($USED_CPU,4))% | Memory=$USED_MEMORY;;;2; Memory%=$($USED_MEMORY_PERC);;;2; CPU%=$USED_CPU;;;2" }
        elseif ($MEM_CODE -eq $EXIT_CODE) { Write-Host "[CRITICAL] - "$service": RAM: $([math]::Round($USED_MEMORY_MB,2)) MB ($([math]::Round($USED_MEMORY_PERC,4))%) | Memory=$USED_MEMORY;;;2; Memory%=$($USED_MEMORY_PERC);;;2; CPU%=$USED_CPU;;;2" }
     }
    3 { Write-Host "[UNKNOWN] - $ERR_MESSAGE" }
}

exit($EXIT_CODE)
