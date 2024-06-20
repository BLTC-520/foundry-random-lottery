//SPDX-Identifier-License:MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {  
    /* Errors */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint64 subscriptionId;
    bytes32 gasLane;// keyHash
    uint256 interval;
    uint256 entranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2;
    address link;

    address public PLAYER = makeAddr("player"); // cheatcodes
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        (
        subscriptionId,
        gasLane, // keyHash
        interval,
        entranceFee,
        callbackGasLimit,
        vrfCoordinatorV2,
        ,
        ) = helperConfig.activeNetworkConfig();


    }

    function testRaffleInitializeInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN); 
        // any Raffle contract that Type(RaffleState) and get the OPEN value 
    }


    ///////////////////////////
    // Enter Raffle Part!    // 
    ///////////////////////////

    function testRaffleRevertsWhenYouDontPayEnoughEth () public {
    // Arrange 
        vm.prank(PLAYER);
    // Act / Assert
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);

        raffle.enterRaffle(); // not sending any value as entrance 
    }

    function testRaffleRecordsPlayersWhenEnter() public {
    // Arrange 
        vm.prank(PLAYER);
    // Act
        raffle.enterRaffle{value: entranceFee}(); // 因为你要test的function是有payable keyword 所以写法是这样
    // Assert 
        address playerRecorded = raffle.getPlayer(0);
        assertEq(playerRecorded, PLAYER);
    }

    function testEmitsWhenEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
    // 如果你只关心事件是否发出（即只检查事件签名 (hash)），
    // 可以使用 vm.expectEmit(true, false, false, false, address(raffle))
    // 你想要验证第一个参数 + 事件是否已经发出，topics[0](indexed keywords), topics[1]的话就 true, true, false, false 
        emit RaffleEnter(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
    
    function testCantEnterWhenRaffleIsCalculating() public {
		vm.prank(PLAYER);
		raffle.enterRaffle{value: entranceFee}();
		vm.warp(block.timestamp + interval + 1);
		vm.roll(block.number + 1);
		raffle.performUpkeep("");

		vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
		vm.prank(PLAYER);
		raffle.enterRaffle{value: entranceFee}();
    }

    ///////////////////////////
    /// checkUpkeep Part!  ////
    ///////////////////////////

    function testCheckUpKeepReturnsFalseIfIthasNoBalance () public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfRaffleNotOpen () public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }
	// C1
	function testCheckUpKeepReturnsFalseIfEnoughTimeHasntPassed () public {
	// Arrange 
		vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
	// Act 
		(bool upkeepNeeded, ) = raffle.checkUpkeep("");
	// Assert
		assert(!upkeepNeeded);
	}
	// C2
	function testCheckUpKeepReturnsTrueWhenParametersAreGood () public {
	// Arrange 
		vm.prank(PLAYER);
		raffle.enterRaffle{value: entranceFee}();
		vm.warp(block.timestamp + interval + 1);
		vm.roll(block.number + 1);
	// Act 
		(bool upkeepNeeded, ) = raffle.checkUpkeep("");
	// Assert 
		assert(upkeepNeeded);
	}

	//////////////////
	// performUpkeep /
	//////////////////

	function testPerformUpKeepIsWorkingOnlyIfCheckUpKeepIsTrue () public { 
		// arrange 
		vm.prank(PLAYER);
		raffle.enterRaffle{value: entranceFee}();
		vm.warp(block.timestamp + interval + 1); // this is letting the timePassed in chckUpkeep to be true
		vm.roll(block.number + 1); // stimulating a new block is mined 

		raffle.performUpkeep(""); // This call to performUpkeep should only be successful if checkUpkeep returns true, which will be the case if all the conditions (timePassed, isOpen, hasPlayers, hasBalance) are true.
	}

	function testPerformUpKeepRevertsIfCheckUpKeepIsFalse () public {
		// arrange 
		uint256 currentBalance = 0;
		uint256 numPlayers = 0;
		uint256 raffleState = 0;
		vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, raffleState));
		raffle.performUpkeep(""); 
	}

    modifier raffleEnteredAndTimePassed () {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId () public raffleEnteredAndTimePassed {
        vm.recordLogs(); // auto save all the logs outputs 
        raffle.performUpkeep(""); // emit the requestId 
        Vm.Log[] memory entries = vm.getRecordedLogs(); 
        bytes32 requestId = entries[1].topics[1]; 
        // 0th topic is the entire hash of the event, 1st topic is the requestId
        Raffle.RaffleState rState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1); // 1 is the value of RaffleState.CALCULATING
    }

    ////////////////////////
    // fulfillRandomWords //
    ////////////////////////

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep (uint256 randomRequestId) public raffleEnteredAndTimePassed skipFork{
        // Arrange 
        vm.expectRevert("nonexistent request"); // line 122 of VRFCoordinatorV2Mock.sol 
        // -> expecting the revert this message when there is no requestId
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(randomRequestId, address(raffle)); 
        // Fuzz test --> Foundry will put random test cases to test the function
    }
    
    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEnteredAndTimePassed skipFork {
        // Arrange 
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;
        uint256 previousTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants + 1); // 1 is the original player

        for(uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
            address player = address(uint160(i)); // like makeAddr("player") 
            hoax(player, STARTING_USER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }
        
        vm.recordLogs(); // auto save all the logs outputs 
        raffle.performUpkeep(""); // emit the requestId 
        Vm.Log[] memory entries = vm.getRecordedLogs(); 
        bytes32 requestId = entries[1].topics[1]; 
        // pretend to be the Chainlink VRF Coordinator (mock)
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(uint256(requestId), address(raffle)); 
        

        // Assert 
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN); // should back to open
        assert(raffle.getRecentWinner() != address(0)); // should have a recent winner 
        assert(raffle.getNumberOfPlayers() == 0); // should reset the players array
        assert(previousTimeStamp < raffle.getLastTimeStamp()); // should reset the blocktime
        assert(raffle.getRecentWinner().balance == prize + STARTING_USER_BALANCE - entranceFee); 
    }
}


