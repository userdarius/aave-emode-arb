// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ProxyCraftPos.sol";
import "../src/ProxyLogic.sol";
import "./HelperTest.t.sol";

import "../src/AaveTransferHelper.sol";
contract ProxyCraftPosTest is HelperTest {
    address FAKE_FACTORY;
    address PROXY_LOGIC;
    address proxyAddress;
    address longToken;
    address shortToken;

    function setUp() public override {
        super.setUp();
        //Deploy the proxy logic with DEPLOYER
        console.log("Starting the setup of ProxyCraftPos by Deployer");
        vm.startPrank(DEPLOYER);
        PROXY_LOGIC = address(new ProxyLogic(AAVE_ADDRESS_PROVIDER, UNISWAP_ROUTER));
        vm.stopPrank();
        //Emulate the deployement of the factory with an EOA
        FAKE_FACTORY = makeAddr("FAKE_FACTORY");
        deal(FAKE_FACTORY, 10 ether);
        //Deploy a proxy from the FAKE_FACTORY
        vm.startPrank(FAKE_FACTORY);
        longToken = Mainnet_wstETH;
        shortToken = Mainnet_wETH;
        //TODO: deploy a ProxyLogic contract
        console.log(PROXY_LOGIC);
        ProxyCraftPos proxy = new ProxyCraftPos(PROXY_LOGIC, USER, shortToken, longToken);
        vm.stopPrank();
        proxyAddress = address(proxy);
        console.log("ProxyCraftPos has been setup");
    }

    function testCraftPos() public {
        //console.log(string(bytes4(keccak256(bytes("craftPosition(bool,uint256,uint256)")))));
        vm.startPrank(USER);
        AaveTransferHelper.safeApprove(longToken, proxyAddress, IERC20(longToken).balanceOf(USER));
        (bool _ok, bytes memory data) = proxyAddress.call(abi.encodeWithSignature("craftPosition(bool,uint256,uint256)", true, 1000, 2));
        vm.stopPrank();
        assertTrue(_ok);
    }

    function testConstructor() public {
        console.log("Starting testConstructor");
        //TODO: assert "address_short, address_long, owner"
        (, bytes memory data) = proxyAddress.call(abi.encodeWithSignature("address_short()"));
        console.log(abi.decode(data, (address)));
        assertEq(abi.decode(data, (address)), shortToken);
        //assertEq(proxyAddress.call(abi.encodeWithSignature("address_long()")), longToken);
        //assertEq(proxyAddress.call(abi.encodeWithSignature("owner()")), USER);
    }


}
