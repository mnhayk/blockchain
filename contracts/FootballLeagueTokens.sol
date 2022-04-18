// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

contract FootballLeagueTokens is ERC1155, Ownable, ReentrancyGuard  {

    event Received(address caller, uint amount, string message);

    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    uint16 private _maxAmountOfEachToken = 1000;
    uint8[] public tokenIds = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    uint public tokenPriceByEthereum = 1e16;
    uint public tokenPriceByUSDC = 30;
    mapping(address => uint) public usdcBalance;
    
    constructor(string memory uri) ERC1155(uri) {}

    receive() external payable {
        emit Received(msg.sender, msg.value, "Contract get money");
    }

    function mintByETH(uint8 tokenId, uint16 amount) external payable nonReentrant {
        require(msg.value >= tokenPriceByEthereum * amount, "Not enough ether");
        require(tokenId < tokenIds.length, "Token doesn't exist");
        require(balanceOf(msg.sender, tokenId) + amount <= _maxAmountOfEachToken, "There is no such amount of tokens");
        
        uint[] memory ids = new uint[](1);
        ids[0] = tokenId;

        uint[] memory amounts = new uint[](1);
        amounts[0] = amount;

        _mintBatch(msg.sender, ids, amounts, "");
    }

   
    function mintByUSDC(uint usdcCount, uint8 tokenId, uint16 tokenAmount) external nonReentrant {
        require(usdcCount >= tokenPriceByUSDC * tokenAmount, "Not enough usdc");
        require(tokenId < tokenIds.length, "Token doesn't exist");
        require(balanceOf(msg.sender, tokenId) + tokenAmount <= _maxAmountOfEachToken, "There is no such amount of tokens");

        ERC20(USDC).transferFrom(msg.sender, address(this), tokenAmount);
        usdcBalance[msg.sender] = usdcBalance[msg.sender] + tokenAmount;
    }

    function withdraw(uint amount) external onlyOwner {
        uint currentBalance = address(this).balance;
        require(amount  <= currentBalance, "Not enough money");
        (bool success, ) = owner().call {value: amount}("");
        require(success, "Failed to withdraw Ether");
    }
}