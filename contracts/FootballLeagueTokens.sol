// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FootballLeagueTokens is ERC1155Supply, Ownable, ReentrancyGuard  {
    
    uint public maxTokenId;
    uint public maxAmountOfEachToken;
    uint public tokenPriceByWei;
    uint public tokenPriceByPaymentToken;
    address public paymentTokenAddress;

    event Received(address caller, uint amount, string message);

    constructor(uint _maxTokenId, 
                uint _maxAmountOfEachToken,
                uint _tokenPriceByWei, 
                uint _tokenPriceByPaymentToken, 
                address _paymentTokenAddress,
                string memory uri) ERC1155(uri) {
                    
        maxTokenId = _maxTokenId;
        maxAmountOfEachToken = _maxAmountOfEachToken;
        tokenPriceByWei = _tokenPriceByWei;
        tokenPriceByPaymentToken = _tokenPriceByPaymentToken;
        paymentTokenAddress = _paymentTokenAddress;
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

        bool success = IERC20(paymentTokenAddress).transferFrom(msg.sender, address(this), tokenPriceByPaymentToken * amount);
        require(success, "Payment Token transfer failed");

        _mint(msg.sender, tokenId, amount, "");
    }

    function withdrawETH(uint amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough ether");
        (bool success, ) = owner().call {value: amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function withdrawPaymentToken(address tokenAddress, uint amount) external onlyOwner {
        bool success = IERC20(tokenAddress).transferFrom(address(this), msg.sender, amount);
        require(success, "Failed to withdraw PaymentToken");
    }
}
