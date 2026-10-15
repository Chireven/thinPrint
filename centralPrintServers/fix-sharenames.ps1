# Init
  $templates = @()
  $verboseprefernce="Continue"

ForEach($printer in Get-Printer)
{
  $process = $true

  If ($printer.name.startswith("_#")) 
  { 
    $process = $false    
  }
  
  If ($printer.name.tolower().Contains("microsoft")) 
  {
    $process = $false
  }

  If (!($printer.Shared))
  {
    $process=$false
  }
  Else
  {
    If ($printer.ShareName -contains "#")
    {
      $process = $false      
    }

    If ($printer.sharename.endswith("$"))
    {
      $process = $false
    }
  }



  If ($process)
  {
    Write-host "Processing : $($printer.name)" -fore cyan
    write-host "  Old Share : " -fore green -nonewline 
    write-host "$($Printer.sharename)" -fore yellow
  
    $newShare = $printer.ShareName.substring(0,$printer.sharename.IndexOf("#")) + "$"
    write-host "  New Share : " -fore green -nonewline
    write-host "$($newShare)" -fore yellow

    $printer | Set-Printer -ShareName $newShare
  }
}



