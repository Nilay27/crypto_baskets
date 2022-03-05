const web3 = require("web3");
const { expect } = require("chai");

describe("Swap", () => {
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
    contractFactory = await ethers.getContractFactory("Subscribe");
    swapContract = await contractFactory.deploy();
    await swapContract.deployed();
  });
  describe("Test UniSwapV3 ", () => {
    it("Should revert if ETH provided is 0", async () => {
      const [account] = await ethers.getSigners();
      const ethToSpend = ethers.utils.parseEther("0");
      let tokens;
      let weights;
      let id;
      let usdt = addresses["USDT"][0];
      let wbtc = addresses["WBTC"][0];
      tokens = [usdt, wbtc];
      weights = [50, 50];
      id = "basket_1";
      const basketTx = await swapContract
        .connect(account1)
        .createBasket(tokens, weights, id);
      let receipt = await basketTx.wait();
      expect(receipt.events[0].args[0]).to.equal(account1.address);
      expect(receipt.events[0].args[1][2]).to.deep.equal(tokens);
      let balanceBeforeSwap = await ethers.provider.getBalance(account.address);
      await expect(
        swapContract
          .connect(account1)
          .deposit(id, addresses["ETH"][0], ethToSpend, { value: ethToSpend })
      ).to.be.revertedWith("amount has to be positive");
    });
  });
});
