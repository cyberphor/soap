function Invoke-WinEventParser {
    param(
        [Parameter(Position=0)][string]$ComputerName,
        [ValidateSet("Application","Security","System","ForwardedEvents")][Parameter(Position=1)][string]$LogName,
        [ValidateSet("4624","4625","4688","5156","6416")][Parameter(Position=2)]$EventId,
        [Parameter(Position=3)][int]$Days=1
    )

    $Date = (Get-Date -Format yyyy-MM-dd-HHmm)
    $Path = "C:\EventId-$EventId-$Date.csv"

    if ($EventId -eq "4624") {
        $FilterXPath = "*[
            System[
                (EventId=4624)
            ] and
            EventData[
                Data[@Name='TargetUserSid'] != 'S-1-5-18' and
                Data[@Name='LogonType'] = '2' or
                Data[@Name='LogonType'] = '3' or
                Data[@Name='LogonType'] = '7' or
                Data[@Name='LogonType'] = '10' or
                Data[@Name='LogonType'] = '11'
            ]
        ]"

        filter Read-WinEvent {
            $TimeCreated = $_.TimeCreated
            $XmlData = [xml]$_.ToXml()
            $Hostname = $XmlData.Event.System.Computer
            $Username = $XmlData.Event.EventData.Data[5].'#text'
            $LogonType = $XmlData.Event.EventData.Data[8].'#text'
            $Event = New-Object psobject
            Add-Member -InputObject $Event -MemberType NoteProperty -Name TimeCreated -Value $TimeCreated
            Add-Member -InputObject $Event -MemberType NoteProperty -Name Hostname -Value $Hostname
            Add-Member -InputObject $Event -MemberType NoteProperty -Name Username -Value $Username
            Add-Member -InputObject $Event -MemberType NoteProperty -Name LogonType -Value $LogonType
            if ($Event.Username -notmatch '(.*\$$|DWM-|ANONYMOUS*)') { $Event }
        }
    } elseif ($EventId -eq "4625") {
        $FilterXPath = "*[
            System[
                (EventId=4625)
            ] and
            EventData[
                Data[@Name='TargetUserName'] != '-'
            ]
        ]"

        filter Read-WinEvent {
            $TimeCreated = $_.TimeCreated
            $XmlData = [xml]$_.ToXml()
            $Hostname = $XmlData.Event.System.Computer
            $Username = $XmlData.Event.EventData.Data[5].'#text'
            $LogonType = $XmlData.Event.EventData.Data[10].'#text'
            $Event = New-Object psobject
            Add-Member -InputObject $Event -MemberType NoteProperty -Name TimeCreated -Value $TimeCreated
            Add-Member -InputObject $Event -MemberType NoteProperty -Name Hostname -Value $Hostname
            Add-Member -InputObject $Event -MemberType NoteProperty -Name Username -Value $Username
            Add-Member -InputObject $Event -MemberType NoteProperty -Name LogonType -Value $LogonType
            $Event
        }
    } elseif ($EventId -eq "4688") {
        $FilterXPath = "*[
            System[
                (EventId=4688)
            ] and
            EventData[
                Data[@Name='TargetUserName'] != '-' and
                Data[@Name='TargetUserName'] != 'LOCAL SERVICE'
            ]
        ]"

        filter Read-WinEvent {
            $TimeCreated = $_.TimeCreated
            $XmlData = [xml]$_.ToXml()
            $Hostname = $XmlData.Event.System.Computer
            $Username = $XmlData.Event.EventData.Data[8].'#text'
            $CommandLine = $XmlData.Event.EventData.Data[10].'#text'
            $Event = New-Object psobject
            Add-Member -InputObject $Event -MemberType NoteProperty -Name TimeCreated -Value $TimeCreated
            Add-Member -InputObject $Event -MemberType NoteProperty -Name Hostname -Value $Hostname
            Add-Member -InputObject $Event -MemberType NoteProperty -Name Username -Value $Username
            Add-Member -InputObject $Event -MemberType NoteProperty -Name CommandLine -Value $CommandLine
            if ($Event.Username -notmatch '(.*\$$|DWM-)') { $Event }
        }
    } elseif ($EventId -eq "5156") {
        $FilterXPath = "*[
            System[
                (EventId=4688)
            ] and
            EventData[
                Data[@Name='DestAddress'] != '127.0.0.1' and
                Data[@Name='DestAddress'] != '::1'
            ]
        ]"

        filter Read-WinEvent {
            $TimeCreated = $_.TimeCreated
            $XmlData = [xml]$_.ToXml()
            $Hostname = $XmlData.Event.System.Computer
            $DestAddress = $XmlData.Event.EventData.Data[5].'#text'
            $DestPort = $XmlData.Event.EventData.Data[6].'#text'
            $Event = New-Object psobject
            Add-Member -InputObject $Event -MemberType NoteProperty -Name TimeCreated -Value $TimeCreated
            Add-Member -InputObject $Event -MemberType NoteProperty -Name Hostname -Value $Hostname
            Add-Member -InputObject $Event -MemberType NoteProperty -Name DestinationAddress -Value $DestAddress
            Add-Member -InputObject $Event -MemberType NoteProperty -Name DestinationPort -Value $DestPort
            $Event
        }
    } elseif ($EventId -eq "6416") {
        $FilterXPath = "*[
            System[
                (EventId=6416)
            ] 
        ]"

        filter Read-WinEvent {
            $TimeCreated = $_.TimeCreated
            $XmlData = [xml]$_.ToXml()
            $Hostname = $XmlData.Event.System.Computer
            $DeviceDescription = $XmlData.Event.EventData.Data[5].'#text'
            $ClassName = $XmlData.Event.EventData.Data[7].'#text'
            $Event = New-Object psobject
            Add-Member -InputObject $Event -MemberType NoteProperty -Name TimeCreated -Value $TimeCreated
            Add-Member -InputObject $Event -MemberType NoteProperty -Name Hostname -Value $Hostname
            Add-Member -InputObject $Event -MemberType NoteProperty -Name ClassName -Value $ClassName
            Add-Member -InputObject $Event -MemberType NoteProperty -Name DeviceDescription -Value $DeviceDescription
            $Event
        }
    } 

    Get-WinEvent -ComputerName $ComputerName -LogName $LogName -FilterXPath $FilterXPath |
    Read-WinEvent |
    ConvertTo-Csv -NoTypeInformation |
    Tee-Object -FilePath $Path |
    ConvertFrom-Csv

    $Events = Get-Content $Path
    Remove-Item -Path $Path
    $Events | ConvertFrom-Csv | Export-Csv -NoTypeInformation -Path $Path
}

