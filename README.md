# DeliveryRegistry

Sella un documento en Ethereum para que cualquiera pueda probar que existía,
sin cambios, en una fecha. **El archivo nunca sale de tu máquina**: se guarda solo su
hash keccak256, que se calcula en el navegador.

Nació de un problema real: en obra, un acta de entrega o una cotización aceptada son
un PDF que viaja por WhatsApp. Si alguien discute qué se entregó y cuándo, no hay nada
que mostrar. Esto deja la constancia en una cadena pública y cuesta centavos.

## Qué tiene adentro

- **Control de acceso por rol**: el dueño autoriza qué cuentas pueden registrar; leer
  es abierto para cualquiera.
- **Errores propios** (`revert NotWriter()`) en vez de `require` con texto: gastan menos
  gas y el frontend puede distinguir cada caso.
- **Almacenamiento empaquetado**: `uint64` de fecha junto a la `address` del autor entran
  en una sola ranura de 32 bytes.
- **`verify` nunca revierte**: un hash desconocido devuelve `exists = false`, así la
  interfaz no tiene que atrapar excepciones para el caso normal.
- **Eventos indexados** por hash y por autor, para reconstruir el historial sin leer el
  estado contrato por contrato.

## Lo que mide

Diez pruebas sobre la red local de Hardhat: registro, duplicados, hash vacío, cuenta sin
permiso, lectura de algo inexistente, alta y baja de permisos, traspaso de propiedad.

```
npm install
npx hardhat test
```

Gas medido con el optimizador en 200 pasadas (solc 0.8.26):

| operación | gas |
|---|---|
| `register` | 94.871 |
| `setWriter` (alta) | 47.782 |
| `setWriter` (baja) | 25.870 |
| `transferOwnership` | 52.233 |
| despliegue | 589.344 |

## Desplegado

| | |
|---|---|
| red | Ethereum Sepolia (11155111) |
| contrato | [`0x89AEf9d5AaC616B7581c77C83c42E63c78648867`](https://sepolia.etherscan.io/address/0x89AEf9d5AaC616B7581c77C83c42E63c78648867) |
| demostración | [nuncibello.vercel.app/registro](https://nuncibello.vercel.app/registro) |
| costo del despliegue | 0,000662 ETH de prueba |

La demostración calcula el hash en el navegador y lee el contrato por un nodo público:
verificar no necesita billetera, registrar sí.

## Desplegar

La clave privada se lee del entorno y nunca se guarda en el repositorio.

```bash
# cuenta descartable, con fondos de un faucet de testnet
export CLAVE_DESPLIEGUE=0x...
export ETHERSCAN_API_KEY=...      # opcional: verifica el código en el explorador
npm run desplegar                 # Ethereum Sepolia
npm run desplegar:base            # o Base Sepolia, si conseguís el faucet
```

El script avisa si la cuenta no tiene fondos, espera cinco confirmaciones y verifica el
contrato en Basescan.

## Decisiones que tomé, y lo que descarté

- **Guardar el hash y no el archivo.** Subir el documento sería más cómodo y lo volvería
  público para siempre. El hash prueba lo mismo y no filtra nada.
- **Sin biblioteca de terceros para el control de acceso.** `Ownable` de OpenZeppelin
  hubiera servido, pero para dos roles agrega dependencia y gas sin aportar nada que no
  se lea en veinte líneas.
- **Una red de prueba primero, y una L2 después.** Está desplegado en Ethereum Sepolia
  porque es donde conseguí fondos de faucet sin fricción. En producción iría a una L2 como
  Base: en la red principal cada documento costaría dólares, en una L2 centavos, y la
  prueba es igual de verificable. El contrato no cambia, solo la red.
- **Sin posibilidad de borrar.** Un registro que se puede borrar no sirve como prueba.
  Lo único que se puede cambiar es quién tiene permiso de escribir.

## Dónde estoy parado

Este es mi primer contrato propio en una red pública. Trabajo hace años con sistemas en
producción, y en cadena vengo del lado de los datos: leo eventos, armo alertas y mido.
Lo digo acá para que nadie tenga que adivinarlo en una entrevista.
