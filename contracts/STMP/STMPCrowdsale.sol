// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./STMPToken.sol";
import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";

contract STMPCrowdsale is Crowdsale, TimedCrowdsale, Ownable {

    uint256 public tokenAmount;
    address public tokenAddress;

    constructor(
        uint256 _tokenAmount,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _tokenRate,
        address payable _wallet,
        address _tokenAddress
    )
        Crowdsale(_tokenRate, _wallet, IERC20(_tokenAddress))
        TimedCrowdsale(_openingTime, _closingTime)
    {
        require(_tokenAmount > 0, "Invalid Token amount");
        require(_tokenAddress != address(0), "Invalid address");
        tokenAmount = _tokenAmount;
        tokenAddress = _tokenAddress;

        STMPToken(tokenAddress).mint(address(this), tokenAmount);
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
}
