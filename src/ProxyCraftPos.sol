//SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IFlashLoan.sol";

contract ProxyCraftPos is IFlashLoan {//TODO: change everything to a InitializableImmutableAdminUpgradeabilityProxy (https://etherscan.io/address/0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2#code)
    address immutable public OWNER_; //placeholder for proxy
    address immutable public HELPER;

    
    constructor(address _owner, address _helper) {
        OWNER_ = _owner;
        HELPER = _helper;
    }
    
    function unwindPosition(uint256 shortDebt, address address_short, address address_long, address address_pool) override external returns (bool success){
        (success, ) = HELPER.delegatecall(
            abi.encodeWithSignature("unwindPosition(uint256,address,address,address)", shortDebt, address_short, address_long, address_pool));
        require(success);
    }

    //TODO: mod craft based on arch
    function craftPosition(bool depositIsLong,
        uint256 _amountDeposited,
        uint256 _leverageRatio,
        address address_short,
        address address_long,
        address address_pool
        ) override external returns (bool success){
        // TODO pass good arg
        (success, ) = HELPER.delegatecall(
            abi.encodeWithSignature("craftPosition(bool,uint256,uint256,address,address,address)", depositIsLong, _amountDeposited, _leverageRatio, address_short, address_long, address_pool));
        require(success);
    }

}