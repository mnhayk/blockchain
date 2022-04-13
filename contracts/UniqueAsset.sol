// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract UniqueTokens is ERC721Enumerable, Ownable  {

    uint256 public cost = 1e18;

    event Received(address caller, uint amount, string message);
    event Refunded(address receiver, uint money);

    string private baseURI = "ipfs://QmUc94ZgGFTwQ1sCbb53iveYKkLzqgFEhvKcsZSCf1fzGS/";

    constructor() ERC721("UniqueToken", "UQT") {}

    function mint(address tokenReceiver) external payable {
        require(tokenReceiver != address(0), "UniqueTokens: Invalid receiver address");
        require(msg.value >= cost, "Less than price");
        if (totalSupply() < 10) {
            (bool success, ) = payable(tokenReceiver).call{value: cost}("");
             require(success, "Failed to send ETH");
             emit Refunded(tokenReceiver, cost);
        }
        _safeMint(tokenReceiver, totalSupply() + 1);
    }

    function withdraw(uint amount) external onlyOwner {
        uint currentBalance = address(this).balance;
        require(amount  <= currentBalance, "Not enough money");
        (bool success, ) = owner().call {value: amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value, "Receive was called");
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value, "Fallback was called");
    }

}