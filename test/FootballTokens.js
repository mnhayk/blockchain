const FootballTokens = artifacts.require("FootballTokens")
const USDCMock = artifacts.require("USDCMock")

const { expectRevert, expectEvent, constants } = require('@openzeppelin/test-helpers');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');
const { assert } = require('chai');

const toBN = web3.utils.toBN;

contract("FootballTokens", accounts => {

    const maxTokenId = 9
    const maxAmountOfEachToken = 1000
    const tokenPriceByWei = web3.utils.toWei('0.01', 'ether')
    const tokenPriceByPaymentToken = 30e18 //30 usdc
    const metadataURI = "MockURI"

    const owner = accounts[0]

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
            const userOne = accounts[1]
            const amountOfUserOneTokens = 1
            const receiptOne = await deployed.mintByETH(maxTokenId, amountOfUserOneTokens, { from: userOne, value: tokenPriceByWei })

            expectEvent(receiptOne, 'TransferSingle', {
                operator: userOne,
                from: constants.ZERO_ADDRESS,
                to: userOne,
                id: toBN(maxTokenId),
                value: toBN(amountOfUserOneTokens),
            });

            const balanceOfUserOne = await deployed.balanceOf(userOne, maxTokenId);
            assert.equal(balanceOfUserOne.toString(), amountOfUserOneTokens.toString());

            const userTwo = accounts[2]
            const amountOfUserTwoTokens = 10
            await deployed.mintByETH(maxTokenId, amountOfUserTwoTokens, { from: userTwo, value: tokenPriceByWei * 10 })

            const balanceOfUserTwo = await deployed.balanceOf(userTwo, maxTokenId);
            assert.equal(balanceOfUserTwo.toString(), amountOfUserTwoTokens.toString());

            const totalSupply = await deployed.totalSupply(maxTokenId)
            assert.equal(totalSupply.toString(), (amountOfUserOneTokens + amountOfUserTwoTokens).toString())
        })

        it("should succeed for 1000 tokens for same tokenId", async () => {
            const tokenId = 0

            const userOne = accounts[3]
            const amountOfUserOneTokens = 500

            const receiptOne = await deployed.mintByETH(tokenId, amountOfUserOneTokens, { from: userOne, value: tokenPriceByWei * amountOfUserOneTokens })
            expectEvent(receiptOne, 'TransferSingle', {
                operator: userOne,
                from: constants.ZERO_ADDRESS,
                to: userOne,
                id: toBN(tokenId),
                value: toBN(amountOfUserOneTokens),
            });

            const userTwo = accounts[3]
            const amountOfUserTwoTokens = 500
            await deployed.mintByETH(tokenId, amountOfUserTwoTokens, { from: userTwo, value: tokenPriceByWei * amountOfUserTwoTokens })

            const totalSupply = await deployed.totalSupply(tokenId)
            assert.equal(totalSupply.toString(), '1000')
        })

        it("should succeed for 2000 tokens for different tokenId", async () => {

            await deployed.mintByETH(0, 1000, { from: accounts[5], value: tokenPriceByWei * 1000 })
            await deployed.mintByETH(1, 1000, { from: accounts[6], value: tokenPriceByWei * 1000 })

            const totalSuppliedForTokenId0 = await deployed.totalSupply(0)
            const totalSuppliedForTokenId1 = await deployed.totalSupply(1)

            assert.equal(totalSuppliedForTokenId0.toString(), '1000')
            assert.equal(totalSuppliedForTokenId1.toString(), '1000')
        })

        it("should fail for 1001 tokens for same tokenId", async () => {
            const tokenId = 0

            await deployed.mintByETH(tokenId, 500, { from: accounts[3], value: tokenPriceByWei * 500 })
            await deployed.mintByETH(tokenId, 500, { from: accounts[4], value: tokenPriceByWei * 500 })
            await expectRevert(
                deployed.mintByETH(tokenId, 1, { from: accounts[5], value: tokenPriceByWei }),
                'Max supply is exceeded'
            )
        })

        it("should fail with incorrect token id", async () => {
            await expectRevert(
                deployed.mintByETH(maxTokenId + 1, 1, { from: accounts[1], value: tokenPriceByWei }),
                'Incorrect tokenId'
            );
        })

        it("should fail not enough ether", async () => {
            await expectRevert(
                deployed.mintByETH(0, 1, { from: accounts[2], value: 1e15 }),
                'Not enough ether'
            );
        })
    });

    describe('mintByPaymentToken', async () => {
        it("should success with correct token id and usdcAmount", async () => {
            const user = accounts[3]
            const usdcAmount = toBN(900e18) //900 usdc

            await usdcMock.mint(usdcAmount, { from: user })
            await usdcMock.approve(deployed.address, usdcAmount, { from: user })
            const receipt = await deployed.mintByPaymentToken(maxTokenId, 30, { from: user })

            expectEvent(receipt, 'TransferSingle', {
                operator: user,
                from: constants.ZERO_ADDRESS,
                to: user,
                id: toBN(maxTokenId),
                value: toBN(30),
            });

            balanceOfUser = await usdcMock.balanceOf(user)
            assert.equal(balanceOfUser.toString(), '0')

            const balanceOfContract = await usdcMock.balanceOf(deployed.address)
            assert.equal(balanceOfContract.toString(), 900e18.toString())


            const balanceOfMintedTokens = await deployed.balanceOf(user, maxTokenId);
            assert.equal(balanceOfMintedTokens.toString(), '30');
        })

        it("should fail with incorrect token id", async () => {
            const user = accounts[1]
            const usdcAmount = toBN(900e18) //900 usdc

            const receiptUSDC = await usdcMock.mint(usdcAmount, { from: user })

            expectEvent(receiptUSDC, 'Transfer', {
                from: constants.ZERO_ADDRESS,
                to: user,
                value: toBN(usdcAmount)
            });

            await usdcMock.approve(deployed.address, usdcAmount, { from: user })

            await expectRevert(
                deployed.mintByPaymentToken(maxTokenId + 1, 30, { from: user }),
                'Incorrect tokenId'
            );
        })

        it("should fail because of max supply is exceeded", async () => {
            const tokenId = 0

            await deployed.mintByETH(tokenId, 500, { from: accounts[3], value: tokenPriceByWei * 500 })
            await deployed.mintByETH(tokenId, 500, { from: accounts[4], value: tokenPriceByWei * 500 })

            const user = accounts[1]
            const usdcAmount = toBN(900e18) //900 usdc

            await usdcMock.mint(usdcAmount, { from: user })
            await usdcMock.approve(deployed.address, usdcAmount, { from: user })

            await expectRevert(
                deployed.mintByPaymentToken(tokenId, 1, { from: user }),
                'Max supply is exceeded'
            );
        })
    });

    describe('withdrawETH', async () => {
        it("should succeed to withdraw ether", async () => {

            const balanceOfContract = await web3.eth.getBalance(deployed.address)
            assert.equal(balanceOfContract.toString(), '0')

            const tokenAmount = 10
            await deployed.mintByETH(0, tokenAmount, { from: accounts[3], value: toBN(tokenPriceByWei * tokenAmount) })

            const balanceOfContractAfter = await web3.eth.getBalance(deployed.address)
            assert.equal(balanceOfContractAfter.toString(), (tokenPriceByWei * tokenAmount).toString())

            const ownerInitialBalance = await web3.eth.getBalance(owner)

            let receipt = await deployed.withdrawETH(toBN(tokenPriceByWei * tokenAmount), { from: owner })

            const ownerBalanceAfterWithdrawing = await web3.eth.getBalance(owner)
            const txSpentGas = receipt.receipt.cumulativeGasUsed
            
            //TODO: Should be fixed
            // assert.equal(ownerInitialBalance - txSpentGas + (tokenPriceByWei * tokenAmount), ownerBalanceAfterWithdrawing)

            const balanceAfterWithdraw = await web3.eth.getBalance(deployed.address)
            assert.equal(balanceAfterWithdraw.toString(), '0')
        })

        it("should fail to withdraw ether if no owner", async () => {

            const user = accounts[3]
            const tokenAmount = 10
            await deployed.mintByETH(0, tokenAmount, { from: user, value: toBN(tokenPriceByWei * tokenAmount) })

            await expectRevert(
                deployed.withdrawETH(toBN(tokenPriceByWei * tokenAmount), { from: user }),
                'caller is not the owner'
            )
        })
    });

    describe('withdrawPaymentToken', async () => {
        it("should succeed to withdraw usdc", async () => {

            const user = accounts[1]
            const usdcAmount = toBN(900e18) //900 usdc

            await usdcMock.mint(usdcAmount, { from: user })
            await usdcMock.approve(deployed.address, usdcAmount, { from: user })

            await deployed.mintByPaymentToken(maxTokenId, 30, { from: user })

            const balanceOfContract = await usdcMock.balanceOf(deployed.address)
            assert.equal(balanceOfContract.toString(), 900e18.toString())

            await deployed.withdrawPaymentToken(usdcMock.address, usdcAmount, { from: owner })

            const balanceOfContractAfter = await usdcMock.balanceOf(deployed.address)
            assert.equal(balanceOfContractAfter.toString(), '0')

            const balanceOfOwner = await usdcMock.balanceOf(owner)
            assert.equal(balanceOfOwner.toString(), usdcAmount.toString())

        })

        it("should fail for not owner to withdraw usdc", async () => {

            const user = accounts[1]
            const usdcAmount = toBN(900e18) //900 usdc

            await usdcMock.mint(usdcAmount, { from: user })
            await usdcMock.approve(deployed.address, usdcAmount, { from: user })
            await deployed.mintByPaymentToken(maxTokenId, 30, { from: user })

            await expectRevert(
                deployed.withdrawPaymentToken(usdcMock.address, usdcAmount, { from: user }),
                'caller is not the owner'
            )
        })
    });
})