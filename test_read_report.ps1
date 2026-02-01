# Script de teste isolado para verificar o parsing HTML
$reportPath = "c:\hp\GitHub\hp-scripts\HPTI\Reports\checkup_-PC_20260131_220116.html"

# Definir cores (simplificado)
$ColorError = "Red"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorInfo = "Cyan"

function Write-Status {
    param([string]$Message, [string]$Type, [string]$Color)
    Write-Host "[$Type] $Message" -ForegroundColor $Color
}

function Read-CheckReport {
    param([string]$ReportPath)
    
    if (-not (Test-Path $ReportPath)) {
        Write-Status "Relatório não encontrado: $ReportPath" "ERRO" $ColorError
        return $null
    }
    
    try {
        $htmlContent = Get-Content -Path $ReportPath -Raw -Encoding UTF8
        
        Write-Host "`n[DEBUG] Lendo relatório HTML..." -ForegroundColor Cyan
        Write-Host "[DEBUG] Tamanho do arquivo: $($htmlContent.Length) caracteres" -ForegroundColor Cyan
        
        # Extrai problemas do HTML (busca por status CRÍTICO e ALERTA)
        $problems = @()
        
        # Regex melhorado para extrair cada linha da tabela <tr>...</tr>
        # Usa [\s\S] em vez de . para capturar quebras de linha
        $rowPattern = '<tr[^>]*>[\s\S]*?</tr>'
        $tableRows = [regex]::Matches($htmlContent, $rowPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        Write-Host "[DEBUG] Total de linhas <tr> encontradas: $($tableRows.Count)" -ForegroundColor Cyan
        
        $criticalCount = 0
        $alertCount = 0
        
        foreach ($rowMatch in $tableRows) {
            $rowHtml = $rowMatch.Value
            
            # Verifica se a linha contém CRÍTICO ou ALERTA
            if ($rowHtml -match "class='status-(critico|alerta)'") {
                $statusType = $matches[1]
                $status = if ($statusType -eq "critico") { "CRÍTICO" } else { "ALERTA" }
                
                if ($status -eq "CRÍTICO") { $criticalCount++ } else { $alertCount++ }
                
                # Extrai todas as células <td> (melhorado para lidar com atributos)
                $cellPattern = '<td[^>]*>(.*?)</td>'
                $cells = [regex]::Matches($rowHtml, $cellPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                
                if ($cells.Count -ge 2) {
                    # Segunda célula (índice 1) contém o nome da verificação
                    $checkName = $cells[1].Groups[1].Value
                    
                    # Remove tags HTML residuais e limpa o texto
                    $checkName = $checkName -replace '<[^>]+>', ''
                    $checkName = $checkName.Trim()
                    
                    if (-not [string]::IsNullOrWhiteSpace($checkName)) {
                        $problems += [PSCustomObject]@{
                            Name   = $checkName
                            Status = $status
                        }
                        Write-Host "[DEBUG] Problema encontrado: $checkName ($status)" -ForegroundColor Gray
                    }
                }
            }
        }
        
        # Remove duplicatas
        $problems = $problems | Sort-Object Name -Unique
        
        Write-Host "`n[DEBUG] Resumo do parsing:" -ForegroundColor Yellow
        Write-Host "[DEBUG] - Críticos encontrados: $criticalCount" -ForegroundColor Red
        Write-Host "[DEBUG] - Alertas encontrados: $alertCount" -ForegroundColor Yellow
        Write-Host "[DEBUG] - Total de problemas únicos: $($problems.Count)" -ForegroundColor White
        
        if ($problems.Count -gt 0) {
            Write-Host "`n[DEBUG] Lista de problemas detectados:" -ForegroundColor Yellow
            foreach ($p in $problems) {
                $color = if ($p.Status -eq "CRÍTICO") { "Red" } else { "Yellow" }
                Write-Host "  - $($p.Name): $($p.Status)" -ForegroundColor $color
            }
        }
        
        return $problems
    }
    catch {
        Write-Status "Erro ao ler relatório: $($_.Exception.Message)" "ERRO" $ColorError
        Write-Host "[DEBUG] Stack trace: $($_.Exception.StackTrace)" -ForegroundColor Red
        return $null
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TESTE DA FUNÇÃO Read-CheckReport" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan

# Executar a função
$problems = Read-CheckReport -ReportPath $reportPath

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "RESULTADO DO TESTE" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total de problemas detectados: $($problems.Count)" -ForegroundColor Yellow

if ($problems -and $problems.Count -gt 0) {
    Write-Host "`nProblemas encontrados:" -ForegroundColor Green
    foreach ($p in $problems) {
        $color = if ($p.Status -eq "CRÍTICO") { "Red" } else { "Yellow" }
        Write-Host "  - $($p.Name): $($p.Status)" -ForegroundColor $color
    }
    
    $criticalCount = ($problems | Where-Object { $_.Status -eq "CRÍTICO" }).Count
    $alertCount = ($problems | Where-Object { $_.Status -eq "ALERTA" }).Count
    
    Write-Host "`nResumo:" -ForegroundColor Cyan
    Write-Host "  Críticos: $criticalCount" -ForegroundColor Red
    Write-Host "  Alertas: $alertCount" -ForegroundColor Yellow
    
    Write-Host "`n✅ TESTE PASSOU! A função detectou os problemas corretamente." -ForegroundColor Green
}
else {
    Write-Host "`n❌ TESTE FALHOU! Nenhum problema detectado!" -ForegroundColor Red
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
