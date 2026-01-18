param(
    [Parameter(Mandatory=$true)]
    [string]$Origem,

    [Parameter(Mandatory=$true)]
    [string]$Destino
)

if (-not (Test-Path $Destino)) {
    New-Item -ItemType Directory -Path $Destino | Out-Null
    # Write-Output envia para o fluxo de dados (pipeline), o que é correto
    Write-Output "Pasta de destino criada."
}

Get-ChildItem -Path $Origem -Recurse | ForEach-Object {
    $destPath = Join-Path -Path $Destino -ChildPath $_.Name
    if (-not (Test-Path $destPath)) {
        Copy-Item -Path $_.FullName -Destination $destPath
        Write-Output "Copiado: $($_.Name)"
    }
}
