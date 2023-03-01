// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/FlashFactory.sol";
import "./HelperTest.t.sol";
contract FlashFactoryTest is Test, HelperTest {

    function setUp() public {
        vm.startPrank(DEPLOYER);
        FlashFactory factory = new FlashFactory();
        vm.stopPrank(DEPLOYER);
    }

    function testConstructor() public {
        assertfactory.REGISTRY()
    }

    function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
