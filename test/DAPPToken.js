const BigNumber = web3.BigNumber;

const DappToken = artifacts.require('DappToken');

require('chai')
  .use(require('chai-bignumber')(BigNumber))
  .should();

const toBN = web3.utils.toBN;

contract.skip('DappToken', accounts => {
  const _name = 'Dapp Token';
  const _symbol = 'DAPP';
  const _decimals = 12;

  beforeEach(async function () {
    this.token = await DappToken.new(_name, _symbol, _decimals);
  });

  describe('token attributes', function() {
    it('has the correct name', async function() {
      const name = await this.token.name();
      name.should.equal(_name);
    });

    it('has the correct symbol', async function() {
      const symbol = await this.token.symbol();
      symbol.should.equal(_symbol);
    });

    //TODO: should be fixed
    it('has the correct decimals', async function() {
        const decimals = await this.token.decimals();
        decimals.should.be.bignumber.equal(toBN(_decimals));
      });
  });
});