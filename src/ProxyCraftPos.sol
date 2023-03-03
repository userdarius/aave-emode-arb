//SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./proxy/UserOwnedProxy.sol";

contract ProxyCraftPos is UserOwnedProxy {
    
    constructor(address _impl, address _owner, address _address_short, address _address_long) UserOwnedProxy(_impl, _owner){
        (bool _ok, ) = _impl.delegatecall(abi.encodeWithSignature("initialize(address,address,address)", _owner, _address_short, _address_long));
        require(_ok);
    }
}