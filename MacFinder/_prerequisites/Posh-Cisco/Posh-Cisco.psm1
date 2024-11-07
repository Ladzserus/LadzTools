# Posh-Cisco PowerShell Cisco Module
# Copyright (c) 2016-2017 Steven Lietaer, All rights reserved.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

# Import PowerShell SSH Module
Import-Module Posh-SSH;

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Get-CiscoSSHResponse
{
    [OutputType([String])]
    param
    (
		[Parameter(Mandatory=$true)]
		[String]$HostAddress,
		[Parameter(Mandatory=$false)]
		[Int]$HostPort = 22,
		[Parameter(Mandatory=$true)]
		[PSCredential]$Credential,
		[Parameter(Mandatory=$false)]
		[Switch]$AcceptKey,
		[Parameter(Mandatory=$true)]
		[String]$Command,
		[Parameter(Mandatory=$false)]
		[String]$StripHeaderAt = $null
    )

    $SSHSession = New-SSHSession -ComputerName $HostAddress -Port $HostPort -Credential $Credential -AcceptKey:$AcceptKey;
    $SSHStream = $SSHSession.Session.CreateShellStream("dumb", 0, 0,0, 0, 10000)
        
    if ($SSHSession.Connected)
    {
        $SSHStream.Read() | Out-Null
        $SSHStream.Write("sh run | include hostname`n")
        Sleep -Milliseconds 2000 # Need a timeout to build the running-config completely
        $HostNameRaw = ($SSHStream.Read() -split "`r`n") | %{$_.trim()}
        
        foreach ($line in $HostNameRaw) {
            if ($line -match "^hostname.*") {
                $HostName = ($line -split " ")[-1]
            }
        }
        
        $SSHStream.Write("terminal Length 0`n");
        Sleep -Milliseconds 100
        $SSHStream.Read() | Out-Null
        $SSHStream.Write($Command + "`n");
        $ResultRaw = $SSHStream.Read()

        # Remove first line (command input)
        $Input, $Result = $ResultRaw -split "`r`n" | %{$_.trim()}
        
        # Wait until either a return or new console input line appears
        while(!$Result) {
            Sleep -Milliseconds 100
            $ResultRaw = $SSHStream.Read()
            $Input, $Result = $ResultRaw -split "`r`n" | %{$_.trim()}
        }
        # Iterate over Read() until console is a new input line or 3 seconds if no return
        $counter = 0
        while (($Result[$Result.Count - 1] -ne "$($HostName)#") -and ($counter -lt 30)) {
            sleep -Milliseconds 100
            $counter++
            $ResultRaw = $SSHStream.Read()
            $Result = $ResultRaw -split "`r`n" | %{$_.trim()}
        }
        # Remove last line (empty console input line)
        return $Result[0..($Result.Length-2)];
    }
    else
    {
        throw [System.InvalidOperationException]"Could not connect to SSH host: $($HostAddress):$HostPort.";
    }
    
    $SSHSessionRemoveResult = Remove-SSHSession -SSHSession $SSHSession;

    if (-Not $SSHSessionRemoveResult)
    {
        Write-Error "Could not remove SSH Session $($SSHSession.SessionId):$($SSHSession.Host).";
    }
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Get-CiscoStartupConfig
{
    [OutputType([String])]
    param
    (
		[Parameter(Mandatory=$true)]
		[String]$HostAddress,
		[Parameter(Mandatory=$false)]
		[Int]$HostPort = 22,
		[Parameter(Mandatory=$true)]
		[PSCredential]$Credential,
		[Parameter(Mandatory=$false)]
		[Switch]$AcceptKey
    )

    return (Get-CiscoSSHResponse -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -AcceptKey:$AcceptKey -Command 'show startup-config' -StripHeaderAt '!');
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Backup-CiscoStartupConfig
{
    param
    (
		[Parameter(Mandatory=$true)]
		[String]$HostAddress,
		[Parameter(Mandatory=$false)]
		[Int]$HostPort = 22,
		[Parameter(Mandatory=$true)]
		[PSCredential]$Credential,
		[Parameter(Mandatory=$false)]
		[Switch]$AcceptKey,
		[Parameter(Mandatory=$true)]
		[String]$FilePath
    )

    Get-CiscoStartupConfig -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -AcceptKey:$AcceptKey | Out-File -FilePath $FilePath -Encoding ascii;
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Get-CiscoRunningConfig
{
    [OutputType([String])]
    param
    (
		[Parameter(Mandatory=$true)]
		[String]$HostAddress,
		[Parameter(Mandatory=$false)]
		[Int]$HostPort = 22,
		[Parameter(Mandatory=$true)]
		[PSCredential]$Credential,
		[Parameter(Mandatory=$false)]
		[Switch]$Full,
		[Parameter(Mandatory=$false)]
		[Switch]$AcceptKey
    )

    $Command = 'show running-config';

    if ($Full)
    {
        $Command = "$Command full";
    }

    return (Get-CiscoSSHResponse -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -AcceptKey:$AcceptKey -Command $Command -StripHeaderAt '!');
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Backup-CiscoRunningConfig
{
    param
    (
		[Parameter(Mandatory=$true)]
		[String]$HostAddress,
		[Parameter(Mandatory=$false)]
		[Int]$HostPort = 22,
		[Parameter(Mandatory=$true)]
		[PSCredential]$Credential,
		[Parameter(Mandatory=$false)]
		[Switch]$Full,
		[Parameter(Mandatory=$false)]
		[Switch]$AcceptKey,
		[Parameter(Mandatory=$true)]
		[String]$FilePath
    )

    Get-CiscoRunningConfig -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -Full:$Full -AcceptKey:$AcceptKey | Out-File -FilePath $FilePath -Encoding ascii;
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Get-CiscoInterfaces
{
    [OutputType([String])]
    param
    (
		[Parameter(Mandatory=$true)]
		[String]$HostAddress,
		[Parameter(Mandatory=$false)]
		[Int]$HostPort = 22,
		[Parameter(Mandatory=$true)]
		[PSCredential]$Credential,
		[Parameter(Mandatory=$false)]
		[Switch]$AcceptKey
    )
    
    return (Get-CiscoSSHResponse -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -AcceptKey:$AcceptKey -Command 'show interfaces' -StripHeaderAt 'Vlan');
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Get-CiscoInterfacesStatus
{
    [OutputType([String])]
    param
    (
		[Parameter(Mandatory=$true)]
		[String]$HostAddress,
		[Parameter(Mandatory=$false)]
		[Int]$HostPort = 22,
		[Parameter(Mandatory=$true)]
		[PSCredential]$Credential,
		[Parameter(Mandatory=$false)]
		[Switch]$AcceptKey
    )
    
    return (Get-CiscoSSHResponse -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -AcceptKey:$AcceptKey -Command 'show interfaces status' -StripHeaderAt 'Port  ');
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Get-CiscoLogging
{
    [OutputType([String])]
    param
    (
		[Parameter(Mandatory=$true)]
		[String]$HostAddress,
		[Parameter(Mandatory=$false)]
		[Int]$HostPort = 22,
		[Parameter(Mandatory=$true)]
		[PSCredential]$Credential,
		[Parameter(Mandatory=$false)]
		[Switch]$AcceptKey
    )

    return (Get-CiscoSSHResponse -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -AcceptKey:$AcceptKey -Command 'show logging' -StripHeaderAt 'Syslog ');
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Get-CiscoLoggingOnboard
{
    [OutputType([String])]
    param
    (
		[Parameter(Mandatory=$true)]
		[String]$HostAddress,
		[Parameter(Mandatory=$false)]
		[Int]$HostPort = 22,
		[Parameter(Mandatory=$true)]
		[PSCredential]$Credential,
		[Parameter(Mandatory=$false)]
		[Switch]$AcceptKey
    )

    return (Get-CiscoSSHResponse -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -AcceptKey:$AcceptKey -Command 'show logging onboard' -StripHeaderAt 'PID: ');
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Get-CiscoMacAddressTable
{
    [OutputType([String])]
    param
    (
		[Parameter(Mandatory=$true)]
		[String]$HostAddress,
		[Parameter(Mandatory=$false)]
		[Int]$HostPort = 22,
		[Parameter(Mandatory=$true)]
		[PSCredential]$Credential,
		[Parameter(Mandatory=$false)]
		[Switch]$AcceptKey
    )

    return (Get-CiscoSSHResponse -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -AcceptKey:$AcceptKey -Command 'show mac address-table' -StripHeaderAt 'Vlan ');
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Get-CiscoVersion
{
    [OutputType([String])]
    param
    (
		[Parameter(Mandatory=$true)]
		[String]$HostAddress,
		[Parameter(Mandatory=$false)]
		[Int]$HostPort = 22,
		[Parameter(Mandatory=$true)]
		[PSCredential]$Credential,
		[Parameter(Mandatory=$false)]
		[Switch]$AcceptKey
    )

    return (Get-CiscoSSHResponse -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -AcceptKey:$AcceptKey -Command 'show version' -StripHeaderAt 'Cisco IOS Software, ');
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Get-CiscoVlan
{
    [OutputType([String])]
    param
    (
		[Parameter(Mandatory=$true)]
		[String]$HostAddress,
		[Parameter(Mandatory=$false)]
		[Int]$HostPort = 22,
		[Parameter(Mandatory=$true)]
		[PSCredential]$Credential,
		[Parameter(Mandatory=$false)]
		[Switch]$AcceptKey
    )

    return (Get-CiscoSSHResponse -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -AcceptKey:$AcceptKey -Command 'show vlan' -StripHeaderAt 'VLAN ');
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Get-CiscoBridgeDomain
{
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory=$true)]
        [String]$HostAddress,
        [Parameter(Mandatory=$false)]
        [Int]$HostPort = 22,
        [Parameter(Mandatory=$true)]
        [PSCredential]$Credential,
        [Parameter(Mandatory=$false)]
        [Switch]$AcceptKey,
        [Parameter(Mandatory=$false)]
        [Int]$BridgeDomain,
        [Parameter(Mandatory=$false)]
        [String]$BridgeDomainName
    )

    # Base command if no optional parameters are present
    $Command = 'show bridge-domain';
	
    # Add specific bridge-domain id if present
    if ($PSBoundParameters.ContainsKey('BridgeDomain'))
    {
        $Command += " $BridgeDomain";
    }
    # Add specific bridge-domain name if present
    elseif ($PSBoundParameters.ContainsKey('BridgeDomainName'))
    {
        $Command += " $BridgeDomainName";
    }
	
    return (Get-CiscoSSHResponse -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -AcceptKey:$AcceptKey -Command $Command -StripHeaderAt 'Bridge-domain ');
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Get-CiscoArp
{
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory=$true)]
        [String]$HostAddress,
        [Parameter(Mandatory=$false)]
        [Int]$HostPort = 22,
        [Parameter(Mandatory=$true)]
        [PSCredential]$Credential,
        [Parameter(Mandatory=$false)]
        [Switch]$AcceptKey,
        [Parameter(Mandatory=$false)]
        [String]$VRF
    )

    # Base command if no optional parameters are present
    $Command = 'show arp';
	
    # Add specific VRF if present
    if ($PSBoundParameters.ContainsKey('VRF'))
    {
        $Command += " vrf $VRF";
    }
	
    # Get and return SSH response
    return (Get-CiscoSSHResponse -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -AcceptKey:$AcceptKey -Command $Command -StripHeaderAt 'Protocol ');
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Get-CiscoIpArp
{
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory=$true)]
        [String]$HostAddress,
        [Parameter(Mandatory=$false)]
        [Int]$HostPort = 22,
        [Parameter(Mandatory=$true)]
        [PSCredential]$Credential,
        [Parameter(Mandatory=$false)]
        [Switch]$AcceptKey,
        [Parameter(Mandatory=$false)]
        [String]$VRF
    )

    # Base command if no optional parameters are present
    $Command = 'show ip arp';
	
    # Add specific VRF if present
    if ($PSBoundParameters.ContainsKey('VRF'))
    {
        $Command += " vrf $VRF";
    }
	
    # Get and return SSH response
    return (Get-CiscoSSHResponse -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -AcceptKey:$AcceptKey -Command $Command -StripHeaderAt 'Protocol ');
}

# .ExternalHelp Posh-Cisco.psm1-Help.xml
function Find-CiscoMacInRunningConfig
{
    [OutputType([String])]
    param
    (
		[Parameter(Mandatory=$true)]
		[String]$HostAddress,
		[Parameter(Mandatory=$false)]
		[Int]$HostPort = 22,
        [Parameter(Mandatory=$true)]
        [String]$Mac,
		[Parameter(Mandatory=$true)]
		[PSCredential]$Credential,
		[Parameter(Mandatory=$false)]
		[Switch]$AcceptKey
    )

    $Command = 'show port-security address | include ' + $Mac;

    return (Get-CiscoSSHResponse -HostAddress $HostAddress -HostPort $HostPort -Credential $Credential -AcceptKey:$AcceptKey -Command $Command -StripHeaderAt '!');
}
