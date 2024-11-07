param(
    [Parameter(Mandatory=$True)]
    [String]$Mac,
    [Parameter(Mandatory=$False)]
    [Switch]$AcceptKey,
    [Parameter(Mandatory=$False)]
    [PSCredential]$Credential
)

Import-Module Posh-Cisco

if ($Credential -eq $null) {
    $Credential = Get-Credential
}

$Present_Switches = @()

foreach ($switch_ip in Get-Content .\configdata\switch_list.conf) {
    Write-Host "Searching on" $switch_ip"..."
    $result = Find-CiscoMacInRunningConfig -HostAddress $switch_ip -Mac $Mac.ToLower() -Credential $Credential -AcceptKey:$AcceptKey
    if ($result -ne $null) {
        $Present_Switches += $switch_ip + " " + ($result -replace '\s+', ' ').Split(" ")[-2]
    } else {
        continue
    }
}

if ($Present_Switches.Length -gt 0) {
    foreach ($entry in $Present_Switches) {
        Write-Host "Mac" $Mac "found on switch" $entry.Split(" ")[0] "at" $entry.Split(" ")[1] -ForegroundColor Green
    }
}