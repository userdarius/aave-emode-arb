//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FlashLoanSimpleReceiverBase} from "lib/aave-v3-core/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import 



contract ProxyLogic is FlashLoanSimpleReceiverBase, IFlashLoan {
    address constant LOGIC_OWNER;
    address public constant HELPER_PLACEHOLDER;
    address public address_short;
    address public address_long;

    modifier onlyOwner() {
        require(msg.sender == LOGIC_OWNER, "Unauthorized");
        _;
    }

    constructor(address _addressProvider)
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider))
    {
        LOGIC_OWNER = msg.sender;
    }

    function craftPosition(
        bool depositIsLong,
        uint256 _amountDeposited,
        uint256 _leverageRatio
    ) public override {
        if (depositIsLong) {
            uint256 repayAmount = longDepositedCraft(_amountDeposited, _leverageRatio);
        } else {
            uint256 repayAmount = shortDepositedCraft(_amountDeposited, _leverageRatio);
        }
        //TODO: repay
        //uint256 amountOwed = amount + premium;
        //IERC20(asset).approve(address(POOL), amountOwed);
    } //TODO

    function longDepositedCraft(uint256 _amountDeposited,
        uint256 _leverageRatio) internal {
        //need to be approved
        IERC20 long_token = IERC20(address_long);
        long_token.transferFrom(msg.sender, address(this), _amountDeposited);
        requestFlashLoan(address_long, _amountDeposited * (_leverageRatio - 1));
        //TODO: deposit on Aave
    }

    function shortDepositedCraft(uint256 _amountDeposited,
        uint256 _leverageRatio) internal {
        IERC20 long_token = IERC20(address_long);
        long_token.transferFrom(msg.sender, address(this), _amountDeposited);
        requestFlashLoan(address_long, _amountDeposited * _leverageRatio);
        //TODO: deposit on Aave
        //borrow short_token - deposited
    }

    function unwindPosition() public override {} //TODO

    function requestFlashLoan(address _token, uint256 _amount) public override {
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;

        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == address(POOL), "Unauthorized");
        require(initiator == address(this), "Unauthorized");

        // Approve the Pool contract allowance to *pull* the owed amount
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);

        return true;
    }

    receive() external payable {} //TODO: check why it is there
}
