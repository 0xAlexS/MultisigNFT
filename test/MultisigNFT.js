const MultisigNFT = artifacts.require("MultisigNFT");

contract("MultisigNFT", () => {
  it("should mint a new nft", async () => {
    const msnft = await MultisigNFT.new();
    await msnft.mint(["0x89f5232e2510e594296c579e1fee9bc24ef362bc", "0x781c1c56a909d903436e8b9f3d5a5596de211778"], 2);
  });
  
  it("should make a proposal", async () => {
    const msnft = await MultisigNFT.new();
    await msnft.mint(["0x89f5232e2510e594296c579e1fee9bc24ef362bc", "0x781c1c56a909d903436e8b9f3d5a5596de211778"], 2);
    await msnft.propose(1, 1);
  });

  it("should cast a vote on a proposal", async () => {
    const msnft = await MultisigNFT.new();
    await msnft.mint(["0x89f5232e2510e594296c579e1fee9bc24ef362bc", "0x781c1c56a909d903436e8b9f3d5a5596de211778"], 1);
    await msnft.propose(1, 1);
    await msnft.vote(1, true);
  });
});