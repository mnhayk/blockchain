const FootballLeagueTokens = artifacts.require("FootballLeagueTokens");
const USDCMock = artifacts.require("USDCMock");

module.exports = function(deployer, network) {
  let maxTokenId = process.env.MAX_TOKEN_ID
  let maxAmountOfEachToken = process.env.MAX_AMOUNT_OF_EACH_TOKEN
  let tokenPriceByWei = process.env.TOKEN_PRICE_BY_WEI
  let tokenPriceByPaymentToken = process.env.TOKEN_PRICE_BY_PAYMENT_TOKEN
  let metadataURI = process.env.METADATA_URI

  if (network == "live") {
    let paymentTokenAddress = process.env.PAYMENT_TOKEN_ADDRESS 
    deployer.deploy(FootballLeagueTokens, maxTokenId, maxAmountOfEachToken, tokenPriceByWei, tokenPriceByPaymentToken, paymentTokenAddress, metadataURI);
  } else {
    deployer.deploy(USDCMock).then(function(){
      return deployer.deploy(FootballLeagueTokens, maxTokenId, maxAmountOfEachToken, tokenPriceByWei, tokenPriceByPaymentToken, USDCMock.address, metadataURI);
    });
  }
}