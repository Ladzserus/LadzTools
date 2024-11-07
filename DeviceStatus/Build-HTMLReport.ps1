$header = @"
<style>
    table {
        font-family: Arial, sans-serif;
        border-collapse: collapse;
        width: 50%;  
    }
    th {
        background-color: #bbb;
    }
    td, th {
        border: 1px, solid, #ddd;
        padding: 8px;
    }
    tr:nth-child(even) {
        background-color: #f2f2f2;
    }
    h3 {
        font-family: Arial, sans-serif;
        border-top : 2px solid #1375b0;
        width: 100%;
        float: none;
        display: flex;
        color: #787878;
    }
    h3::before {
        content: "";
        display: block;
        position: relative;
        top: 0px;
        left: 0;
        font-size: 24px;
        padding: 12px 25px;
        background-image: linear-gradient(to top, #429ce9 0, #1375b0 100%);
        color: #fff;
        float: left;
        line-height: 0;
        line-width: 600;
        clip-path: polygon(0 0, 100% 0, calc(100% - 25px) 100%, 0 100%);
    }
</style>
"@

$fragments = Get-ChildItem -Path $($PSScriptRoot+"\status") -Filter "*.html"
$report = ""

foreach ($fragment in $fragments) {
    $report += "<h3>" + $fragment.Name.Split(".")[0] + "</h3>"
    $report += Get-Content $fragment.FullName
}

ConvertTo-Html -Head $header -Body $report -Title "Device Report" | Out-File Device_Report.html -Force
