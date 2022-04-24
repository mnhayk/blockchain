const FootballLeagueTokens = artifacts.require("FootballLeagueTokens");
const USDCMock = artifacts.require("USDCMock");

module.exports = function(deployer) {
  let maxTokenId = process.env.maxTokenId
  let maxAmountOfEachToken = process.env.maxAmountOfEachToken
  let tokenPriceByWei = process.env.tokenPriceByEth
  let tokenPriceByUSDC = process.env.tokenPriceByUSDC
  // Uncomment for production version
  let USDCTokenAddress = process.env.USDCTokenAddress 
  let metadataURI = process.env.metadataURI

  // Comment for production version
  deployer.deploy(USDCMock).then(function(){
    return deployer.deploy(FootballLeagueTokens, maxTokenId, maxAmountOfEachToken, tokenPriceByWei, tokenPriceByUSDC, USDCMock.address, metadataURI);
  });

  // Uncomment for production version
  // deployer.deploy(FootballLeagueTokens, maxTokenId, maxAmountOfEachToken, tokenPriceByWei, tokenPriceByUSDC, USDCTokenAddress, metadataURI);
};
