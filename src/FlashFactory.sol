//SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProxyLogic.sol";
import "./ProxyCraftPos.sol";
import "./Registry.sol";

contract FlashFactory {
    address public REGISTRY;
    address public PROXY_LOGIC;
    address AAVE_ADDRESS_PROVIDER;

    constructor(address aaveAddressProvider) {
        REGISTRY = address(new Registry());
        PROXY_LOGIC = address(new ProxyLogic(aaveAddressProvider));
    }

    function createProxy(address shortToken, address longToken) public returns (address newProxyAddress){
        newProxyAddress = address(new ProxyCraftPos(msg.sender, PROXY_LOGIC, shortToken, longToken));
        REGISTRY.registerUser(msg.sender, newProxyAddress);
    }

    //TODO: should we really have this function or just use the one in Registry
    function getDeployedContracts(address user, uint256 index)
        public
        view
        returns (address[] memory)
    {
        return Registry(REGISTRY).getUserProxy(user, index);
    }
}
