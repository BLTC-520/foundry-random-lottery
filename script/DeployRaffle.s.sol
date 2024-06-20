// SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (
            uint64 subscriptionId, // if this is default 0, we're unable to make a new call 
            bytes32 gasLane, // keyHash
            uint256 interval,
            uint256 entranceFee,
            uint32 callbackGasLimit,
            address vrfCoordinatorV2,
            address link,
            uint256 deployerkey
        ) = helperConfig.activeNetworkConfig();

        if(subscriptionId == 0) { 
            // if we don't have a subscription
            // 1. we are going to need to create a subscription
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinatorV2, deployerkey);

            // 2. Fund It!
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinatorV2, subscriptionId, link, deployerkey);
        }
        vm.startBroadcast(deployerkey);
        Raffle raffle = new Raffle(
            subscriptionId,
            gasLane,
            interval,
            entranceFee,
            callbackGasLimit,
            vrfCoordinatorV2
        );
        vm.stopBroadcast();
        // 3. Add a consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), vrfCoordinatorV2, subscriptionId, deployerkey);
        return (raffle, helperConfig);  
    }
}