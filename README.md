# Chainlink VRF Raffle Smart Contract

A decentralized and verifiably random raffle system built with Solidity and Chainlink VRF v2.5. This project implements a fair lottery system where participants can enter by paying an entrance fee, and winners are selected using Chainlink's verifiable random function.

# Table of Contents

- [Chainlink VRF Raffle Smart Contract](#chainlink-vrf-raffle-smart-contract)
- [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Technologies Used](#technologies-used)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Smart Contracts](#smart-contracts)
    - [Raffle.sol](#rafflesol)
    - [HelperConfig.sol](#helperconfigsol)
    - [Interactions.sol](#interactionssol)
  - [Testing](#testing)
  - [Contract Deployment](#contract-deployment)
    - [Private Key](#private-key)
    - [Verify](#verify)
  - [Contract Addresses](#contract-addresses)
  - [Contributing](#contributing)
  - [License](#license)
  - [Acknowledgments](#acknowledgments)

## Features

- Automated random winner selection using Chainlink VRF v2.5
- Chainlink Automation for time-based raffle draws
- Multi-chain support (Sepolia, BSC Testnet, Local)
- Fully tested and verified smart contracts
- Configurable entrance fees and time intervals

## Technologies Used

- Solidity v0.8.19
- Foundry Framework
- Chainlink VRF v2.5
- Chainlink Automation

## Prerequisites

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Make](https://www.gnu.org/software/make/)

## Installation

1. Clone the repository

```
git clone https://github.com/lucianoZgabriel/FortuneLedger
cd FortuneLedger

```

2. Install dependencies

```
make install
```

3. Create a .env file with the following variables:

```
SEPOLIA_RPC_URL=your_sepolia_rpc_url
BSC_RPC_URL=your_bsc_rpc_url
BSC_API_KEY=your_bscscan_api_key
ETHERSCAN_API_KEY=your_etherscan_api_key
PRIVATE_KEY=your_wallet_private_key
```

## Smart Contracts

### Raffle.sol

The main contract that handles:

- Raffle entry
- Random winner selection
- Prize distribution
- State management

### HelperConfig.sol

Manages network-specific configurations for:

- Entrance fees
- Time intervals
- VRF Coordinator addresses
- Gas lanes
- Subscription IDs

### Interactions.sol

Handles Chainlink VRF setup:

- Subscription creation
- Subscription funding
- Consumer registration

## Testing

Run the test suite:

```
make test
```

## Contract Deployment

Before run the deploy command, you need to create a .env file with the correct variables. (see next section for more details)
Then run the command:

```
source .env
make deploy-bsc
```

### Private Key

The private key is the key of the wallet that will deploy the contract.
If you prefer use your private key from the .env file, which is not recommended, you can use the command:

```
make deploy-bsc-private-key
```

The recommended way is importing your private key into a encrypted keystore.
In the Makefile, the account name is "metamask", if your account name is different, you need to change it.

```
cast wallet import [options] account_name
```

### Verify

The deploy command will verify the contract in the blockchain. Testnet sometimes has issues with the verification, in case of failure, you can verify manually through the BSCScan website.
After the Deploy, you can see the contract address in the terminal.
So you run:

```
forge verify-contract  src/Raffle.sol:Raffle  (contract_address) --etherscan-api-key $BSC_API_KEY --rpc-url $BSC_RPC_URL --show-standard-json-input > json.json
```

This will generate a json file, you need to copy the content of the file and paste in the BSCScan website.

## Contract Addresses

- Sepolia VRF Coordinator: `0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B`
- BSC Testnet VRF Coordinator: `0xDA3b641D438362C440Ac5458c57e00a712b66700`

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Chainlink VRF Documentation](https://docs.chain.link/vrf/v2/introduction)
- [Foundry Book](https://book.getfoundry.sh/)
