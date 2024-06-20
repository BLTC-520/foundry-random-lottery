// SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig () public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        ( , , , , ,address vrfCoordinatorV2, ,uint256 deployerkey) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinatorV2, deployerkey);
    }

    function createSubscription (address vrfCoordinatorV2, uint256 deployerkey) public returns (uint64) {
        console.log("Creating a subscription");
        vm.startBroadcast(deployerkey);
        uint64 subscriptionId = VRFCoordinatorV2Mock(vrfCoordinatorV2).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription created with id: ", subscriptionId);
        console.log("Please update subscription ID in HelperConfig");
        return subscriptionId;
    }

    function run() external returns (uint64) 
    {
        return createSubscriptionUsingConfig();
        // create a subscription
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (uint64 subscriptionId , , , , ,address vrfCoordinatorV2, address link,uint256 deployerkey ) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinatorV2, subscriptionId, link, deployerkey); 
    }
    function fundSubscription (address vrfCoordinatorV2, uint64 subscriptionId, address link, uint256 deployerkey) public {
        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinatorV2);
        console.log("On ChainID: ", block.chainid);  
        if(block.chainid == 31337) {
            vm.startBroadcast(deployerkey);
            VRFCoordinatorV2Mock(vrfCoordinatorV2).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerkey);
            LinkToken(link).transferAndCall(vrfCoordinatorV2, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() external {
    return fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
         (uint64 subscriptionId , , , , ,address vrfCoordinatorV2, ,uint256 deployerkey) = helperConfig.activeNetworkConfig();
         addConsumer(raffle, vrfCoordinatorV2, subscriptionId, deployerkey);
    }

    function addConsumer (address raffle, address vrfCoordinatorV2, uint64 subscriptionId, uint256 deployerkey) public {
        console.log("Adding consumer contract: ", raffle);
        console.log("Using vrfCoordinator: ", vrfCoordinatorV2);
        console.log("On ChainID: ", block.chainid);  
        vm.startBroadcast(deployerkey);
        VRFCoordinatorV2Mock(vrfCoordinatorV2).addConsumer(subscriptionId, raffle);
        vm.stopBroadcast();
    }
    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
    }
}