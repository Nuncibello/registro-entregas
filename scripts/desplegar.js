// Despliega el contrato y deja los datos para verificarlo en el explorador.
// La clave privada se lee del entorno (CLAVE_DESPLIEGUE); nunca se guarda en el repo.
const { ethers, network, run } = require('hardhat');

async function main() {
  const [cuenta] = await ethers.getSigners();
  if (!cuenta) throw new Error('Falta CLAVE_DESPLIEGUE en el entorno');

  const saldo = await ethers.provider.getBalance(cuenta.address);
  console.log('red:', network.name, '· cuenta:', cuenta.address);
  console.log('saldo:', ethers.formatEther(saldo), 'ETH');
  if (saldo === 0n) throw new Error('La cuenta no tiene fondos de testnet');

  const registro = await (await ethers.getContractFactory('DeliveryRegistry')).deploy();
  await registro.waitForDeployment();
  const direccion = await registro.getAddress();
  const explorador = network.name === 'sepolia'
    ? 'https://sepolia.etherscan.io/address/'
    : 'https://sepolia.basescan.org/address/';
  console.log('contrato:', direccion);
  console.log('explorador: ' + explorador + direccion);

  // esperar confirmaciones antes de verificar: el explorador necesita ver el bloque
  await registro.deploymentTransaction().wait(5);
  if (process.env.ETHERSCAN_API_KEY || process.env.BASESCAN_API_KEY) {
    try {
      await run('verify:verify', { address: direccion, constructorArguments: [] });
      console.log('código verificado en el explorador');
    } catch (e) {
      console.log('no se pudo verificar:', e.message.split('\n')[0]);
    }
  }
}

main().catch((e) => { console.error(e.message); process.exit(1); });
