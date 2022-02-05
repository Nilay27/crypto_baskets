const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  const SampleContract = await hre.ethers.getContractFactory("Subscribe");
  const sampleContract = await SampleContract.deploy();

  await sampleContract.deployed();
  console.log("Sample Contract address:", sampleContract.address);

  saveFrontendFiles(sampleContract);
}

function saveFrontendFiles(contract) {
  const fs = require("fs");
  const contractsDir = __dirname + "/../src/abis";

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    contractsDir + "/contract-address.json",
    JSON.stringify({ SampleContract: contract.address }, undefined, 2)
  );

  const SampleContractArtifact = artifacts.readArtifactSync("Subscribe");

  fs.writeFileSync(
    contractsDir + "/Subscribe.json",
    JSON.stringify(SampleContractArtifact, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.log(error);
    process.exit(1);
  });

// const hre = require("hardhat");

// //Sample Contract address: 0x78E29d767FDA445700AF2519507155b78d5812d8
// //Sample Contract address: 0xA315B98D798499abc3627dd451Ffb34DA2686073

// async function main() {
//   const [deployer] = await hre.ethers.getSigners();

//   const SampleContract = await hre.ethers.getContractFactory("Baskets");
//   const sampleContract = await SampleContract.deploy();
//   const SampleContract1 = await hre.ethers.getContractFactory("Subscribe");
//   const sampleContract1 = await SampleContract.deploy();

//   await sampleContract.deployed();
//   await sampleContract1.deployed();

//   console.log("Sample Contract address:", sampleContract.address);
//   console.log("Sample Contract address:", sampleContract1.address);

//   saveFrontendFiles(sampleContract);
//   saveFrontendFiles(sampleContract1);
// }

// function saveFrontendFiles(contract) {
//   const fs = require("fs");
//   const contractsDir = __dirname + "/../src/abis";

//   if (!fs.existsSync(contractsDir)) {
//     fs.mkdirSync(contractsDir);
//   }

//   fs.writeFileSync(
//     contractsDir + "/contract-address.json",
//     JSON.stringify({ SampleContract: contract.address }, undefined, 2)
//   );

//   const SampleContractArtifact = artifacts.readArtifactSync("Baskets");

//   fs.writeFileSync(
//     contractsDir + "/Baskets.json",
//     JSON.stringify(SampleContractArtifact, null, 2)
//   );

//   fs.writeFileSync(
//     contractsDir + "/contract-address1.json",
//     JSON.stringify({ SampleContract1: contract.address }, undefined, 2)
//   );

//   const SampleContractArtifact1 = artifacts.readArtifactSync("Subscribe");

//   fs.writeFileSync(
//     contractsDir + "/Baskets.json",
//     JSON.stringify(SampleContractArtifact1, null, 2)
//   );
// }

// main()
//   .then(() => process.exit(0))
//   .catch((error) => {
//     console.log(error);
//     process.exit(1);
//   });
