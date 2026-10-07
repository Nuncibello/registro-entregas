# Despliega el contrato tomando la clave privada del portapapeles.
# La clave no se escribe en ningun archivo ni queda en el historial de la terminal.
# Uso: copiás la clave en MetaMask y corrés   .\desplegar.ps1

$crudo = (Get-Clipboard)
if ($crudo -is [array]) { $crudo = $crudo -join "" }
$clave = ($crudo -replace '\s', '')          # saca espacios y saltos de linea

if (-not $clave) {
    Write-Host "El portapapeles esta vacio. Copia la clave privada en MetaMask y volve a correr." -ForegroundColor Red
    exit 1
}

# acepta con o sin el prefijo 0x
if ($clave -match '^[0-9a-fA-F]{64}$') { $clave = "0x$clave" }

if ($clave -notmatch '^0x[0-9a-fA-F]{64}$') {
    Write-Host "Lo que hay en el portapapeles no es una clave privada." -ForegroundColor Red
    Write-Host ""
    Write-Host "Diagnostico (no muestro el contenido):" -ForegroundColor Yellow
    Write-Host ("  largo sin espacios: {0} caracteres" -f $clave.Length)
    Write-Host ("  empieza con 0x: {0}" -f ($clave.StartsWith("0x")))
    Write-Host ("  solo numeros y letras A-F: {0}" -f ($clave -match '^(0x)?[0-9a-fA-F]+$'))
    $palabras = ($crudo -split '\s+' | Where-Object { $_ }).Count
    Write-Host ("  palabras separadas por espacio: {0}" -f $palabras)
    Write-Host ""
    if ($palabras -ge 12) {
        Write-Host "Eso parece la FRASE DE RECUPERACION. No la uses y no la pegues en ningun lado." -ForegroundColor Red
        Write-Host "Es la llave maestra de todas tus cuentas." -ForegroundColor Red
    } elseif ($clave.Length -eq 42) {
        Write-Host "Eso es la DIRECCION de la cuenta (la que empieza con 0xAC36...), no la clave." -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Donde esta la clave privada en MetaMask:" -ForegroundColor Cyan
    Write-Host "  1. Elegi la cuenta descartable."
    Write-Host "  2. Tres puntos al lado del nombre de la cuenta."
    Write-Host "  3. Detalles de la cuenta."
    Write-Host "  4. Mostrar clave privada (te pide la contrasena de MetaMask)."
    Write-Host "  5. Mantene apretado el boton para revelarla y tocá Copiar."
    exit 1
}

Write-Host "Clave valida leida del portapapeles. Desplegando en Ethereum Sepolia..." -ForegroundColor Green
$env:CLAVE_DESPLIEGUE = $clave

npm run desplegar

# limpieza: la clave no queda ni en la variable ni en el portapapeles
$env:CLAVE_DESPLIEGUE = ""
Set-Clipboard -Value " "
Write-Host "Listo. Limpie la variable de entorno y el portapapeles." -ForegroundColor Green
