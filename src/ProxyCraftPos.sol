//SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IFlashLoan.sol";

contract ProxyCraftPos is IFlashLoan {
    address constant public OWNER_; //placeholder for proxy
    address constant public OWNER;
    address constant public HELPER;
    address constant public address_short;
    address constant public address_long;
    
    constructor(address _owner, address _helper, address _short, address _long) {
        OWNER = _owner;
        HELPER = _helper;
        address_short = _short;
        address_long = _long;
    }
    
    function unwindPosition(uint256 slippage) override external{
        (bool success, ) = HELPER.delegatecall(
            abi.encodeWithSignature("unwindPosition(uint256)", slippage));
        require(success);
    }

    //TODO: mod craft based on arch
    function craftPosition() override external {
        // TODO pass good arg
        (bool success, ) = HELPER.delegatecall(
            abi.encodeWithSignature("craftPosition()", ));//TODO
        require(success);
    }

    //TODO: mod unwind based on arch
    function unwindPosition() override external {
        // TODO pass good arg
        (bool success, _) = HELPER.delegatecall(
            abi.encodeWithSignature("unwindPosition()", ));//TODO
        require(success);
    }
}