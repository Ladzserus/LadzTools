# Various format converters

This folder just holds a bunch of helper functions I wrote to convert between various file formats in ways that require a bit more control than basic PowerShell built-in functions.

## Functions

* Convert-CSVtoExcel: Converts a CSV (.csv) file to an Excel (.xlsx) file of the same name.

## Usage

### Convert-CSVToExcel

```PowerShell
PS>Convert-CSVToExcel -inputFile
```

Note: The original CSV must use "," as the delimiter.

## Changelog

### Initial version

Uploaded.
