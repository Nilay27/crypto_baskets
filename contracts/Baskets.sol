// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Baskets is Ownable {
    event basketCreated(address owner, Basket basket);

    mapping(address => Basket[]) creators; //mapping of creators to the baskets created by them
    mapping(string => Basket) uniqueBasketMapping; //mapping of basketId to Basket

    struct Basket {
        bool active;
        string BasketID; //hash of the constituents of basket and weights
        address[] tokens;
        uint256[] weights;
        address basketOwner;
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

    function createBasket(
        address[] memory tokens,
        uint256[] memory weights,
        string memory id
    ) external validateBasket(tokens, weights, id) {
        Basket memory basket = Basket({
            BasketID: id,
            tokens: tokens,
            weights: weights,
            basketOwner: msg.sender,
            active: true
        });

        uniqueBasketMapping[id] = basket; //create a mapping for unique baskets
        creators[msg.sender].push(basket); //append to the list of baskets for the particular creator

        emit basketCreated(msg.sender, basket);
    }

    function resetWeights(string memory _id, uint256[] memory _weights)
        internal
        view
    {
        Basket memory basket;
        basket = uniqueBasketMapping[_id];
        basket.weights = _weights;
    }

    function getBasketById(string memory id)
        internal
        view
        returns (Basket memory)
    {
        require(uniqueBasketMapping[id].active, "basket does not exists");
        return uniqueBasketMapping[id];
    }

    function transferBasketOwnership(address _newOwner, string memory basketId)
        external
    {
        require(
            msg.sender == uniqueBasketMapping[basketId].basketOwner,
            "you are not the owner of the basket"
        );
        uniqueBasketMapping[basketId].basketOwner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}
