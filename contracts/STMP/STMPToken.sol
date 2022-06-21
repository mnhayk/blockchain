// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract STMPToken is ERC20, ERC20Permit, ERC20Votes, Pausable, Ownable {
    //TODO: Make this values hardcoded
    // Presale opening time - 1 July 2022 00:00:00 GMT
    uint256 public presaleOpeningTime = 1656633600;

    // Presale closing time - 1 August 2022 00:00:00 GMT
    uint256 public presaleClosingTime = 1659312000; //TODO: should be clarified

    // Crowdsale closing time - 1 October 2022 00:00:00 GMT
    uint256 public crowdsaleClosingTime = 1664582400; //TODO: should be clarified

    // Crowdsale closing time - 2 October 2022 00:00:00 GMT
    uint256 public tokensReleaseDate = 1664668800; //TODO: should be clarified(One day after crowdsaleClosingTime)

    // All existing token amount
    uint256 public constant tokenAmount = 1e27; // 1 billion

    // The tokens already used for the presale buyers
    uint256 public tokensDistributedPresale = 0;

    // The tokens already released for the presale buyers
    uint256 public tokensReleased = 0;

    // The maximum amount of tokens for the presale investors
    uint256 public constant limitPresale = 3e24; //TODO: this should be clarified 50.000.000

    // Initial unlock percentage for next day after crowdsale closing time
    uint256 public unlockPercentage = 16;

    // Unlocking token percentage per month
    uint256 public constant unlockPercentagePerMonth = 7;

    // Shows how many token should be released per investor
    mapping(address => uint256) public tokenAmountPerInvestor;

    // Investors address during presale
    address[] public investorAddresses;

    // Crowdsale contract address
    address public crowdsaleAddress;

    // The treasury address
    address public treasuryAddress;

    modifier onlyPresalePeriod() {
        require(
            block.timestamp >= presaleOpeningTime &&
                block.timestamp <= presaleClosingTime
        );
        _;
    }

    /**
     * @param _name The distributed token name
     * @param _symbol The distributed token symbol
     * @param _treasuryAddress The Treasury address
     */
    constructor(
        uint256 _presaleOpeningTime,
        uint256 _presaleClosingTime,
        uint256 _crowdsaleClosingTime,
        string memory _name,
        string memory _symbol,
        address _treasuryAddress
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        require(_treasuryAddress != address(0), "Treasury address is zero");
        require(
            _presaleOpeningTime >= block.timestamp,
            "Presale: opening time is before current time"
        );
        require(
            _presaleClosingTime > _presaleOpeningTime,
            "Presale: opening time is not before closing time"
        );
        require(
            _crowdsaleClosingTime > _presaleClosingTime,
            "Presale: crowdsale closing time is not before presale closing time"
        );

        treasuryAddress = _treasuryAddress;
        presaleOpeningTime = _presaleOpeningTime;
        presaleClosingTime = _presaleClosingTime;
        crowdsaleClosingTime = _crowdsaleClosingTime;

        _mint(treasuryAddress, tokenAmount);
        _pause();
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
        onlyPresalePeriod
        onlyOwner
    {
        require(_buyer != address(0), "Buyer address is zero");
        require(
            _numberOfTokens > 0 && _numberOfTokens <= limitPresale,
            "Out of token limit"
        );

        // Check that the limit of presale numberOfTokens hasn't been met yet
        require(
            tokensDistributedPresale + _numberOfTokens <= limitPresale,
            "Existing token amount exceeded"
        );

        tokensDistributedPresale += _numberOfTokens;

        if (tokenAmountPerInvestor[_buyer] == 0) {
            investorAddresses.push(_buyer);
        }

        tokenAmountPerInvestor[_buyer] += _numberOfTokens;
    }

    /**
     * @dev Transfer presale tokens to investors. Only the owner can do this
     */
    function releasePresaleTokens() external onlyOwner {
        require(tokensReleased < limitPresale);
        require(
            block.timestamp >= tokensReleaseDate,
            "Release time is not reached yet"
        );
        uint256 len = investorAddresses.length;
        for (uint256 i = 0; i < len; ++i) {
            address buyer = investorAddresses[i];
            require(buyer != address(0), "Release: investor doesn't exist");

            uint256 tokensAmountForInvestor = tokenAmountPerInvestor[buyer];
            uint256 releaseTokenAmount = (tokensAmountForInvestor *
                unlockPercentage) / 100;
            require(
                releaseTokenAmount > 0 &&
                    (tokensReleased + releaseTokenAmount) <= limitPresale
            );

            tokensReleased += releaseTokenAmount;
            transferFrom(treasuryAddress, buyer, releaseTokenAmount);
        }
        uint256 month = 30 * 24 * 60 * 60;
        tokensReleaseDate += month;
        if (unlockPercentage != unlockPercentagePerMonth) {
            unlockPercentage = unlockPercentagePerMonth;
        }
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
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpausing the token minting/approving/transfering. Only the owner can do this
     */
    function unpause() external onlyOwner {
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
     * minting and burning. Make sure Token can't be mint, burn or transfer
     * till the end of crowdsale
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

        bool allowed = block.timestamp > crowdsaleClosingTime && !paused();
        require(allowed, "ERC20Pausable: token transfer while paused");
    }
}
