$command1 = {get-itemproperty -ErrorAction Stop 'HKLM:\SOFTWARE\Wow6432Node\Research In Motion\BlackBerry Enterprise Service\Logging Info' | select -ExpandProperty LogRoot }

Function Get-BesLogs(){
        param(
            [Parameter(Position = 0)]
            [int]$BeginDate = (get-Date -format "yyyyMMdd"),
            [Parameter(Position = 1)]
            [int]$EndDate = $null,
            [Parameter(Position = 2)]
            [string]$DestinationDirectory = "${env:TEMP}\bb_logs",
            [Parameter(Position = 3)]
            [bool]$IncludeInstallLogs = $false,
            [Parameter(Position = 4)]
            [bool]$logZip = $false
        )
 
	If (!($logPath)){
		try{
			$SourceDirectory = Invoke-Command -ScriptBlock $command1 
		}
		Catch [System.Exception]{
			$_.Exception.Message
			Write-Host 'You may not have rights to the registry, you could specify the path to logs maually (-logPath) '
		}
	}
    If($SourceDirectory -eq $null){
 
        # Ask if log files are set to the default path
        $title = "Confirm Log File Path"
        $message = "Was the default log file path used?`n`nEx: ${env:ProgramFiles(x86)}\Research In Motion\BlackBerry Enterprise Service 10\Logs"
 
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
                "BES log files are in default path"
        $no  = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
                "BES log files are in non-default path"
 
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no)
 
        $result = $Host.UI.PromptForChoice($title, $message, $options, 0)
 
        switch ($result)
        { # 0 for Yes, 1 for No
            0 { $SourceDirectory = "${env:ProgramFiles(x86)}\Research In Motion\BlackBerry Enterprise Service 10\Logs" }
            1 {
                $browse = New-Object -ComObject shell.Application
                $folder = $browse.BrowseForFolder(0,"Please select a folder",0,17)
                #TODO: Test results when 'Cancel' is used to exit this dialog
                $SourceDirectory = $folder.self.Path
              }
        }
    }
 
    If(!(Test-path $DestinationDirectory)){
        New-Item $DestinationDirectory -ItemType directory | Out-Null
        Write-Host "Created $DestinationDirectory"
    }
    Else{
        Write-Host "$DestinationDirectory exists"
        If(test-path ($DestinationDirectory + '*')){
            Write-Host "Removing previous artifacts from $DestinationDirectory"
            Remove-Item ($DestinationDirectory + '*') -Recurse -Force
        }
 
    }
 
    If($EndDate -ne 0){
        $DateRange = @()
        $DateRange = ($begindate..$enddate)
    }
    Else{
        $DateRange = $BeginDate
    }
 
    $OddLog = @()
    $OddLog = ($SourceDirectory, ($SourceDirectory + 'webserver\'), ($SourceDirectory + 'RIM.BUDS.BWCN\'))
 
    Foreach ($day in $DateRange){
 
        If(!(Test-path $DestinationDirectory\$day)){
            New-Item $DestinationDirectory\$day -ItemType directory | Out-Null
        }
 
        Else{
            Write-Host "$DestinationDirectory\$day exists"
        }
 
        # Copy files that contain the date in filename for the day
        $copyfile = @()
        Get-ChildItem -Recurse -Path ($SourceDirectory + '*.*') | ?{!($_.psiscontainer) -and $_.name -match $day -and $_.directory -notmatch 'Installer'} | Copy-Item -Destination $DestinationDirectory\$day -Force
        $day
        # Convert input date to datetime
 
        $date = ([datetime]::ParseExact($day,"yyyyMMdd",$null)).toshortdatestring()
 
        Foreach ($log in $oddlog){
            Get-Item ($log + '\*') | ?{!($_.psiscontainer) -and $_.lastwritetime -match $date} | Copy-Item -Destination $DestinationDirectory\$day -Force
 
        }
 
    }
    If($IncludeInstallLogs -eq $true){
 
        Write-Host "Including Installer files"
        Copy-Item -Path "$SourceDirectory\Installer" -Destination "$DestinationDirectory\Installer" -Recurse -Force | Out-Null
    }
 
	if($logZip){
		zipLogs ($logDir)
	}
 
    <#
 
.SYNOPSIS
    Collects BlackBerry Logs for 1 or more days
 
.DESCRIPTION
    Collects, then compresses BlackBerry Enterprise Service 10 Logs for 1 or more days. If an end date is specified as a parameter all logs from begindate to endate will be collected. They will then be compressed.
 
.PARAMETER $BeginDate
    The convention for this date is yyyyMMdd e.g 20130725. The default value is the current date.
 
.PARAMETER $EndDate
    The convention for this date is yyyyMMdd e.g 20130725. There is no default value and a single date will be used (begindate)
 
.PARAMETER $DestinationDirectory
    This is a string of the directory where the logs will be copied e.g c:\temp. The default value is "${env:TEMP}\bb_logs"
 
.PARAMETER $IncludeInstallLogs
    This is a boolean value of $true or $false. The default is $false
 
.PARAMETER $logZip
    This is a boolean value of $true or $false. The default is $true
 
.EXAMPLE
    Get-BackupBESLogs
 
.EXAMPLE
    Get-BackupBESLogs -BeginDate 20130725
 
    This will collect the logs only for the
 
.EXAMPLE
    Get-BackupBESLogs -BeginDate 20130725 -enddate 20130725
 
.EXAMPLE
    Get-BackupBESLogs -BeginDate 20130725 -enddate 20130725 -logZip $false
 
.EXAMPLE
    Get-BackupBESLogs -IncludeInstallLogs
 
.NOTES
    Author: Geoff Ginley
 
#>
 
}
