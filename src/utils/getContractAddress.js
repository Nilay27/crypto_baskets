import { ethers } from "ethers";
import { addresses,chainlinkOraclesRinkeby } from "../assets/Addresses/rinkeby";
import SampleContract from "../abis/contract-address.json";
import SubscribeBasket from "../abis/Subscribe.json";
import axios from "axios";
const client = axios.create({
  baseURL: "http://127.0.0.1:8000",
});

// The ERC-20 Contract ABI, which is a common contract interface
// for tokens (this is the Human-Readable ABI format)
const Abi = [
  // Some details about the token
  "function name() view returns (string)",
  "function symbol() view returns (string)",

  // Get the account balance
  "function balanceOf(address) view returns (uint)",

  // Send some of your tokens to someone else
  "function transfer(address to, uint amount)",

  //approve tokens to be transfered
  "function approve(address _spender, uint256 _value) public returns (bool success)",
  // An event triggered whenever anyone transfers to someone else
  "event Transfer(address indexed from, address indexed to, uint amount)",

  "function allowance(address owner, address spender) external view returns (uint256)",
  "function decimals() public view virtual override returns (uint8)",
];

export async function getContractAddress(token, provider) {
  // console.log("addresses: ", token);
  // console.log(addresses[token][0]);
  return addresses[token][0];
}

export async function getTokenValue(token, provider){
  if (typeof window.ethereum !== "undefined") {
    const signer = provider.getSigner();
    const routerAddress = SampleContract.SampleContract;
    const routerContract = new ethers.Contract(
      routerAddress,
      SubscribeBasket.abi,
      signer
    );
    var pairAddress = chainlinkOraclesRinkeby[token];
    try {
      const value = await routerContract.getPrice(pairAddress);
      return value/10**8;
    } catch (err) {
      console.log("Error: ", err);
    }
  }
}

export async function getUserHoldingForBasket(
  defaultAccount,
  _basketId,
  token,
  provider
) {
  if (typeof window.ethereum !== "undefined") {
    const signer = provider.getSigner();
    const routerAddress = SampleContract.SampleContract;
    const routerContract = new ethers.Contract(
      routerAddress,
      SubscribeBasket.abi,
      signer
    );
    const erc20Contract = new ethers.Contract(token, Abi, signer);
    try {
      // console.log("reached tx new ");
      // console.log("token: ", token);
      // console.log("basketId: ", _basketId);
      // console.log("account: ", defaultAccount);
      const balance = await routerContract.getUserHoldingForToken(
        defaultAccount,
        _basketId,
        token
      );
      const decimals = await erc20Contract.decimals();
      const balanceInTokenAmount = balance / 10 ** decimals;
      // const balance = await transaction.wait();

      // console.log("balanceInTokenAmount", balanceInTokenAmount);
      return balanceInTokenAmount;
    } catch (err) {
      console.log("Error: ", err);
    }
  }
}

export async function getApproval(token, provider, address) {
  if (typeof window.ethereum !== "undefined") {
    const signer = provider.getSigner();
    const routerAddress = SampleContract.SampleContract;
    const amount = ethers.utils.parseEther("10000000");
    const contract = new ethers.Contract(token, Abi, signer);
    const userBalance = await contract.balanceOf(address);
    const approvalAmount = await contract.allowance(address, routerAddress);
    // console.log("balance of user: ", userBalance);
    // console.log("approval for the token: ", approvalAmount);
    try {
      const transaction = await contract.approve(routerAddress, amount);
      // console.log("reached tx");
      const data = await transaction.wait();
      // console.log("reached approve");
      // console.log("approved", token);
    } catch (err) {
      // console.log("Error: ", err);
    }
  }
}

