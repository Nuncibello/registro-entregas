require('@nomicfoundation/hardhat-toolbox');

/** Red local para las pruebas; Base Sepolia para el despliegue real.
 *  La clave privada nunca vive en el repo: se lee del entorno al desplegar. */
module.exports = {
  solidity: {
    version: '0.8.26',
    settings: { optimizer: { enabled: true, runs: 200 }, viaIR: false },
  },
  paths: { sources: './contratos', tests: './test' },
  networks: {
    sepolia: {
      url: process.env.RPC_SEPOLIA || 'https://ethereum-sepolia-rpc.publicnode.com',
      accounts: process.env.CLAVE_DESPLIEGUE ? [process.env.CLAVE_DESPLIEGUE] : [],
      chainId: 11155111,
    },
    baseSepolia: {
      url: process.env.RPC_BASE_SEPOLIA || 'https://sepolia.base.org',
      accounts: process.env.CLAVE_DESPLIEGUE ? [process.env.CLAVE_DESPLIEGUE] : [],
      chainId: 84532,
    },
  },
  // Etherscan V2: una sola clave sirve para todas las cadenas, y ya no hacen
  // falta las entradas por red ni customChains.
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || '',
  },
  sourcify: { enabled: false },
};
