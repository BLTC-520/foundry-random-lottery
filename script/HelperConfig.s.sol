// SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";


contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        uint64 subscriptionId;
        bytes32 gasLane; // keyHash
        uint256 interval;
        uint256 entranceFee;
        uint32 callbackGasLimit;
        address vrfCoordinatorV2;
        address link;
        uint256 deployerkey;
    }
    
    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if(block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig ({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinatorV2: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId : 0,
            callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerkey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig () public returns (NetworkConfig memory) {
    if(activeNetworkConfig.vrfCoordinatorV2 != address(0)) {
        return activeNetworkConfig;
        }

    uint96 baseFee = 0.25 ether; //0.25 LINK
    uint96 gasPriceLink = 1e9; // 1 gwei LINK

    vm.startBroadcast();
    VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
    LinkToken link = new LinkToken();
    vm.stopBroadcast();

    return NetworkConfig ({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinatorV2: address(vrfCoordinatorV2Mock),
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId : 0,
            callbackGasLimit: 500000,
            link: address(link),
            deployerkey: DEFAULT_ANVIL_KEY
        });
    }
}