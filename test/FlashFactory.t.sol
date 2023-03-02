// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/FlashFactory.sol";
import "./HelperTest.t.sol";
contract FlashFactoryTest is Test, HelperTest {
    FlashFactory factory;
    address REGISTRY_ADDRESS;

    function setUp() public {
        HelperTest.main();
        vm.startPrank(DEPLOYER);
        factory = new FlashFactory(AAVE_ADDRESS_PROVIDER);
        vm.stopPrank(DEPLOYER);
        REGISTRY_ADDRESS = factory.REGISTRY();
    }

    function testConstructor() public {
        //making sure Registry and ProxyLogic have been deployed correctly
        //assertTrue(temp != address(0));
        assertTrue(factory.PROXY_LOGIC() != address(0));
        //TODO: test some getters from Registry and ProxyLogic
    }

    function createProxy() public {
        vm.startPrank(USER);
        address longToken = Mainnet_wstETH;
        address shortToken = Mainnet_wETH;
        address proxy = factory.createProxy(shortToken, longToken);
        vm.stopPrank(USER);
        assertEq(Registry(REGISTRY_ADDRESS).getCount(USER), 1);
        assertEq(Registry(REGISTRY_ADDRESS).FACTORY_ADDRESS, address(factory));
        assertEq(Registry(REGISTRY_ADDRESS).getUserProxy(USER, 0), proxy);
        //TODO assert the new proxy is in the Registry
        //assert the getters of the Proxy contract
        assertEq(ProxyPosCraft(proxy).OWNER(), address(factory));
        assertEq(ProxyPosCraft(proxy).HELPER(), factory.PROXY_LOGIC());
        assertEq(ProxyPosCraft(proxy).address_short(), address(factory));

        
    }
}
