// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract STMPToken is ERC20, Ownable {
   
    uint public closingTime;
    address public crowdsaleAddress;

    modifier onlyCrowdsale {
        require(msg.sender == crowdsaleAddress);
        _;
    }

    modifier afterCrowdsale {
        require(block.timestamp > closingTime || msg.sender == crowdsaleAddress);
        _;
    }

    constructor (uint _closingTime, string memory name, string memory symbol) ERC20(name, symbol) {
        require(_closingTime > 0);
        closingTime = _closingTime;
    }

    function mint(address account, uint256 amount) public onlyCrowdsale {
        _mint(account, amount);
    }

    function setCrowdsale(address _crowdsaleAddress) public onlyOwner {
      require(_crowdsaleAddress != address(0));
      crowdsaleAddress = _crowdsaleAddress;
    }

/// @notice Override the functions to not allow token transfers until the end of the ICO
    function transfer(address _to, uint256 _value) public override  afterCrowdsale returns(bool) {
        return super.transfer(_to, _value);
    }

/// @notice Override the functions to not allow token transfers until the end of the ICO
    function transferFrom(address _from, address _to, uint256 _value) public override afterCrowdsale returns(bool) {
         return super.transferFrom(_from, _to, _value);
    }

/// @notice Override the functions to not allow token transfers until the end of the ICO
    function approve(address _spender, uint256 _value) public override afterCrowdsale returns(bool) {
        return super.approve(_spender, _value);
    }

/// @notice Override the functions to not allow token transfers until the end of the ICO
    function increaseAllowance(address _spender, uint _addedValue) public override afterCrowdsale returns(bool success) {
        return super.increaseAllowance(_spender, _addedValue);
    }

/// @notice Override the functions to not allow token transfers until the end of the ICO
    function decreaseAllowance(address _spender, uint _subtractedValue) public override afterCrowdsale returns(bool success) {
        return super.decreaseAllowance(_spender, _subtractedValue);
    }

    function emergencyExtract() external onlyOwner {
        (bool success, ) = owner().call {value: address(this).balance}("");
        require(success, "Failed to withdraw Ether");
    }
}