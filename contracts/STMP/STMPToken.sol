// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract STMPToken is ERC20, ERC20Permit, ERC20Votes, Pausable, Ownable {
    // All existing token amount
    uint256 public tokenAmount = 1e27; // 1 miliard

    // The tokens already used for the presale buyers
    uint256 public tokensDistributedPresale = 0;

    // The maximum amount of tokens for the presale investors
    uint256 public limitPresale = 3e24; //TODO: this should be clarified

    // Crowdsale contract address
    address public crowdsaleAddress;

    // The treasury address
    address public treasuryAddress;

    modifier onlyCrowdsale() {
        require(msg.sender == crowdsaleAddress);
        _;
    }

    /**
     * @param _name The distributed token name
     * @param _symbol The distributed token symbol
     * @param _treasuryAddress The Treasury address
     */
    constructor(string memory _name, string memory _symbol, address _treasuryAddress)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
    {
        require(_treasuryAddress != address(0), "Treasury address is zero");
        treasuryAddress = _treasuryAddress;

        _mint(treasuryAddress, tokenAmount);
        // _pause();
    }

    /**
     * @dev Set crowdsale address. Only the owner can do this
     * @param _crowdsaleAddress The address of Crowdsale contract
     */
    function setCrowdsaleAddress(address _crowdsaleAddress) external onlyOwner {
        require(_crowdsaleAddress != address(0), "Crowdsale address is zero");
        crowdsaleAddress = _crowdsaleAddress;
    }

    /**
     * @dev Distributes the presale numberOfTokens. Only the owner can do this
     * @param _buyer The address of the buyer
     * @param _numberOfTokens The amount of tokens corresponding to that buyer
     */
    function distributePresaleTokens(address _buyer, uint256 _numberOfTokens)
        external
        onlyOwner
    {
        require(_buyer != address(0), "Buyer address is zero");
        require(_numberOfTokens > 0 && _numberOfTokens <= limitPresale, "Out of token limit");

        // Check that the limit of presale numberOfTokens hasn't been met yet
        require(tokensDistributedPresale + _numberOfTokens <= limitPresale, "Existing token amount exceeded");

        tokensDistributedPresale += _numberOfTokens;

        //TODO: Make sure treasury address approves contract to transfer
        transferFrom(treasuryAddress, _buyer, _numberOfTokens);
    }

    /**
     * @dev Function for withdrawing all existing ether: Only the owner can do this
     */
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Failed to withdraw Ether");
    }

    /**
     * @dev Pausing the token minting/approving/transfering. Only the owner can do this
     */
    function puase() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpausing the token minting/approving/transfering. Only the owner can do this
     */
    function unpuase() external onlyOwner {
        _unpause();
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     * @param from The address who transfer tokens
     * @param to The address who received tokens
     * @param amount The amount of tokens
     */
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
