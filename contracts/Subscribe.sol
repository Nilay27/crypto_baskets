// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "hardhat/console.sol";
import "./Baskets.sol";
import "./SwapUniswapV3.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Subscribe is Baskets, Swap {
    using Math for uint256;

    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    mapping(address => mapping(address => address)) tokenToLinkPriceAddress; // first leg to second leg to chainlink oracle address
    mapping(address => mapping(string => mapping(address => uint256)))
        public userToHolding; // user to basketid and to a mapping with token address to amount
    mapping(address => mapping(string => address[])) userToActiveTokenArray; // user to basketid and to a mapping with token address to amount
    mapping(address => mapping(string => mapping(address => uint256))) userToTokenIndex; // track userToActiveTokenArray index position for tokens + 1, so 0 is no holding
    mapping(string => mapping(address => uint256)) basketToWeight; //temp utility mapping, basket to token to weight

    /// @dev Break basket information into token array, and component amount array so that we can send trades
    function basketToComponent(string memory _basketID, uint256 _amount)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        // inherit function - retrieve the basket information from the state variable in the Basket contract
        Baskets.Basket memory basket = getBasketById(_basketID);

        address[] memory tokenArray = basket.tokens;
        uint256[] memory weightArray = basket.weights;
        uint256[] memory amountArray = new uint256[](tokenArray.length); // must be the same length as tokenArray

        for (uint256 i = 0; i < tokenArray.length; i++) {
            amountArray[i] = (_amount * weightArray[i]) / 100;
        }
        return (tokenArray, amountArray);
    }


    /// @dev helper function on transaction, _buy is a boolean on buy or sell
    function transaction(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        bool _buy,
        string memory _basketID
    ) internal {
        require(_amountIn > 0, "amount has to be positive");

        // frontend sets ETH to be address(0), in this case we need to use a different swap function
        // as it's not ERC20
        if (_tokenIn == address(0) && _buy) {
            // has to be buy transaction

            uint256 amountOut = Swap.convertExactEthToToken(
                _tokenOut,
                _amountIn
            );
            // if this is a new holding, we need to update the holding list mapping and holding index mapping
            if (userToHolding[msg.sender][_basketID][_tokenOut] == 0) {
                userToActiveTokenArray[msg.sender][_basketID].push(_tokenOut);

                userToTokenIndex[msg.sender][_basketID][
                    _tokenOut
                ] = userToActiveTokenArray[msg.sender][_basketID].length;
            }
            // add amountOut to user holding mapping
            userToHolding[msg.sender][_basketID][_tokenOut] += amountOut;

            // only acceptable ERC20 tokens here, rely on the front end to restrict
        } else {
            uint256 amountOut = Swap.swapExactTokenInForTokenOut(
                _tokenIn,
                _tokenOut,
                _amountIn
            );
            // buy and sell should be treated different for the mappings
            if (_buy) {
                // add to _tokenOut holding
                // if this is a new holding, we need to update the holding list mapping and holding index mapping
                if (userToHolding[msg.sender][_basketID][_tokenOut] == 0) {
                    userToActiveTokenArray[msg.sender][_basketID].push(
                        _tokenOut
                    );

                    userToTokenIndex[msg.sender][_basketID][
                        _tokenOut
                    ] = userToActiveTokenArray[msg.sender][_basketID].length;
                }
                // add amountOut to user holding mapping
                userToHolding[msg.sender][_basketID][_tokenOut] += amountOut;
            } else {
                // trim _tokenIn
                // update the holder mapping and token array
                userToHolding[msg.sender][_basketID][_tokenIn] -= _amountIn;
                // if no holding anymore delete the token from tokenArray and assign index to 0
                if (userToHolding[msg.sender][_basketID][_tokenIn] == 0) {
                    delete userToActiveTokenArray[msg.sender][_basketID][
                        userToTokenIndex[msg.sender][_basketID][_tokenIn] - 1
                    ]; // index is 1 + position, so get the token by minus 1
                    userToTokenIndex[msg.sender][_basketID][_tokenIn] = 0;
                }
            }
        }
    }

    /// execute the trades when user decides to deposit certain amount to a basket
    function deposit(
        string memory _basketID,
        address _tokenIn,
        uint256 _amount
    ) external payable {
        // // update the transaction mapping userToTransaction
        // Transaction memory userTransaction = Transaction(block.timestamp, msg.sender, _tokenIn, _basketID, _amount, "deposit");
        // userToTransaction[msg.sender].push(userTransaction);

        // pay the subscriber fee to creator
        // address payable creator = payable(Baskets.getBasketById(_basketID).basketOwner);
        // sendFee(_tokenIn, creator, uint(_amount * 1 / 100)); // decidie later how much to charge
        // uint transactionAmount = uint(_amount - _amount * 1 / 100);

        require(_amount > 0, "amount has to be positive");
        // break basket deposit into trade amount by tokens
        (
            address[] memory tokenArray,
            uint256[] memory amountArray
        ) = basketToComponent(_basketID, _amount);

        for (uint256 i = 0; i < tokenArray.length; i++) {
            transaction(
                _tokenIn,
                tokenArray[i],
                amountArray[i],
                true,
                _basketID
            );
        }
    }

    /// only apply if user decides to exit all the holding related to a basket
    function exit(string memory _basketID, address _tokenOut) external {
        // ETH can't be accepted as a withdraw token
        require(_tokenOut != address(0), "user can't receive ETH");

        // // update the transaction mapping subscriberToTransaction
        // Transaction memory userTransaction = Transaction(block.timestamp, msg.sender, _tokenOut, _basketID, 0, "exit");
        // userToTransaction[msg.sender].push(userTransaction);

        // loop through the current holding and exit
        address[] memory tokenArray = userToActiveTokenArray[msg.sender][
            _basketID
        ];
        for (uint256 i = 0; i < tokenArray.length; i++) {
            if (tokenArray[i] != address(0)) {
                // if it's address(0), it means token is deleted hence zero holding
                // compare the balance with holding mapping, taking the lower value
                uint256 tokenBalance = Math.min(
                    userToHolding[msg.sender][_basketID][tokenArray[i]],
                    ERC20(tokenArray[i]).balanceOf(msg.sender)
                );

                if (tokenBalance > 0) {
                    // if user still holds something, we will sell too
                    transaction(
                        tokenArray[i],
                        _tokenOut,
                        tokenBalance,
                        false,
                        _basketID
                    );
                }
            }
        }
    }

    /// get the price for token vs ETH from chainlink oracle, address of that pair needed
    function getPrice(address _pair) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_pair);
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    /// get user basket balance in total and in each token (in _balanceToken)
    function getBasketBalance(
        address _userAddress,
        string memory _basketID,
        address _balanceToken
    )
        internal
        view
        returns (
            uint256,
            address[] memory,
            uint256[] memory
        )
    {
        // active token array from user's subscription
        address[] memory activeTokenArray = userToActiveTokenArray[
            _userAddress
        ][_basketID];
        // track the total balance in _balanceToken
        uint256 totalBalance;
        // tokenBalanceETH array intends to match the activeTokenArray
        uint256[] memory tokenBalance = new uint256[](activeTokenArray.length);

        for (uint256 i = 0; i < activeTokenArray.length; i++) {
            address activeToken = activeTokenArray[i];
            if (activeToken != address(0)) {
                uint256 tokenAmountLocal = userToHolding[_userAddress][
                    _basketID
                ][activeToken]; // in activeToken unit
                // tokenAmount is in token unit, convert them into _balanceToken
                uint256 tokenAmount = tokenAmountLocal *
                    getPrice(
                        tokenToLinkPriceAddress[_balanceToken][activeToken]
                    );
                // update the token balance and total balance
                tokenBalance[i] = tokenAmount;
                totalBalance += tokenAmount;
            } else {
                //if a token is address 0, it means the balance is zero and got deleted
                tokenBalance[i] = 0;
            }
        }
        return (totalBalance, activeTokenArray, tokenBalance);
    }

    /** @dev rebalance the holding according to the current basket
     * logic is as follows:
     * 1. find the current basket holding in _balanceToken by total and by token, calculate the targetAmount
     * 2. loop through the current basket, create the mapping and if not in current holding, then initiate the holding
     * 3. loop through the current holding, if token not in current basket, sell them entirely; then rebalance via
     * the tokenBalance
     */
    function rebalance(
        string memory _basketID,
        int256 _deltaAmount, // in terms of balance token
        bool _current, // if we try to maintain the current balance
        address _balanceToken // token to add or sell, all the trades go through it
    ) internal {
        // get user's total balance and token balance in _balanceToken for a basket
        (
            uint256 balance,
            address[] memory activeTokenArray,
            uint256[] memory balanceArray
        ) = getBasketBalance(msg.sender, _basketID, _balanceToken);

        // calculate the targetAmount
        uint256 targetAmount;
        if (_current) {
            targetAmount = balance;
        } else {
            targetAmount = uint256(int256(balance) + _deltaAmount);
        }

        require(
            int256(balance) + _deltaAmount > 0,
            "holding not enough to cover sell"
        );

        // iterate the current basket and initiate trades on tokens we don't hold yet
        Baskets.Basket memory basket = getBasketById(_basketID);

        for (uint256 i = 0; i < basket.tokens.length; i++) {
            // integrate into current holding
            basketToWeight[_basketID][basket.tokens[i]] = basket.weights[i];

            if (
                userToTokenIndex[msg.sender][_basketID][basket.tokens[i]] == 0
            ) {
                // if no holding yet, we need to buy them
                transaction(
                    _balanceToken,
                    basket.tokens[i],
                    (targetAmount * basket.weights[i]) / 100,
                    true,
                    _basketID
                );
            }
        }

        // loop through the current holding and calculate the trades
        for (uint256 i = 0; i < activeTokenArray.length; i++) {
            if (activeTokenArray[i] != address(0)) {
                // if address is 0, then it's deleted, so we leave them
                if (
                    basketToWeight[_basketID][activeTokenArray[i]] == 0 &&
                    balanceArray[i] > 0
                ) {
                    // not in current basket anymore
                    transaction(
                        activeTokenArray[i],
                        _balanceToken,
                        balanceArray[i] /
                            getPrice(
                                tokenToLinkPriceAddress[_balanceToken][
                                    activeTokenArray[i]
                                ]
                            ), // sell the entire holding
                        false,
                        _basketID
                    );
                } else {
                    // balancing trade
                    int256 tokenBalanceAmount = int256(
                        ((targetAmount * basket.weights[i]) / 100) -
                            balanceArray[i]
                    );
                    if (tokenBalanceAmount > 0) {
                        // add to this token
                        transaction(
                            _balanceToken,
                            activeTokenArray[i],
                            uint256(tokenBalanceAmount),
                            true,
                            _basketID
                        );
                    } else {
                        // trim this token
                        transaction(
                            activeTokenArray[i],
                            _balanceToken,
                            uint256(tokenBalanceAmount) /
                                getPrice(
                                    tokenToLinkPriceAddress[_balanceToken][
                                        activeTokenArray[i]
                                    ]
                                ),
                            false,
                            _basketID
                        );
                    }
                }
            }
        }
    }

    function add(
        string memory _basketID,
        address _tokenIn,
        uint256 _amountAdd
    ) external payable {
        rebalance(_basketID, int256(_amountAdd), false, _tokenIn);
    }

    function sell(
        string memory _basketID,
        address _tokenOut,
        uint256 _amountSell
    ) external payable {
        rebalance(_basketID, int256(_amountSell) * -1, false, _tokenOut);
    }

    function getUserHoldingForToken(
        address user,
        string memory _basketID,
        address _token
    ) public view returns (uint256) {
        return userToHolding[user][_basketID][_token];
    }
}