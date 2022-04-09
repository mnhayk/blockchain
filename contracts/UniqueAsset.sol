// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract UniqueTokens is ERC721Enumerable, Ownable  {
    uint256 public cost = 1e16 wei;

    event Received(address caller, uint amount, string message);

    constructor() ERC721("UniqueToken", "UQT") {}

    function mint(address tokenReceiver) external payable {
        require(tokenReceiver != address(0), "UniqueTokens: Invalid receiver address");
        require(msg.value >= cost, "Less than price");
        (bool success, ) = payable(address(this)).call{value: cost}("");
        require(success, "Failed to send ETH");
        _safeMint(tokenReceiver, totalSupply() + 1);
    }

    function withdraw(uint amount) external onlyOwner {
        uint currentBalance = address(this).balance;
        require(amount  <= currentBalance, "Not enough money");
        (bool success, ) = owner().call {value: amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://Qmcejucyec37bo4hAKN25TpG4BWSoH5ZA8RJ3bC6PVpaNK/";
    }

    receive() external payable {
        emit Received(msg.sender, msg.value, "Receive was called");
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value, "Fallback was called");
    }

}
