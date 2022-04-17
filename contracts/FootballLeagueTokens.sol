// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FootballLeagueTokens is ERC1155, Ownable  {

    event Received(address caller, uint amount, string message);

    mapping (uint8 => uint16) private _tokenAmountPerId;
    uint16 private _maxAmountOfEachToken = 1000;
    
    uint8[] public tokenIds = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    uint public tokenPriceWithEthereum = 1e16;
    
    constructor(string memory uri) ERC1155(uri) {}

    receive() external payable {
        emit Received(msg.sender, msg.value, "Contract get money");
    }

    function mintETH(uint8 tokenId, uint16 amount) external payable {
        require(msg.value >= tokenPriceWithEthereum, "Not enough money");
        require(tokenId < tokenIds.length, "Token doesn't exist");
        require(_tokenAmountPerId[tokenId] < _maxAmountOfEachToken, "There is no such amount of tokens");
        
        uint[] memory ids = new uint[](tokenId);
        uint[] memory amounts = new uint[](amount);

        _mintBatch(msg.sender, ids, amounts, "");
        _tokenAmountPerId[tokenId] += amount;

    }

    function withdraw(uint amount) external onlyOwner {
        uint currentBalance = address(this).balance;
        require(amount  <= currentBalance, "Not enough money");
        (bool success, ) = owner().call {value: amount}("");
        require(success, "Failed to withdraw Ether");
    }


}