export async function createBasket(
  provider,
  tokens,
  weights,
  id,
  basketName,
  navigate,
  defaultAccount,
  tokenNames,
  setBasketCreated
) {
  if (typeof window.ethereum !== "undefined") {
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      SampleContract.SampleContract,
      SubscribeBasket.abi,
      signer
    );
    try {
      const transaction = await contract.createBasket(tokens, weights, id);
      const data = await transaction.wait();
      const event = await data.events.find(
        (event) => event.event === "basketCreated"
      );
      // console.log("event.args");
      // console.log(event);
      const [creator, basket] = await event.args;
      // console.log(creator, basket);
      client
        .post("/baskets/create-basket", {
          basket_id: id,
          tokens: tokenNames,
          weights: weights,
          creator_address: defaultAccount,
          name: basketName,
        })
        .then((response) => {
          if (response.data["HTTPStatusCode"] === 200) {
            // console.log(response.data["message"]);
            setBasketCreated(true);
            navigate("../view-baskets", { replace: true });
          } else {
            // console.log(response.data["message"]);
          }
        })
        .catch((error) => {
          // console.log("Error occurred: ", error);
        });
    } catch (err) {
      // console.log("Error: ", err);
    }
  }
}

export async function subscribeToBasket(
  provider,
  _basketID,
  _tokenIn,
  _amount,
  tokenNames,
  defaultAccount,
  frequency,
  navigate,
  setBasketSubscribed
) {
  if (typeof window.ethereum !== "undefined") {
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      SampleContract.SampleContract,
      SubscribeBasket.abi,
      signer
    );

    try {
      const amount = ethers.utils.parseEther(_amount);

      const transaction = await contract.deposit(_basketID, _tokenIn, amount, {
        value: amount,
      });
      const data = await transaction.wait();
      // console.log(Transaction);
      const token_amounts = tokenNames.map((name) => 0);
      client
        .post("/subscriptions/subscribe", {
          basket_id: _basketID,
          tokens: tokenNames,
          token_amounts: token_amounts,
          user_id: defaultAccount,
          frequency: frequency,
        })
        .then((response) => {
          if (response.data["HTTPStatusCode"] === 200) {
            // console.log(response.data["message"]);
            setBasketSubscribed(true);
            navigate("../app", { replace: true });
          } else {
            // console.log(response.data["message"]);
          }
        })
        .catch((error) => {
          console.log("Error occurred: ", error);
        });
    } catch (err) {
      console.log("Error: ", err);
    }
  }
}
export async function addFunds(
  provider,
  _basketID,
  _tokenIn,
  _amount,
) {
  if (typeof window.ethereum !== "undefined") {
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      SampleContract.SampleContract,
      SubscribeBasket.abi,
      signer
    );

    try {
      const amount = ethers.utils.parseEther(_amount);

      const transaction = await contract.add(_basketID, _tokenIn, amount, {
        value: amount,
      });
      const data = await transaction.wait();
    } catch (err) {
      console.log("Error: ", err);
    }
  }
}

export async function partialExit(
  provider,
  _basketID,
  _tokenIn,
  _amount,
) {
  if (typeof window.ethereum !== "undefined") {
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      SampleContract.SampleContract,
      SubscribeBasket.abi,
      signer
    );

    try {
      const amount = ethers.utils.parseEther(_amount);

      const transaction = await contract.sell(_basketID, _tokenIn, amount);
      const data = await transaction.wait();
    } catch (err) {
      console.log("Error: ", err);
    }
  }
}


export async function exitBasket(
  provider,
  _basketID,
  _tokenOut,
  defaultAccount,
  navigate
) {
  if (typeof window.ethereum !== "undefined") {
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      SampleContract.SampleContract,
      SubscribeBasket.abi,
      signer
    );

    try {
      // console.log("id", _basketID);
      // console.log("input token", _tokenOut);
      const transaction = await contract.exit(_basketID, _tokenOut);
      const data = await transaction.wait();
      // console.log(Transaction);
      client
        .post("/subscriptions/unsubscribe", {
          basket_id: _basketID,
          user_id: defaultAccount,
        })
        .then((response) => {
          if (response.data["HTTPStatusCode"] === 200) {
            // console.log(response.data["message"]);
            navigate("../app", { replace: true });
          } else {
            // console.log(response.data["message"]);
          }
        })
        .catch((error) => {
          // console.log("Error occurred: ", error);
        });
    } catch (err) {
      // console.log("Error: ", err);
    }
  }
}
