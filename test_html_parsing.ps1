# Test script to diagnose HTML parsing issue
$reportPath = "c:\hp\GitHub\hp-scripts\HPTI\Reports\checkup_-PC_20260131_220116.html"

Write-Host "`n=== Testing HTML Parsing ===" -ForegroundColor Cyan
Write-Host "Report: $reportPath`n" -ForegroundColor Gray

# Read HTML
$htmlContent = Get-Content -Path $reportPath -Raw -Encoding UTF8
Write-Host "HTML Length: $($htmlContent.Length) characters" -ForegroundColor Yellow

# Test 1: Check if status classes exist
Write-Host "`n--- Test 1: Status Classes ---" -ForegroundColor Cyan
$hasCritico = $htmlContent -match "status-critico"
$hasAlerta = $htmlContent -match "status-alerta"
Write-Host "Contains 'status-critico': $hasCritico" -ForegroundColor $(if ($hasCritico) { "Green" }else { "Red" })
Write-Host "Contains 'status-alerta': $hasAlerta" -ForegroundColor $(if ($hasAlerta) { "Green" }else { "Red" })

# Test 2: Count occurrences
Write-Host "`n--- Test 2: Count Occurrences ---" -ForegroundColor Cyan
$criticoMatches = [regex]::Matches($htmlContent, "status-critico")
$alertaMatches = [regex]::Matches($htmlContent, "status-alerta")
Write-Host "status-critico count: $($criticoMatches.Count)" -ForegroundColor Red
Write-Host "status-alerta count: $($alertaMatches.Count)" -ForegroundColor Yellow

# Test 3: Extract table rows
Write-Host "`n--- Test 3: Table Rows ---" -ForegroundColor Cyan
$rowPattern = '<tr[^>]*>[\s\S]*?</tr>'
$tableRows = [regex]::Matches($htmlContent, $rowPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
Write-Host "Total <tr> rows found: $($tableRows.Count)" -ForegroundColor Yellow

# Test 4: Find rows with status-critico or status-alerta
Write-Host "`n--- Test 4: Problem Rows ---" -ForegroundColor Cyan
$problemRows = 0
foreach ($rowMatch in $tableRows) {
    $rowHtml = $rowMatch.Value
    if ($rowHtml -match "class='status-(critico|alerta)'") {
        $problemRows++
        $statusType = $matches[1]
        
        # Extract check name (2nd <td>)
        $cellPattern = '<td[^>]*>(.*?)</td>'
        $cells = [regex]::Matches($rowHtml, $cellPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        
        if ($cells.Count -ge 2) {
            $checkName = $cells[1].Groups[1].Value -replace '<[^>]+>', '' 
            $checkName = $checkName.Trim()
            
            $color = if ($statusType -eq "critico") { "Red" }else { "Yellow" }
            Write-Host "  Found: $checkName ($statusType)" -ForegroundColor $color
        }
    }
}
Write-Host "`nTotal problem rows: $problemRows" -ForegroundColor $(if ($problemRows -gt 0) { "Green" }else { "Red" })

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
