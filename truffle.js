module.exports = {
  networks: {
    devnet: {
      host: 'localhost',
      port: 8547,
      network_id: '*',
      gas: 20e6,
      gasPrice: 15000000001
    },
    test: {
      host: 'localhost',
      port: 8545,
      network_id: '*',
      gas: 20e6,
      gasPrice: 15000000001
    }
  },
  compilers: {
    solc: {
      version: "0.4.24"
    }
  }
}
