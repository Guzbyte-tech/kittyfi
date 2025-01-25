// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {KittyCoin} from "src/KittyCoin.sol";
import {KittyPool} from "src/KittyPool.sol";
import {KittyVault, IAavePool} from "src/KittyVault.sol";
import {DeployKittyFi, HelperConfig} from "script/DeployKittyFi.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract KittyFiStatelessFuzzTest is Test {
    KittyCoin kittyCoin;
    KittyPool kittyPool;
    KittyVault wethVault;
    HelperConfig.NetworkConfig config;
    address weth;
    address meowntainer = makeAddr("meowntainer");
    address user;
    
    uint256 constant MAX_DEPOSIT = 100 ether;
    uint256 constant MAX_MINT = 50 ether;

    function setUp() external {
        HelperConfig helperConfig = new HelperConfig();
        config = helperConfig.getNetworkConfig();
        weth = config.weth;

        kittyPool = new KittyPool(
            meowntainer,
            config.euroPriceFeed,
            config.aavePool
        );

        vm.prank(meowntainer);
        kittyPool.meownufactureKittyVault(config.weth, config.ethUsdPriceFeed);

        kittyCoin = KittyCoin(kittyPool.getKittyCoin());
        wethVault = KittyVault(kittyPool.getTokenToVault(config.weth));
    }

    // Fuzz test for depositing collateral with different amounts
    function testFuzz_DepositCollateral(uint256 depositAmount) public {
        vm_assumeValidDeposit(depositAmount);
        
        user = makeAddr("user");
        deal(weth, user, depositAmount);

        vm.startPrank(user);
        IERC20(weth).approve(address(wethVault), depositAmount);
        kittyPool.depawsitMeowllateral(weth, depositAmount);
        vm.stopPrank();

        assertEq(wethVault.totalMeowllateralInVault(), depositAmount);
        assertEq(wethVault.userToCattyNip(user), depositAmount);
    }

    // Fuzz test for minting KittyCoin with different amounts
    function testFuzz_MintKittyCoin(uint256 depositAmount, uint256 mintAmount) public {
        vm_assumeValidDeposit(depositAmount);
        vm_assumeValidMint(mintAmount, depositAmount);

        user = makeAddr("user");
        deal(weth, user, depositAmount);

        vm.startPrank(user);
        IERC20(weth).approve(address(wethVault), depositAmount);
        kittyPool.depawsitMeowllateral(weth, depositAmount);
        kittyPool.meowintKittyCoin(mintAmount);
        vm.stopPrank();

        assertEq(kittyPool.getKittyCoinMeownted(user), mintAmount);
        assertEq(kittyCoin.balanceOf(user), mintAmount);
    }

    // Fuzz test for withdrawing collateral with different amounts
    function testFuzz_WithdrawCollateral(uint256 depositAmount, uint256 withdrawAmount) public {
        vm_assumeValidDeposit(depositAmount);
        vm_assumeValidWithdraw(depositAmount, withdrawAmount);

        user = makeAddr("user");
        deal(weth, user, depositAmount);

        vm.startPrank(user);
        IERC20(weth).approve(address(wethVault), depositAmount);
        kittyPool.depawsitMeowllateral(weth, depositAmount);
        
        kittyPool.whiskdrawMeowllateral(weth, withdrawAmount);
        vm.stopPrank();

        assertEq(wethVault.totalMeowllateralInVault(), depositAmount - withdrawAmount);
        assertEq(wethVault.userToCattyNip(user), depositAmount - withdrawAmount);
    }

    // Helper function to validate deposit amount
    function vm_assumeValidDeposit(uint256 depositAmount) internal {
        vm.assume(depositAmount > 0);
        vm.assume(depositAmount <= MAX_DEPOSIT);
    }

    // Helper function to validate mint amount
    function vm_assumeValidMint(uint256 mintAmount, uint256 depositAmount) internal {
        vm.assume(mintAmount > 0);
        vm.assume(mintAmount <= MAX_MINT);
        
        // Ensure collateralization ratio is maintained
        uint256 requiredCollateral = mintAmount * 169 / 100;
        vm.assume(depositAmount >= requiredCollateral);
    }

    // Helper function to validate withdraw amount
    function vm_assumeValidWithdraw(uint256 depositAmount, uint256 withdrawAmount) internal {
        vm.assume(withdrawAmount > 0);
        vm.assume(withdrawAmount <= depositAmount);
    }
}