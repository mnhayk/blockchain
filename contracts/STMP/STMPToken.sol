// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract STMPToken is ERC20, Pausable, Ownable {
    uint256 public tokenAmount;
    uint256 public closingTime;
    address public crowdsaleAddress;

    // The treasure address
    address public treasuryAddress;

    // The tokens already used for the presale buyers
    uint256 public tokensDistributedPresale = 0;

    // The tokens already used for the ICO buyers
    uint256 public tokensDistributedCrowdsale = 0;

    // The maximum amount of tokens for the presale investors
    uint256 public limitPresale = 3e24;

    // The maximum amount of tokens sold in the crowdsale
    uint256 public limitCrowdsale = 800e24;

    modifier onlyCrowdsale() {
        require(msg.sender == crowdsaleAddress);
        _;
    }

    modifier afterCrowdsale() {
        require(
            block.timestamp > closingTime || msg.sender == crowdsaleAddress
        );
        _;
    }

    constructor(
        uint256 _tokenAmount,
        uint256 _closingTime,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        require(_closingTime > 0 && tokenAmount > 0);
        closingTime = _closingTime;
        tokenAmount = _tokenAmount;

        _mint(treasuryAddress, tokenAmount);
        _pause();
    }

    function setCrowdsale(address _crowdsaleAddress)
        public
        onlyOwner
        whenNotPaused
    {
        require(_crowdsaleAddress != address(0));
        crowdsaleAddress = _crowdsaleAddress;
    }

    /**
     * @notice Distributes the presale numberOfTokens. Only the owner can do this
     * @param _buyer The address of the buyer
     * @param numberOfTokens The amount of tokens corresponding to that buyer
     */
    function distributePresaleTokens(address _buyer, uint256 numberOfTokens)
        external
        onlyOwner
        whenPaused
    {
        require(_buyer != address(0));
        require(numberOfTokens > 0 && numberOfTokens <= limitPresale);

        // Check that the limit of 3M presale numberOfTokens hasn't been met yet
        require(tokensDistributedPresale < limitPresale);
        require(tokensDistributedPresale + numberOfTokens < limitPresale);

        tokensDistributedPresale = tokensDistributedPresale + numberOfTokens;

        transferFrom(treasuryAddress, _buyer, numberOfTokens);
    }

    /**
     * @notice Distributes the ICO tokens. Only the crowdsale address can execute this
     * @param _buyer The buyer address
     * @param numberOfTokens The amount of tokens to send to that address
     */
    function distributeICOTokens(address _buyer, uint256 numberOfTokens)
        external
        onlyCrowdsale
        whenPaused
    {
        require(msg.sender != address(0));
        require(_buyer != address(0));
        require(numberOfTokens > 0);

        // Check that the limit of 50M ICO tokens hasn't been met yet
        require(tokensDistributedCrowdsale < limitCrowdsale);
        require(tokensDistributedCrowdsale + numberOfTokens <= limitCrowdsale);

        tokensDistributedCrowdsale =
            tokensDistributedCrowdsale +
            numberOfTokens;

        transferFrom(treasuryAddress, _buyer, numberOfTokens);
    }

    function emergencyExtract() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Failed to withdraw Ether");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        bool allowed = msg.sender == crowdsaleAddress ||
            msg.sender == owner() ||
            !paused();
        require(allowed, "ERC20Pausable: token transfer while paused");
    }
}
