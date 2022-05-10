// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FootballTokens is ERC1155Supply, Ownable, ReentrancyGuard  {
    
    uint128 public maxTokenId; 
    uint128 public maxAmountOfEachToken;
    uint public tokenPriceByWei;
    uint public tokenPriceByPaymentToken;
    address public paymentTokenAddress;
    string public baseURI;
    


    event Received(address caller, uint amount, string message);

    constructor(uint128 _maxTokenId, 
                uint128 _maxAmountOfEachToken,
                uint _tokenPriceByWei, 
                uint _tokenPriceByPaymentToken, 
                address _paymentTokenAddress,
                string memory _uri) ERC1155(_uri) {
                    
        maxTokenId = _maxTokenId;
        maxAmountOfEachToken = _maxAmountOfEachToken;
        tokenPriceByWei = _tokenPriceByWei;
        tokenPriceByPaymentToken = _tokenPriceByPaymentToken;
        paymentTokenAddress = _paymentTokenAddress;
        baseURI = _uri;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value, "Contract get money");
    }

    function mintByETH(uint tokenId, uint amount) external payable nonReentrant {
        require(msg.value >= tokenPriceByWei * amount, "Not enough ether");
        require(tokenId <= maxTokenId, "Incorrect tokenId");
        require(totalSupply(tokenId) + amount <= maxAmountOfEachToken, "Max supply is exceeded");

        _mint(msg.sender, tokenId, amount, "");

    }

    function mintByPaymentToken(uint tokenId, uint amount) external nonReentrant {
        require(tokenId <= maxTokenId, "Incorrect tokenId");
        require(totalSupply(tokenId) + amount <= maxAmountOfEachToken, "Max supply is exceeded");

        IERC20(paymentTokenAddress).transferFrom(msg.sender, address(this), tokenPriceByPaymentToken * amount);

        _mint(msg.sender, tokenId, amount, "");
    }

    function withdrawETH(uint amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough ether");
        (bool success, ) = owner().call {value: amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function withdrawPaymentToken(address tokenAddress, uint amount) external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }
}
