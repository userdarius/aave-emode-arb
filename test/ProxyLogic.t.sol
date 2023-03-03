//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../src/ProxyLogic.sol";
import "./HelperTest.t.sol";

contract ProxyLogicTest is HelperTest {
    ProxyLogic proxyLogic;

    uint256 testNumber = 42;

    function setUp() public override {
        super.setUp();
        console.log("Starting the setup of ProxyLogic by Deployer");
        vm.startPrank(DEPLOYER);
        proxyLogic = new ProxyLogic(AAVE_ADDRESS_PROVIDER, UNISWAP_ROUTER);
        vm.stopPrank();
        console.log("ProxyLogic has been setup");
    }

    function testNumberIs42() public {
        assertEq(testNumber, 42);
    }

    function testProxyLogicIsDeployed() public {
        assertEq(address(proxyLogic), address(proxyLogic));
    }

    function testGetOwner() public {
        console.log("Starting the testGetOwner");
        vm.startPrank(DEPLOYER);
        (bool _ok, bytes memory _data) = address(proxyLogic).delegatecall(
            abi.encodeWithSignature("getOwner()")
        );
        address _owner = abi.decode(_data, (address));

        assert(_owner == DEPLOYER);
        vm.stopPrank();
        assertEq(_ok, true);
    }

    function testInitialize() public {
        address longToken = Mainnet_wstETH;
        address shortToken = Mainnet_wETH;
        console.log("Starting the testInitialize");
        vm.startPrank(DEPLOYER);
        (bool _ok, ) = address(proxyLogic).delegatecall(
            abi.encodeWithSignature(
                "initialize(address,address,address)",
                DEPLOYER,
                longToken,
                shortToken
            )
        );
        vm.stopPrank();
        assertEq(_ok, true);
    }

    function testRequestFlashLoan() public {
        address poolAddy = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
        address longToken = Mainnet_wstETH;
        address shortToken = Mainnet_wETH;
        console.log("Starting the testRequestFlashLoan");
        vm.startPrank(DEPLOYER);
        (bool _ok, ) = address(proxyLogic).delegatecall(
            abi.encodeWithSignature(
                "requestFlashLoan(address,uint256)",
                shortToken,
                1000000000000000000
            )
        );
        vm.stopPrank();
        assertEq(_ok, true);
    }

    // function testLongDepositedCraft() public {
    //     console.log("Starting the testLongDepositedCraft");
    //     vm.startPrank(DEPLOYER);
    //     (bool _ok, ) = address(proxyLogic).delegatecall(
    //         abi.encodeWithSignature(
    //             "longDepositedCraft(address,uint256)",
    //             DAI,
    //             1000000000000000000
    //         )
    //     );
    //     vm.stopPrank();
    //     assertEq(_ok, true);
    // }

    // function testShortDepositedCraft() public {
    //     console.log("Starting the testShortDepositedCraft");
    //     vm.startPrank(DEPLOYER);
    //     (bool _ok, ) = address(proxyLogic).delegatecall(
    //         abi.encodeWithSignature(
    //             "shortDepositedCraft(address,uint256)",
    //             WETH,
    //             1000000000000000000
    //         )
    //     );
    //     vm.stopPrank();
    //     assertEq(_ok, true);
    // }
}
