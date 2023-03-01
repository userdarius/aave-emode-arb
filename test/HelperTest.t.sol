// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
contract HelperTest is Test {
    address DEPLOYER;

    function setUp() public {

        DEPLOYER = makeAddr("DEPLOYER");
        vm.deal(DEPLOYER, 10 ether);
    }
} 