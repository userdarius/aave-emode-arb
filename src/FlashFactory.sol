//SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProxyCraftPos.sol";
import "./Registry.sol";

contract FlashFactory {
    address public REGISTRY;

    constructor() {
        REGISTRY = new Registry();
    }

    function createProxy(address shortToken, address longToken) public {
        ProxyCraftPos newProxy = new ProxyCraftPos(); //TODO: should take "shortToken, longToken, msg.sender"
        newProxy.craftPosition(); //TODO: fill the args
        REGISTRY.registerUser(msg.sender, address(newProxy));
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
