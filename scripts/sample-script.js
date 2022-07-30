
const hre = require("hardhat");

async function main() {
  const Kaching = await hre.ethers.getContractFactory("Kaching");
  
  const kaching = await Kaching.deploy();
  await kaching.deployed();
  console.log("Kaching deployed to:", kaching.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
