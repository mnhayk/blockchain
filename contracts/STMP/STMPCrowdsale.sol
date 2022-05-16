// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./STMPToken.sol";
import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";

contract STMPCrowdsale is Crowdsale, TimedCrowdsale, Ownable {
    uint256 public fullTokenAmount;
    uint256 public icoTokenAmount;
    address public tokenAddress;

    uint256 public rateOne = 5000;
    uint256 public rateTwo = 4000;
    uint256 public rateThree = 3000;
    uint256 public rateFour = 2000;
    uint256 public limitTierOne = 150e6 * (10**(STMPToken(address(getToken())).decimals()));
    uint256 public limitTierTwo = 150e6 * (10**(STMPToken(address(getToken())).decimals()));
    uint256 public limitTierThree = 150e6 * (10**(STMPToken(address(getToken())).decimals()));
    uint256 public limitTierFour = 350e6 * (10**(STMPToken(address(getToken())).decimals()));

    // Crowdsale Stages
    // ICOFirstStage => 150m at $ 0.03 ($4.5m),
    // ICOSecondStage => 150m at $ 0.04 ($6m)
    // ICOThirdStage => 150m at $ 0.05 ($7.5m)
    // ICOForthStage => 350m plus any pre-sale unsold at price of $ 0.08 ($28m)

    enum CrowdsaleStage {
        PreSale,
        ICO
    }

    // Default to presale stage
    CrowdsaleStage public stage = CrowdsaleStage.PreSale;

    constructor(
        uint256 _fullTokenAmount,
        uint256 _icoTokenAmount,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _tokenRate,
        address payable _wallet,
        address _tokenAddress
    )
        Crowdsale(_tokenRate, _wallet, IERC20(_tokenAddress))
        TimedCrowdsale(_openingTime, _closingTime)
    {
        require(
            _fullTokenAmount > 0 &&
                _icoTokenAmount > 0 &&
                _icoTokenAmount <= _fullTokenAmount,
            "Invalid Token amount"
        );
        require(_tokenAddress != address(0), "Invalid address");
        fullTokenAmount = _fullTokenAmount;
        icoTokenAmount = _icoTokenAmount;
        tokenAddress = _tokenAddress;

        STMPToken(tokenAddress).mint(address(this), fullTokenAmount);
    }

    /**
     * @dev Allows admin to update the crowdsale stage
     * @param _stage Crowdsale stage
     */
    //TODO: Rate should be calculated
    function setCrowdsaleStage(uint256 _stage) public onlyOwner {
        if (uint256(CrowdsaleStage.PreSale) == _stage) {
            stage = CrowdsaleStage.PreSale;
        } else if (uint256(CrowdsaleStage.ICO) == _stage) {
            stage = CrowdsaleStage.ICO;
        }
    }

    function _getTokenAmount(uint256 weiAmount)
        internal
        view
        override
        returns (uint256)
    {
        uint256 tokensToBuy;
        uint256 rate;
        uint256 tierSelected;
        uint256 limitTier;
        if (tokenRaised() <= limitTierOne) {
            rate = rateOne;
            limitTier = limitTierOne;
            tierSelected = 1;
        } else if (
            tokenRaised() > limitTierOne && tokenRaised() <= limitTierTwo
        ) {
            rate = rateTwo;
            limitTier = limitTierTwo;
            tierSelected = 2;
        } else if (
            tokenRaised() > limitTierTwo && tokenRaised() <= limitTierThree
        ) {
            rate = rateThree;
            limitTier = limitTierThree;
            tierSelected = 3;
        } else if (
            tokenRaised() > limitTierThree && tokenRaised() <= limitTierFour
        ) {
            rate = rateFour;
            limitTier = limitTierFour;
            tierSelected = 4;
        }

        tokensToBuy = ((weiAmount * (10**(STMPToken(address(getToken())).decimals()) / 1 ether))) * rate;

        // If the amount of tokens that you want to buy gets out of this tier
        if (tokenRaised() + tokensToBuy > limitTier) {
            tokensToBuy = calculateExcessTokens(
                weiAmount,
                limitTier,
                tierSelected,
                rate
            );
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
        uint256 tokensThisTier,
        uint256 tierSelected,
        uint256 _rate
    ) private view returns (uint256 totalTokens) {
        require(amount > 0 && tokensThisTier > 0 && _rate > 0);
        require(tierSelected >= 1 && tierSelected <= 4);

        uint256 weiThisTier = tokensThisTier - (tokenRaised()) / (_rate);
        uint256 weiNextTier = amount - (weiThisTier);
        uint256 tokensNextTier = 0;
        bool returnTokens = false;

        // If there's excessive wei for the last tier, refund those
        if (tierSelected != 4)
            tokensNextTier = calculateTokensTier(
                weiNextTier,
                tierSelected + (1)
            );
        else returnTokens = true;

        totalTokens = tokensThisTier - tokenRaised() + (tokensNextTier);

        // Do the transfer at the end
        //TODO: should be checked
        // if (returnTokens) { 
        //     (bool success, ) = msg.sender.call {value: weiNextTier }("");
        //     require(success, "refunding failed");
        // }
    }

    function calculateTokensTier(uint256 weiPaid, uint256 tierSelected)
        private
        view
        returns (uint256 calculatedTokens)
    {
        require(weiPaid > 0);
        require(tierSelected >= 1 && tierSelected <= 4);

        if (tierSelected == 1) calculatedTokens = weiPaid * rateOne;
        else if (tierSelected == 2) calculatedTokens = weiPaid * rateTwo;
        else if (tierSelected == 3) calculatedTokens = weiPaid * rateThree;
        else calculatedTokens = weiPaid * rateFour;
    }
}
