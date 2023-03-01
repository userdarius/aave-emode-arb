// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ProxyCraftPos.sol";
import "../src/ProxyLogic.sol";
import "./HelperTest.t.sol";
contract ProxyTest is Test, HelperTest {
    address FAKE_FACTORY;
    address PROXY_LOGIC;

    function setUp() public {
        //Deploy the proxy logic with DEPLOYER
        vm.startPrank(DEPLOYER);
        PROXY_LOGIC = address(new ProxyLogic(AAVE_ADDRESS_PROVIDER));
        vm.stopPrank();

        //Emulate the deployement of the factory with an EOA
        FAKE_FACTORY = makeAdrr("FAKE_FACTORY");
        deal(FAKE_FACTORY, 10 ether);
    }

    function testConstructor() public {
        //Deploy a proxy from the FAKE_FACTORY
        vm.startPrank(FAKE_FACTORY);
        address longToken = Mainnet_wstETH;
        address shortToken = Mainnet_wETH;
        ProxyCraftPos proxy = new ProxyCraftPos(PROXY_LOGIC, shortToken, longToken);
        vm.stopPrank(FAKE_FACTORY);

    }

    function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
