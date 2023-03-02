//SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IFlashLoan.sol";

contract ProxyCraftPos is IFlashLoan {//TODO: change everything to a InitializableImmutableAdminUpgradeabilityProxy (https://etherscan.io/address/0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2#code)
    address public OWNER_; //placeholder for ProxyLogic
    address immutable public OWNER; //TODO: should these var be immutable?
    address immutable public HELPER;
    address immutable public address_short;
    address immutable public address_long;
    
    constructor(address _owner, address _helper, address _address_short, address _address_long) {
        OWNER = _owner;
        HELPER = _helper;
        address_short = _address_short;
        address_long = _address_long;
    }
    
    function unwindPosition(uint256 shortDebt) override external returns (bool success){
        (success, ) = HELPER.delegatecall(
            abi.encodeWithSignature("unwindPosition(uint256)", shortDebt));
        require(success);
    }

    //TODO: mod craft based on arch
    function craftPosition(bool depositIsLong,
        uint256 _amountDeposited,
        uint256 _leverageRatio
        ) override external returns (bool success) {
        // TODO pass good arg
        (success, ) = HELPER.delegatecall(
            abi.encodeWithSignature("craftPosition(bool,uint256,uint256)", depositIsLong, _amountDeposited, _leverageRatio));
        require(success);
    }

}