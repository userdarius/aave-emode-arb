// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the getImplementation() internal function.
 */
contract Proxy {
    modifier onlyOwner() {
        require(msg.sender == _getOwner());
        _;
    }

    /**
     * @dev Constructor.
     */
    constructor(address owner, address implementation) {
        _setOwner(owner);
        _setImplementation(implementation);
    }

    //IMPLEMENTATION:

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev function returning the owner of this proxy
     */
    function getImplementation() external view returns (address) {
        return _implementation();
    }

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        //solium-disable-next-line
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Sets the implementation address of the proxy.
     * @param newImplementation Address of the new implementation.
     */
    function _setImplementation(address newImplementation) internal {
        //TODO
        //require(
        //Address.isContract(newImplementation),
        //'Cannot set a proxy implementation to a non-contract address'
        //);

        bytes32 slot = _IMPLEMENTATION_SLOT;

        //solium-disable-next-line
        assembly {
            sstore(slot, newImplementation)
        }
    }

    //OWNERSHIP of the proxy:

    bytes32 internal constant _OWNER_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev function returning the owner of this proxy
     */
    function getOwner() external view returns (address) {
        return _getOwner();
    }

    /**
     * @dev internal function returning the owner of this proxy
     */
    function _getOwner() internal view returns (address owner) {
        bytes32 slot = _OWNER_SLOT;
        //solium-disable-next-line
        assembly {
            owner := sload(slot)
        }
    }

    /**
     * @dev function setting the owner of this proxy
     */
    function setOwner(address newOwner) external onlyOwner {
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        bytes32 slot = _OWNER_SLOT;

        //solium-disable-next-line
        assembly {
            sstore(slot, newOwner)
        }
    }

    //UPGRADABILITY of the proxy:

    /**
     * @notice Upgrade the backing implementation of the proxy.
     * @dev Only the admin can call this function.
     * @param newImplementation The address of the new implementation.
     */
    function upgradeTo(address newImplementation) external onlyOwner {
        _setImplementation(newImplementation); //TODO: emit an event?
    }

    /**
     * @notice Upgrade the backing implementation of the proxy and call a function
     * on the new implementation.
     * @dev This is useful to initialize the proxied contract.
     * @param newImplementation The address of the new implementation.
     * @param data Data to send as msg.data in the low level call.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        onlyOwner
    {
        _setImplementation(newImplementation);
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @dev fallback implementation.
     * Delegates execution to an implementation contract.
     * This is a low level function that doesn't return to its internal call site.
     * It will return to the external caller whatever the implementation returns.
     */
    fallback() external payable {
        address impl = _implementation();
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
