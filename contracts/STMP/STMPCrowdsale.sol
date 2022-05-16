// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./STMPToken.sol";
import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";

contract STMPCrowdsale is Crowdsale, TimedCrowdsale, Ownable {
    uint256 public fullTokenAmount;
    address public tokenAddress;

    //TODO: Rate should be calculated
    uint256 public ratePreSale = 6000;

    uint256 public rateOne = 5000;
    uint256 public rateTwo = 4000;
    uint256 public rateThree = 3000;
    uint256 public rateFour = 2000;

    uint256 public stagePreSaleLimit =
        3e6 * (10**(STMPToken(address(getToken())).decimals()));

    uint256 public stageOneLimit =
        153e6 * (10**(STMPToken(address(getToken())).decimals()));
    uint256 public stageTwoLimit =
        303e6 * (10**(STMPToken(address(getToken())).decimals()));
    uint256 public stageThreeLimit =
        453e6 * (10**(STMPToken(address(getToken())).decimals()));
    uint256 public stageFourLimit =
        803e6 * (10**(STMPToken(address(getToken())).decimals()));

    enum CrowdsaleStage {
        PreSale,
        ICO
    }

    // Default to presale stage
    CrowdsaleStage public stage = CrowdsaleStage.PreSale;

    constructor(
        uint256 _fullTokenAmount,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _tokenRate,
        address payable _wallet,
        address _tokenAddress
    )
        Crowdsale(_tokenRate, _wallet, IERC20(_tokenAddress))
        TimedCrowdsale(_openingTime, _closingTime)
    {
        require(_fullTokenAmount > 0, "Invalid Token amount");
        require(_tokenAddress != address(0), "Invalid address");
        fullTokenAmount = _fullTokenAmount;
        tokenAddress = _tokenAddress;

        STMPToken(tokenAddress).mint(address(this), fullTokenAmount);
    }

    /**
     * @dev Allows admin to update the crowdsale stage
     * @param _stage Crowdsale stage
     */
    function setCrowdsaleStage(uint256 _stage) public onlyOwner {
        if (uint256(CrowdsaleStage.PreSale) == _stage) {
            stage = CrowdsaleStage.PreSale;
        } else if (uint256(CrowdsaleStage.ICO) == _stage) {
            stage = CrowdsaleStage.ICO;
        }
    }

    function _getTokenAmount(uint256 weiAmount) internal view override returns (uint256) {

        uint256 tokensToBuy;
        uint256 decimals = STMPToken(address(getToken())).decimals();

        if (stage == CrowdsaleStage.PreSale) {
            tokensToBuy = ((weiAmount * (10**decimals)) / 1 ether) * ratePreSale;
            if (tokenRaised() + tokensToBuy > stagePreSaleLimit) {
                tokensToBuy = calculateExcessTokens(weiAmount, stagePreSaleLimit, 0, ratePreSale);
             }
        } else if (stage == CrowdsaleStage.ICO) {
            if (tokenRaised() < stageOneLimit) {
                tokensToBuy = ((weiAmount * (10**decimals)) / 1 ether) * rateOne;
                if (tokenRaised() + tokensToBuy > stageOneLimit) {
                    tokensToBuy = calculateExcessTokens(weiAmount, stageOneLimit, 1, rateOne);
                }
            } else if (tokenRaised() >= stageOneLimit && tokenRaised() < stageTwoLimit) {
                tokensToBuy = ((weiAmount * (10**decimals)) / 1 ether) * rateTwo;
                if (tokenRaised() + tokensToBuy > stageTwoLimit) {
                    tokensToBuy = calculateExcessTokens(weiAmount, stageTwoLimit, 2, rateTwo);
                }
            } else if (tokenRaised() >= stageTwoLimit && tokenRaised() < stageThreeLimit) {
                tokensToBuy = ((weiAmount * (10**decimals)) / 1 ether) * rateThree;
                if (tokenRaised() + tokensToBuy > stageThreeLimit) {
                    tokensToBuy = calculateExcessTokens(weiAmount, stageThreeLimit, 3, rateThree);
                }
            } else if (tokenRaised() >= stageThreeLimit) {
                tokensToBuy = ((weiAmount * (10**decimals)) / 1 ether) * rateFour;
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
        uint256 currentStageWei = (currentStageTokens - tokenRaised()) / _rate;
        uint256 nextStageWei = amount - currentStageWei;
        uint256 nextStageTokens = 0;
        bool returnTokens = false;

        if (currentStage != 4 || currentStage != 0) {
            nextStageTokens = calculateStageTokens(nextStageWei, currentStage + 1);
        } else {
            returnTokens = true;
        }
        totalTokens = currentStageTokens - tokenRaised() + nextStageTokens;

        // Do the transfer at the end
        // if(returnTokens) msg.sender.transfer(weiNextTier);
    }

    function calculateStageTokens(uint256 weiPaid, uint256 currentStage)
        private
        view
        returns (uint256 calculatedTokens)
    {
        require(weiPaid > 0);
        require(currentStage >= 0 && currentStage <= 4);
        
        if (currentStage == 0) {
            calculatedTokens = weiPaid * ratePreSale;
        } else if (currentStage == 1) {
            calculatedTokens = weiPaid * rateOne;
        } else if (currentStage == 2) {
            calculatedTokens = weiPaid * rateTwo;
        } else if (currentStage == 3) {
            calculatedTokens = weiPaid * rateThree;
        } else {
            calculatedTokens = weiPaid * rateFour;
        }
    }
}
