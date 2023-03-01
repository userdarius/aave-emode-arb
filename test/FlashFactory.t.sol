// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/FlashFactory.sol";
import "./HelperTest.t.sol";
contract FlashFactoryTest is Test, HelperTest {
    FlashFactory factory;

    function setUp() public {
        vm.startPrank(DEPLOYER);
        factory = new FlashFactory(AAVE_ADDRESS_PROVIDER);
        vm.stopPrank(DEPLOYER);
    }

    function testConstructor() public {
        //making sure Registry and ProxyLogic have been deployed correctly
        assertTrue(factory.REGISTRY() != 0x0);
        assertTrue(factory.PROXY_LOGIC() != 0x0);
        //TODO: test some getters from Registry and ProxyLogic
    }

    function createProxy() public {
        vm.startPrank(USER);
        address longToken = Mainnet_wstETH;
        address shortToken = Mainnet_wETH;
        address proxy = factory.createProxy(shortToken, longToken);
        vm.stopPrank(USER);
        Registry(REGISTRY).getCount(USER);
        assertEq(Registry(REGISTRY).getCount(USER), 1);
        assertEq(Registry(REGISTRY).FACTORY_ADDRESS, address(factory));
        //TODO assert the new proxy is in the Registry
        //assert the getters of the Proxy contract
        
    }
}
