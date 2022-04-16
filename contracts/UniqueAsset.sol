// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract UniqueTokens is ERC721Enumerable, Ownable, ReentrancyGuard  {

    event  Deposit(address sender, uint amount);
    event Refunded(address sender, uint amount);

    uint256 public _tokenPrice = 1e16;
    string private _tokenBaseURI = "ipfs://QmUc94ZgGFTwQ1sCbb53iveYKkLzqgFEhvKcsZSCf1fzGS/";

    mapping(address => uint8) private _freeMintingAmountPerUser;

    constructor() ERC721("UniqueToken", "UQT") {}

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function mint() external payable nonReentrant {
        require(msg.value >= _tokenPrice, "Less than price");
        
        if (_freeMintingAmountPerUser[msg.sender] < 10) {
            (bool success, ) = payable(msg.sender).call{value: msg.value}("");

            require(success, "Failed to Refund ETH");
            emit Refunded(msg.sender, _tokenPrice);

            _freeMintingAmountPerUser[msg.sender] += 1;
        }

        _safeMint(msg.sender, totalSupply() + 1);
    }

    function withdraw(uint amount) external onlyOwner {
        uint currentBalance = address(this).balance;
        require(amount  <= currentBalance, "Not enough money");
        (bool success, ) = owner().call {value: amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function setBaseURI(string memory tokenBaseURI) external onlyOwner {
        _tokenBaseURI = tokenBaseURI;
    }
}