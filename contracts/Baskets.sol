// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/access/Ownable.sol';

contract Baskets is Ownable{

    event basketCreated(address owner, Basket basket);
    //mapping of creators to the baskets created by them
    mapping (address=>Basket[]) creators; 
    //mapping of basketId to Basket
    mapping (string=>Basket) uniqueBasketMapping; 

    struct Basket {
        bool active;
        string BasketID; 
        address[] tokens;
        uint256[] weights;
        address basketOwner;
    }

    /**
        @dev modifier to validate the baskets and perform trivial checks before creation
     */
    modifier validateBasket(address[] memory tokens, uint256[] memory weights, string memory id){
        require(tokens.length == weights.length,"all tokens have not been assigned weights");
        require(!uniqueBasketMapping[id].active, "identical basket already exists");
        uint256 sum=0;
        for (uint i=0;i<weights.length;i++){
             require(weights[i] > 0 , "weight must be postive" );
            sum+=weights[i];
        }
        require(sum==100,"sum of weights of constituents is not equal to 100");
        _;
   }
   
   /**
        @notice Creates the Basket with tokens and respective weights
        @dev Pushes the new Basket into the list of Baskets created by the creator
        @param tokens The list of tokens present in the basket
        @param weights Respective weights of Tokens as fixed by the creator
        @param id Unique Id corresponding to the basket
    */
    function createBasket(address[] memory tokens, uint256[] memory weights, string memory id) external validateBasket(tokens,weights,id){

        Basket memory basket = Basket({BasketID:id,tokens:tokens, weights:weights,basketOwner:msg.sender, active: true});

        
        uniqueBasketMapping[id]= basket; //create a mapping for unique baskets
        creators[msg.sender].push(basket); //append to the list of baskets for the particular creator

        emit basketCreated(msg.sender, basket);
    }
    

    /**
        @dev Change the weights of baskets when the owner resets them
     */
    function resetWeights(string memory _basketId, uint256[] memory _weights) internal view {
        Basket memory basket;
        basket = uniqueBasketMapping[_basketId] ;
        require (basket.basketOwner==msg.sender, "only owner can modify the weights of basket");
        basket.weights = _weights ;
    }

    /**
        @dev fetch the struct Basket when called by its Basket Id 
     */
    function getBasketById(string memory _basketId) internal view returns(Basket memory basket){
        require(uniqueBasketMapping[_basketId].active, "basket does not exists");
        return uniqueBasketMapping[_basketId];
    }

    /**
        @dev transfers the ownership to a new address
     */
    function transferBasketOwnership(address _newOwner, string memory basketId) external{
        require(msg.sender == uniqueBasketMapping[basketId].basketOwner, "you are not the owner of the basket");
        uniqueBasketMapping[basketId].basketOwner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }

}