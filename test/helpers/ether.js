const toBN = web3.utils.toBN

module.exports = function ether(n) {
  return new toBN(web3.utils.toWei(String(n), 'ether'));
}