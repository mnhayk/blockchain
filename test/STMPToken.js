const STMPToken = artifacts.require("STMPToken")

const { expectRevert, expectEvent, constants } = require('@openzeppelin/test-helpers');
const ether = require('@openzeppelin/test-helpers/src/ether');
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
        it('should be minted correct amount of tokens', async function () {
            const amount = await token.tokenAmount()
            const balance = await token.balanceOf(treasuryAddress)
            assert.equal(amount.toString(), balance.toString())
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
        it('should succeed if numberOfTokens is minimum 1', async function () {
            const buyer = accounts[1]
            const numberOfTokens = 1
            await token.approve(owner, numberOfTokens, { from: treasuryAddress })
            await token.distributePresaleTokens(buyer, numberOfTokens, { from: owner })

            const balance = await token.balanceOf(buyer)
            assert.equal(numberOfTokens.toString(), balance.toString())
        })

        it('should succeed if numberOfTokens is limitPresale', async function () {
            const buyer = accounts[1]
            const numberOfTokens = limitPresale
            await token.approve(owner, numberOfTokens, { from: treasuryAddress })
            await token.distributePresaleTokens(buyer, numberOfTokens, { from: owner })

            const balance = await token.balanceOf(buyer)
            assert.equal(numberOfTokens.toString(), balance.toString())
        })

        it('should sum distributed number of tokens', async function () {
            const buyerOne = accounts[1]
            const buyerOneNumberOfTokens = toBN(web3.utils.toWei('1', 'ether'))
            await token.approve(owner, buyerOneNumberOfTokens, { from: treasuryAddress })
            await token.distributePresaleTokens(buyerOne, buyerOneNumberOfTokens, { from: owner })

            const buyerTwo = accounts[4]
            const buyerTwoNumberOfTokens =toBN( web3.utils.toWei('1', 'ether'))
            await token.approve(owner, buyerTwoNumberOfTokens, { from: treasuryAddress })
            await token.distributePresaleTokens(buyerTwo, buyerTwoNumberOfTokens, { from: owner })

            const totalNumberOfTokens = buyerOneNumberOfTokens.add(buyerTwoNumberOfTokens)
            const distributedNumberOfTokens = await token.tokensDistributedPresale()

            assert.equal(totalNumberOfTokens.toString(), distributedNumberOfTokens.toString())
        })

        it('should revert in case of not owner', async function () {
            const buyer = accounts[3]
            const notOwner = accounts[1]
            const numberOfTokens = 1e6
            await token.approve(owner, numberOfTokens, { from: treasuryAddress })
            await expectRevert(
                token.distributePresaleTokens(buyer, numberOfTokens, { from: notOwner }),
                'Ownable: caller is not the owner'
            );
        })

        it('should revert in case of buyer is Zero', async function () {
            const buyer = constants.ZERO_ADDRESS
            const numberOfTokens = 1e6
            await token.approve(owner, numberOfTokens, { from: treasuryAddress })
            await expectRevert(
                token.distributePresaleTokens(buyer, numberOfTokens, { from: owner }),
                'Buyer address is zero'
            );
        })

        it('should revert if numberOfTokens is 0', async function () {
            const buyer = accounts[1]
            const numberOfTokens = 0
            await token.approve(owner, numberOfTokens, { from: treasuryAddress })
            await expectRevert(
                token.distributePresaleTokens(buyer, numberOfTokens, { from: owner }),
                'Out of token limit'
            );
        })

        it('should revert if numberOfTokens is bigger than limitPresale', async function () {
            const buyer = accounts[1]
            const numberOfTokens = toBN(limitPresale).add(toBN(1))
            await token.approve(owner, numberOfTokens, { from: treasuryAddress })
            await expectRevert(
                token.distributePresaleTokens(buyer, numberOfTokens, { from: owner }),
                'Out of token limit'
            );
        })

        it('should revert if distributed number of tokens is bigger than limitPresale', async function () {
            const buyerOne = accounts[1]
            const buyerOneNumberOfTokens = limitPresale
            await token.approve(owner, buyerOneNumberOfTokens, { from: treasuryAddress })
            await token.distributePresaleTokens(buyerOne, buyerOneNumberOfTokens, { from: owner })

            const buyerTwo = accounts[4]
            const buyerTwoNumberOfTokens = toBN(1)
            await token.approve(owner, buyerTwoNumberOfTokens, { from: treasuryAddress })
            await expectRevert(
                token.distributePresaleTokens(buyerTwo, buyerTwoNumberOfTokens, { from: owner }),
                'Existing token amount exceeded'
            );
        })
    })

    describe('test pause() logic', async () => {
        it('should success if owner called pause()', async function () {
            // We should unpause() it first as token is pauased inside the constructor
            await token.unpause({ from: owner })

            await token.pause({ from: owner })
            const isPaused = await token.paused()
            assert.equal(isPaused, true)
        })

        it('should success if owner called unpause()', async function () {
            // We can call unpause() as token is pauased inside the constructor
            await token.unpause({ from: owner })

            const isPaused = await token.paused()
            assert.equal(isPaused, false)
        })

        it('should fail if not owner called pause()', async function () {
            // We should unpause() it first as token is pauased inside the constructor
            await token.unpause({ from: owner })

            const notOwner = accounts[1]
            await expectRevert(
                token.pause({ from: notOwner }),
                'Ownable: caller is not the owner'
            );
        })

        it('should fail if not owner called unpause()', async function () {
            const notOwner = accounts[1]
            // We can try to unpause() it as token is pauased inside the constructor
            await expectRevert(
                token.unpause({ from: notOwner }),
                'Ownable: caller is not the owner'
            );
        })
    })
})


