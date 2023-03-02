//SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProxyLogic.sol";
import "./ProxyCraftPos.sol";
import "./Registry.sol";

contract FlashFactory {
    address public REGISTRY;
    address public PROXY_LOGIC;
    address AAVE_ADDRESS_PROVIDER;

    constructor(address aaveAddressProvider, address helper) {
        REGISTRY = address(new Registry(address(this)));
        PROXY_LOGIC = address(new ProxyLogic(aaveAddressProvider));
    }

    function createProxy(address shortToken, address longToken) public returns (address newProxyAddress){
        newProxyAddress = address(new ProxyCraftPos(msg.sender, PROXY_LOGIC, shortToken, longToken, Registry(REGISTRY).getUniswapV3Pool(shortToken, longToken)));
        Registry(REGISTRY).registerUser(msg.sender, newProxyAddress);
    }

    function getRegistry() public view returns (Registry registry) {
        return Registry(REGISTRY);
    }

    //TODO: should we really have this function or just use the one in Registry
    function getDeployedContracts(address user, uint256 index)
        public
        view
        returns (address)
    {
        return Registry(REGISTRY).getUserProxy(user, index);
    }
}
