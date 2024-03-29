//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FlashLoanSimpleReceiverBase} from "lib/aave-v3-core/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./interface/IFlashLoan.sol";
import "../lib/v3-core/contracts/UniswapV3Pool.sol";
import "./AaveTransferHelper.sol";
import "forge-std/Test.sol";

import "./FlashFactory.sol";

import "./Registry.sol";

contract ProxyLogic is FlashLoanSimpleReceiverBase, IFlashLoan, Test {
    address public owner;
    address public address_short;
    address public address_long;

    address public immutable swapRouterAddr;

    modifier ifOwner() {
        console.log("Entering ifOwner");
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    constructor(address _aaveAddressProvider, address _swapRouterAddr)
        FlashLoanSimpleReceiverBase(
            IPoolAddressesProvider(_aaveAddressProvider)
        )
    {
        swapRouterAddr = _swapRouterAddr;
    }

    //function address_short() external view returns (address){
    //return address_short;
    //}

    //function address_long() external view returns (address){
    //return address_long;
    //}

    function getOwner() external view returns (address) {
        console.log("getOwner called");
        return owner;
    }

    function initialize(
        address _owner,
        address _address_short,
        address _address_long
    ) public {
        console.log("initialize called");
        owner = _owner;
        address_short = _address_short;
        address_long = _address_long;
    }

    function craftPosition(
        bool depositIsLong,
        uint256 _amountDeposited,
        uint256 _leverageRatio
    ) public override ifOwner returns (bool success) {
        //TODO: still WIP
        console.log("Starting the craftPos");
        if (depositIsLong) {
            longDepositedCraft(_amountDeposited, _leverageRatio);
        } else {
            shortDepositedCraft(_amountDeposited, _leverageRatio);
        }
        success = true;
        return success;
    }

    //SWAP CRAFTER
    function craftSwap(
        //TODO: use this example (no need to know the pool address beforehand)
        //https://docs.uniswap.org/contracts/v3/guides/swaps/single-swaps#a-complete-single-swap-contract
        uint256 amountOut,
        uint256 amountInMaximum,
        address tokenBeforeSwap,
        address tokenAfterSwap
    ) internal returns (uint256 amountIn) {
        //We use the lowest fee tier for the pool
        uint24 poolFee = 100; //UniswapV3Pool(address_pool).fee();
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
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = ISwapRouter(swapRouterAddr).exactOutputSingle(params);

        if (amountIn < amountInMaximum) {
            AaveTransferHelper.safeApprove(tokenBeforeSwap, swapRouterAddr, 0);
        }
        return amountIn;
    }

    function longDepositedCraft(
        uint256 _amountDeposited,
        uint256 _leverageRatio
    ) public {//returns (uint256) {
        console.log("Entering longDepositedCraft");
        //pulling the tokens from the user into the contract
        AaveTransferHelper.safeTransferFrom(address_long, owner, address(this), _amountDeposited);

        console.log("BALANCE after user deposit is :", IERC20(address_long).balanceOf(address(this)));
        //calculating the amount to flashloan depending on the leverage ad the amount deposited
        uint256 amount = _amountDeposited * (_leverageRatio - 1);
        console.log("The amount to borrow is ", amount);
        console.log("function requestFlashloan is getting called");
        //calling the flashloan function
        requestFlashLoan(address_long, amount);//TODO: add the necessary arguments
        //this function calls aave smartcontracts which then call back this contracts "executeOperation" function
    }

    function prepareRepayement(uint256 _repayAmount) internal {
        //TODO: move this part
        console.log("function requestFlashloan has been called");
        uint256 totalBalance = IERC20(address_long).balanceOf(address(this));
        console.log("Now the balance of longToken ", address_long, " is ", totalBalance);

        AaveTransferHelper.safeApprove(
            address_long,
            address(POOL),
            totalBalance
        );
        // check balanceOf long_token for this contract to check flashloan has been correctly executed
        // console.log(address_long.balanceOf(address(this)));
        // deposit flashloaned longed asset on Aave

        uint16 referralCode = 0;
        POOL.supply(address_long, totalBalance, address(this), referralCode);
        // borrow phase on aave (this next part is tricky)
        // fetch the pool configuration from the reserve data
        uint256 configuration = POOL
            .getReserveData(address_long)
            .configuration
            .data;
        // fetch the category id from the configuration (bits 168-175 from the configuration uin256)
        uint8 categoryId = fetchBits(configuration);
        // activate emode for this contract
        POOL.setUserEMode(categoryId);
        console.log("User EMode has been set");
        // borrow short_token
        console.log("trying to borrow shortToken");
        POOL.borrow(address_short, _repayAmount, 2, referralCode, address(this));
        uint256 shortTokenBalance = IERC20(address_short).balanceOf(address(this));
        console.log("The borrow went through and the balance of shortToken");
        console.log("The borrow went through and the balance of shortToken", address_short, " is ", shortTokenBalance);
        //swaping shortToken to longToken to repay the flashloan
        craftSwap(
            _repayAmount,
            shortTokenBalance,
            address_long,
            address_short
        );
    }

    function shortDepositedCraft(//TODO: need to be recoded with in the same way longDepositedCraft is structured
        uint256 _amountDeposited,
        uint256 _leverageRatio
    ) internal returns (uint256) {
        IERC20 long_token = IERC20(address_long);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: address_short,
                tokenOut: address_long,
                fee: 100,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: 10**ERC20(address_long).decimals(),
                amountInMaximum: IERC20(address_short).balanceOf(msg.sender),
                sqrtPriceLimitX96: 0
            });

        uint256 amountIn = ISwapRouter(swapRouterAddr).exactOutputSingle(
            params
        );
        uint256 amount = amountIn * _amountDeposited * _leverageRatio;

        long_token.transferFrom(
            msg.sender,
            address(this),
            _amountDeposited * amountIn
        );
        requestFlashLoan(address_long, amount);

        uint16 referralCode = 0;
        AaveTransferHelper.safeTransferFrom(address_long, owner, address(this), amount);
        AaveTransferHelper.safeApprove(address_long, address(POOL), amount);
        POOL.supply(address_long, amount, address(this), referralCode);


        uint256 configuration = POOL
            .getReserveData(address_long)
            .configuration
            .data;

        uint8 categoryId = fetchBits(configuration);

        POOL.setUserEMode(categoryId);

        // borrow short_token
        POOL.borrow(
            address_short,
            amount - _amountDeposited,
            2,
            referralCode,
            address(this)
        );

        return amount - _amountDeposited;
    }

    function unwindPosition(uint256 shortDebt)
        public
        override
        ifOwner
        returns (bool success)
    {
        address variableDebt = POOL
            .getReserveData(address_short)
            .variableDebtTokenAddress;
        IERC20 variableDebtToken = IERC20(variableDebt);
        uint256 variableDebtBalance = variableDebtToken.balanceOf(
            address(this)
        ); //TODO

        requestFlashLoan(address_short, variableDebtBalance);
        //TODO: deposit on aave
        POOL.repay(address_short, variableDebtBalance, 2, address(this)); //TODO

        craftSwap(
            variableDebtBalance,
            IERC20(address_short).balanceOf(address(this)), //TODO
            address_long,
            address_short
        );

        return true;
    }

    function requestFlashLoan(address _token, uint256 _amount) internal {
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
        //TODO: is it useful?
        console.log("Entering executeOperation function");
        //TODO: calculate how much short token should be sold (= repayAmount) to get enough longToken to repay the flashloan (= amount)
        uint256 repayAmount = amount + premium;//TODO: use the uniswap functions to calculate the amountIn (=> borrowAmount) to be able to repay the flashloan
        prepareRepayement(repayAmount);
        
        // require(msg.sender == address(POOL), "Unauthorized");
        // require(initiator == address(this), "Unauthorized");

        // Approve the Pool contract allowance to *pull* the owed amount
        console.log("LOOOL", amount);
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);

        return true;
    }

    function fetchBits(uint256 x) public pure returns (uint8) {
        uint8 bits = uint8((x >> 168) & 0xFF);
        return bits;
    }
}
