const FootballTokens = artifacts.require("FootballTokens")
const USDCMock = artifacts.require("USDCMock")

const { expectRevert, expectEvent, constants } = require('@openzeppelin/test-helpers');
const { inTransaction } = require('@openzeppelin/test-helpers/src/expectEvent');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');
const { assert, expect } = require('chai');

const toBN = web3.utils.toBN;

contract("FootballTokens", accounts => {

    let maxTokenId = 9
    let maxAmountOfEachToken = 1000
    let tokenPriceByWei = 1e16  //0.01 eth
    let tokenPriceByPaymentToken = 30e18 //30 usdc
    let metadataURI = "MockURI"

    let owner = accounts[0]

    let deployed
    let usdcMock

    beforeEach(async () => {
        usdcMock = await USDCMock.new()
        deployed = await FootballTokens.new(maxTokenId,
            maxAmountOfEachToken,
            tokenPriceByWei.toString(),
            tokenPriceByPaymentToken.toString(),
            usdcMock.address,
            metadataURI, { from: owner })
    })

    describe('mintByETH', async () => {

        it("should success with correct token id", async () => {
            let firstUser = accounts[1]
            await deployed.mintByETH(maxTokenId, 1, { from: firstUser, value: tokenPriceByWei })

            let balanceOfFirstUser = await deployed.balanceOf(firstUser, maxTokenId);
            assert.equal(balanceOfFirstUser.toString(), '1');

            let secondUser = accounts[2]
            await deployed.mintByETH(maxTokenId, 10, { from: secondUser, value: tokenPriceByWei * 10 })

            let balanceOfSecondUser = await deployed.balanceOf(secondUser, maxTokenId);
            assert.equal(balanceOfSecondUser.toString(), '10');

            let totalSupply = await deployed.totalSupply(maxTokenId)
            assert.equal(totalSupply.toString(), '11')
        })

        it("should succeed for 1000 tokens for same tokenId", async () => {
            let tokenId = 0

            await deployed.mintByETH(tokenId, 500, { from: accounts[3], value: tokenPriceByWei * 500 })
            await deployed.mintByETH(tokenId, 500, { from: accounts[4], value: tokenPriceByWei * 500 })

            let totalSupply = await deployed.totalSupply(tokenId)
            assert.equal(totalSupply.toString(), '1000')
        })

        it("should succeed for 2000 tokens for different tokenId", async () => {

            await deployed.mintByETH(0, 1000, { from: accounts[5], value: tokenPriceByWei * 1000 })
            await deployed.mintByETH(1, 1000, { from: accounts[6], value: tokenPriceByWei * 1000 })

            let totalSuppliedForTokenId0 = await deployed.totalSupply(0)
            let totalSuppliedForTokenId1 = await deployed.totalSupply(1)

            assert.equal(totalSuppliedForTokenId0.toString(), '1000')
            assert.equal(totalSuppliedForTokenId1.toString(), '1000')
        })

        it("should failed for 1001 tokens for same tokenId", async () => {
            let tokenId = 0

            await deployed.mintByETH(tokenId, 500, { from: accounts[3], value: tokenPriceByWei * 500 })
            await deployed.mintByETH(tokenId, 500, { from: accounts[4], value: tokenPriceByWei * 500 })
            await expectRevert(
                deployed.mintByETH(tokenId, 1, { from: accounts[5], value: tokenPriceByWei }),
                'Max supply is exceeded'
            )
        })

        it("should faill with incorrect token id", async () => {
            await expectRevert(
                deployed.mintByETH(maxTokenId + 1, 1, { from: accounts[1], value: tokenPriceByWei }),
                'Incorrect tokenId'    
            );
        })

        it("should faill not enough ether", async () => {
            await expectRevert(
                deployed.mintByETH(0, 1, { from: accounts[2], value: 1e15 }),
                'Not enough ether'    
            );
        })
    });

    describe('mintByPaymentToken', async () => {
        it("should success with correct token id and usdcAmount", async () => {
            let user = accounts[3]
            let usdcAmount = toBN(900e18) //900 usdc

            await usdcMock.mint(usdcAmount, { from: user })
            await usdcMock.approve(deployed.address, usdcAmount, { from : user })
            await deployed.mintByPaymentToken(maxTokenId, 30, { from : user })

            balanceOfUser = await usdcMock.balanceOf(user)
            assert.equal(balanceOfUser.toString(), '0')

            var balanceOfContract = await usdcMock.balanceOf(deployed.address)
            assert.equal(balanceOfContract.toString(), 900e18.toString())


            let balanceOfMintedTokens = await deployed.balanceOf(user, maxTokenId);
            assert.equal(balanceOfMintedTokens.toString(), '30');
        })

        it("should faill with incorrect token id", async () => {
            let user = accounts[1]
            let usdcAmount = toBN(900e18) //900 usdc

            await usdcMock.mint(usdcAmount, { from: user })
            await usdcMock.approve(deployed.address, usdcAmount, { from : user })

            await expectRevert(
                deployed.mintByPaymentToken(maxTokenId + 1, 30, { from: user }),
                'Incorrect tokenId'    
            );
        })

        it("should faill because of max supply is exceeded", async () => {
            let tokenId = 0

            await deployed.mintByETH(tokenId, 500, { from: accounts[3], value: tokenPriceByWei * 500 })
            await deployed.mintByETH(tokenId, 500, { from: accounts[4], value: tokenPriceByWei * 500 })

            let user = accounts[1]
            let usdcAmount = toBN(900e18) //900 usdc

            await usdcMock.mint(usdcAmount, { from: user })
            await usdcMock.approve(deployed.address, usdcAmount, { from : user })

            await expectRevert(
                deployed.mintByPaymentToken(tokenId, 1, { from: user }),
                'Max supply is exceeded'    
            );
        })
    });

    // describe('withdrawETH', async () => {
    // });

    describe('withdrawPaymentToken', async () => {
        it("should succeed to withdraw usdc", async () => {

            let user = accounts[1]
            let usdcAmount = toBN(900e18) //900 usdc

            await usdcMock.mint(usdcAmount, { from: user })
            await usdcMock.approve(deployed.address, usdcAmount, { from: user })

            await deployed.mintByPaymentToken(maxTokenId, 30, { from: user })

            var balanceOfContract = await usdcMock.balanceOf(deployed.address)
            assert.equal(balanceOfContract.toString(), 900e18.toString())

            await deployed.withdrawPaymentToken(usdcMock.address, usdcAmount, { from: owner })

            var balanceOfContractAfter = await usdcMock.balanceOf(deployed.address)
            assert.equal(balanceOfContractAfter.toString(), '0')

            var balanceOfOwner = await usdcMock.balanceOf(owner)
            assert.equal(balanceOfOwner.toString(), usdcAmount.toString())

        })

        it("should fail for not owner to withdraw usdc", async () => {

            let user = accounts[1]
            let usdcAmount = toBN(900e18) //900 usdc

            await usdcMock.mint(usdcAmount, { from: user })
            await usdcMock.approve(deployed.address, usdcAmount, { from: user })
            await deployed.mintByPaymentToken(maxTokenId, 30, { from: user })

            expectRevert( 
                deployed.withdrawPaymentToken(usdcMock.address, usdcAmount, { from: user }),
                'caller is not the owner'
            )
        })
    });
})