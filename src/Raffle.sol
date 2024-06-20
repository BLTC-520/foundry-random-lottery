// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
/**
 * @title A sample Raffle Contract 
 * @author Brian Har
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 */
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Errors */
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );
    error Raffle__TransferFailed();
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__RaffleNotOpen();

    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    /* State variables */
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
// NOTE! As of newer versions of Chainlink, the subscription id is a uint256 instead of a uint64
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    uint256 private immutable i_interval;
    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address payable[] private s_players;
    RaffleState private s_raffleState;

    /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);

    /* Functions */
    constructor(
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_entranceFee = entranceFee;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
    }
    // external is more gas efficient too
    function enterRaffle() external payable {
    // require(msg.value >= i_entranceFee, "Not enough ETH sent"); ("if false more gas efficient")
    // require(s_raffleState = RaffleState.OPEN, "Raffle State is not OPEN!")
        if(msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }

        // after done checking, add players to the array!
        s_players.push(payable(msg.sender));
        // Emit an event when we update a dynamic array or mapping
        // Named events with the function name reversed - good practice
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */

    function checkUpkeep (bytes memory /*checkData*/) public view override returns 
    (bool upkeepNeeded, bytes memory /*performData*/) {
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasPlayers && hasBalance); // all have to be true
        return (upkeepNeeded, "0x0");
        // 由于 performData 在这个实现中没有实际用途，所以返回了 "0x0"。
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */

    function performUpkeep(bytes calldata /*performData*/) external override {
    (bool upkeepNeeded, ) = checkUpkeep("");
    // 这段代码的执行过程如下：
    // 调用 checkUpkeep("")，获取两个返回值。
    // 将第一个返回值 upkeepNeeded 赋值给 bool 类型的变量 upkeepNeeded。
    // 第二个返回值（performData）被忽略。
    if(!upkeepNeeded) {
        revert Raffle__UpkeepNotNeeded (
            address(this).balance,
            s_players.length,
            uint256(s_raffleState)
        );
    }
    // turn state to CALCULATING 
    s_raffleState = RaffleState.CALCULATING;

    // 向VRF请求随机数
    uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gas lane 
            i_subscriptionId, 
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId); // 这行是否多余？
        // 触发 `RequestedRaffleWinner` 事件是否多余取决于外部系统或用户是否需要知道请求随机数的时间。
     }

    function fulfillRandomWords(uint256 /*requestID */, uint256[] memory randomWords)
    internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        // reset 
        s_players = new address payable[](0); // reset the whole array
        s_raffleState = RaffleState.OPEN; // state change to open
        s_lastTimeStamp = block.timestamp; // reset the blocktime 

        emit WinnerPicked(recentWinner); // event WinnerPicked(address indexed player);
        // (bool success, bytes memory data) = targetAddress.call{value: amount, gas: gasLimit}("functionSignature");
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(success, "Transfer failed");
        if(!success) {
            revert Raffle__TransferFailed();
        }
        
    }
    /** Getter Function */
    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
}