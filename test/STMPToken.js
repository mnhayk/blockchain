const STMPToken = artifacts.require("STMPToken")

const { expectRevert, expectEvent, constants } = require('@openzeppelin/test-helpers')
const { web3 } = require('@openzeppelin/test-helpers/src/setup')
const { assert } = require('chai')

const toBN = web3.utils.toBN;

contract("STMPToken", accounts => {

    const owner = accounts[0]
    const tokenName = "STMP Token"
    const tokenSymbol = "STMP"
    const tokenAmount = web3.utils.toWei('1000000000', 'ether')
    const tokensDistributedPresale = 0
    const limitPresale = web3.utils.toWei('3000000', 'ether')
    const crowdsaleAddress = constants.ZERO_ADDRESS
    const treasuryAddress = accounts[5]

    let token

    beforeEach(async () => {
        token = await STMPToken.new(
            tokenName,
            tokenSymbol,
            treasuryAddress, { from: owner })
    })

    describe('token attributes', async () => {
        it('has the correct name', async function () {
            const name = await token.name()
            assert.equal(name, tokenName)
        })

        it('has the correct symbol', async function () {
            const symbol = await token.symbol()
            assert.equal(symbol, tokenSymbol)
        })

        it('has the correct treasury address', async function () {
            const treasury = await token.treasuryAddress()
            assert.equal(treasuryAddress, treasury)
        })

        it('has the correct token amount', async function () {
            const amount = await token.tokenAmount()
            assert.equal(tokenAmount.toString(), amount.toString())
        })

        it('has the correct token distributed presale value', async function () {
            assert.equal(tokensDistributedPresale, await token.tokensDistributedPresale())
        })

        it('has the correct token presale amount', async function () {
            assert.equal(limitPresale, await token.limitPresale())
        })

        it('has the correct token crowdsale address', async function () {
            assert.equal(crowdsaleAddress, await token.crowdsaleAddress())
        })

        it('has the correct treasury address', async function () {
            assert.equal(treasuryAddress, await token.treasuryAddress())
        })
    })

    describe('constructor logic', async () => {
        //TODO: Should be fixed
        it.skip('should be minted correct amount of tokens', async function () {
            expectEvent(token, 'Transfer', {
                from: constants.ZERO_ADDRESS,
                to: treasuryAddress,
                amount: toBN(tokenAmount)
            })
        })

        it('should be token puased', async function () {
            assert.equal(true, await token.paused())
        })
    })

    describe('setting Crowdsale address logic', async () => {
        it('should revert in case of ZERO address', async function () {
            const crowdsale = constants.ZERO_ADDRESS
            await expectRevert(
                token.setCrowdsaleAddress(crowdsale, { from: owner }),
                'Crowdsale address is zero'
            );
        })

        it('should set correct crowdsale if owner', async function () {
            const crowdsale = accounts[2]
            await token.setCrowdsaleAddress(crowdsale, { from: owner })
            assert.equal(crowdsale, await token.crowdsaleAddress())
        })

        it('should not set if no owner with correct crowdsale address', async function () {
            const notOwner = accounts[1]
            const crowdsale = accounts[2]
            await expectRevert(
                token.setCrowdsaleAddress(crowdsale, { from: notOwner }),
                'Ownable: caller is not the owner'
            );
        })
    })

    describe('check distribution of Presale Tokens work', async () => {
        it('should revert in case of not owner', async function () {
            const buyer = accounts[3]
            const notOwner = accounts[1]
            const numberOfTokens = 1e6
            await expectRevert(
                token.distributePresaleTokens(buyer, numberOfTokens, { from: notOwner }),
                'Ownable: caller is not the owner'
            );
        })

        it('should revert in case of buyer is Zero', async function () {
            const buyer = constants.ZERO_ADDRESS
            const numberOfTokens = 1e6
            await expectRevert(
                token.distributePresaleTokens(buyer, numberOfTokens, { from: owner }),
                'Buyer address is zero'
            );
        })

        it('should revert if numberOfTokens is 0', async function () {
            const buyer = accounts[1]
            const numberOfTokens = 0
            await expectRevert(
                token.distributePresaleTokens(buyer, numberOfTokens, { from: owner }),
                'Out of token limit'
            );
        })

        it('should revert if numberOfTokens is bigger than limitPresale', async function () {
            const buyer = accounts[1]
            const numberOfTokens = toBN(limitPresale).add(toBN(1))
            await expectRevert(
                token.distributePresaleTokens(buyer, numberOfTokens, { from: owner }),
                'Out of token limit'
            );
        })

        //TODO: should be fixed
        it.skip('should succeed if numberOfTokens is minimum 1e18', async function () {
            const buyer = accounts[1]
            const numberOfTokens = web3.utils.toWei('1', 'ether')

            await token.approve(token.address, numberOfTokens, { from: treasuryAddress })

            const balance = await token.balanceOf(treasuryAddress)
            const allowance = await token.allowance(treasuryAddress, token.address)
            
            console.log(">>>>balance: ", balance.toString())
            console.log(">>>>allowance: ", allowance.toString())

            const receiptOne = await token.distributePresaleTokens(buyer, numberOfTokens, { from: owner })
        })
    })
})