import { Wallet } from "zksync-web3";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

export default async function (hre: HardhatRuntimeEnvironment) {
  // Initialize the wallet.
  const wallet = new Wallet(require("../keys.json").zkSyncDeployerWallet);

  // Create deployer object and load the artifact of the contract we want to deploy.
  const deployer = new Deployer(hre, wallet);

  console.log("Deploying NFTLendingController...");	
  let artifactNFTLendingController = await deployer.loadArtifact("NFTLendingController");  
  let nftLendingController = await deployer.deploy(artifactNFTLendingController, []);
  console.log(`${artifactNFTLendingController.contractName} was deployed to ${nftLendingController.address}`);
}
