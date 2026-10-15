[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)][string]$remoteServer
)

# Init
  $tpAutoConnectArgs = @("-a %server%", "-f", "-v")
  $fixShares         = @()

# Rotate Logs
  If (test-path ".\lastImport.bak") { Remove-Item ".\lastImport.bak" }
  If (test-path ".\lastImport.log") { Rename-Item ".\lastImport.log" ".\lastImport.bak" }

# Check to see if server is in the translation table
  $mappingExists = $false
  $regKey    = "HKLM:Software\ThinPrint\TPAutoConnect"
  $regValue  = "NameTranslationEx"

  $DPM = Get-ItemProperty $regKey -Name $regValue

  ForEach($entry in $dpm.NameTranslationEx)
  {
    $aEntry = $entry.split(",")
    If ($aEntry[1].tolower() -eq $remoteServer.tolower()) 
    {     
      $templatePrinter = "_#$($aEntry[9])"
      write-verbose "  Found Printer Mapping for [_#$($aEntry[9])]"
      $mappingExists = $true
      break
    } Else {
      Write-Verbose $aEntry[9]
    }
    
  }



# Check to see if server is online
  If (!(test-connection $remoteServer -Count 1 )) 
  { 
    write-host "ERROR:" -fore white -back red -nonewline 
    write-host " The server you attempted to import printers from (" -fore cyan -nonewline
    write-host $remoteServer -fore yellow -nonewline
    write-host ") does not appear to be online." -fore cyan
    exit
  }
  Else
  {
    write-host "$($remoteServer) is online" -fore green
  }
  
    



# Import Printers
  Write-host "Importing Printers, Please wait" -fore Cyan
  $tpACCmd = $tpAutoConnect + " " + $tpAutoConnectArgs.replace("%server%", $remoteServer)
  
  $processInfo = New-Object System.Diagnostics.ProcessStartInfo
  $processInfo.CreateNoWindow = $true
  $processInfo.UseShellExecute = $false
  $processInfo.RedirectStandardOutput = $True
  $processInfo.RedirectStandardError = $true
  $processInfo.Filename = "C:\Program Files\Common Files\ThinPrint\TPAutoConnect.exe"
  $processInfo.Arguments = $tpAutoConnectArgs
  $processInfo.Arguments = @()
  $processInfo.Arguments+= " -a $($remoteServer)"
  $processInfo.Arguments+= " -f"

  If (!($verbosePreference -like "silentlycontinue")) {  $processInfo.Arguments+= " -v" }
  
  $process = New-Object System.Diagnostics.Process
  $process.StartInfo = $processInfo
  
  Write-Verbose "Program: $($processInfo.Filename)"
  Write-Verbose "Parameters: $($ProcessINFO.Arguments -join ' ')"
  
  [void]$process.Start()
  $output = $process.StandardOutput.ReadToEnd()
  $output | Out-File ".\LastImport.log" 
  $process.WaitForExit()
  
  

  
  
# Parse Output
  Write-host "Parsing results" -fore cyan
  $stdOut = $output.split("`r`n")

    
  ForEach ($line in $stdOut)
  {
    # Retrun No Template Errors
    # =========================================================================================
      If ($line.tolower().startswith("no template for:"))
      {
        $buffer = ($line.replace("No template for: Printer: ", "")).replace("'", "")
        $printer = $buffer.split(",")

        write-host "  " -nonewline
        write-host "ERROR:" -fore white -back red -nonewline
        write-host " No template defined for printer " -fore cyan -nonewline 
        write-host "$($printer[0])" -fore yellow -nonewline
        write-host ".  Check for Template printer (_#Plant)" -fore cyan
      }

    # Return Exit code
    # ========================================================================================
      If ($line.tolower().StartsWith("create"))      
      {
        If ($line.ToLower().EndsWith("ok"))        
        {
          $p1 = $line.IndexOf([char]34) + 1
          $printerName = $line.substring($p1)
          $printername = $printerName.substring(0,$printerName.indexof([char]34))
          write-host "  Created Printer: $($printerName)" -fore green          
        }
        Else
        {
          write-host "  " -nonewline
          Write-host "ERROR:" -fore white -back red -nonewline
          write-host " Attempt to create a printer failed" -fore Yellow
          write-host "       $($line)" -fore yellow
        }
      }
    
    # Return Exit code
    # ========================================================================================
      If ($line.tolower().StartsWith("exiting with code ... ("))
      {
        $buffer = $line.replace("Exiting with code ... (", "")
        $buffer = $buffer.replace(")", "")
          
        Switch ($buffer)
        {
          "220"
           {
             write-host "  Import failed with exit code $($buffer)." -fore yellow
           }  
             
          "0" 
            { 
              Write-host "  Import was successfull." -fore green
            }
        }
      }

  }

  
  
 # Fixup Share Names
  .\fix-sharenames.ps1  
