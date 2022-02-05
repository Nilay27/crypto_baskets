// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
// import 'hardhat/console.sol';


interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

contract Swap {
    IUniswapRouter public constant uniswapRouter = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    // address private constant UNI = 0xC8F88977E21630Cf93c02D02d9E8812ff0DFC37a;
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // change for mainnet


    function swapExactTokenInForTokenOut(address _tokenIn, address _tokenOut, uint amountIn) internal returns (uint256 amountOut) {
        require(amountIn > 0, "Must pass non 0 input amount");
        //check whether the token has been allowed by the user for the amount given
        uint256 allowance = IERC20(_tokenIn).allowance(msg.sender, address(this));
        require(allowance >= amountIn, "Check the token allowance");
        // Transfer the specified amount of input token to this contract.
        TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), amountIn);

        // Approve the router to spend Input token.
        TransferHelper.safeApprove(_tokenIn, address(uniswapRouter), amountIn);

        uint256 deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
        uint24 fee = 3000;

        address recipient = msg.sender;
        uint256 amountOutMinimum = 1;
        uint160 sqrtPriceLimitX96 = 0;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            _tokenIn,
            _tokenOut,
            fee,
            recipient,
            deadline,
            amountIn,
            amountOutMinimum,
            sqrtPriceLimitX96
        );

        amountOut = uniswapRouter.exactInputSingle(params);
        
    }

    function convertExactEthToToken(address _tokenOut, uint _amountIn) internal returns (uint256 amountOut){
        // console.log(msg.value);
        // require(msg.value > 0, "Must pass non 0 ETH amount");

        uint256 deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
        address _tokenIn = WETH;
        uint24 fee = 3000;
        address recipient = msg.sender;
        // uint256 amountIn = msg.value;
        uint256 amountOutMinimum = 1;
        uint160 sqrtPriceLimitX96 = 0;
        
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            _tokenIn,
            _tokenOut,
            fee,
            recipient,
            deadline,
            _amountIn,
            amountOutMinimum,
            sqrtPriceLimitX96
        );
        
        amountOut = uniswapRouter.exactInputSingle{ value: _amountIn }(params);
        
  }
}