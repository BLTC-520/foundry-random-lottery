# Provably Random Raffle Contracts

A smart contract lottery implementation using Chainlink VRF and Automation for provably fair randomness and automatic winner selection.

## Overview

This project implements a decentralized raffle system that ensures fairness through cryptographic randomness and automated execution. Built with Foundry and leveraging Chainlink's oracle services.

## Features

- **Provably Fair**: Uses Chainlink VRF (Verifiable Random Function) for cryptographically secure randomness
- **Automated Execution**: Chainlink Automation triggers winner selection after specified time intervals  
- **Gas Optimized**: Efficient contract design with custom errors and optimized state management
- **Multi-Network Support**: Configured for Sepolia testnet and local Anvil development
- **Comprehensive Testing**: Full test suite with unit tests and fuzz testing

## How It Works

1. **Entry Phase**: Users enter the raffle by paying the entrance fee
2. **Collection Period**: The contract collects entries for a specified time interval
3. **Winner Selection**: After the time period, Chainlink Automation triggers the lottery
4. **Random Selection**: Chainlink VRF provides verifiable randomness to select the winner
5. **Prize Distribution**: The winner receives the entire prize pool automatically

## Technology Stack

- **Smart Contracts**: Solidity ^0.8.19
- **Development Framework**: Foundry
- **Randomness**: Chainlink VRF v2
- **Automation**: Chainlink Keepers/Automation
- **Testing**: Forge with comprehensive unit tests

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Installation

```bash
git clone https://github.com/yourusername/foundry-random-lottery
cd foundry-random-lottery
make install
```

### Build

```bash
make build
```

### Test

```bash
make test
```

### Deploy

#### Local Deployment (Anvil)
```bash
make anvil    # In one terminal
make deploy   # In another terminal
```

#### Testnet Deployment (Sepolia)
```bash
make deploy ARGS="--network sepolia"
```

## Configuration

### Environment Variables

Create a `.env` file with:

```bash
SEPOLIA_RPC_URL=your_sepolia_rpc_url
PRIVATE_KEY=your_private_key
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### Network Configuration

- **Sepolia**: Pre-configured with Chainlink VRF Coordinator and LINK token addresses
- **Anvil**: Uses mock contracts for local development

## Contract Architecture

### Core Contracts

- **Raffle.sol**: Main lottery contract with VRF and Automation integration
- **DeployRaffle.s.sol**: Deployment script with network-specific configuration
- **HelperConfig.s.sol**: Network configuration management
- **Interactions.s.sol**: Scripts for VRF subscription management

### Key Parameters

- **Entrance Fee**: 0.01 ETH
- **Interval**: 30 seconds
- **Gas Lane**: Chainlink VRF gas lane for transaction speed/cost balance
- **Callback Gas Limit**: 500,000 gas for VRF callback execution

## Testing

The project includes comprehensive tests:

- **Unit Tests**: Individual function testing
- **Integration Tests**: End-to-end workflow testing  
- **Fuzz Tests**: Random input testing for edge cases
- **Fork Tests**: Testing against live networks

Run specific test categories:
```bash
forge test --match-contract RaffleTest
forge test --fork-url $SEPOLIA_RPC_URL
```

## Gas Optimization

- Custom error messages instead of require statements
- Efficient state variable packing
- Minimal external calls
- Optimized loops and conditionals

## Security Features

- Reentrancy protection through state changes before external calls
- Access control for critical functions
- Input validation and bounds checking
- Safe math operations (Solidity ^0.8.0)

## Scripts and Automation

Available Make commands:
- `make deploy`: Deploy to configured network
- `make test`: Run full test suite
- `make format`: Format code with Forge
- `make snapshot`: Generate gas snapshots
- `make clean`: Clean build artifacts

## License

MIT License - see LICENSE file for details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Future Work
1. Make it a full-stack project (working on it with RainbowKit and wagmi)

For questions or issues, please open an issue in the repository or contact the maintainers.
