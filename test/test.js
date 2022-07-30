const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Kaching", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Kaching = await ethers.getContractFactory("Kaching");
    const kaching = await Kaching.deploy();
    await kaching.deployed();

    for (let x = 0; x < 100000000000; x++) {
      console.log(await kaching.createUsdcSubscription("rr", 1, 100000000));
    }

    console.log(await kaching.getOptions());
  });
}); 
