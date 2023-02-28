//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FlashLoanSimpleReceiverBase} from "lib/aave-v3-core/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
contract ProxyLogic is FlashLoanSimpleReceiverBase, IFlashLoan {
    address constant LOGIC_OWNER;
    address public constant HELPER_PLACEHOLDER;
    address public address_short;
    address public address_long;

    ISwapRouter public constant swapRouter;

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
        uint256 premium = POOL.FLASHLOAN_PREMIUM_TOTAL();
        if (depositIsLong) {
            uint256 repayAmount = longDepositedCraft(
                _amountDeposited,
                _leverageRatio
            );
            
            craftSwap(repayAmount + premium, ERC20(address_long).balanceOf(msg.sender), address_long);
        
        } else {

            uint256 repayAmount = shortDepositedCraft(
                _amountDeposited,
                _leverageRatio
            );

            craftSwap(repayAmount + premium - _amountDeposited, ERC20(address_long).balanceOf(msg.sender), address_long);
        
        }
        
    } 

    //SWAP CRAFTER
    function craftSwap(uint256 amountOut, uint256 amountInMaximum, address tokenAfterSwap) internal returns (uint256 amountOut) {
        TransferHelper.safeTransferFrom(address_short, msg.sender, address(this), amountInMaximum);
        TransferHelper.safeApprove(address_short, address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: address_short,
                tokenOut: tokenAfterSwap,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = swapRouter.exactOutputSingle(params);

        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(address_short, address(swapRouter), 0);
            TransferHelper.safeTransfer(address_short, msg.sender, amountInMaximum - amountIn);
        }
    }

    function longDepositedCraft(
        uint256 _amountDeposited,
        uint256 _leverageRatio
    ) internal {
        //need to be approved
        IERC20 long_token = IERC20(address_long);
        long_token.transferFrom(msg.sender, address(this), _amountDeposited);
        requestFlashLoan(address_long, _amountDeposited * (_leverageRatio - 1));
        //TODO: deposit on Aave
    }

    function shortDepositedCraft(
        uint256 _amountDeposited,
        uint256 _leverageRatio
    ) internal {
        IERC20 long_token = IERC20(address_long);
        long_token.transferFrom(msg.sender, address(this), _amountDeposited);
        requestFlashLoan(address_long, _amountDeposited * _leverageRatio);
        //TODO: deposit on Aave
        //borrow short_token - deposited
    }

    function unwindPosition(uint256 shortDebt) public override {
        (,,,,,,,,, address stableDebt, address variableDebt, ,,,) = POOL.getReserveData(address_short);
        IERC20 stableDebtToken = IERC20(stableDebt);
        IERC20 variableDebtToken = IERC20(variableDebt);
        uint256 stableDebtBalance = stableDebtToken.balanceOf(msg.sender);
        uint256 variableDebtBalance = variableDebtToken.balanceOf(msg.sender);
    } //TODO

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
