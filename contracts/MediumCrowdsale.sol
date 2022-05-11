// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "./ICOToken.sol";

contract MeidumCrowdsale {

    bool icoCompleted;

    uint public icoStartTime;
    uint public icoEndTime;
    uint public tokenRate;
    uint public fundingGoal;
    uint public tokensRaised;
    uint public etherRaised;

    ICOToken public token;
    address public owner;
    

    modifier whenIcoCompleted {
        require(icoCompleted);
        _;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Not owner");
        _;
    }

    constructor(uint _icoStartTime, uint _icoEndTime, uint _tokenRate, uint _fundingGoal, address _tokenAddress) {
        require(_icoStartTime > 0 &&
                _icoEndTime > 0 && 
                _tokenRate > 0 &&
                _icoEndTime < _icoStartTime &&
                _fundingGoal > 0 &&
                _tokenAddress != address(0));
            
        icoStartTime = _icoStartTime;
        icoEndTime = _icoEndTime;
        tokenRate = _tokenRate;
        fundingGoal = _fundingGoal;
        token = ICOToken(_tokenAddress);
        owner = msg.sender;
    }

    function pay() public payable {
        require(tokensRaised < fundingGoal);
        require(block.timestamp < icoEndTime && block.timestamp > icoStartTime);

        uint tokensToBuy;
        uint etherUsed = msg.value;

        tokensToBuy = tokenRate * (10 ** ICOToken(token).decimals()) * msg.value / 1 ether;

        if(tokensRaised + tokensToBuy > fundingGoal) {
            uint exceedingTokens = tokensRaised + tokensToBuy - fundingGoal;
            uint exceedingEther;

            // Convert the exceedingTokens to ether and refund that ether
            exceedingEther = exceedingTokens * 1 ether / tokenRate / token.decimals();

            (bool success, ) = msg.sender.call {value: exceedingEther}("");
            require(success, "Failed to refund Ether");
 
            // Change the tokens to buy to the new number
            tokensToBuy -= exceedingTokens;

             // Update the counter of ether used
            etherUsed -= exceedingEther;
        }

        // Send the tokens to the buyer
        token.buyTokens(msg.sender, tokensToBuy);

        // Increase the tokens raised and ether raised state variables
        tokensRaised += tokensToBuy;
        etherRaised += etherUsed;
    }

    function extractEther() public payable whenIcoCompleted onlyOwner{
        (bool success, ) = owner.call {value: address(this).balance} ("");
        require(success, "Failed to withdraw Ether");
    }

}