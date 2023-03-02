//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FlashLoanSimpleReceiverBase} from "lib/aave-v3-core/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import "../lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./interface/IFlashLoan.sol";
import "../lib/v3-core/contracts/UniswapV3Pool.sol";
import "./AaveTransferHelper.sol";

import "./FlashFactory.sol";

import "./Registry.sol";

contract ProxyLogic is FlashLoanSimpleReceiverBase, IFlashLoan {
    address immutable LOGIC_OWNER;//TODO: immutable?
    address private PROXY_OWNER; //placeholder
    address private HELPER; //placeholder
    address public address_short; //placeholder
    address public address_long; //placeholder

    address public constant swapRouterAddr = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

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
    ) public override returns (bool success){//TODO: still WIP
        uint256 repayAmount;
        uint256 premium = POOL.FLASHLOAN_PREMIUM_TOTAL();//TODO: still useful?
        if (depositIsLong) {
            repayAmount = longDepositedCraft(
                _amountDeposited,
                _leverageRatio
            );
        } else {
            repayAmount = shortDepositedCraft(
                _amountDeposited,
                _leverageRatio
            );
        }
        craftSwap(
                repayAmount,
                IERC20(address_long).balanceOf(LOGIC_OWNER),
                address_long,
                address_short
            );
        //TODO: repay the flashloan
        success = true;
        return success;
    }

    //function afterSwap(uint256 amountOut, uint256 amountInMaximum)
    //    internal
    //    returns (uint256 amountIn)//TODO: is it still usefull?
    //{
    //    return
    //        craftSwap(
    //            userDebt,
    //            IERC20(address_short).balanceOf(msg.sender),
    //            address_short,
    //            address_long
    //        );
    //}

    //SWAP CRAFTER
    function craftSwap(//TODO: use this example (no need to know the pool address beforehand)
    //https://docs.uniswap.org/contracts/v3/guides/swaps/single-swaps#a-complete-single-swap-contract
        uint256 amountOut,
        uint256 amountInMaximum,
        address tokenBeforeSwap,
        address tokenAfterSwap
    ) internal returns (uint256 amountIn) {
        uint24 poolFee = 0;//UniswapV3Pool(address_pool).fee();
        AaveTransferHelper.safeTransferFrom(
            tokenBeforeSwap,
            LOGIC_OWNER,
            address(this),
            amountInMaximum
        );
        AaveTransferHelper.safeApprove(
            tokenBeforeSwap,
            swapRouterAddr,
            amountInMaximum
        );

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenBeforeSwap,
                tokenOut: tokenAfterSwap,
                fee: poolFee,
                recipient: LOGIC_OWNER,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = ISwapRouter(swapRouterAddr).exactOutputSingle(params);

        if (amountIn < amountInMaximum) {
            AaveTransferHelper.safeApprove(tokenBeforeSwap, swapRouterAddr, 0);
            AaveTransferHelper.safeTransfer(
                tokenBeforeSwap,
                LOGIC_OWNER,
                amountInMaximum - amountIn
            );
        }
        return amountIn;
    }

    function longDepositedCraft(
        uint256 _amountDeposited,
        uint256 _leverageRatio
    ) internal returns (uint256){
        //need to be approved
        uint256 amount = _amountDeposited * (_leverageRatio - 1);

        AaveTransferHelper.safeApprove(address_long, address(POOL),  _amountDeposited);
        IERC20 long_token = IERC20(address_long);
        long_token.transferFrom(LOGIC_OWNER, address(this), _amountDeposited);

        //TODO: Check that the following definition of amount if correct.
        requestFlashLoan(address_long, _amountDeposited * (_leverageRatio - 1));
        // check balanceOf long_token for this contract to check flashloan has been correctly executed
        //console.log(address_long.balanceOf(address(this)));
        // deposit flashloaned longed asset on Aave

        //TODO: For now we use referalCode 0.
        uint16 referralCode = 0;
        POOL.supply(address_long, amount, LOGIC_OWNER, referralCode);
        // borrow phase on aave (this next part is tricky)
        // fetch the pool configuration from the reserve data
        uint256 configuration = POOL.getReserveData(address_long).configuration.data ;
        // fetch the category id from the configuration (bits 168-175 from the configuration uin256)
        uint8 categoryId = fetchBits(configuration);
        // activate emode for this contract
        POOL.setUserEMode(categoryId);
        // borrow short_token
        POOL.borrow(
            address_short,
            amount,
            2,
            referralCode,
            address(this)
        );

        return amount;
    }

    function shortDepositedCraft(
        uint256 _amountDeposited,
        uint256 _leverageRatio
    ) internal returns (uint256){
        IERC20 long_token = IERC20(address_long);

        //TODO: Check that the following definition of amount if correct.
        uint256 amount = _amountDeposited * _leverageRatio;
        long_token.transferFrom(msg.sender, address(this), _amountDeposited);
        requestFlashLoan(address_long, _amountDeposited * _leverageRatio);
        //TODO: deposit on Aave
        //borrow short_token - deposited

        return amount;
    }

    function unwindPosition(uint256 shortDebt) public override returns (bool success) {
        address variableDebt = POOL.getReserveData(address_short).variableDebtTokenAddress;
        IERC20 variableDebtToken = IERC20(variableDebt);
        uint256 variableDebtBalance = variableDebtToken.balanceOf(LOGIC_OWNER);

        requestFlashLoan(address_short, variableDebtBalance);
        POOL.repay(address_short, variableDebtBalance, 2, LOGIC_OWNER);

        craftSwap(variableDebtBalance, IERC20(address_short).balanceOf(LOGIC_OWNER), address_long, address_short);

        return true;
    } //TODO

    function requestFlashLoan(address _token, uint256 _amount) public {
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

    function fetchBits(uint256 x) public pure returns (uint8) {
        uint8 bits = uint8((x >> 168) & 0xFF);
        return bits;
    }
}
