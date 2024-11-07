param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("HPE", "Cisco")]
    [string]$DeviceVendor,

    [Parameter(Mandatory=$true)]
    [ValidateSet("frontswitch", "backswitch", "router")]
    [string]$DeviceRole,

    [Parameter(Mandatory=$true)]
    [Alias("IPAddress")]
    [string]$FQDN,

    [Parameter(Mandatory=$true)]
    [string]$KeePassDB,

    # This c/should probably be changed to be a securestring
    [Parameter(Mandatory=$true)]
    [string]$KeePassMPwd
)


function Get-KeePassCredential {
    param(
        [Parameter(Mandatory=$true)]
        [string]$KeePassDB,

        # This c/should probably be changed to be a securestring
        [Parameter(Mandatory=$true)]
        [string]$KeePassMPwd,

        [Parameter(Mandatory=$true)]
        [string]$Device
    )

    $Mpwd = ConvertTo-SecureString $KeePassMPwd -AsPlainText -Force # do this if the password parameter is a normal string
    $VaultName = "KPVault"

    # If a Vault is already registered with that name, remove it
    if (Get-SecretVault -name $VaultName) {Unregister-SecretVault $VaultName}

    # Register the Vault, then unlock it
    $VParams = @{
        Path = $KeePassDB
        UseMasterPassword = $true
        MasterPassword = $Mpwd
    }
    Register-SecretVault -Name $VaultName -ModuleName SecretManagement.KeePass -VaultParameters $VParams -DefaultVault
    Unlock-SecretVault -Name "KPVault" -Password $Mpwd

    # Retrieve the credential - prompt it if none found
    try {
        $cred = Get-Secret -Vault $VaultName -Name ($Device+" - Admin Account") -AsPlainText
    } catch {
        Write-Host "No secret recovered for device $($Device). Enter manually:"
        $cred = Get-Credential
    }

    # Cleanup the Vault
    Unregister-SecretVault $VaultName
    # And return the credentials
    return $cred
}

Import-Module -Name Posh-SSH, Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore, SecretManagement.KeePass

$cred = Get-KeePassCredential -KeePassDB $KeePassDB -KeePassMPwd $KeePassMPwd -Device ($FQDN.Split(".")[0].ToLower())

$conn = New-SSHSession -ComputerName $FQDN -Credential $cred -AcceptKey

if($DeviceVendor -eq "HPE") {
    $screenscrollcmd = "screen-length disable"
    $intstatuscmd = "display interface brief"
    # collengths = @(21,5,8)
} elseif ($DeviceVendor -eq "Cisco") {
    $screenscrollcmd = "terminal length 0"
    $intstatuscmd = "show interface status"
    # collengths = @(11,30>+13,60>+7)
}

Invoke-SSHCommand -Command $screenscrollcmd -SSHSession $conn -EnsureConnection | Out-Null
$res = Invoke-SSHCommand -Command $intstatuscmd -SSHSession $conn -EnsureConnection -TimeOut 20

$output = @()
Foreach($check in $(Get-Content $PSScriptRoot\deviceconf\$($DeviceRole).txt)) {
    Foreach($line in $($res.Output -split "'r'n")) {
        if ($line.StartsWith($check, "CurrentCultureIgnoreCase")) {
            if ($DeviceVendor -eq "HPE") {
                $intDetails = [PSCustomObject][Ordered]@{
                    Interface = $line.Substring(0,21).TrimEnd()
                    Status = $line.Substring(21,5).TrimEnd()
                    Speed = $line.Substring(26,8).TrimEnd()
                }
                $output += $intDetails
            } elseif ($DeviceVendor -eq "Cisco") {
                $intDetails = [PSCustomObject][Ordered]@{
                    Interface = $line.Substring(0,11).TrimEnd()
                    Status = $line.Substring(30,13).TrimEnd()
                    Speed = $line.Substring(60,7).TrimStart()
                }
                $output += $intDetails
            }
        }
    }
}

$output | ConvertTo-CSV -NoTypeInformation -Delimiter "," | % {$_ -replace '"', ''} | Out-File -FilePath $($PSScriptRoot+"\status\"+$FQDN.Split(".")[0]+".csv") -Force

$output | ConvertTo-Html -Fragment | Out-File -FilePath $($PSScriptRoot+"\status\"+$FQDN.Split(".")[0]+".html") -Force

