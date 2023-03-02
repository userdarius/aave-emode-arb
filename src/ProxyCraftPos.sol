//SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IFlashLoan.sol";

contract ProxyCraftPos is IFlashLoan {//TODO: change everything to a InitializableImmutableAdminUpgradeabilityProxy (https://etherscan.io/address/0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2#code)
    address constant public OWNER_; //placeholder for proxy
    address constant public OWNER;
    address constant public HELPER;
    address constant public address_short;
    address constant public address_long;
    
    constructor(address _owner, address _helper, address _short, address _long) {
        OWNER = _owner;
        HELPER = _helper;
        address_short = _address_short;
        address_long = _address_long;
        address_pool = _address_pool;
    }
    
    function unwindPosition(uint256 shortDebt) override external returns (bool success){
        (bool success, ) = HELPER.delegatecall(
            abi.encodeWithSignature("unwindPosition(uint256)", shortDebt));
        require(success);
    }

    //TODO: mod craft based on arch
    function craftPosition(bool depositIsLong,
        uint256 _amountDeposited,
        uint256 _leverageRatio
        ) override external returns (bool success) {
        // TODO pass good arg
        (bool success, ) = HELPER.delegatecall(
            abi.encodeWithSignature("craftPosition(bool,uint256,uint256)", depositIsLong, _amountDeposited, _leverageRatio));
        require(success);
    }

    //TODO: mod unwind based on arch
    function unwindPosition() override external {
        // TODO pass good arg
        (bool success, ) = HELPER.delegatecall(
            abi.encodeWithSignature("unwindPosition()", ));//TODO
        require(success);
    }
}