var MultisigNFT = artifacts.require("MultisigNFT");

module.exports = async function(deployer) {
  await deployer.deploy(MultisigNFT);
  const instance = await MultisigNFT.deployed();
};