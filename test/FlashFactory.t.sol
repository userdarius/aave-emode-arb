// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/FlashFactory.sol";
import "./HelperTest.t.sol";
import "../src/ProxyCraftPos.sol";
contract FlashFactoryTest is HelperTest {
    FlashFactory factory;
    address REGISTRY_ADDRESS;

    function setUp() public override {
        super.setUp();
        console.log("Starting the setup of FlashFactory by Deployer");
        vm.startPrank(DEPLOYER);
        factory = new FlashFactory(AAVE_ADDRESS_PROVIDER, UNISWAP_ROUTER);
        vm.stopPrank();
        REGISTRY_ADDRESS = factory.REGISTRY();
        console.log("FlashFactory has been setup");
    }

    function testConstructor() public {
        //making sure Registry and ProxyLogic have been deployed correctly
        assertTrue(factory.PROXY_LOGIC() != address(0));
        assertTrue(factory.REGISTRY() != address(0));
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
        ProxyCraftPos proxy = ProxyCraftPos(payable(proxy_address));
        vm.startPrank(USER);
        assertEq(proxy.admin(), USER);
        assertEq(proxy.implementation(), factory.PROXY_LOGIC());
        vm.stopPrank();


        //To call proxy functions, you need to use a selector else there are compilation errors
        //see example below
        (bool _ok, bytes memory data) = proxy_address.call(abi.encodeWithSignature("address_short()"));
        (address _factory_address) = abi.decode(data, (address));
        assertEq(_factory_address, address(factory));
        
    }
}
