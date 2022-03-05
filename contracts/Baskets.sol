// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Baskets is Ownable {
    event basketCreated(address owner, Basket basket);
    event weightsChanged(string basketId, Basket basket);
    //mapping of creators to the baskets created by them
    mapping(address => Basket[]) creators;
    //mapping of basketId to Basket
    mapping(string => Basket) uniqueBasketMapping;

    struct Basket {
        bool active;
        string basketID;
        address[] tokens;
        uint256[] weights;
        address basketOwner;
    }

    /**
        @dev modifiers to validate the baskets and perform trivial checks before creation
     */
    modifier checkBasketExists(string memory id) {
        require(uniqueBasketMapping[id].active, "basket does not exists");
        _;
    }
    modifier validateBasket(
        address[] memory tokens,
        uint256[] memory weights,
        string memory id
    ) {
        require(
            tokens.length == weights.length,
            "all tokens have not been assigned weights"
        );
        require(
            !uniqueBasketMapping[id].active,
            "identical basket already exists"
        );
        _;
    }
    modifier validateWeights(uint256[] memory weights) {
        uint256 sum = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            require(weights[i] > 0, "weight must be postive");
            sum += weights[i];
        }
        require(
            sum == 100,
            "sum of weights of constituents is not equal to 100"
        );
        _;
    }

    /**
        @notice Creates the Basket with tokens and respective weights
        @dev Pushes the new Basket into the list of Baskets created by the creator
        @param tokens The list of tokens present in the basket
        @param weights Respective weights of Tokens as fixed by the creator
        @param id Unique Id corresponding to the basket
    */
    function createBasket(
        address[] memory tokens,
        uint256[] memory weights,
        string memory id
    ) external validateBasket(tokens, weights, id) validateWeights(weights) {
        Basket memory basket = Basket({
            basketID: id,
            tokens: tokens,
            weights: weights,
            basketOwner: msg.sender,
            active: true
        });

        uniqueBasketMapping[id] = basket; //create a mapping for unique baskets
        creators[msg.sender].push(basket); //append to the list of baskets for the particular creator

        emit basketCreated(msg.sender, basket);
    }

    /**
        @dev Change the weights of baskets when the owner resets them
     */
    function resetWeights(string memory basketId, uint256[] memory weights)
        external
        validateWeights(weights)
        checkBasketExists(basketId)
    {
        require(
            uniqueBasketMapping[basketId].weights.length == weights.length,
            "new and old basket weights are not of equal lengths"
        );
        Basket memory basket;
        basket = uniqueBasketMapping[basketId];
        require(
            basket.basketOwner == msg.sender,
            "only owner can modify the weights of basket"
        );
        basket.weights = weights;
        emit weightsChanged(basketId, basket);
    }

    /**
        @dev fetch the struct Basket when called by its Basket Id 
     */
    function getBasketById(string memory _basketId)
        public
        view
        checkBasketExists(_basketId)
        returns (Basket memory)
    {
        Basket memory basket = uniqueBasketMapping[_basketId];
        return basket;
    }

    /**
        @dev transfers the ownership to a new address
     */
    function transferBasketOwnership(address _newOwner, string memory basketId)
        external
        checkBasketExists(basketId)
    {
        require(
            msg.sender == uniqueBasketMapping[basketId].basketOwner,
            "you are not the owner of the basket"
        );
        uniqueBasketMapping[basketId].basketOwner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}
