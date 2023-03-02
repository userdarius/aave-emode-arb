// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/FlashFactory.sol";
import "./HelperTest.t.sol";
import "../src/ProxyCraftPos.sol";
contract FlashFactoryTest is Test, HelperTest {
    FlashFactory factory;
    address REGISTRY_ADDRESS;

    function setUp() public {
        HelperTest.main();
        vm.startPrank(DEPLOYER);
        factory = new FlashFactory(AAVE_ADDRESS_PROVIDER);
        vm.stopPrank();
        REGISTRY_ADDRESS = factory.REGISTRY();
    }

    function testConstructor() public {
        //making sure Registry and ProxyLogic have been deployed correctly
        //assertTrue(temp != address(0));
        assertTrue(factory.PROXY_LOGIC() != address(0));
    }

    function createProxy() public {
        //TODO: test some getters from Registry and ProxyLogic
        vm.startPrank(USER);
        address longToken = Mainnet_wstETH;
        address shortToken = Mainnet_wETH;
        address proxy_address = factory.createProxy(shortToken, longToken);
        vm.stopPrank();
        Registry registry  = Registry(REGISTRY_ADDRESS);
        assertEq(registry.getCount(USER), 1);
        assertEq(registry.FACTORY_ADDRESS(), address(factory));
        assertEq(registry.getUserProxy(USER, 0), proxy_address);
        //TODO assert the new proxy is in the Registry
        //assert the getters of the Proxy contract
        ProxyCraftPos proxy = ProxyCraftPos(proxy_address);
        assertEq(proxy.OWNER(), address(factory));
        assertEq(proxy.HELPER(), factory.PROXY_LOGIC());
        assertEq(proxy.address_short(), address(factory));
        
    }
}
