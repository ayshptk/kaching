const { expect } = require("chai");
const { ethers } = require("hardhat");
async function init() {
  const Kaching = await ethers.getContractFactory("Kaching");
  const kaching = await Kaching.deploy(
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
  );
  await kaching.deployed();
  return kaching;
}

async function deployTestToken(kaching) {
  const Token = await ethers.getContractFactory("TestToken");
  const token = await Token.deploy(
    "TEST",
    "TEST",
    ethers.utils.parseEther("1000000")
  );
  await token.deployed();
  return token;
}

async function getOption(kaching) {
  const option = await kaching.getAllOptions();
  return option[0];
}
async function getSub(kaching) {
  const option = await kaching.getAllSubscriptions();
  return option[0];
}

async function createTestOption(kaching) {
  const user = ethers.Wallet.createRandom();
  const token = await deployTestToken(kaching);
  const Kaching = await init();
  const tx = await Kaching.createTokenSubscriptionToAddress(
    "test",
    ethers.utils.parseEther("1"),
    60 * 60 * 24 * 30,
    token.address,
    user.address
  );

  const option = await getOption(Kaching);
  return {
    token,
    user,
    Kaching,
    option,
  };
}

describe("Initialise", function () {
  it("should deploy properly", async function () {
    await init();
  });
});

describe("Creator", function () {
  it("should use default setting", async function () {
    const Kaching = await init();
    const tx = await Kaching.createSubscription(
      "test",
      ethers.utils.parseEther("1"),
      60 * 60 * 24 * 30
    );

    const option = await getOption(Kaching);
    expect(option.price).to.equal(ethers.utils.parseEther("1"));
    expect(option.interval).to.equal(ethers.BigNumber.from(60 * 60 * 24 * 30));
  });

  it("should use default settings", async function () {
    const Kaching = await init();
    const test = ethers.Wallet.createRandom();
    const tx = await Kaching.createSubscriptionToAddress(
      "test",
      ethers.utils.parseEther("1"),
      60 * 60 * 24 * 30,
      test.address
    );

    const option = await getOption(Kaching);
    expect(option.owner).to.equal(test.address);
  });

  it("should use different token", async function () {
    const Kaching = await init();
    const tx = await Kaching.createTokenSubscription(
      "test",
      ethers.utils.parseEther("1"),
      60 * 60 * 24 * 30,
      "0x6B175474E89094C44Da98b954EedeAC495271d0F"
    );

    const option = await getOption(Kaching);
    expect(option.token).to.equal("0x6B175474E89094C44Da98b954EedeAC495271d0F");
  });

  it("should use different token and different owner", async function () {
    const Kaching = await init();
    const test = ethers.Wallet.createRandom();
    const tx = await Kaching.createTokenSubscriptionToAddress(
      "test",
      ethers.utils.parseEther("1"),
      60 * 60 * 24 * 30,
      "0x6B175474E89094C44Da98b954EedeAC495271d0F",
      test.address
    );

    const option = await getOption(Kaching);
    expect(option.token).to.equal("0x6B175474E89094C44Da98b954EedeAC495271d0F");
  });
});

describe("Subscriber", function () {
  it("should be able to subscribe", async function () {
    const { token, user, Kaching, option } = await createTestOption();
    await token.approve(Kaching.address, ethers.utils.parseEther("1"));
    const tx = await Kaching.subscribe(option.id);
    const balance = await token.balanceOf(user.address);
    expect(balance).to.equal(ethers.utils.parseEther("1"));
  });
  it("should be able to unsubscribe", async function () {
    const { token, user, Kaching, option } = await createTestOption();
    await token.approve(Kaching.address, ethers.utils.parseEther("1"));
    await Kaching.subscribe(option.id);
    const sub = await getSub(Kaching);
    await Kaching.unsubscribe(sub.id);
  });

  it("should assign ID properly", async function () {
    const { token, user, Kaching } = await createTestOption();
    const tx = await Kaching.createTokenSubscriptionToAddress(
      "test",
      ethers.utils.parseEther("1"),
      60 * 60 * 24 * 30,
      token.address,
      user.address
    );
    await token.approve(Kaching.address, ethers.utils.parseEther("1"));
    await Kaching.subscribe(1);
    const sub = await getSub(Kaching);
    expect(sub.optionId.toNumber()).to.equal(1);
    expect(sub.id.toNumber()).to.equal(0);
  });
});
