// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ProxyCraftPos.sol";
import "../src/ProxyLogic.sol";
import "./HelperTest.t.sol";
contract ProxyTest is Test, HelperTest {
    address FAKE_FACTORY;
    address AAVE_ADDRESS_PROVIDER = 0x0;
    address PROXY_LOGIC;
    address Mainnet_wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address Mainnet_wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

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
        address long_asset = Mainnet_wstETH;
        address short_asset = Mainnet_wETH;
        ProxyCraftPos proxy = new ProxyCraftPos(PROXY_LOGIC, short_asset, long_asset);
        vm.stopPrank(FAKE_FACTORY);
        
    }

    function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
