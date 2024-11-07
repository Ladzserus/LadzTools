# Find-MACAddressOnDevices

This PowerShell command is used to find a MAC address in Cisco running configurations. It's useful in environments where port-security is in effect and you need to find on which port a particular device is cabled up.

## Dependancies 

* Posh-Cisco (Ladz version)
* A list of devices (IP addresses) to search on should be configured in the .\configdata\switch_list.conf file.

## Usage

```PowerShell
PS>Find-MacAdressOnDevices.ps1 -Mac "maca.ddre.ssss" -Credential (Get-Credential)
```

Advanced Options:

* Specify the ```-AcceptKey``` flag to automatically accept SSH key.

## Output

```PowerShell
PS>Mac maca.ddre.ssss found on switch 192.168.2.1 at ge0/1
PS>Mac maca.ddre.ssss found on switch 192.168.3.1 at ge1/1
```

## Change Log

### Initial version

Uploaded.
