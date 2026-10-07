# Publica el codigo fuente del contrato en Etherscan, tomando la clave del portapapeles.
# Uso: copias la API key en Etherscan y corres   .\verificar.ps1

$CONTRATO = "0x89AEf9d5AaC616B7581c77C83c42E63c78648867"

$crudo = (Get-Clipboard)
if ($crudo -is [array]) { $crudo = $crudo -join "" }
$clave = ($crudo -replace '\s', '')

if (-not $clave) {
    Write-Host "El portapapeles esta vacio. Copia la API key de Etherscan y volve a correr." -ForegroundColor Red
    exit 1
}
if ($clave -notmatch '^[0-9A-Za-z]{20,80}$') {
    Write-Host "Lo que hay en el portapapeles no parece una API key de Etherscan." -ForegroundColor Red
    Write-Host ("  largo: {0} caracteres · solo letras y numeros: {1}" -f $clave.Length, ($clave -match '^[0-9A-Za-z]+$')) -ForegroundColor Yellow
    Write-Host "  Deberia ser una cadena de ~34 letras y numeros, sin guiones ni 0x." -ForegroundColor Yellow
    Write-Host "  Esta en etherscan.io, menu de tu usuario, API Keys." -ForegroundColor Cyan
    exit 1
}

Write-Host "Clave leida. Publicando el codigo del contrato en Etherscan..." -ForegroundColor Green
$env:ETHERSCAN_API_KEY = $clave

npx hardhat verify --network sepolia $CONTRATO

$env:ETHERSCAN_API_KEY = ""
Set-Clipboard -Value " "
Write-Host ""
Write-Host "Mira el resultado en: https://sepolia.etherscan.io/address/$CONTRATO#code" -ForegroundColor Cyan
