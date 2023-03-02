// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
contract HelperTest is Test {
    address DEPLOYER= makeAddr("DEPLOYER");
    address USER = makeAddr("USER");
    address REGISTRY = makeAddr("REGISTRY");
    address AAVE_ADDRESS_PROVIDER = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address Mainnet_wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address Mainnet_wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    function main() public {
        deal(DEPLOYER, 10 ether);
        deal(USER, 10 ether);
        deal(Mainnet_wETH, USER, 10 ether);
        deal(Mainnet_wstETH, USER, 10 ether);
    }
} 