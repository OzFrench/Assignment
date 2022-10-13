<#
Author : Arnaud Bour
Date : 10/12/2022
Script : ServiceStatus.ps1

Usage : ServiceStatus.ps1 -Inputfile "YourInput.file" -ServiceName "The Windows Service" [-Status "Optional"]

Result file : "YourInput.csv".
Error file : "YourInput.err".

The servers defined only by their IP adress needs to be in the WinRM TrustedHosts list.
#>

#Definition of the parameters

param
(
	[Parameter(ValuefromPipeline=$true,mandatory=$true)][string]$InputFile,
    [Parameter(ValuefromPipeline=$true,mandatory=$true)][string]$ServiceName,
    [Parameter(ValuefromPipeline=$true)][ValidateSet("Running","running","Stopped","stopped")][string]$Status
)

 #Function that will ensure that the Input File does exist

 function testInputFile {
  if (-not(Test-Path -path .\$InputFile -PathType Leaf))
    {
     write-host "ERROR : The file $InputFile does not exist"
     exit
    }
}

 #Function that will ensure that the remote host is reachable

 function testhost {
    $script:testhostRES = ""
    test-connection -computername $Hostname -count 1 >$null 2>&1
     if (($?) -eq $false)
       {
         $script:testhostRES = "KO"
         echo "$Hostname : unreachable" >> $ErrorFile
       }
}

#Function that gets the Service status

function servicestatus {
#If the optional "Status" parameter is not present
  if ( $Status -eq "" )
    {
      $Stat = (Get-CimInstance -ClassName Win32_Service -Filter "Name like '$ServiceName%'" -ComputerName "$Hostname").State
      echo "$HostName,$ServiceName,$Stat" >> $ResultFile
    }
#If the optional "Status" parameter is present in order to avoid the results that are not in the desired state
  else
    {
      $Stat = (Get-CimInstance -ClassName Win32_Service -Filter "Name like '$ServiceName%'" -ComputerName "$Hostname" | Where-Object {$_.State -EQ "$Status"}).State
        if ( $Stat -ne "" )
          {
            echo "$HostName,$ServiceName,$Stat" >> $ResultFile
          }
    }
}

#Function that tests if the service is present on the remote computer

function testservice {
  $script:testserviceRES = ""
  $service = Get-Service -Name $ServiceName >$null 2>&1
    if ($? -eq $false)
      {
        $script:testserviceRES = "KO"
        echo "$Hostname : Service $ServiceName not present" >> $ErrorFile
      }
}

#Testing the presence of the input file

testinputfile

#Naming the Result and the Error File

$script:ResultFile = ($InputFile -split '\.',2)[0] + '.csv'
$script:ErrorFile = ($InputFile -split '\.',2)[0] + '.err'

#Initialising the Result and the Error File

echo "Machine,Service,Status" > $ResultFile
echo $null > $ErrorFile

#Main program

foreach ($Hostname in (Get-Content .\$Inputfile))
  {
    testhost

    if ($testhostRES -ne "KO")
      {
        testservice
          if ( $testserviceRES -ne "KO")
            {
              servicestatus
            }
      }
}
