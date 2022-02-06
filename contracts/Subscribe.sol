// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "hardhat/console.sol";
import "./Baskets.sol";
import "./SwapUniswapV3.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Subscribe is Baskets, Swap {

    // struct Transaction {
    //     //transaction information
    //     uint callTime;
    //     address user; // subscriber
    //     address token; // deposit or withdraw tokens
    //     string basketID; // defined in baskets contract
    //     uint transactionAmount; // let's figure out the unit later
    //     string transactionType; // deposit, exit, partial sell
    // }

    using Math for uint;

    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    //mapping(string => address) userCoinToAddress; // user token code to token address
    mapping(address => address) tokenToLinkPriceAddress; // token address to chainlink price address
    //mapping(address => Transaction[]) public userToTransaction; // user to his/her transaction array
    mapping(address => mapping(string => mapping(address => uint))) public userToHolding; // user to basketid and to a mapping with token address to amount
    mapping(address => mapping(string => address[])) userToActiveTokenArray; // user to basketid and to a mapping with token address to amount
    mapping(address => mapping(string => mapping(address => uint))) userToTokenIndex; // track userToActiveTokenArray index position for tokens + 1, so 0 is no holding
    mapping(string => mapping(address => uint)) basketToWeight; //temp utility mapping, basket to token to weight

    constructor() {
        // hardcode the address for now, can deal with them on front end


        // userCoinToAddress["LINK"] = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
        // userCoinToAddress["WBTC"] = 0x577D296678535e4903D59A4C929B718e1D575e0A;
        // userCoinToAddress["USDC"] = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926;
        // userCoinToAddress["DAI"] = 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;
        // userCoinToAddress["MKR"] = 0xF9bA5210F91D0474bd1e1DcDAeC4C58E359AaD85;

        tokenToLinkPriceAddress[0xeb8f08a975Ab53E34D8a0330E0D34de942C95926] = 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf; // USDC rinkeby
        tokenToLinkPriceAddress[0x577D296678535e4903D59A4C929B718e1D575e0A] = 0x2431452A0010a43878bF198e170F6319Af6d27F4; // BTC rinkeby
        tokenToLinkPriceAddress[0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa] = 0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D; // DAI
        // ["0x577D296678535e4903D59A4C929B718e1D575e0A", "0x01BE23585060835E02B77ef475b0Cc51aA1e0709"]
        //0x0000000000000000000000000000000000000000;
    }

    /// Break basket information into token array, and component amount array so that we can send trades
    function basketToComponent(
        string memory _basketID,
        uint _amount
        ) public view returns (
            address[] memory,
            uint[] memory) {

        // inherit function - retrieve the basket information from the state variable in the Basket contract
        Baskets.Basket memory basket = getBasketById(_basketID);

        address[] memory tokenArray = basket.tokens;
        uint[] memory weightArray = basket.weights;
        uint[] memory amountArray = new uint[](tokenArray.length); // must be the same length as tokenArray

        for (uint i = 0; i < tokenArray.length; i ++) {
            amountArray[i] = (_amount * weightArray[i]) / 100;
        }
        return (tokenArray, amountArray);
    }

    // function sendFee(string memory _coin, address payable _to, uint _amount) public payable {
    //     /* send subscriber fee, need to modify this probably */

    //     if (keccak256(abi.encodePacked(_coin)) == keccak256(abi.encodePacked("ETH"))){
    //         (bool success, ) = _to.call {value : _amount}("");
    //         require(success, "fail to send the subscriber fee to creator");
    //     } else {
    //         ERC20(userCoinToAddress[_coin]).transfer(_to, _amount);
    //     }
    // }


    /// helper function on transaction, _buy is a boolean on buy or sell
    function transaction(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        bool _buy,
        string memory _basketID
        ) internal {

        require(_amountIn > 0, "amount has to be positive");

        // frontend sets ETH to be address(0), in this case we need to use a different swap function
        // as it's not ERC20
        if (_tokenIn == address(0) && _buy) { // has to be buy transaction
            require(msg.value == _amountIn, "value called != value passed");

            uint amountOut = Swap.convertExactEthToToken(_tokenOut, _amountIn);
            // if this is a new holding, we need to update the holding list mapping and holding index mapping
            if (userToHolding[msg.sender][_basketID][_tokenOut] == 0) {
                userToActiveTokenArray[msg.sender][_basketID].push(_tokenOut);

                userToTokenIndex[msg.sender][_basketID][_tokenOut] =
                userToActiveTokenArray[msg.sender][_basketID].length;
            }
            // add amountOut to user holding mapping
            userToHolding[msg.sender][_basketID][_tokenOut] += amountOut;

        // only acceptable ERC20 tokens here, rely on the front end to restrict
        } else {
            uint amountOut = Swap.swapExactTokenInForTokenOut(_tokenIn, _tokenOut, _amountIn);
            // buy and sell should be treated different for the mappings
            if (_buy) { // add to _tokenOut holding
                // if this is a new holding, we need to update the holding list mapping and holding index mapping
                if (userToHolding[msg.sender][_basketID][_tokenOut] == 0) {
                    userToActiveTokenArray[msg.sender][_basketID].push(_tokenOut);

                    userToTokenIndex[msg.sender][_basketID][_tokenOut] =
                    userToActiveTokenArray[msg.sender][_basketID].length;
                }
                // add amountOut to user holding mapping
                userToHolding[msg.sender][_basketID][_tokenOut] += amountOut;
            } else { // trim _tokenIn
                // update the holder mapping and token array
                userToHolding[msg.sender][_basketID][_tokenIn] -= _amountIn;
                // if no holding anymore delete the token from tokenArray and assign index to 0
                if (userToHolding[msg.sender][_basketID][_tokenIn] == 0) {
                    delete userToActiveTokenArray[msg.sender][_basketID][userToTokenIndex[msg.sender][_basketID][_tokenIn] - 1]; // index is 1 + position, so get the token by minus 1
                    userToTokenIndex[msg.sender][_basketID][_tokenIn] = 0;
                }
            }
        }
    }

   /// @dev execute the trades when user decides to deposit certain amount to a basket
    function deposit(string memory _basketID, address _tokenIn, uint _amount) external payable {

        // // update the transaction mapping userToTransaction
        // Transaction memory userTransaction = Transaction(block.timestamp, msg.sender, _tokenIn, _basketID, _amount, "deposit");
        // userToTransaction[msg.sender].push(userTransaction);

        // pay the subscriber fee to creator
        // address payable creator = payable(Baskets.getBasketById(_basketID).basketOwner);
        // sendFee(_tokenIn, creator, uint(_amount * 1 / 100)); // decidie later how much to charge
        // uint transactionAmount = uint(_amount - _amount * 1 / 100);

        require(_amount > 0, "amount has to be positive");
        // break basket deposit into trade amount by tokens
        (address[] memory tokenArray, uint[] memory amountArray) = basketToComponent(_basketID, _amount);

        for (uint i = 0; i < tokenArray.length; i ++) {
            transaction(
                _tokenIn,
                tokenArray[i],
                amountArray[i],
                true,
                _basketID
            );
        }
    }


    // /// @dev execute the trades when user decides to deposit certain amount to a basket
    // function deposit(string memory _basketID, address _tokenIn, uint _amount) external payable {

    //     // // update the transaction mapping userToTransaction
    //     // Transaction memory userTransaction = Transaction(block.timestamp, msg.sender, _tokenIn, _basketID, _amount, "deposit");
    //     // userToTransaction[msg.sender].push(userTransaction);

    //     // pay the subscriber fee to creator
    //     // address payable creator = payable(Baskets.getBasketById(_basketID).basketOwner);
    //     // sendFee(_tokenIn, creator, uint(_amount * 1 / 100)); // decidie later how much to charge
    //     // uint transactionAmount = uint(_amount - _amount * 1 / 100);

    //     require(_amount > 0, "amount has to be positive");
    //     // break basket deposit into trade amount by tokens
    //     (address[] memory tokenArray, uint[] memory amountArray) = basketToComponent(_basketID, _amount);

    //     // frontend sets ETH to be address(0), in this case we need to use a different swap function
    //     // as it's not ERC20
    //     if (_tokenIn == address(0)) {
    //         for (uint i = 0; i < tokenArray.length; i ++) {
    //             // target holding in each token
    //             uint amountOut = Swap.convertExactEthToToken(tokenArray[i], amountArray[i]);
    //             // if this is a new holding, we need to update the holding list mapping and holding index mapping
    //             if (userToHolding[msg.sender][_basketID][tokenArray[i]] == 0) {
    //                 userToActiveTokenArray[msg.sender][_basketID].push(tokenArray[i]);

    //                 userToTokenIndex[msg.sender][_basketID][tokenArray[i]] =
    //                 userToActiveTokenArray[msg.sender][_basketID].length;
    //             }
    //             // add amountOut to user holding mapping
    //             userToHolding[msg.sender][_basketID][tokenArray[i]] += amountOut;
    //         }

    //     // only acceptable ERC20 tokens here, rely on the front end to restrict
    //     } else {
    //         for (uint i = 0; i < tokenArray.length; i ++) {
    //             // target holding in each token
    //             uint amountOut = Swap.swapExactTokenInForTokenOut(_tokenIn, tokenArray[i], amountArray[i]);
    //             // if this is a new holding, we need to update the holding list mapping and holding index mapping
    //             if (userToHolding[msg.sender][_basketID][tokenArray[i]] <= 0) {
    //                 userToActiveTokenArray[msg.sender][_basketID].push(tokenArray[i]);

    //                 userToTokenIndex[msg.sender][_basketID][tokenArray[i]] =
    //                 userToActiveTokenArray[msg.sender][_basketID].length;
    //             }
    //             // add amountOut to user holding mapping
    //             userToHolding[msg.sender][_basketID][tokenArray[i]] += amountOut;
    //         }
    //     }
    // }


    /// only apply if user decides to exit all the holding related to a basket
    function exit(string memory _basketID, address _tokenOut) external {

        // ETH can't be accepted as a withdraw token
        require(_tokenOut != address(0), "user can't receive ETH");

        // // update the transaction mapping subscriberToTransaction
        // Transaction memory userTransaction = Transaction(block.timestamp, msg.sender, _tokenOut, _basketID, 0, "exit");
        // userToTransaction[msg.sender].push(userTransaction);

        // loop through the current holding and exit
        address[] memory tokenArray = userToActiveTokenArray[msg.sender][_basketID];
        for (uint i = 0; i < tokenArray.length; i ++) {
            if (tokenArray[i] != address(0)) { // if it's address(0), it means token is deleted hence zero holding
                // compare the balance with holding mapping, taking the lower value
                uint tokenBalance = Math.min(userToHolding[msg.sender][_basketID][tokenArray[i]], ERC20(tokenArray[i]).balanceOf(msg.sender));

                if (tokenBalance > 0) { // if user still holds something, we will sell too
                    transaction(
                        tokenArray[i],
                        _tokenOut,
                        tokenBalance,
                        false,
                        _basketID
                    );

                    // // swap the token for the entire holding
                    // uint _amountOut = Swap.swapExactTokenInForTokenOut(tokenArray[i], _tokenOut, tokenBalance);

                    // // update the holder mapping and token array (delete the token from tokenArray)
                    // userToHolding[msg.sender][_basketID][tokenArray[i]] = 0;
                    // delete userToActiveTokenArray[msg.sender][_basketID][userToTokenIndex[msg.sender][_basketID][tokenArray[i]] - 1]; // index is 1 + position, so get the token by minus 1
                    // userToTokenIndex[msg.sender][_basketID][tokenArray[i]] = 0;
                }
            }
        }
    }

    // /// only apply if user decides to exit all the holding related to a basket
    // function exit(string memory _basketID, address _tokenOut) external {

    //     // ETH can't be accepted as a withdraw token
    //     require(_tokenOut != address(0), "user can't receive ETH");

    //     // // update the transaction mapping subscriberToTransaction
    //     // Transaction memory userTransaction = Transaction(block.timestamp, msg.sender, _tokenOut, _basketID, 0, "exit");
    //     // userToTransaction[msg.sender].push(userTransaction);

    //     // loop through the current holding and exit
    //     address[] memory tokenArray = userToActiveTokenArray[msg.sender][_basketID];
    //     for (uint i = 0; i < tokenArray.length; i ++) {
    //         if (tokenArray[i] != address(0)) { // if it's address(0), it means token is deleted hence zero holding
    //             // compare the balance with holding mapping, taking the lower value
    //             uint tokenBalance = Math.min(userToHolding[msg.sender][_basketID][tokenArray[i]], ERC20(tokenArray[i]).balanceOf(msg.sender));

    //             if (tokenBalance > 0) { // if user still holds something, we will sell too
    //                 // swap the token for the entire holding
    //                 uint _amountOut = Swap.swapExactTokenInForTokenOut(tokenArray[i], _tokenOut, tokenBalance);

    //                 // update the holder mapping and token array (delete the token from tokenArray)
    //                 userToHolding[msg.sender][_basketID][tokenArray[i]] = 0;
    //                 delete userToActiveTokenArray[msg.sender][_basketID][userToTokenIndex[msg.sender][_basketID][tokenArray[i]] - 1]; // index is 1 + position, so get the token by minus 1
    //                 userToTokenIndex[msg.sender][_basketID][tokenArray[i]] = 0;
    //             }
    //         }
    //     }
    // }

    /// get the price for token vs ETH from chainlink oracle, address of that pair needed
    function getPriceETH(address _pair) internal view returns(uint) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_pair);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint(answer);
    }

    /// get user basket balance in total and in each token (in ETH)
    function getBasketBalanceETH(address _userAddress, string memory _basketID) internal view returns(
            uint,
            address[] memory,
            uint[] memory) {

        // active token array from user's subscription in a basket
        address[] memory activeTokenArray = userToActiveTokenArray[_userAddress][_basketID];
        // track the total balance in ETH
        uint totalBalanceETH;
        // tokenBalanceETH array intends to match the activeTokenArray
        uint[] memory tokenBalanceETH = new uint[](activeTokenArray.length);

        for (uint i = 0; i < activeTokenArray.length; i ++) {
            address token = activeTokenArray[i];
            if (token != address(0)) {
                uint tokenAmount = userToHolding[_userAddress][_basketID][token];
                // tokenAmount is in token unit, convert them into ETH
                uint tokenPriceETH = getPriceETH(tokenToLinkPriceAddress[token]);
                uint tokenAmountETH = tokenAmount * tokenPriceETH;
                // update the token balance and total balance
                tokenBalanceETH[i] = tokenAmountETH;
                totalBalanceETH += tokenAmountETH;
            } else {//if a token is address 0, it means the balance is zero and got deleted
                tokenBalanceETH[i] = 0;
            }
        }
        return (totalBalanceETH, activeTokenArray, tokenBalanceETH);
    }



    /** rebalance the holding according to the current basket
    * logic is as follows:
    * 1. loop through the current basket, use the targetamount to calculate the end amount and rebalance
    * against current holding; if not in current holding, then initiate it; we need to put basket token and weight
    * in a mapping that is useful for step 2
    * 2. then loop through the current holding, if token not in current basket, sell them entirely
    * 3. use balance token to do the balancing trade
    */
    // function reblance(
    //     string memory _basketID,
    //     uint _targetAmount,
    //     bool _current,
    //     address _balanceToken) external payable {

    //     // get user's total balance and token balance in ETH for a basket, ETH is just a common unit to convert
    //     // (uint balanceETH, address[] memory activeTokenArray, uint[] memory balanceArrayETH) = getBasketBalanceETH(msg.sender, _basketID);

    //     // iterate the current basket
    //     Baskets.Basket memory basket = getBasketById(_basketID);

    //     for (uint i = 0; i < basket.tokens.length; i ++) {
    //         // integrate into current holding
    //         basketToWeight[_basketID][basket.tokens[i]] = basket.weights[i];

    //         if (userToTokenIndex[msg.sender][_basketID][basket.tokens[i]] == 0) { // no holding
    //             // if no holding, we need to buy them
    //             tradeTokenArray[tradeCounter] = basket.tokens[i];
    //             tradeETHArray[tradeCounter] = balanceETH * basket.weights[i];
    //             tradeCounter ++;
    //         }

    //     }

    //     // check all the current basket and then check for left out tokens in arayctiveAr
    //     // check all the activeArray and then


    //     // integrate the current basket into weight mapping, and then do the trade
    //     for (uint i = 0; i < basket.tokens.length; i ++) {
    //         basketToWeight[_basketID][basket.tokens[i]] = basket.weights[i];
    //         if (userToTokenIndex[msg.sender][_basketID][basket.tokens[i]] == 0) { // no holding
    //             // if no holding, we need to buy them
    //             tradeTokenArray[tradeCounter] = basket.tokens[i];
    //             tradeETHArray[tradeCounter] = balanceETH * basket.weights[i];
    //             tradeCounter ++;
    //         }
    //     }

    //     // loop through the current holding and calculate the trades
    //     for (uint i = 0; i < activeTokenArray.length; i ++) {
    //         if (activeTokenArray[i] != address(0)) {
    //             if (basketToWeight[_basketID][activeTokenArray[i]] * balanceETH != balanceArrayETH[i]) {
    //                 tradeTokenArray[tradeCounter] = activeTokenArray[i];
    //                 tradeETHArray[tradeCounter] = basketToWeight[_basketID][activeTokenArray[i]] * balanceETH - balanceArrayETH[i];
    //                 tradeCounter ++;
    //             }
    //         }
    //     }

    //     // loop through the trade array and trade through WETH
    //     for (uint i = 0; i < tradeTokenArray.length; i ++) {
    //         if (tradeETHArray[i] > 0) { // if it's a buy we buy with WETH
    //             //getPriceETH(address _pair)
    //             uint _amountOut = Swap.swapExactTokenInForTokenOut(WETH, tradeTokenArray[i], tradeETHArray[i]);

    //             // update the holder mapping
    //             userToHolding[msg.sender][_basketID][tradeTokenArray[i]] += _amountOut;

    //             // update the token index if not existant before
    //             if (userToTokenIndex[msg.sender][_basketID][basket.tokens[i]] == 0) {
    //                 userToActiveTokenArray[msg.sender][_basketID].push(tradeTokenArray[i]);
    //                 userToTokenIndex[msg.sender][_basketID][tradeTokenArray[i]] = userToActiveTokenArray[msg.sender][_basketID].length;
    //             }
    //         } else {
    //             uint _amountOut = Swap.swapExactTokenInForTokenOut(tradeTokenArray[i], WETH, tradeETHArray[i] * getPriceETH(tokenToLinkPriceAddress[tradeTokenArray[i]]));

    //             // update the holder mapping
    //             userToHolding[msg.sender][_basketID][tradeTokenArray[i]] = basketToWeight[_basketID][tradeTokenArray[i]] * balanceETH * getPriceETH(tokenToLinkPriceAddress[tradeTokenArray[i]]);
    //             if (basketToWeight[_basketID][activeTokenArray[i]] == 0) {
    //                 delete userToActiveTokenArray[msg.sender][_basketID][userToTokenIndex[msg.sender][_basketID][activeTokenArray[i]]];
    //                 userToTokenIndex[msg.sender][_basketID][activeTokenArray[i]] = 0;
    //             }
    //         }

    //         }
    //     }

    // }



    // /// rebalance the holding according to the current basket
    // function reblance(string memory _basketID) external {

    //     // get user's total balance and token balance in ETH for a basket, ETH is just a common unit to convert
    //     (uint balanceETH, address[] memory activeTokenArray, uint[] memory balanceArrayETH) = getBasketBalanceETH(msg.sender, _basketID);

    //     // current basket information
    //     Baskets.Basket memory basket = getBasketById(_basketID);

    //     uint tradeCounter = 0;
    //     address[] memory tradeTokenArray = new address[](activeTokenArray.length + basket.tokens.length);
    //     uint[] memory tradeETHArray = new uint[](activeTokenArray.length + basket.tokens.length);

    //     // integrate the current basket into weight mapping, and check for new tokens
    //     for (uint i = 0; i < basket.tokens.length; i ++) {
    //         basketToWeight[_basketID][basket.tokens[i]] = basket.weights[i];
    //         if (userToTokenIndex[msg.sender][_basketID][basket.tokens[i]] == 0) { // no holding
    //             // if no holding, we need to buy them
    //             tradeTokenArray[tradeCounter] = basket.tokens[i];
    //             tradeETHArray[tradeCounter] = balanceETH * basket.weights[i];
    //             tradeCounter ++;
    //         }
    //     }

    //     // loop through the current holding and calculate the trades
    //     for (uint i = 0; i < activeTokenArray.length; i ++) {
    //         if (activeTokenArray[i] != address(0)) {
    //             if (basketToWeight[_basketID][activeTokenArray[i]] * balanceETH != balanceArrayETH[i]) {
    //                 tradeTokenArray[tradeCounter] = activeTokenArray[i];
    //                 tradeETHArray[tradeCounter] = basketToWeight[_basketID][activeTokenArray[i]] * balanceETH - balanceArrayETH[i];
    //                 tradeCounter ++;
    //             }
    //         }
    //     }

    //     // loop through the trade array and trade through WETH
    //     for (uint i = 0; i < tradeTokenArray.length; i ++) {
    //         if (tradeETHArray[i] > 0) { // if it's a buy we buy with WETH
    //             //getPriceETH(address _pair)
    //             uint _amountOut = Swap.swapExactTokenInForTokenOut(WETH, tradeTokenArray[i], tradeETHArray[i]);

    //             // update the holder mapping
    //             userToHolding[msg.sender][_basketID][tradeTokenArray[i]] += _amountOut;

    //             // update the token index if not existant before
    //             if (userToTokenIndex[msg.sender][_basketID][basket.tokens[i]] == 0) {
    //                 userToActiveTokenArray[msg.sender][_basketID].push(tradeTokenArray[i]);
    //                 userToTokenIndex[msg.sender][_basketID][tradeTokenArray[i]] = userToActiveTokenArray[msg.sender][_basketID].length;
    //             }
    //         } else {
    //             uint _amountOut = Swap.swapExactTokenInForTokenOut(tradeTokenArray[i], WETH, tradeETHArray[i] * getPriceETH(tokenToLinkPriceAddress[tradeTokenArray[i]]));

    //             // update the holder mapping
    //             userToHolding[msg.sender][_basketID][tradeTokenArray[i]] = basketToWeight[_basketID][tradeTokenArray[i]] * balanceETH * getPriceETH(tokenToLinkPriceAddress[tradeTokenArray[i]]);
    //             if (basketToWeight[_basketID][activeTokenArray[i]] == 0) {
    //                 delete userToActiveTokenArray[msg.sender][_basketID][userToTokenIndex[msg.sender][_basketID][activeTokenArray[i]]];
    //                 userToTokenIndex[msg.sender][_basketID][activeTokenArray[i]] = 0;
    //             }
    //         }

    //         }
    //     }










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

    }
