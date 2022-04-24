// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FootballLeagueTokens is ERC1155Supply, Ownable, ReentrancyGuard  {
    
    uint private _maxTokenId;
    uint private _maxAmountOfEachToken;
    uint public tokenPriceByWei;
    uint public tokenPriceByUSDC;
    ERC20 public USDCTokenAddress;

    event Received(address caller, uint amount, string message);

    constructor(uint maxTokenId, 
                uint maxAmountOfEachToken,
                uint _tokenPriceByWei, 
                uint _tokenPriceByUSDC, 
                ERC20 _USDCTokenAddress,
                string memory uri) ERC1155(uri) {
                    
        _maxTokenId = maxTokenId;
        _maxAmountOfEachToken = maxAmountOfEachToken;
        tokenPriceByWei = _tokenPriceByWei;
        tokenPriceByUSDC = _tokenPriceByUSDC;
        USDCTokenAddress = _USDCTokenAddress;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value, "Contract get money");
    }

    function mintByETH(uint tokenId, uint amount) external payable nonReentrant {
        require(amount > 0, "Incorrect amount");
        require(msg.value >= tokenPriceByWei * amount, "Not enough ether");
        require(tokenId <= _maxTokenId, "tokenId should be smaller from 10");
        require(totalSupply(tokenId) + amount <= _maxAmountOfEachToken, "Generating Token Amount is exceeded");

        _mint(msg.sender, tokenId, amount, "");

    }

    function mintByUSDC(uint tokenId, uint amount) external nonReentrant {
        require(amount > 0, "Incorrect amount");
        require(tokenId <= _maxTokenId, "Incorrect tokenId");
        require(totalSupply(tokenId) + amount <= _maxAmountOfEachToken, "Generating Token Amount is exceeded");

        bool success = USDCTokenAddress.transferFrom(msg.sender, address(this), tokenPriceByUSDC * amount);
        require(success, "USDC transfer failed");

        _mint(msg.sender, tokenId, amount, "");
    }

    function withdrawETH(uint amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough ether");
        (bool success, ) = owner().call {value: amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function withdrawUSDC(uint amount) external onlyOwner {
        require(amount > 0, "Invalid amount");
        bool success = USDCTokenAddress.transferFrom(address(this), msg.sender, amount);
        require(success, "Failed to withdraw USDC");
    }
}
