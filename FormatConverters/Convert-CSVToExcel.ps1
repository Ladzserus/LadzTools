[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $inputFile
)

$TempFile = "$PSScriptRoot\Tmp.csv"

# Create Excel object
$excel = New-Object -ComObject excel.application
$workbook = $excel.Workbooks.Add(1)
$worksheet = $workbook.Worksheets.Item(1)

# Remove any quotes around the data
(Get-Content $inputFile) | % {$_ -replace '"', ""} | Out-File $TempFile -Force -Encoding utf8

$outputFile = (Get-Item $inputFile).DirectoryName + "\" + 
                (Get-Item $inputFile).BaseName + ".xlsx"

# Create the query (equivalent to the Data > import from text in Excel)
$TxtConnector = ("TEXT;" + $TempFile)
$Connector = $worksheet.QueryTables.Add($TxtConnector, $worksheet.Range("A1"))
$query = $worksheet.QueryTables.item($Connector.Name)
$query.TextFileOtherDelimiter = ","
$query.TextFileParseType = 1
$query.TextFileColumnDataTypes = ,2 * $worksheet.Cells.Columns.Count
$query.AdjustColumnWidth = 1

# Run then clean the query
$query.Refresh()
$query.Delete()

# Save the Excel file
$workbook.SaveAs($outputFile, 51)
$excel.Quit()

# Clean up temp files
Remove-Item "$PSScriptRoot\Tmp.csv"