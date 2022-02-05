// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Baskets.sol";
import "./SwapUniswapV3.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// import 'hardhat/console.sol';

contract Subscribe is Baskets, Swap {
    struct Transaction {
        //transaction information
        uint256 callTime;
        uint256 transactionAmount;
        address user; // subscriber
        address userCoin; // deposit or withdraw tokens
        string basketID; // defined in baskets contract
        string transactionType; // deposit, exit, partial sell
    }

    event log(Transaction);

    mapping(string => mapping(address => uint256)) basketToWeight; //temp utility mapping
    mapping(string => address) userCoinToAddress; // user token code to token address
    mapping(address => address) tokenToLinkPriceAddress; // token address to chainlink price address
    mapping(address => Transaction[]) public userToTransaction; // user to his/her transaction array
    mapping(address => mapping(string => mapping(address => uint256)))
        public userToHolding; // user to basketid and to a mapping with token address to amount
    mapping(address => mapping(string => address[])) userToActiveTokenArray; // user to basketid and to a mapping with token address to amount
    mapping(address => mapping(string => mapping(address => uint256))) userToTokenIndex; // track userToActiveTokenArray

    // constructor() {
    //     // hardcode the address for now, can deal with them on front end
    //     userCoinToAddress["WETH"] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    //     userCoinToAddress["USDT"] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    //     //userCoinToAddress["LINK"] = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    //     tokenToLinkPriceAddress[0x0Eb3a705fc54725037CC9e008bDede697f62F335] = 0xc751E86208F0F8aF2d5CD0e29716cA7AD98B5eF5; // ATOM rinkeby
    //     tokenToLinkPriceAddress[0x514910771AF9Ca656af840dff83E8264EcF986CA] = 0xFABe80711F3ea886C3AC102c81ffC9825E16162E; // LINK rinkeby
    //     tokenToLinkPriceAddress[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e; // USDT
    //     // ["0x0Eb3a705fc54725037CC9e008bDede697f62F335", "0x514910771AF9Ca656af840dff83E8264EcF986CA"]
    // }

    // modifier validUserCoin(string memory _userCoin) {
    //     /* restrict customer deposit and withdraw coins to be ETH, WETH, USDT */
    //     require((keccak256(abi.encodePacked(_userCoin)) == keccak256(abi.encodePacked("ETH")) || (userCoinToAddress[_userCoin] != address(0))), "Not valid coin");
    //     _;
    // }

    function basketToComponent(string memory _basketID, uint256 _amount)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        /* Break basket information into token array, and component amount array so that we can send them to DEX */

        Baskets.Basket memory basket = getBasketById(_basketID);

        address[] memory tokenArray = basket.tokens;
        uint256[] memory weightArray = basket.weights;
        uint256[] memory amountArray = new uint256[](tokenArray.length);

        for (uint256 i = 0; i < tokenArray.length; i++) {
            amountArray[i] = (_amount * weightArray[i]) / 100;
        }
        return (tokenArray, amountArray);
    }

    function sendFee(
        string memory _coin,
        address payable _to,
        uint256 _amount
    ) public payable {
        /* send subscriber fee, need to modify this probably */

        if (
            keccak256(abi.encodePacked(_coin)) ==
            keccak256(abi.encodePacked("ETH"))
        ) {
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "fail to send the subscriber fee to creator");
        } else {
            ERC20(userCoinToAddress[_coin]).transfer(_to, _amount);
        }
    }

    function deposit(
        string memory _basketID,
        address _tokenIn,
        uint256 _amount
    ) external payable {
        /* execute the trades when user decides to deposit to a basket*/

        // update the transaction mapping userToTransaction

        Transaction memory userTransaction = Transaction(
            block.timestamp,
            0,
            msg.sender,
            _tokenIn,
            _basketID,
            "deposit"
        );
        userToTransaction[msg.sender].push(userTransaction);

        // pay the subscriber fee to creator
        address payable creator = payable(
            Baskets.getBasketById(_basketID).basketOwner
        );
        // sendFee(_tokenIn, creator, uint(_amount * 1 / 100)); // decidie later how much to charge
        uint256 transactionAmount = uint256(_amount);

        // send detailed transaction arrays for swapping
        (
            address[] memory tokenArray,
            uint256[] memory amountArray
        ) = basketToComponent(_basketID, transactionAmount);

        // use different swap function in case of ETH as it's not a ERC20 token
        if (_tokenIn == address(0)) {
            require(msg.value == _amount, "value called != value passed");
            require(msg.value > 0, "Must pass non 0 ETH amount");

            for (uint256 i = 0; i < tokenArray.length; i++) {
                // console.log(amountArray[i]);
                // console.log(tokenArray[i]);
                // swap the token
                // uint _amountOut = 0;
                uint256 _amountOut = Swap.convertExactEthToToken(
                    tokenArray[i],
                    amountArray[i]
                );
                // update the holding and index
                // if no holding before we should add it to the array
                if (userToHolding[msg.sender][_basketID][tokenArray[i]] <= 0) {
                    userToActiveTokenArray[msg.sender][_basketID].push(
                        tokenArray[i]
                    );
                    // userToTokenIndex[msg.sender][_basketID][tokenArray[i]] = userToActiveTokenArray[msg.sender][_basketID].length - 1;
                }
                userToHolding[msg.sender][_basketID][
                    tokenArray[i]
                ] += _amountOut;
            }
        } else {
            for (uint256 i = 0; i < tokenArray.length; i++) {
                // swap the token
                // uint _amountOut = 0;
                uint256 _amountOut = Swap.swapExactTokenInForTokenOut(
                    _tokenIn,
                    tokenArray[i],
                    amountArray[i]
                );
                // update the holding and index
                // if no holding before we should add it to the array
                if (userToHolding[msg.sender][_basketID][tokenArray[i]] <= 0) {
                    userToActiveTokenArray[msg.sender][_basketID].push(
                        tokenArray[i]
                    );
                    // userToTokenIndex[msg.sender][_basketID][tokenArray[i]] = userToActiveTokenArray[msg.sender][_basketID].length - 1;
                }
                userToHolding[msg.sender][_basketID][
                    tokenArray[i]
                ] = _amountOut;
            }
        }

        emit log(userTransaction);
    }

    function exit(string memory _basketID, address _tokenOut) external {
        /* execute the trades when user decides to exit a basket */

        // ETH can't be accepted as a withdraw token
        require(
            keccak256(abi.encodePacked(_tokenOut)) !=
                keccak256(abi.encodePacked("ETH")),
            "user can't receive ETH as token out"
        );

        // update the transaction mapping subscriberToTransaction
        Transaction memory userTransaction = Transaction(
            block.timestamp,
            0,
            msg.sender,
            _tokenOut,
            _basketID,
            "exit"
        );
        userToTransaction[msg.sender].push(userTransaction);

        // send detailed transaction arrays for swapping
        // loop through the current holding in a basket
        address[] memory tokenArray = userToActiveTokenArray[msg.sender][
            _basketID
        ];
        for (uint256 i = 0; i < tokenArray.length; i++) {
            // swap the token for the entire holding
            uint256 _amountOut = Swap.swapExactTokenInForTokenOut(
                tokenArray[i],
                _tokenOut,
                userToHolding[msg.sender][_basketID][tokenArray[i]]
            );

            // update the holder mapping and token array (delete the token from tokenArray)
            userToHolding[msg.sender][_basketID][tokenArray[i]] = 0;
            delete userToActiveTokenArray[msg.sender][_basketID][
                userToTokenIndex[msg.sender][_basketID][tokenArray[i]]
            ];
        }

        emit log(userTransaction);
    }

    function getUserHoldingForToken(
        address user,
        string memory _basketID,
        address _token
    ) public view returns (uint256) {
        return userToHolding[user][_basketID][_token];
    }

    function getPriceETH(address _pair) public view returns (uint256) {
        /* get the price for token pair vs ETH from chainlink Oracle */
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_pair);
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    // function getBasketBalanceETH(address _userAddress, string memory _basketID) public view returns(uint, uint[] memory) {
    //     // get user basket balance in total and in each token (in ETH)

    //     // active token array from user's subscription in a basket
    //     address[] memory activeTokenArray = userToActiveTokenArray[_userAddress][_basketID];
    //     // track the total balance in ETH
    //     uint totalBalanceETH;
    //     // tokenBalanceETH array matches the activeTokenArray
    //     //uint[] memory tokenBalanceETH;
    //     uint[] memory tokenBalanceETH = new uint[](activeTokenArray.length);

    //     //loop through the basket balance for a user
    //     for (uint i = 0; i < activeTokenArray.length; i ++) {
    //         address token = activeTokenArray[i];
    //         if (token != address(0)) { //if a token is address 0, it means the balance is zero and got deleted
    //             uint tokenAmount = userToHolding[_userAddress][_basketID][token];
    //             // tokenAmount is in token unit, convert them into ETH
    //             uint tokenPriceETH = getPriceETH(tokenToLinkPriceAddress[token]);
    //             uint tokenAmountETH = tokenAmount * tokenPriceETH;
    //             // update the token balance and total balance
    //             tokenBalanceETH[i] = tokenAmountETH;
    //             totalBalanceETH += tokenAmountETH;
    //         } else {
    //             //
    //             tokenBalanceETH[i] = 0;
    //         }
    //     }
    //     return (totalBalanceETH, tokenBalanceETH);
    // }

    // function sell(string memory _basketID, string memory _tokenOut, uint _amount) public validUserCoin(_tokenOut) {
    //     /* execute the trades when user decides to partial sell a basket */

    //     // ETH can't be worked as a withdraw token
    //     require(keccak256(abi.encodePacked(_tokenOut)) != keccak256(abi.encodePacked("ETH")), "user can't receive ETH as token out");

    //     // get user's total balance and token balance in ETH for a basket
    //     (uint balanceETH, uint[] memory balanceArrayETH) = getBasketBalanceETH(msg.sender, _basketID);

    //     // price is the _tokenOut/ETH
    //     uint _tokenOutPrice;
    //     if (keccak256(abi.encodePacked(_tokenOut)) == keccak256(abi.encodePacked("WETH"))){
    //         _tokenOutPrice = 1;
    //     } else {
    //         _tokenOutPrice = getPriceETH(tokenToLinkPriceAddress[userCoinToAddress[_tokenOut]]);
    //     }

    //     // check if the balance is enough to cover _amount
    //     require(balanceETH >= _amount * _tokenOutPrice, "Insufficient balance to cover withdraw");

    //     // update the transaction mapping userToTransaction
    //     userToTransaction[msg.sender].push(Transaction(block.timestamp, msg.sender, _tokenOut, _basketID, _amount, "partial sell"));

    //     // target remaining amount in ETH
    //     uint remainingBalanceETH = balanceETH - _amount * _tokenOutPrice;

    //     // update the weight mapping in the temp mapping
    //     // Baskets.Basket memory basket = Baskets.getBasketById(_basketID);
    //     for (uint i = 0; i < Baskets.getBasketById(_basketID).tokens.length; i ++) {
    //         basketToWeight[_basketID][Baskets.getBasketById(_basketID).tokens[i]] = Baskets.getBasketById(_basketID).weights[i];
    //     }

    //     // loop through the active token list and try to achieve the target weight
    //     address[] memory tokenArray = userToActiveTokenArray[msg.sender][_basketID];
    //     for (uint i = 0; i < tokenArray.length; i ++) {
    //         if (tokenArray[i] != address(0)) { // if the token still has value
    //             // price to token tokenArray[i]
    //             uint tokenPrice = getPriceETH(tokenToLinkPriceAddress[tokenArray[i]]);
    //             // in token unit, balanceArrayETH is in the same order of tokenArray
    //             uint currentTokenAmount = balanceArrayETH[i] / tokenPrice;
    //             // target remaining amount in token unit
    //             uint remainingAmount = remainingBalanceETH * basketToWeight[_basketID][tokenArray[i]] / tokenPrice;
    //             // only sell if current token amount is more than target remaining amount
    //             if (currentTokenAmount > remainingAmount) {
    //                 uint _amountOut = Swap.swapExactTokenInForTokenOut(tokenArray[i], userCoinToAddress[_tokenOut], currentTokenAmount - remainingAmount);
    //                 // update the holder mapping
    //                 userToHolding[msg.sender][_basketID][tokenArray[i]] = remainingAmount;
    //                 if (remainingAmount == 0) {
    //                     delete userToActiveTokenArray[msg.sender][_basketID][userToTokenIndex[msg.sender][_basketID][tokenArray[i]]];
    //                 }
    //             }
    //         }

    //     }
    //     emit log(Transaction(block.timestamp, msg.sender, _tokenOut, _basketID, _amount, "partial sell"));

    // }
}
