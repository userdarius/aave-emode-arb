//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFlashLoan {
    //TODO: mod craft based on arch
    function craftPosition() external returns (bool);

    //TODO: mod unwind based on arch
    function unwindPosition(uint256 slippage) external returns (bool);
}
