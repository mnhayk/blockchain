// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./STMPToken.sol";
import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";

contract STMPCrowdsale is Crowdsale, TimedCrowdsale, Ownable {
    // ICO stage one Rate
    uint256 public stageOneRate = 5000;

    // ICO stage two Rate
    uint256 public stageTwoRate = 4000;

    // ICO stage three Rate
    uint256 public stageThreeRate = 3000;

    // ICO stage one token maximum limit
    uint256 public stageOneLimit =
        150e6 * (10**(STMPToken(address(token())).decimals()));

    // ICO stage two token maximum limit
    uint256 public stageTwoLimit =
        300e6 * (10**(STMPToken(address(token())).decimals()));

    // ICO stage two token maximum limit
    uint256 public stageThreeLimit =
        450e6 * (10**(STMPToken(address(token())).decimals()));

    // ICO sateg one opening time - 01.07.2022 GMT+0400 (Armenia Standard Time)
    uint256 stageOneOpeningTime = 1656619200;

    // ICO sateg two opening time - 01.08.2022 GMT+0400 (Armenia Standard Time)
    uint256 stageTwoOpeningTime = 1659297600;

    // ICO sateg two opening time - 01.09.2022 GMT+0400 (Armenia Standard Time)
    uint256 stageThreeOpeningTime = 1661976000;

    // ICO closing - 01.10.2022 GMT+0400 (Armenia Standard Time)
    uint256 stageThreeClosingTime = 1664568000;

    // Variable showing whether should be done refund for exceeding money
    bool private shouldRefund = false;

    // Address for investor for refunding exceeding money
    address private investorAddressForRefund;

    // Exceeding money value
    uint256 private refundValue;

    // USDC address
    address public usdcTokenAddress =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    /**
     * @dev Constructor for ICOCrowdsale
     * @param fullTokenAmount_ Token Amount during the ICO
     * @param wallet_ Crowdsale wallet
     * @param usdcWallet_ Crowdsale wallet
     * @param tokenAddress_ Token address for crowdsale
     */
    constructor(
        uint256 fullTokenAmount_,
        address payable wallet_,
        address usdcWallet_,
        address tokenAddress_
    )
        Crowdsale(stageOneRate, wallet_, usdcWallet_, IERC20(tokenAddress_))
        TimedCrowdsale(stageOneOpeningTime, stageThreeClosingTime)
    {
        require(fullTokenAmount_ > 0, "Invalid Token amount");
    }

    /**
     * @dev Calculate token amount which should be transfered to investor
     * @param weiAmount Amount of wei contributed
     */
    function _getTokenAmount(uint256 weiAmount)
        internal
        override
        returns (uint256)
    {
        uint256 tokensToBuy;
        uint256 decimals = STMPToken(address(token())).decimals();

        if (
            tokenRaised() <= stageOneLimit &&
            (block.timestamp >= stageOneOpeningTime &&
                block.timestamp < stageTwoOpeningTime)
        ) {
            tokensToBuy =
                ((weiAmount * (10**decimals)) / 1 ether) *
                stageOneRate;
            if (tokenRaised() + tokensToBuy > stageOneLimit) {
                tokensToBuy = calculateExcessTokens(
                    weiAmount,
                    stageOneLimit,
                    1,
                    stageOneRate
                );
            }
        } else if (
            (tokenRaised() > stageOneLimit && tokenRaised() <= stageTwoLimit) &&
            (block.timestamp >= stageTwoOpeningTime &&
                block.timestamp < stageThreeOpeningTime)
        ) {
            tokensToBuy =
                ((weiAmount * (10**decimals)) / 1 ether) *
                stageTwoRate;
            if (tokenRaised() + tokensToBuy > stageTwoLimit) {
                tokensToBuy = calculateExcessTokens(
                    weiAmount,
                    stageTwoLimit,
                    2,
                    stageTwoRate
                );
            }
        } else if (
            (tokenRaised() > stageTwoLimit &&
                tokenRaised() <= stageThreeLimit) &&
            (block.timestamp >= stageThreeOpeningTime &&
                block.timestamp < stageThreeClosingTime)
        ) {
            tokensToBuy =
                ((weiAmount * (10**decimals)) / 1 ether) *
                stageTwoRate;
            if (tokenRaised() + tokensToBuy > stageThreeLimit) {
                tokensToBuy = calculateExcessTokens(
                    weiAmount,
                    stageThreeLimit,
                    3,
                    stageThreeRate
                );
            }
        }
        return tokensToBuy;
    }

    function _getTokenAmountPayedWithUsdc(uint256 usdcAmount)
        internal
        virtual
        override
        returns (uint256)
    {
        //TODO: should add logic for calculating tokens amount using sent usdcAmount and current usdc price from Oracle
    }

    function _forwardFundsWithUSDC(uint256 usdcAmount)
        internal
        virtual
        override
    {
        IERC20(usdcTokenAddress).transferFrom(
            msg.sender,
            usdcWallet(),
            usdcAmount
        );
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        override(Crowdsale, TimedCrowdsale)
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount)
        internal
        override
    {
        super._processPurchase(beneficiary, tokenAmount);

        if (shouldRefund) {
            require(beneficiary == investorAddressForRefund);
            (bool success, ) = investorAddressForRefund.call{
                value: refundValue
            }("");
            require(success, "Refund failed");

            shouldRefund = false;
            investorAddressForRefund = address(0);
            refundValue = 0;
        }
    }

    /**
     * @dev Calculate exceeding token amount for current stage
     * @param amount Amount of wei contributed
     * @param currentStageLimit Current stage maximum limit
     * @param currentStage Current stage index
     * @param _rate Current stage rate
     */
    function calculateExcessTokens(
        uint256 amount,
        uint256 currentStageLimit,
        uint256 currentStage,
        uint256 _rate
    ) private returns (uint256 totalTokens) {
        uint256 currentStageWei = (currentStageLimit - tokenRaised()) / _rate;
        uint256 nextStageWei = amount - currentStageWei;
        uint256 nextStageTokens = 0;
        bool returnTokens = false;

        if (currentStage != 3) {
            nextStageTokens = calculateStageTokens(
                nextStageWei,
                currentStage + 1
            );
        } else {
            returnTokens = true;
        }

        if (returnTokens) {
            shouldRefund = true;

            investorAddressForRefund = msg.sender;
            refundValue = nextStageWei;
        }

        totalTokens = currentStageLimit - tokenRaised() + nextStageTokens;
    }

    /**
     * @dev Calculate stage tokens count for specific amount of wei
     * @param weiPaid Amount of wei contributed
     * @param stage stage index
     */
    function calculateStageTokens(uint256 weiPaid, uint256 stage)
        private
        view
        returns (uint256 calculatedTokens)
    {
        require(weiPaid > 0);
        require(stage >= 0 && stage <= 3);

        uint256 decimals = STMPToken(address(token())).decimals();

        if (stage == 1) {
            calculatedTokens =
                ((weiPaid * (10**decimals)) / 1 ether) *
                stageOneRate;
        } else if (stage == 2) {
            calculatedTokens =
                ((weiPaid * (10**decimals)) / 1 ether) *
                stageTwoRate;
        } else if (stage == 3) {
            calculatedTokens =
                ((weiPaid * (10**decimals)) / 1 ether) *
                stageThreeRate;
        }
    }
}
