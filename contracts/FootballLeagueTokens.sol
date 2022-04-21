// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FootballLeagueTokens is ERC1155Supply, Ownable, ReentrancyGuard  {

    event Received(address caller, uint amount, string message);

    address public constant USDC = 0x2673C1Ec91e8cE64bE73248706Bf8db0475d46C2;

    uint16 private _maxAmountOfEachToken = 1000;
    uint8[] public tokenIds = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    uint public tokenPriceByEthereum = 1e16;
    uint public tokenPriceByUSDC = 30;
    
    constructor(string memory uri) ERC1155(uri) {}

    receive() external payable {
        emit Received(msg.sender, msg.value, "Contract get money");
    }

    function mintByETH(uint tokenId, uint amount) external payable nonReentrant {
        require(amount > 0, "Incorrect amount");
        require(msg.value >= tokenPriceByEthereum * amount, "Not enough ether");
        require(tokenId < tokenIds.length, "Token doesn't exist");
        require(totalSupply(tokenId) + amount <= 1000, "There is no such amount of tokens");
        
        uint[] memory ids = new uint[](1);
        ids[0] = tokenId;

        uint[] memory amounts = new uint[](1);
        amounts[0] = amount;

        _mintBatch(msg.sender, ids, amounts, "");
    }

   
    function mintByUSDC(uint usdcCount, uint tokenId, uint tokenAmount) external nonReentrant {
        require(tokenAmount > 0, "Incorrect amount");
        require(usdcCount >= tokenPriceByUSDC * tokenAmount, "Not enough usdc");
        require(tokenId < tokenIds.length, "Token doesn't exist");
        require(totalSupply(tokenId) + tokenAmount <= 1000, "There is no such amount of tokens");

        uint senderUSDCBalance = ERC20(USDC).balanceOf(msg.sender);
        require(usdcCount <= senderUSDCBalance, "USDC balance is low");

        bool success = ERC20(USDC).transferFrom(msg.sender, address(this), usdcCount);
        require(success, "USDC transfer failed");

        uint[] memory ids = new uint[](1);
        ids[0] = tokenId;

        uint[] memory amounts = new uint[](1);
        amounts[0] = tokenAmount;

        _mintBatch(msg.sender, ids, amounts, "");
    }

    function withdrawETH(uint amount) external onlyOwner {
        uint currentBalance = address(this).balance;
        require(amount  <= currentBalance, "Not enough ether");
        (bool success, ) = owner().call {value: amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function withdrawUSDC(uint amount) external onlyOwner {
        require(amount > 0, "Invalid amount");
        require(amount <= ERC20(USDC).balanceOf(address(this)), "Not enough usdc");

        bool success = ERC20(USDC).transferFrom(address(this), msg.sender, amount);
        require(success, "Failed to withdraw USDC");
    }
}