function Test-Port {
    param(
        [Parameter(Mandatory)][ipaddress]$IpAddress,
        [Parameter(Mandatory)][int]$Port,
        [ValidateSet("TCP","UDP")[string]$Protocol = "TCP"
    )

    if ($Protocol -eq "TCP") {
        $TcpClient = New-Object System.Net.Sockets.TcpClient
        $TcpClient.ConnectAsync($IpAddress,$Port).Wait(1000)
    }
}

function Get-AssetInventory {
    [CmdletBinding(DefaultParameterSetName = "IP")]
    param(
        [Parameter(ParameterSetName = "IP",Position = 0)]$NetworkId = "10.11.12.",
        [Parameter(ParameterSetName = "IP",Position = 1)]$NetworkRange = (1..254),
        [Parameter(ParameterSetName = "DNS",Position = 0)]$Filter = "*"
    )

    $Assets = @()
    if ($PSCmdlet.ParameterSetName -eq "IP") {
        $NetworkRange |
        ForEach-Object {
            $IpAddress = $NetworkId + $_
            $NameResolved = Resolve-DnsName -Name $IpAddress -Type PTR -DnsOnly -ErrorAction Ignore
            if ($NameResolved -and $IpAddress -notin $Assets.IpAddress) {
                $Hostname = $NameResolved.NameHost | Where-Object { $_ -notlike "*_site*" }
            } else {
                $Hostname = "-"
            }
            $Asset = New-Object psobject
            Add-Member -InputObject $Asset -MemberType NoteProperty -Name IpAddress -Value $IpAddress
            Add-Member -InputObject $Assets -MemberType NoteProperty -Name Hostname -Value $Hostname
            $Assets += $Asset
        }
    } elseif ($PSCmdlet.ParameterSetName -eq "DNS") {
        Get-AdComputer -Filter $Filter |
        Select-Object -ExpandProperty DnsHostname |
        ForEach-Object {
            $NameResolved = Resolve-DnsName -Name $_ -DnsOnly -ErrorAction Ignore
            if ($NameResolved -and $NameResolved.IpAddress -notin $Assets.IpAddress) {
                $Asset = New-Object psobject
                Add-Member -InputObject $Asset -MemberType NoteProperty -Name IpAddress -Value $IpAddress
                Add-Member -InputObject $Assets -MemberType NoteProperty -Name Hostname -Value $Hostname
                $Assets += $Asset    
            }
        }
    }
}

function Get-ComputersOnline {
    <#
    Param(
        [Parameter(Position=0,Mandatory=$true)][string]$NetworkId,
        [Parameter(Position=1,Mandatory=$true)][string]$NetworkRange
    )
    #>
    
    $NetworkId = "10.11.12"
    $NetworkRange = 1..254
    Get-Event -SourceIdentifier "Ping-*" | Remove-Event -ErrorAction Ignore
    Get-EventSubscriber -SourceIdentifier "Ping-*" | Unregister-Event -ErrorAction Ignore

    $NetworkRange |
    ForEach-Object {
        $IpAddress = $NetworkId + $_
        $Event = "Ping-" + $IpAddress
        New-Variable -Name $Event -Value (New-Object System.Net.NetworkInformation.Ping)
        Register-ObjectEvent -InputObject (Get-Variable $Event -ValueOnly) -EventName PingCompleted -SourceIdentifier $Event
        (Get-Variable $Event -ValueOnly).SendAsync($IpAddress,2000,$Event)
    }

    while ($Pending -lt $NetworkRange.Count) {
        Wait-Event -SourceIdentifier "Ping-*" | Out-Null
        Start-Sleep -Milliseconds 10
        $Pending = (Get-Event -SourceIdentifier "Ping-*").Count
    }

    $ComputersOnline = @()
    Get-Event -SourceIdentifier "Ping-*" |
    ForEach-Object {
        if ($_.SourceEventArgs.Reply.Status -eq "Success") {
            $ComputersOnline += $_.SourceEventArgs.Reply.Address.IpAddressToString
            Remove-Event $_.SourceIdentifier
            Unregister-Event $_.SourceIdentifier
        }
    }

    $ComputersOnline | Sort-Object { $_ -as [Version] } -Unique
}

function Get-LocalGroupAdministrators {
    $Computers = Get-Computers
    Invoke-Command -ComputerName $Computers -ScriptBlock {
      Get-LocalGroupMember -Group "administrators"
    } | Select-Object @{Name="Hostname";Expression={$_.PSComputerName}}, @{Name="Member";Expression={$_.Name}}
}

function ConvertTo-Base64 {
    $Text = ""
    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text)
    $EncodedText =[Convert]::ToBase64String($Bytes)
    $EncodedText
}

function ConvertFrom-Base64 {
    $EncodedText = ""
    $DecodedText = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($EncodedText))
    $DecodedText
}
