
//SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProxyLogic.sol";
import "./ProxyCraftPos.sol";
import "./Registry.sol";

contract FlashFactory {
    address public REGISTRY;
    address public PROXY_LOGIC;
    address AAVE_ADDRESS_PROVIDER;

    function getUniswapV3Pool(address token0, address token1)
        external
        view
        returns (address)
    {
        return uniswapV3Pools[token0][token1];
    }

    constructor(address aaveAddressProvider, address helper) {
        REGISTRY = address(new Registry(address(this)));
        PROXY_LOGIC = address(new ProxyLogic(aaveAddressProvider));
    }

    function createProxy(address shortToken, address longToken) public returns (address newProxyAddress){
        newProxyAddress = address(new ProxyCraftPos(msg.sender, PROXY_LOGIC, shortToken, longToken, getUniswapV3Pool(shortToken, longToken)));
        Registry(REGISTRY).registerUser(msg.sender, newProxyAddress);
    }
}
