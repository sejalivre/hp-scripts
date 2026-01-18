param(
    [Parameter(Mandatory=$true)]
    [string]$Origem,

    [Parameter(Mandatory=$true)]
    [string]$Destino
)

# Cria a pasta de destino se não existir
if (-not (Test-Path $Destino)) {
    New-Item -ItemType Directory -Path $Destino | Out-Null
    Write-Host "Pasta de destino criada." -ForegroundColor Green
}

# Copia os arquivos (o parametro -Update, se disponivel no seu PS, copiaria so os novos, 
# mas faremos copia simples com log para garantir compatibilidade)
Get-ChildItem -Path $Origem -Recurse | ForEach-Object {
    $destPath = Join-Path -Path $Destino -ChildPath $_.Name
    if (-not (Test-Path $destPath)) {
        Copy-Item -Path $_.FullName -Destination $destPath
        Write-Host "Copiado: $($_.Name)" -ForegroundColor Cyan
    }
}
