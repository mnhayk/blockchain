// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DappToken is ERC20PresetMinterPauser, Ownable {

    uint8 private tokenDecimals;

    constructor(string memory _name, string memory _symbol, uint8 _decimals)
        ERC20PresetMinterPauser(_name, _symbol) {
            tokenDecimals = _decimals;
        }

    function decimals() public view virtual override returns (uint8) {
        return tokenDecimals;
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        super.transferOwnership(newOwner);
        super.grantRole(MINTER_ROLE, newOwner);
        super.grantRole(PAUSER_ROLE, newOwner);
    }
}