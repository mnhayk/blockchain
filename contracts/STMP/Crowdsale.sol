// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Crowdsale is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // The token being sold
    IERC20 private _token;

    // Address where funds are collected
    address payable private _wallet;

    // Address where USD Coints are collected
    address private _usdcWallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    // Amount of token raised  >>>> By Hayk
    uint256 private _tokenRaised;

    // Amount of USDC token raised  >>>> By Hayk
    uint256 private _usdcRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value usdc sent for tokens
     * @param amount amount of tokens purchased
     */
    event TokensPurchasedWithUSDC(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     *@dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param rate_ Number of token units a buyer gets per wei
     * @param wallet_ Address where collected funds will be forwarded to
     * @param usdcWallet_ Address where collected USDC will be forwarded to
     * @param token_ Address of the token being sold
     */
    constructor (uint256 rate_, address payable wallet_, address usdcWallet_, IERC20 token_)  {
        require(rate_ > 0, "Crowdsale: rate is 0");
        require(wallet_ != address(0), "Crowdsale: wallet is the zero address");
        require(usdcWallet_ != address(0), "Crowdsale: usdc wallet is the zero address");
        require(address(token_) != address(0), "Crowdsale: token_ is the zero address");

        _rate = rate_;
        _wallet = wallet_;
        _usdcWallet = usdcWallet_;
        _token = token_;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    fallback() external payable {
        buyTokens(_msgSender());
    }

    receive() external payable {
        buyTokens(_msgSender());
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the address where USDC are collected.
     */
    function usdcWallet() public view returns (address) {
        return _usdcWallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    // By Hayk
    /**
     * @param rate_ number of token units a buyer gets per wei.
     */
    function setRate(uint256 rate_) public {
        require(rate_ > 0, "Rate should be positive");
        _rate = rate_;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @return the amount of token raised.
     */
    function tokenRaised() public view returns (uint256) {
        return _tokenRaised;
    }

    /**
     * @return the amount of USDC token raised.
     */
    function usdcRaised() public view returns (uint256) {
        return _usdcRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        //TODO, Added by Hayk should be discussed refunded part
        (uint256 tokens, uint256 weiRefund) = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised + weiAmount - weiRefund;
        _tokenRaised = _tokenRaised + tokens;

        _processPurchase(beneficiary, tokens, weiRefund);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     * @param usdcAmount USDC sent for buying tokens
     */
    function buyTokensWithUSDC(address beneficiary, uint256 usdcAmount) public nonReentrant {
        _preValidatePurchase(beneficiary, usdcAmount);

        // calculate token amount to be created
        // TODO: I believe we should check refundable part as well and subtract from 'usdcAmount'
        (uint256 tokens, uint256 usdcRefund) = _getTokenAmountPayedWithUsdc(usdcAmount);

        // update state
        _usdcRaised = _usdcRaised + usdcAmount - usdcRefund;
        _tokenRaised = _tokenRaised + tokens;

        _processPurchaseWithUsdc(beneficiary, tokens, usdcRefund);
        emit TokensPurchasedWithUSDC(_msgSender(), beneficiary, usdcAmount, tokens);

        _updatePurchasingState(beneficiary, usdcAmount);

        _forwardFundsWithUSDC(usdcAmount);
        _postValidatePurchase(beneficiary, usdcAmount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal virtual {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal virtual {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount, uint256 weiRefund) internal virtual {
        _deliverTokens(beneficiary, tokenAmount);

        (bool success, ) = beneficiary.call{value: weiRefund}("");
        require(success, "Refund failed");
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchaseWithUsdc(address beneficiary, uint256 tokenAmount, uint256 usdcRefund) internal virtual {
        _deliverTokens(beneficiary, tokenAmount);

        //TODO: should transfer usdc back to beneficiary

    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return tokenAmount tokenAmount of tokens that can be purchased with the specified _weiAmount
     * @return weiRefund amount of wei which is refunded because of exceeding limit
     */
    function _getTokenAmount(uint256 weiAmount) internal view virtual returns (uint256 tokenAmount, uint256 weiRefund) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which USDC is converted to tokens.
     * @return tokenAmount tokenAmount of tokens that can be purchased with the specified usdc amount
     * @return usdcRefund amount of usdc which is refunded because of exceeding limit
     */
    function _getTokenAmountPayedWithUsdc(uint256 usdcAmount) internal view virtual returns (uint256 tokenAmount, uint256 usdcRefund) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal virtual {
        _wallet.transfer(msg.value);
    }

    /**
     * @dev Determines how USDC is stored/forwarded on purchases.
     * @param usdcAmount Amount of USDC to saved
     */
    function _forwardFundsWithUSDC(uint256 usdcAmount) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }
}
