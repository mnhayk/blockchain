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

    it("should fail for enough amount less money", async () => {
        tokenId = 0
        amount = 1
        cryptocurrency = 'ether'
        price = '0.001'

        await expect(wallet.mintETH(tokenId, amount, {from: users[0], value: web3.utils.toWei(price, cryptocurrency)})).to.be.rejected
    })

    it("should fail for less amount enough money", async () => {
        tokenId = 0
        amount = 2
        cryptocurrency = 'ether'
        price = '0.01'

        await expect(wallet.mintETH(tokenId, amount, {from: users[0], value: web3.utils.toWei(price, cryptocurrency)})).to.be.rejected
    })

    it("should fail tokenId should be smaller 10", async () => {
        tokenId = 10
        amount = 1
        cryptocurrency = 'ether'
        price = '0.01'

        await expect(wallet.mintETH(tokenId, amount, {from: users[0], value: web3.utils.toWei(price, cryptocurrency)})).to.be.rejected
    })

    it("should success max token amount for one user can be till 1000", async () => {
        tokenId = 0
        amount = 1000
        cryptocurrency = 'ether'
        price = '10'

        await expect(wallet.mintETH(tokenId, amount, {from: users[0], value: web3.utils.toWei(price, cryptocurrency)})).to.be.satisfy
    })

    it("should fail max token amount for one user can be till 1000", async () => {
        tokenId = 0
        amount = 1001
        cryptocurrency = 'ether'
        price = '10.1'

        await expect(wallet.mintETH(tokenId, amount, {from: users[0], value: web3.utils.toWei(price, cryptocurrency)})).to.be.rejected
    })

    it("Minting should succeed", async () => {
        amount = 1000
        cryptocurrency = 'ether'
        price = '10'

        await wallet.mintETH(0, amount, {from: users[0], value: web3.utils.toWei(price, cryptocurrency)})
        assert(await wallet.balanceOf(users[0], 0) == amount)

        await wallet.mintETH(2, amount, {from: users[2], value: web3.utils.toWei(price, cryptocurrency)})
        assert(await wallet.balanceOf(users[2], 2) == amount)
    })
})