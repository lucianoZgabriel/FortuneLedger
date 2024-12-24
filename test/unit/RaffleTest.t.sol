// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 public entranceFee;
    uint256 public interval;
    address public vrfCoordinator;
    bytes32 public gasLane;
    uint32 public callbackGasLimit;
    uint256 public subscriptionId;

    address public PLAYER = makeAddr("PLAYER");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed winner);

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function setUp() public {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.deployContract();

        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getConfig();
        entranceFee = networkConfig.entranceFee;
        interval = networkConfig.interval;
        vrfCoordinator = networkConfig.vrfCoordinator;
        gasLane = networkConfig.gasLane;
        callbackGasLimit = networkConfig.callbackGasLimit;
        subscriptionId = networkConfig.subscriptionId;
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function test_RaffleStateIsOpenWhenCreated() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function test_RaffleRevertsWhenNotEnoughEthIsSent() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function test_RaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        assert(raffle.getPlayer(0) == PLAYER);
    }

    function test_EnteringRaffleEmitsEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEnter(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function test_DontAllowEnteringWhileRaffleIsCalculating()
        public
        raffleEntered
    {
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function test_CheckUpkeepReturnsFalseIfItHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function test_CheckUpkeepReturnsFalseIfRaffleIsNotOpen()
        public
        raffleEntered
    {
        raffle.performUpkeep("");
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
        assert(raffle.getRaffleState() != Raffle.RaffleState.OPEN);
    }

    function test_CheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        uint256 timeElapsed = block.timestamp - raffle.getLastTimeStamp();
        uint256 intervalRequired = raffle.getInterval();

        assert(!upkeepNeeded);
        assert(timeElapsed < intervalRequired);
    }

    function test_CheckUpkeepReturnsFalseIfNoPlayers() public {
        vm.warp(block.timestamp + interval + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function test_CheckUpkeepReturnsTrueIfParametersAreGood()
        public
        raffleEntered
    {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    function test_PerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue()
        public
        raffleEntered
    {
        raffle.performUpkeep("");
    }

    function test_PerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = address(raffle).balance;
        uint256 numPlayers = raffle.getNumberOfPlayers();
        uint256 raffleState = uint256(raffle.getRaffleState());

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance = currentBalance + entranceFee;
        numPlayers = 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    function test_PerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEntered
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == uint256(Raffle.RaffleState.CALCULATING));
    }

    function test_FulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public raffleEntered {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function test_FulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        raffleEntered
    {
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        uint256 players = additionalEntrants + 1;
        address expectedWinner = address(1);

        for (uint256 i = startingIndex; i < players; i++) {
            address player = address(uint160(i));
            hoax(player, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * players;

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == uint256(Raffle.RaffleState.OPEN));
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
