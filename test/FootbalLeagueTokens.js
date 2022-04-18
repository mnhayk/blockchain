const chai = require("chai")
chai.use(require("chai-as-promised"))

const expect = chai.expect

const FootballLeagueTokens = artifacts.require("FootballLeagueTokens")

contract("FootballLeagueTokens", accounts => {
    const users = [accounts[0], accounts[1], accounts[2]]

    let wallet

    beforeEach(async () => {
        wallet = await FootballLeagueTokens.new("")
    })

    it("should fail: amount is zero", async () => {
        tokenId = 0
        amount = 0
        cryptocurrency = 'ether'
        price = '0.001'

        await expect(wallet.mintByETH(tokenId, amount, {from: users[0], value: web3.utils.toWei(price, cryptocurrency)})).to.be.rejected
    })

    it("should fail: less money (less price)", async () => {
        tokenId = 0
        amount = 1
        cryptocurrency = 'ether'
        price = '0.001'

        await expect(wallet.mintByETH(tokenId, amount, {from: users[0], value: web3.utils.toWei(price, cryptocurrency)})).to.be.rejected
    })

    it("should fail: less money (less amount)", async () => {
        tokenId = 0
        amount = 2
        cryptocurrency = 'ether'
        price = '0.01'

        await expect(wallet.mintByETH(tokenId, amount, {from: users[0], value: web3.utils.toWei(price, cryptocurrency)})).to.be.rejected
    })

    it("should fail: tokenId doesn't exist", async () => {
        tokenId = 10
        amount = 1
        cryptocurrency = 'ether'
        price = '0.01'

        await expect(wallet.mintByETH(tokenId, amount, {from: users[0], value: web3.utils.toWei(price, cryptocurrency)})).to.be.rejected
    })

    it("should success: max token amount can be 1000", async () => {
        tokenId = 0
        amount = 1000
        cryptocurrency = 'ether'
        price = '10'

        await expect(wallet.mintByETH(tokenId, amount, {from: users[0], value: web3.utils.toWei(price, cryptocurrency)})).to.be.satisfy
    })

    it("should fail: max token amount can't be more from 1000", async () => {
        tokenId = 0
        amount = 1001
        cryptocurrency = 'ether'
        price = '10.1'

        await expect(wallet.mintByETH(tokenId, amount, {from: users[0], value: web3.utils.toWei(price, cryptocurrency)})).to.be.rejected
    })

    it("Should succeed: two users", async () => {
        amount = 1000
        cryptocurrency = 'ether'
        price = '10'

        await wallet.mintByETH(0, amount, {from: users[0], value: web3.utils.toWei(price, cryptocurrency)})
        assert(await wallet.balanceOf(users[0], 0) == amount)

        await wallet.mintByETH(2, amount, {from: users[2], value: web3.utils.toWei(price, cryptocurrency)})
        assert(await wallet.balanceOf(users[2], 2) == amount)
    })
})