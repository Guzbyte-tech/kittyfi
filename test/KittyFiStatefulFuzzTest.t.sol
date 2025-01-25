// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {KittyCoin} from "src/KittyCoin.sol";
import {KittyPool} from "src/KittyPool.sol";
import {KittyVault, IAavePool} from "src/KittyVault.sol";
import {DeployKittyFi, HelperConfig} from "script/DeployKittyFi.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract KittyFiHandler is Test {
    KittyCoin kittyCoin;
    KittyPool kittyPool;
    KittyVault wethVault;
    address weth;
    address meowntainer;
    address[] users;

    uint256 constant MAX_USERS = 10;
    uint256 constant MAX_DEPOSIT = 100 ether;
    uint256 constant MAX_MINT = 50 ether;

    constructor(
        KittyPool _kittyPool,
        KittyVault _wethVault,
        KittyCoin _kittyCoin,
        address _weth,
        address _meowntainer
    ) {
        kittyPool = _kittyPool;
        wethVault = _wethVault;
        kittyCoin = _kittyCoin;
        weth = _weth;
        meowntainer = _meowntainer;
    }

    function deposit(uint256 userSeed, uint256 depositAmount) public {
        address user = _getUser(userSeed);
        depositAmount = bound(depositAmount, 1, MAX_DEPOSIT);

        deal(weth, user, depositAmount);
        vm.startPrank(user);
        IERC20(weth).approve(address(wethVault), depositAmount);
        kittyPool.depawsitMeowllateral(weth, depositAmount);
        vm.stopPrank();
    }

    function mint(uint256 userSeed, uint256 mintAmount) public {
        address user = _getUser(userSeed);
        uint256 userDeposit = wethVault.getUserMeowllateral(user);

        mintAmount = bound(mintAmount, 1, MAX_MINT);

        // Ensure collateralization ratio is maintained
        if (userDeposit * 100 >= mintAmount * 169) {
            vm.startPrank(user);
            kittyPool.meowintKittyCoin(mintAmount);
            vm.stopPrank();
        }
    }

    function withdraw(uint256 userSeed, uint256 withdrawAmount) public {
        address user = _getUser(userSeed);
        uint256 userCattyNip = wethVault.userToCattyNip(user);

        withdrawAmount = bound(withdrawAmount, 1, userCattyNip);

        vm.startPrank(user);
        kittyPool.whiskdrawMeowllateral(weth, withdrawAmount);
        vm.stopPrank();
    }

    function burn(uint256 userSeed, uint256 burnAmount) public {
        address user = _getUser(userSeed);
        uint256 userMinted = kittyPool.getKittyCoinMeownted(user);

        burnAmount = bound(burnAmount, 1, userMinted);

        vm.startPrank(user);
        kittyPool.burnKittyCoin(user, burnAmount);
        vm.stopPrank();
    }

    function _getUser(uint256 userSeed) internal returns (address) {
        address user = address(uint160(userSeed));

        if (users.length < MAX_USERS && !_userExists(user)) {
            users.push(user);
        }

        return user;
    }

    function _userExists(address user) internal view returns (bool) {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == user) return true;
        }
        return false;
    }
}

contract KittyFiStatefulFuzzTest is StdInvariant, Test {
    KittyCoin kittyCoin;
    KittyPool kittyPool;
    KittyVault wethVault;
    HelperConfig.NetworkConfig config;
    address weth;
    address meowntainer = makeAddr("meowntainer");
    KittyFiHandler handler;

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

        handler = new KittyFiHandler(
            kittyPool,
            wethVault,
            kittyCoin,
            weth,
            meowntainer
        );

        targetContract(address(handler));
    }

    // Invariant: Total minted KittyCoin should never exceed total collateral value
    function invariant_TotalMintedShouldNotExceedCollateral() public view {
        uint256 totalMinted = kittyCoin.totalSupply();
        uint256 totalCollateralInEuros = kittyPool.getUserMeowllateralInEuros(
            address(this)
        );

        assert(totalMinted <= (totalCollateralInEuros * 100) / 169);
    }

    // Invariant: Collateralization ratio should always be maintained
    function invariant_CollateralizationRatioMaintained() public view {
        address[] memory users = new address[](10);
        for (uint256 i = 0; i < users.length; i++) {
            users[i] = address(uint160(i + 1));
            uint256 minted = kittyPool.getKittyCoinMeownted(users[i]);
            uint256 collateralInEuros = kittyPool.getUserMeowllateralInEuros(
                users[i]
            );

            if (minted > 0) {
                assert(collateralInEuros >= (minted * 169) / 100);
            }
        }
    }

    // Invariant: Total vault collateral should be consistent
    function invariant_TotalVaultCollateralConsistent() public view {
        uint256 totalMeowllateralInVault = wethVault.getTotalMeowllateral();
        uint256 collateralInAave = wethVault.getTotalMeowllateralInAave();
        uint256 localVaultCollateral = wethVault.totalMeowllateralInVault();

        assert(
            totalMeowllateralInVault == localVaultCollateral + collateralInAave
        );
    }
}
