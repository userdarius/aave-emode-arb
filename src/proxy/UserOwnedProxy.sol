// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the getImplementation() internal function.
 */
contract UserOwnedProxy is TransparentUpgradeableProxy {
    //https://docs.openzeppelin.com/contracts/3.x/api/proxy#TransparentUpgradeableProxy

    /**
     * @dev Constructor.
     */
    constructor(address implementation, address admin) TransparentUpgradeableProxy(implementation, admin, "") {
    }

    function _beforeFallback() internal virtual override {
        //empty
    }
}
