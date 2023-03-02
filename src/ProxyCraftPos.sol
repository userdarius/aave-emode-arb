//SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./proxy/Proxy.sol";

contract ProxyCraftPos is Proxy {
    
    constructor(address _owner, address _impl, address _address_short, address _address_long) Proxy(_owner, _impl){
        (bool _ok, ) = _impl.delegatecall(abi.encode("initialize(address,address,address)", _owner, _address_short, _address_long));
        require(_ok);
    }
    
}