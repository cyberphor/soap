```
   _____   ____     ___      ____ 
  / ___/  / __ \   /   |    / __ \
  \__ \  / / / /  / /| |   / /_/ /
 ___/ / / /_/ /  / ___ |  / ____/ 
/____/  \____/  /_/  |_| /_/      
   
```
SOAP is a PowerShell module with incident handling and penetration testing functions. 

## Installation
```pwsh
Invoke-WebRequest -Url $URL -Outfile $Outfile
Copy-Item -Path $Outfile -Destination "C:\Program Files\WindowsPowerShell\Modules\"
Import-Module -Name soap -Force
```

## Usage
Once you download and import the PowerShell module, a number of functions will become available. See below for examples invoking them. 

## Examples
```pwsh
Get-WinEventParser -ComputerName EVILCORP01 -LogName Security -EventId 4624 -Days 3

TimeCreated          Hostname Username        LogonType
-----------          -------- --------        ---------
8/19/2021 5:59:32 AM Windows  SYSTEM          5        
8/19/2021 5:59:28 AM Windows  SYSTEM          5        
8/19/2021 5:59:13 AM Windows  SYSTEM          5        
8/19/2021 5:59:13 AM Windows  SYSTEM          5        
8/19/2021 5:59:12 AM Windows  Victor          2        
8/19/2021 5:59:12 AM Windows  Victor          2        
8/19/2021 5:59:06 AM Windows  SYSTEM          5        
8/19/2021 5:59:05 AM Windows  DWM-2           2        
8/19/2021 5:59:05 AM Windows  DWM-2           2        
8/19/2021 5:59:05 AM Windows  UMFD-2          2        
8/19/2021 5:59:05 AM Windows  SYSTEM          5        
8/19/2021 5:59:04 AM Windows  SYSTEM          5        
8/19/2021 5:58:43 AM Windows  SYSTEM          5        
8/19/2021 5:58:38 AM Windows  SYSTEM          5        
8/19/2021 5:58:38 AM Windows  SYSTEM          5        
8/19/2021 5:58:38 AM Windows  SYSTEM          5        
8/19/2021 5:58:38 AM Windows  SYSTEM          5        
8/19/2021 5:58:38 AM Windows  SYSTEM          5        
8/19/2021 5:58:38 AM Windows  NETWORK SERVICE 5        
```
