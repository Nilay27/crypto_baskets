# Crypto_Baskets

CryptoBaksets allows retail investors to invest in custom thematic baskets and Dollar Cost Average their Crypto Investments with the click of a single button!

# Description

CryptoBaskets is a decentralized platform where users can invest in crypto market themes via trading baskets. A basket can be rule-based as well as involve discretion. Our team will publish high-quality baskets and we also welcome external experts/traders opening up their basket designs for a subscription. Basket creators will earn management fees as a proportion of the assets under management. 

# Architecture:

## Front End: 

Front end of the app is hosted on Web3.0 and made using ReactJS which is used to design the landing pages and also for the integration and usage of smart contract functions.

## Smart Contracts:

We have 3 smart contracts:
### 1. Baskets.sol
This contract creates the baskets with the user given weight inputs and also mapping of users to baskets, 

### 2. Subscribe.sol
This has multiple methods: 
- a. add - to subscribe to a basket
- b. exit - to completely exit the basket
- c. invest more - to invest more as a part of recurring payment
- d. partial exit - if the user wants to exit partially
- e. rebalance - if the weights of the baskets are changed, this function rebalances the basket position accordingly
- f. getPrice-  gets prices of the tokens from Chainlink in order to determine which token should be bought in what proportion while rebalancing or depositing more. 

### 3. Swap.sol
Performs swaps on uniswap

## Backend:

A decentralized database to store user-data i.e their public address and corresponding basket subscribed.
A Microservice which will notify the user of investment due date and take approval from the user to trigger the contract on regular intervals to perform systematic payment.


# Installation
-  Clone this Repo:
    ```
    git clone https://github.com/Nilay27/crypto_baskets.git
    ```

-   Install all dependencies:

    ```
    cd crypto_baskets/
    npm install
    ```

-   Run Tests:
    ```
    npx hardhat test
    ```

- Run the Code on localHost:3000:
    ```
    npm start
    ``` 
## Security Considerations

-   The Repository is currently not Audited and Does is only meant for testing purposes on Testnets (Rinkeby, Ropsten etc.)

## Areas For Improvement

- Cleanup Subscribe.sol, add NatSpec and make it gas optimised
- Write Tests for Subscribe.sol
- Add functionality of Exact output refund ETH in case of ExactOutPutSingle
