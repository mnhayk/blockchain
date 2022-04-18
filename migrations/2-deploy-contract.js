var FootballLeagueTokens = artifacts.require("FootballLeagueTokens");
module.exports = function(deployer) {
  deployer.deploy(FootballLeagueTokens, "");
};