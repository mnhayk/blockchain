const FootballLeagueTokens = artifacts.require("FootballLeagueTokens");
const USDCMock = artifacts.require("USDCMock");

module.exports = async function(deployer, network) {
  const maxTokenId = process.env.MAX_TOKEN_ID
  const maxAmountOfEachToken = process.env.MAX_AMOUNT_OF_EACH_TOKEN
  const tokenPriceByWei = process.env.TOKEN_PRICE_BY_WEI
  const tokenPriceByPaymentToken = process.env.TOKEN_PRICE_BY_PAYMENT_TOKEN
  const metadataURI = process.env.METADATA_URI

  if (network == "live") {
    const paymentTokenAddress = process.env.PAYMENT_TOKEN_ADDRESS 
    await deployer.deploy(FootballLeagueTokens, maxTokenId, maxAmountOfEachToken, tokenPriceByWei, tokenPriceByPaymentToken, paymentTokenAddress, metadataURI);
  } else {
    await deployer.deploy(USDCMock)
    await deployer.deploy(FootballLeagueTokens, maxTokenId, maxAmountOfEachToken, tokenPriceByWei, tokenPriceByPaymentToken, USDCMock.address, metadataURI);
  }
}