const FootballLeagueTokens = artifacts.require("FootballLeagueTokens");
module.exports = function(deployer) {
  let maxTokenId = process.env.maxTokenId
  let maxAmountOfEachToken = process.env.maxAmountOfEachToken
  let tokenPriceByEthereum = process.env.tokenPriceByEthereum
  let tokenPriceByUSDC = process.env.tokenPriceByUSDC
  let USDCTokenAddress = process.env.USDCTokenAddress
  let metadataURI = process.env.metadataURI
  deployer.deploy(FootballLeagueTokens, maxTokenId, maxAmountOfEachToken, tokenPriceByEthereum, tokenPriceByUSDC, USDCTokenAddress, metadataURI);
};