# Crypto_Baskets

CryptoBaksets allows retail investors to invest in custom thematic baskets and Dollar Cost Average their Crypto Investments with the click of a single button!

# Description

CryptoBaskets is a decentralized platform where users can invest in crypto market themes via trading baskets. A basket can be rule-based as well as involve discretion. Our team will publish high-quality baskets and we also welcome external experts/traders opening up their basket designs for a subscription. Basket creators will earn management fees as a proportion of the assets under management. 

# Architecture:

## Front End: 

Front end of the app is made using ReactJS which is used to design the landing pages and also for the integration and usage of smart contract functions.

## Smart Contracts:

We have 3 smart contracts:
### 1. Baskets.sol
This contract creates the baskets with the user given weight inputs and also contains mapping of creators to their corresponding created baskets.

### 2. Subscribe.sol
This has multiple methods: 
- deposit - to subscribe to a basket and purchase tokens with pre-defined weights
- exit - to completely exit the basket
- add - to invest more as a part of recurring payment
- partial exit - if the user wants to exit partially
- rebalance - if the weights of the baskets are changed, this function rebalances the basket position accordingly
- getPrice-  gets prices of the tokens from Chainlink in order to determine which token should be bought in what proportion while rebalancing or depositing more. 

### 3. Swap.sol
Contract to perform swaps on uniswap.

## Backend:

A decentralized database to store user-data i.e their public address and corresponding basket subscribed.

## Branch2 changes                                                 
Adding branch2 changes after which branch2 changes will be added.
Lets see if there is any merge conflict for branch2
while completing the PR for branch2


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

-   The Repository is currently not audited and is only meant for testing purposes on Testnets (Rinkeby, Ropsten etc.)

## TODO/Areas For Improvement
- Add scripts to run tests on Rinkeby instead of localhost for the code to be production ready.
- A Microservice which will notify the user of investment due date and take approval from the user to trigger the contract on regular intervals to perform systematic payment.
- Add functionality for basket creation management fee.
- Cleanup Subscribe.sol, add NatSpec and make it gas optimised
- Write Tests for Subscribe.sol
- Add functionality of Exact output refund ETH in case of ExactOutPutSingle
