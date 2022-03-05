const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

describe("Baskets.sol", () => {
  let BasketContract, basketContract;
  const addresses = {
    WETH: ["0xc778417E063141139Fce010982780140Aa0cD5Ab", "Wrapped Ether"],
    USDT: ["0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD", "USD Tether"],
    WBTC: ["0x577D296678535e4903D59A4C929B718e1D575e0A", "Wrapped Bitcoin"],
    ETH: ["0x0000000000000000000000000000000000000000", "Ether"],
  };
  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    owner = accounts[0];
    account1 = accounts[1];
    account2 = accounts[2];
    BasketContract = await ethers.getContractFactory("Baskets");
    basketContract = await BasketContract.deploy();
    await basketContract.deployed();
  });

  describe("Create Basket", function () {
    describe("Revert scenarios", function () {
      let tokens;
      let weights;
      let id;
      let weth = addresses["WETH"][0];
      let usdt = addresses["USDT"][0];
      let wbtc = addresses["WBTC"][0];

      it("should fail when all tokens are not assigned weights", async function () {
        tokens = [weth, usdt, wbtc];
        weights = [50, 50];
        id = "basket_1";
        await expect(
          basketContract.connect(account1).createBasket(tokens, weights, id)
        ).to.be.revertedWith("all tokens have not been assigned weights");
      });

      it("should fail when sum of weights not equal 100", async function () {
        tokens = [weth, usdt, wbtc];
        weights = [33, 33, 33];
        id = "basket_1";
        await expect(
          basketContract.connect(account1).createBasket(tokens, weights, id)
        ).to.be.revertedWith(
          "sum of weights of constituents is not equal to 100"
        );
      });

      it("should fail when identical baskets exists ", async function () {
        tokens = [weth, usdt, wbtc];
        weights = [33, 33, 34];
        id = "basket_1";
        await basketContract
          .connect(account1)
          .createBasket(tokens, weights, id);
        await expect(
          basketContract.connect(account1).createBasket(tokens, weights, id)
        ).to.be.revertedWith("identical basket already exists");
      });
    });

    describe("Success Scenarios", function () {
      let tokens;
      let weights;
      let id;
      let weth = addresses["WETH"][0];
      let usdt = addresses["USDT"][0];
      let wbtc = addresses["WBTC"][0];
      it("should emit a BasketCreated event with correct parameters", async function () {
        tokens = [weth, usdt, wbtc];
        weights = [33, 33, 34];
        id = "basket_1";
        let tx = await basketContract
          .connect(account1)
          .createBasket(tokens, weights, id);
        let receipt = await tx.wait();
        expect(receipt.events[0].args[0]).to.equal(account1.address);
        expect(receipt.events[0].args[1][2]).to.deep.equal(tokens);
      });
    });
  });

  describe("Reset Weights", function () {
    let tokens;
    let weights;
    let id;
    let weth = addresses["WETH"][0];
    let usdt = addresses["USDT"][0];
    let wbtc = addresses["WBTC"][0];
    describe("Revert scenarios", function () {
      it("should revert when basket does not exist", async function () {
        tokens = [weth, usdt, wbtc];
        weights = [33, 33, 34];
        id = "basket_1";
        id2 = "basket_2";
        await basketContract
          .connect(account1)
          .createBasket(tokens, weights, id);
        await expect(
          basketContract.connect(account1).resetWeights(id2, weights)
        ).to.be.revertedWith("basket does not exist");
      });

      it("should revert when new and old basket weights are not of equal lengths", async function () {
        tokens = [weth, usdt, wbtc];
        oldWeights = [33, 33, 34];
        newWeights = [50, 50];
        id = "basket_1";
        await basketContract
          .connect(account1)
          .createBasket(tokens, oldWeights, id);
        await expect(
          basketContract.connect(account1).resetWeights(id, newWeights)
        ).to.be.revertedWith(
          "new and old basket weights are not of equal lengths"
        );
      });

      it("should revert when new basket weights do not sum up to 100", async function () {
        tokens = [weth, usdt, wbtc];
        oldWeights = [33, 33, 34];
        newWeights = [33, 33, 33];
        id = "basket_1";
        await basketContract
          .connect(account1)
          .createBasket(tokens, oldWeights, id);
        await expect(
          basketContract.connect(account1).resetWeights(id, newWeights)
        ).to.be.revertedWith(
          "sum of weights of constituents is not equal to 100"
        );
      });
      it("should revert when non-owner tries to reset weights", async function () {
        tokens = [weth, usdt, wbtc];
        oldWeights = [33, 33, 34];
        newWeights = [33, 33, 34];
        id = "basket_1";
        await basketContract
          .connect(account1)
          .createBasket(tokens, oldWeights, id);
        await expect(
          basketContract.connect(account2).resetWeights(id, newWeights)
        ).to.be.revertedWith("only owner can modify the weights of basket");
      });
    });

    describe("Success Scenarios", function () {
      it("should have new weights assigned ", async function () {
        tokens = [weth, usdt, wbtc];
        oldWeights = [33, 33, 34];
        newWeights = [20, 20, 60];
        id = "basket_1";
        await basketContract
          .connect(account1)
          .createBasket(tokens, oldWeights, id);
        let tx = await basketContract
          .connect(account1)
          .resetWeights(id, newWeights);
        let receipt = await tx.wait();
        expect(receipt.events[0].args[1].weights[0]).to.deep.equal(
          BigNumber.from(20)
        );
      });
    });
  });

  describe("Get Basket", function () {
    let tokens;
    let weights;
    let id;
    let weth = addresses["WETH"][0];
    let usdt = addresses["USDT"][0];
    let wbtc = addresses["WBTC"][0];
    describe("Revert scenarios", function () {
      it("should revert when basket does not exist", async function () {
        tokens = [weth, usdt, wbtc];
        weights = [33, 33, 34];
        id = "basket_1";
        id2 = "basket_2";
        await basketContract
          .connect(account1)
          .createBasket(tokens, weights, id);
        await expect(
          basketContract.connect(account1).getBasketById(id2)
        ).to.be.revertedWith("basket does not exist");
      });
    });

    describe("Success scenarios", function () {
      it("should return the correct basket", async function () {
        tokens = [weth, usdt, wbtc];
        weights = [33, 33, 34];
        id = "basket_1";
        await basketContract
          .connect(account1)
          .createBasket(tokens, weights, id);

        var basket = await basketContract.connect(account1).getBasketById(id);
        expect(basket.weights[2]).to.equal(BigNumber.from(34));
        expect(basket.basketOwner).to.equal(account1.address);
      });
    });
  });

  describe("Transfer OwnerShip", function () {
    let tokens;
    let weights;
    let id;
    let weth = addresses["WETH"][0];
    let usdt = addresses["USDT"][0];
    let wbtc = addresses["WBTC"][0];
    describe("Revert scenarios", function () {
      it("should revert when basket does not exist", async function () {
        tokens = [weth, usdt, wbtc];
        weights = [33, 33, 34];
        id = "basket_1";
        id2 = "basket_2";
        await basketContract
          .connect(account1)
          .createBasket(tokens, weights, id);
        await expect(
          basketContract
            .connect(account1)
            .transferBasketOwnership(account2.address, id2)
        ).to.be.revertedWith("basket does not exist");
      });
      it("should revert when not initiated by owner does not exist", async function () {
        tokens = [weth, usdt, wbtc];
        weights = [33, 33, 34];
        id = "basket_1";
        id2 = "basket_2";
        await basketContract
          .connect(account1)
          .createBasket(tokens, weights, id);
        await expect(
          basketContract
            .connect(account2)
            .transferBasketOwnership(account2.address, id)
        ).to.be.revertedWith("you are not the owner of the basket");
      });
    });

    describe("Success Scenarios", function () {
      it("should have ownershipTransferred ", async function () {
        tokens = [weth, usdt, wbtc];
        weights = [33, 33, 34];
        id = "basket_1";
        await basketContract
          .connect(account1)
          .createBasket(tokens, weights, id);
        let tx = await basketContract
          .connect(account1)
          .transferBasketOwnership(account2.address, id);
        let receipt = await tx.wait();
        expect(receipt.events[0].args.previousOwner).to.equal(account1.address);
        expect(receipt.events[0].args.newOwner).to.equal(account2.address);
      });
    });
  });
});
