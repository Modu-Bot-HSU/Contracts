// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployAll} from "../script/DeployAll.s.sol";
import {HsToken} from "../src/HsToken.sol";
import {HsNft} from "../src/HsNft.sol";

contract HsTokenTest is Test {
    HsToken public hsToken;
    HsNft public hsNft;
    DeployAll public deployer;

    address public owner;
    address public USER1 = makeAddr("user1");
    address public USER2 = makeAddr("user2");

    uint256 public constant INITIAL_SUPPLY = 100 ether;
    uint256 public constant REWARD_AMOUNT = 10 ether;
    uint256 public constant NFT_PRICE = 5 ether;

    event RewardIssued(address indexed user, uint256 amount);
    event NftPurchased(
        address indexed buyer,
        uint256 indexed index,
        uint256 tokenId,
        uint256 price
    );

    function setUp() public {
        deployer = new DeployAll();
        (hsToken, hsNft) = deployer.run();

        // deployer.run() 내부의 vm.startBroadcast()에 의해 생성된 컨트랙트의 owner 가져옴
        owner = hsToken.owner();
    }

    /* ====================================
       [HsToken.sol] 테스트 케이스
    ==================================== */

    function test_InitialSupplyAndOwner() public view {
        assertEq(hsToken.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(hsToken.owner(), owner);
    }

    function test_MintOnlyOwner() public {
        vm.prank(owner);
        hsToken.mint(USER1, 50 ether);
        assertEq(hsToken.balanceOf(USER1), 50 ether);
    }

    function test_RevertMintNotOwner() public {
        vm.prank(USER1);
        vm.expectRevert();
        hsToken.mint(USER1, 50 ether);
    }

    function test_GetBalanceOf() public {
        vm.prank(owner);
        hsToken.mint(USER1, 10 ether);
        assertEq(hsToken.getBalanceOf(USER1), 10 ether);
    }

    function test_RewardUser() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit RewardIssued(USER1, REWARD_AMOUNT);
        hsToken.rewardUser(USER1, REWARD_AMOUNT);

        assertEq(hsToken.balanceOf(USER1), REWARD_AMOUNT);
    }

    function test_RevertRewardUserNotOwner() public {
        vm.prank(USER1);
        vm.expectRevert();
        hsToken.rewardUser(USER2, REWARD_AMOUNT);
    }

    function test_RevertRewardUserZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid address");
        hsToken.rewardUser(address(0), REWARD_AMOUNT);
    }

    function test_RevertRewardUserZeroAmount() public {
        vm.prank(owner);
        vm.expectRevert("Reward amount must be greater than 0");
        hsToken.rewardUser(USER1, 0);
    }

    /* ====================================
       [HsNft.sol] 테스트 케이스
    ==================================== */

    function test_NftOwnerIsCorrect() public view {
        assertEq(hsNft.owner(), owner);
    }

    function test_BuyNftForUserSuccess() public {
        // 1. 유저에게 토큰 지급 (보상)
        vm.startPrank(owner);
        hsToken.rewardUser(USER1, NFT_PRICE);
        vm.stopPrank();

        // 2. 유저가 HsNft 컨트랙트가 자신의 토큰을 사용할 수 있도록 approve
        vm.startPrank(USER1);
        hsToken.approve(address(hsNft), NFT_PRICE);
        vm.stopPrank();

        // 3. Owner(관리자 서버)가 유저를 위해 NFT 구매 실행
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit NftPurchased(USER1, 0, 0, NFT_PRICE);
        hsNft.buyNftForUser(USER1, 0, NFT_PRICE);
        vm.stopPrank();

        // 4. 상태 확인: 유저 잔액 차감, Nft 소유권 이전 확인
        assertEq(hsToken.balanceOf(USER1), 0);
        assertEq(hsNft.ownerOf(0), USER1);
        assertEq(hsNft.getNftOwner(0), USER1);
    }

    function test_RevertBuyNftForUserNotOwner() public {
        vm.startPrank(USER1);
        vm.expectRevert();
        hsNft.buyNftForUser(USER1, 0, NFT_PRICE);
        vm.stopPrank();
    }

    function test_RevertBuyNftForUserOutOfRange() public {
        vm.startPrank(owner);
        vm.expectRevert("Out of range");
        hsNft.buyNftForUser(USER1, 20, NFT_PRICE);
        vm.stopPrank();
    }

    function test_RevertBuyNftAlreadySold() public {
        // 첫번째 구매 (성공)
        vm.prank(owner);
        hsToken.rewardUser(USER1, NFT_PRICE);

        vm.prank(USER1);
        hsToken.approve(address(hsNft), NFT_PRICE);

        vm.prank(owner);
        hsNft.buyNftForUser(USER1, 0, NFT_PRICE);

        // 두번째 구매 (동일한 NFT 인덱스 0번 요청 시 이미 팔렸으므로 Revert)
        vm.prank(owner);
        hsToken.rewardUser(USER2, NFT_PRICE);

        vm.prank(USER2);
        hsToken.approve(address(hsNft), NFT_PRICE);

        vm.prank(owner);
        vm.expectRevert("Already sold");
        hsNft.buyNftForUser(USER2, 0, NFT_PRICE);
    }

    function test_RevertBuyNftWithoutApproval() public {
        // 보상만 지급 (approve 안함)
        vm.prank(owner);
        hsToken.rewardUser(USER1, NFT_PRICE);

        // 유저가 approve를 안 한 상태에서 구매 프로세스 진행 시, transferFrom에서 실패해야 함
        vm.prank(owner);
        vm.expectRevert(); // OZ ERC20 내부의 InsufficientAllowance 커스텀 에러 또는 일반 에러 발생
        hsNft.buyNftForUser(USER1, 0, NFT_PRICE);
    }

    function test_GetInventoryStatus() public {
        // 첫 구매
        vm.prank(owner);
        hsToken.rewardUser(USER1, NFT_PRICE);

        vm.prank(USER1);
        hsToken.approve(address(hsNft), NFT_PRICE);

        // index 1 구매
        vm.prank(owner);
        hsNft.buyNftForUser(USER1, 1, NFT_PRICE);

        bool[20] memory status = hsNft.getInventoryStatus();
        assertEq(status[0], false);
        assertEq(status[1], true);
        assertEq(status[2], false);
    }

    function test_GetNftOwnerNotSold() public view {
        // 아직 팔리지 않은 NFT는 owner를 물어봤을 때 address(0) 반환
        assertEq(hsNft.getNftOwner(5), address(0));
    }

    function test_TokenUriMapping() public {
        // 1. 유저에게 토큰 지급 (보상)
        vm.startPrank(owner);
        hsToken.rewardUser(USER1, NFT_PRICE);
        vm.stopPrank();

        // 2. 유저가 HsNft 컨트랙트가 자신의 토큰을 사용할 수 있도록 approve
        vm.startPrank(USER1);
        hsToken.approve(address(hsNft), NFT_PRICE);
        vm.stopPrank();

        // 3. Owner(관리자 서버)가 유저를 위해 NFT 구매 실행 (0번)
        vm.startPrank(owner);
        hsNft.buyNftForUser(USER1, 0, NFT_PRICE);
        vm.stopPrank();

        // 4. 생성된 URI 확인
        string memory uri = hsNft.tokenURI(0);
        
        // .env에서 읽어온 BASE_URI와 tokenId(0)가 합쳐졌는지 확인
        string memory baseUri = vm.envString("NFT_BASE_URI");
        string memory expectedUri = string(abi.encodePacked(baseUri, "0"));
        
        assertEq(uri, expectedUri);
        console.log("Token 0 URI:", uri);
    }

    function test_SetBaseURI() public {
        string memory newUri = "ipfs://NEW_CID/";
        
        vm.prank(owner);
        hsNft.setBaseURI(newUri);
        
        // 0번 구매 시뮬레이션
        vm.prank(owner);
        hsToken.rewardUser(USER1, NFT_PRICE);
        vm.prank(USER1);
        hsToken.approve(address(hsNft), NFT_PRICE);
        vm.prank(owner);
        hsNft.buyNftForUser(USER1, 0, NFT_PRICE);

        assertEq(hsNft.tokenURI(0), string(abi.encodePacked(newUri, "0")));
    }
}
