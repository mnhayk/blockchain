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
        150e6 * (10**(STMPToken(address(getToken())).decimals()));

    // ICO stage two token maximum limit
    uint256 public stageTwoLimit =
        300e6 * (10**(STMPToken(address(getToken())).decimals()));

    // ICO stage two token maximum limit
    uint256 public stageThreeLimit =
        450e6 * (10**(STMPToken(address(getToken())).decimals()));

    // ICO sateg one opening time - 01.07.2022 GMT+0400 (Armenia Standard Time)
    uint256 stageOneOpeningTime = 1656619200;

    // ICO sateg two opening time - 01.08.2022 GMT+0400 (Armenia Standard Time)
    uint256 stageTwoOpeningTime = 1659297600;

    // ICO sateg two opening time - 01.09.2022 GMT+0400 (Armenia Standard Time)
    uint256 stageThreeOpeningTime = 1661976000;

    // ICO closing - 01.10.2022 GMT+0400 (Armenia Standard Time)
    uint256 stageThreeClosingTime = 1664568000;

    constructor(
        uint256 _fullTokenAmount,
        uint256 _tokenRate,
        address payable _wallet,
        address _tokenAddress
    )
        Crowdsale(_tokenRate, _wallet, IERC20(_tokenAddress))
        TimedCrowdsale(stageOneOpeningTime, stageThreeClosingTime)
    {
        require(_fullTokenAmount > 0, "Invalid Token amount");
    }

    function _getTokenAmount(uint256 weiAmount)
        internal
        view
        override
        returns (uint256)
    {
        uint256 tokensToBuy;
        uint256 decimals = STMPToken(address(getToken())).decimals();

        if (
            tokenRaised() <= stageOneLimit &&
            (block.timestamp >= stageOneOpeningTime && block.timestamp < stageTwoOpeningTime)
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
            (block.timestamp >= stageTwoOpeningTime && block.timestamp < stageThreeOpeningTime)
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
            (tokenRaised() > stageTwoLimit && tokenRaised() <= stageThreeLimit) &&
            (block.timestamp >= stageThreeOpeningTime && block.timestamp < stageThreeClosingTime)
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
        }
        return tokensToBuy;
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect investor min/max funding cap.
     * @param _beneficiary Token purchaser
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        override(Crowdsale, TimedCrowdsale)
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    //Private functions
    function calculateExcessTokens(
        uint256 amount,
        uint256 currentStageTokens,
        uint256 currentStage,
        uint256 _rate
    ) private view returns (uint256 totalTokens) {
        //TODO: should be checked
        uint256 currentStageWei = (currentStageTokens - tokenRaised()) / _rate;
        uint256 nextStageWei = amount - currentStageWei;
        uint256 nextStageTokens = 0;
        bool returnTokens = false;

        if (currentStage != 4 || currentStage != 0) {
            nextStageTokens = calculateStageTokens(
                nextStageWei,
                currentStage + 1
            );
        } else {
            returnTokens = true;
        }
        totalTokens = currentStageTokens - tokenRaised() + nextStageTokens;

        // Do the transfer at the end
        // if(returnTokens) msg.sender.transfer(nextStageWei);
    }

    function calculateStageTokens(uint256 weiPaid, uint256 currentStage)
        private
        view
        returns (uint256 calculatedTokens)
    {
        require(weiPaid > 0);
        require(currentStage >= 0 && currentStage <= 4);

        if (currentStage == 1) {
            calculatedTokens = weiPaid * stageOneRate;
        } else if (currentStage == 2) {
            calculatedTokens = weiPaid * stageTwoRate;
        } else if (currentStage == 3) {
            calculatedTokens = weiPaid * stageThreeRate;
        } 
    }
}
