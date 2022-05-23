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
        address tokenAddress_,
        address usdcTokenAddress_
    )
        Crowdsale(stageOneRate, wallet_, usdcWallet_, IERC20(tokenAddress_), IERC20(usdcTokenAddress_))
        TimedCrowdsale(stageOneOpeningTime, stageThreeClosingTime)
    {
        require(fullTokenAmount_ > 0, "Invalid Token amount");
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return tokenAmount tokenAmount of tokens that can be purchased with the specified _weiAmount
     * @return weiRefund amount of wei which is refunded because of exceeding limit
     */
    function _getTokenAmount(uint256 weiAmount)
        internal
        view
        virtual
        override
        returns (uint256 tokenAmount, uint256 weiRefund)
    {
        uint256 tokensToBuy;
        uint256 weiShouldRefund;
        uint256 decimals = STMPToken(address(token())).decimals();

        if (
            tokenRaised() <= stageOneLimit &&
            (block.timestamp >= stageOneOpeningTime &&
                block.timestamp < stageTwoOpeningTime)
        ) {
            tokenAmount =
                ((weiAmount * (10**decimals)) / 1 ether) *
                stageOneRate;
            if (tokenRaised() + tokensToBuy > stageOneLimit) {
                (tokensToBuy, weiShouldRefund) = calculateExcessTokens(
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
                (tokensToBuy, weiShouldRefund) = calculateExcessTokens(
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
                (tokensToBuy, weiShouldRefund) = calculateExcessTokens(
                    weiAmount,
                    stageThreeLimit,
                    3,
                    stageThreeRate
                );
            }
        }
        tokenAmount = tokensToBuy;
        weiRefund = weiShouldRefund;
    }

    function _getTokenAmountPayedWithUsdc(uint256 usdcAmount)
        internal
        view
        virtual
        override
        returns (uint256 tokenAmount, uint256 usdcRefund)
    {
        //TODO: should add logic for calculating tokens amount using sent usdcAmount and current usdc price from Oracle
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
    ) private view returns (uint256 totalTokens, uint256 weiRefund) {
        uint256 currentStageWei = (currentStageLimit - tokenRaised()) / _rate;
        uint256 nextStageWei = amount - currentStageWei;
        uint256 nextStageTokens = 0;
        bool returnTokens = false;
        weiRefund = 0;

        if (currentStage != 3) {
            nextStageTokens = calculateStageTokens(
                nextStageWei,
                currentStage + 1
            );
        } else {
            returnTokens = true;
        }

        if (returnTokens) {
            weiRefund = nextStageWei;
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
