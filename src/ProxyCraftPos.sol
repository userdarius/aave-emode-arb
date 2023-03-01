//SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IFlashLoan.sol";

contract ProxyCraftPos is IFlashLoan {//TODO: change everything to a InitializableImmutableAdminUpgradeabilityProxy (https://etherscan.io/address/0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2#code)
    address immutable public OWNER_; //placeholder for proxy
    address immutable public HELPER;
    address immutable public address_short;
    address immutable public address_long;
    
    constructor(address _owner, address _helper, address _short, address _long) {
        OWNER_ = _owner;
        HELPER = _helper;
        address_short = _short;
        address_long = _long;
    }
    
    function unwindPosition(uint256 slippage) override external returns (bool success){
        (success, ) = HELPER.delegatecall(
            abi.encodeWithSignature("unwindPosition(uint256)", slippage));
        require(success);
    }

    //TODO: mod craft based on arch
    function craftPosition(bool depositIsLong,
        uint256 _amountDeposited,
        uint256 _leverageRatio
        ) override external returns (bool success){
        // TODO pass good arg
        (success, ) = HELPER.delegatecall(
            abi.encodeWithSignature("craftPosition()"));//TODO
        require(success);
    }

}