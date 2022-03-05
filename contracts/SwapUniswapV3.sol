// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable; //TODO: use refund ETH in case of ExactOutPutSingle
}

contract Swap {
    /**
        @dev Router used to interact with V3 pools and perform Swaps
    */
    IUniswapRouter public constant uniswapRouter =
        IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // TODO: change for mainnet

    function getExactInputSingleParams(
        address _tokenOut,
        uint256 _amountIn,
        address _tokenIn
    ) internal view returns (ISwapRouter.ExactInputSingleParams memory) {
        uint256 deadline = block.timestamp + 15; // TODO : using 'now' for convenience, for mainnet pass deadline from frontend!
        address tokenIn;
        if (_tokenIn == address(0)) {
            tokenIn = WETH;
        } else {
            tokenIn = _tokenIn;
        }
        uint24 fee = 3000; //TODO: take it from front-end when option to give custom fee is available
        address recipient = msg.sender;
        uint256 amountOutMinimum = 1;
        uint160 sqrtPriceLimitX96 = 0;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams(
                tokenIn,
                _tokenOut,
                fee,
                recipient,
                deadline,
                _amountIn,
                amountOutMinimum,
                sqrtPriceLimitX96
            );
        return params;
    }

    /**
        @notice Swaps `amountIn` of one _tokenIn for as much as possible of another token _tokenOut
        @dev  Performs a single exact input swap between 2 ERC20 tokens for exact amountIn of _tokenIn
        @return amountOut The amount of the received token (_tokenOut)
     */
    function swapExactTokenInForTokenOut(
        address _tokenIn,
        address _tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        require(amountIn > 0, "Must pass non 0 input amount");

        //check whether _tokenIn has been allowed by the user for the amount given
        uint256 allowance = IERC20(_tokenIn).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= amountIn, "Check the token allowance");
        // Transfer amountIn of _tokenIn to this contract.
        TransferHelper.safeTransferFrom(
            _tokenIn,
            msg.sender,
            address(this),
            amountIn
        );

        // Approve uniswapRouter to spend _tokenIn.
        TransferHelper.safeApprove(_tokenIn, address(uniswapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = getExactInputSingleParams(
            _tokenOut,
            amountIn,
            _tokenIn
        );

        amountOut = uniswapRouter.exactInputSingle(params);
        return amountOut;
    }

    /**
        @notice Swaps `amountIn` of ETH(WETH) for as much as possible of _tokenOut
        @dev  Performs a single exact input swap of WETH with ERC20 token for exact amountIn of WETH
        @return amountOut The amount of the received token (_tokenOut)
     */
    function convertExactEthToToken(address _tokenOut, uint256 _amountIn)
        internal
        returns (uint256 amountOut)
    {
        require(_amountIn > 0, "Must pass non 0 input amount");
        ISwapRouter.ExactInputSingleParams memory params = getExactInputSingleParams(
            _tokenOut,
            _amountIn,
            address(0)
        );
        amountOut = uniswapRouter.exactInputSingle{value: _amountIn}(params);
        return amountOut;
    }
}
