// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract UniqueTokens is ERC721Enumerable, Ownable  {

    event  Deposit(address sender, uint amount);
    event Refunded(address sender, uint amount);
    event Minted(address owner);

    uint256 public TokenPrice = 1e16;
    string private baseURI = "ipfs://QmUc94ZgGFTwQ1sCbb53iveYKkLzqgFEhvKcsZSCf1fzGS/";
    mapping(address => uint8) private freeMintingAmountPerUser;

    modifier validAddress() {
        require(msg.sender != address(0), "Not valid address");
        _;
    }    

    constructor() ERC721("UniqueToken", "UQT") {}

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function mint(address payable sender) external payable validAddress {
        require(msg.value >= TokenPrice, "Less than price");
        
        if (freeMintingAmountPerUser[sender] < 10) {
            (bool success, ) = payable(msg.sender).call{value: msg.value}("");
            
            require(success, "Failed to Refund ETH");
            emit Refunded(sender, TokenPrice);

            freeMintingAmountPerUser[sender] += 1;
        }

        _safeMint(sender, totalSupply() + 1);
        emit Minted(sender);
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
}