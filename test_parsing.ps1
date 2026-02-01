# Teste do parsing HTML
$htmlContent = Get-Content "c:\hp\GitHub\hp-scripts\HPTI\Reports\checkup_-PC_20260131_220116.html" -Raw -Encoding UTF8

$problems = @()

# Regex para extrair cada linha da tabela <tr>...</tr>
$rowPattern = '<tr>.*?</tr>'
$tableRows = [regex]::Matches($htmlContent, $rowPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

Write-Host "Total de linhas encontradas: $($tableRows.Count)" -ForegroundColor Cyan

foreach ($rowMatch in $tableRows) {
    $rowHtml = $rowMatch.Value
    
    # Verifica se a linha contém CRÍTICO ou ALERTA
    if ($rowHtml -match "class='status-(critico|alerta)'") {
        $statusType = $matches[1]
        $status = if ($statusType -eq "critico") { "CRÍTICO" } else { "ALERTA" }
        
        # Extrai todas as células <td>
        $cellPattern = '<td[^>]*>(.*?)</td>'
        $cells = [regex]::Matches($rowHtml, $cellPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        
        Write-Host "`nLinha com $status - Total células: $($cells.Count)" -ForegroundColor Yellow
        
        if ($cells.Count -ge 2) {
            # Segunda célula (índice 1) contém o nome da verificação
            $checkName = $cells[1].Groups[1].Value
            
            # Remove tags HTML residuais e limpa o texto
            $checkName = $checkName -replace '<[^>]+>', ''
            $checkName = $checkName.Trim()
            
            Write-Host "  Nome: $checkName" -ForegroundColor Green
            
            if (-not [string]::IsNullOrWhiteSpace($checkName)) {
                $problems += [PSCustomObject]@{
                    Name   = $checkName
                    Status = $status
                }
            }
        }
    }
}

Write-Host "`n`n=== RESULTADO FINAL ===" -ForegroundColor Cyan
Write-Host "Problemas detectados: $($problems.Count)" -ForegroundColor Yellow
foreach ($p in $problems) {
    Write-Host "  - $($p.Name): $($p.Status)" -ForegroundColor Gray
}
