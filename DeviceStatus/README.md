# Get-DeviceStatus PowerShell script

This PowerShell script logs on to a specified device to generate a report of the current interface configuration state. Returned interfaces are the ones specified in the .\deviceconf\(role).txt file.
These outputs being vendor specific, it only handles output from CISCO and HPE devices.

It was built as part of a project to programmatically poll the state of critical interfaces on remote sites.

It also leverages KeePass as a store for the credentials of the devices to poll.

## Dependancies

* Posh-SSH
* Microsoft.PowerShell.SecretManagement
* Microsoft.PowerShell.SecretStore
* SecretManagement.KeePass

## Functions

* Get-KeePassCredential: For a given KeePass database and master password, recovers the credentials to a given device.
* Main body: Retrieve specified Interface statuses for a given device using credentials supplied from a KeePass database.

## Usage

```PowerShell
PS>Get-DeviceStatus -DeviceVendor "CISCO" -DeviceRole "frontswitch" -IPAddress "192.168.1.1" -KeePassDB "Path\To\KeePass\File.kdbx" -KeePassMpwd "password"
```

Notes:
* DeviceVendor is a set of values. For now, only "CISCO" and "HPE" are supported.
* DeviceRole is a set of values. For now, only "frontswitch", "backswitch", and "router" are supported.

## Changelog

### Initial version

Uploaded.



## ToDo

* Replace KeePassMpwd parameter with a SecureString.
* Add Juniper as vendor.
* If "DeviceRole" is not specified, return the full interface configuration.
