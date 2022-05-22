// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract STMPToken is ERC20, Pausable, Ownable {

    // All existing token amount
    uint256 public tokenAmount;

    // Crowdsale contract address
    address public crowdsaleAddress;

    // The treasure address
    address public treasuryAddress;

    // The tokens already used for the presale buyers
    uint256 public tokensDistributedPresale = 0;

    // The maximum amount of tokens for the presale investors
    uint256 public limitPresale = 3e24;

    modifier onlyCrowdsale() {
        require(msg.sender == crowdsaleAddress);
        _;
    }

    constructor(
        uint256 _tokenAmount,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        require(tokenAmount > 0);
        tokenAmount = _tokenAmount;

        _mint(treasuryAddress, tokenAmount);
        _pause();
    }

    // TODO: We can't set crowdsale as object is paused in the constructor.
    function setCrowdsale(address _crowdsaleAddress)
        public
        onlyOwner
        whenPaused
    {
        require(_crowdsaleAddress != address(0));
        crowdsaleAddress = _crowdsaleAddress;
        approve(crowdsaleAddress, tokenAmount);
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
