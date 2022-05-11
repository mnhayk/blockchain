// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/utils/TokenTimelock.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../OZCrowdsale/Crowdsale.sol";
import "../OZCrowdsale/CappedCrowdsale.sol";
import "../OZCrowdsale/TimedCrowdsale.sol";
import "../OZCrowdsale/WhitelistCrowdsale.sol";
import "../OZCrowdsale/RefundableCrowdsale.sol";
import "./DappToken.sol";

contract DappTokenCrowdsale is
    Crowdsale,
    CappedCrowdsale,
    TimedCrowdsale,
    WhitelistCrowdsale,
    RefundableCrowdsale,
    Ownable
{
    using SafeMath for uint256;
    // Track investor contributions
    uint256 public investorMinCap = 2000000000000000; // 0.002 ether
    uint256 public investorHardCap = 50000000000000000000; // 50 ether
    mapping(address => uint256) public contributions;

    // Crowdsale Stages
    enum CrowdsaleStage {
        PreICO,
        ICO
    }
    // Default to presale stage
    CrowdsaleStage public stage = CrowdsaleStage.PreICO;

    // Token Distribution
    uint256 public tokenSalePercentage = 70;
    uint256 public foundersPercentage = 10;
    uint256 public foundationPercentage = 10;
    uint256 public partnersPercentage = 10;

    // Token reserve funds
    address public foundersFund;
    address public foundationFund;
    address public partnersFund;

    // Token time lock
    uint256 public releaseTime;
    TokenTimelock public foundersTimelock;
    TokenTimelock public foundationTimelock;
    TokenTimelock public partnersTimelock;

    //By Hayk: Saved locally token for "finalization", open to discuss other solution
    ERC20PresetMinterPauser private token;

    constructor(
        uint256 _rate,
        address payable _wallet,
        ERC20PresetMinterPauser _token,
        uint256 _cap,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _goal,
        address _foundersFund,
        address _foundationFund,
        address _partnersFund,
        uint256 _releaseTime
    )
        Crowdsale(_rate, _wallet, _token)
        CappedCrowdsale(_cap)
        TimedCrowdsale(_openingTime, _closingTime)
        WhitelistCrowdsale(_rate)
        RefundableCrowdsale(_goal)
    {
        require(_goal <= _cap);
        foundersFund = _foundersFund;
        foundationFund = _foundationFund;
        partnersFund = _partnersFund;
        releaseTime = _releaseTime;
        token = _token;
    }

    /**
     * @dev Returns the amount contributed so far by a sepecific user.
     * @param _beneficiary Address of contributor
     * @return User contribution so far
     */
    function getUserContribution(address _beneficiary)
        public
        view
        returns (uint256)
    {
        return contributions[_beneficiary];
    }

    /**
     * @dev Allows admin to update the crowdsale stage
     * @param _stage Crowdsale stage
     */
    function setCrowdsaleStage(uint256 _stage) public onlyOwner {
        if (uint256(CrowdsaleStage.PreICO) == _stage) {
            stage = CrowdsaleStage.PreICO;
        } else if (uint256(CrowdsaleStage.ICO) == _stage) {
            stage = CrowdsaleStage.ICO;
        }

        if (stage == CrowdsaleStage.PreICO) {
            super.setRate(500);
        } else if (stage == CrowdsaleStage.ICO) {
            super.setRate(250);
        }
    }

    /**
     * @dev forwards funds to the wallet during the PreICO stage, then the refund vault during ICO stage
     */
    function _forwardFunds() internal override(Crowdsale, RefundableCrowdsale) {
        if (stage == CrowdsaleStage.PreICO) {
            //TODO: should be checked "wallet.transfer(msg.value);"
            getWallet().transfer(msg.value);
        } else if (stage == CrowdsaleStage.ICO) {
            super._forwardFunds();
        }
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect investor min/max funding cap.
     * @param _beneficiary Token purchaser
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        override(Crowdsale, CappedCrowdsale, TimedCrowdsale, WhitelistCrowdsale)
    {
        //TODO: Investingate which one will be called.
        super._preValidatePurchase(_beneficiary, _weiAmount);
        uint256 _existingContribution = contributions[_beneficiary];
        uint256 _newContribution = _existingContribution.add(_weiAmount);
        require(
            _newContribution >= investorMinCap &&
                _newContribution <= investorHardCap
        );
        contributions[_beneficiary] = _newContribution;
    }

    //TODO: I believe this should be somethign overriden, need to check
    function finalization() internal {
        if (goalReached()) {
            uint256 _alreadyMinted = token.totalSupply();

            uint256 _finalTotalSupply = _alreadyMinted
                .div(tokenSalePercentage)
                .mul(100);

            foundersTimelock = new TokenTimelock(
                token,
                foundersFund,
                releaseTime
            );
            foundationTimelock = new TokenTimelock(
                token,
                foundationFund,
                releaseTime
            );
            partnersTimelock = new TokenTimelock(
                token,
                partnersFund,
                releaseTime
            );

            token.mint(
                address(foundersTimelock),
                _finalTotalSupply.mul(foundersPercentage).div(100)
            );
            token.mint(
                address(foundationTimelock),
                _finalTotalSupply.mul(foundationPercentage).div(100)
            );
            token.mint(
                address(partnersTimelock),
                _finalTotalSupply.mul(partnersPercentage).div(100)
            );

            //Not exisit in current contract
            // TODO: should be found alternative
            // token.finishMinting();
            // Unpause the token
            token.unpause();
            
            
            // TODO: should be found alternative, maybe this will work
            // >>>>>> "token.transfer(getWallet(), token.totalSupply());"
            // token.transferOwnership(getWallet());
        }
       
        // TODO: original version was "super.finalization();"
         super.finalize();
    }
}
