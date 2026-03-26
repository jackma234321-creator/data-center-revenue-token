// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title DataCenterRevenueToken
 * @dev ERC-20 token for a tokenised data centre revenue participation model.
 *
 * IMPORTANT:
 * This contract only represents tokenised units on-chain.
 * Actual ownership, revenue distribution, governance rights, and legal claims
 * must be defined separately through off-chain legal agreements.
 */
contract DataCenterRevenueToken is ERC20, Ownable, ERC20Burnable {
    uint256 public immutable maxSupply;
    uint256 public tokenPrice; // price per whole token in wei
    bool public saleActive;

    event TokensPurchased(address indexed buyer, uint256 tokenAmount, uint256 cost);
    event TokenPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event SaleStatusUpdated(bool status);
    event Withdrawn(address indexed owner, uint256 amount);

    constructor(
        address initialOwner,
        uint256 _maxSupply,
        uint256 _initialMint,
        uint256 _tokenPrice
    ) ERC20("DataCenterRevenueToken", "DCRT") Ownable(initialOwner) {
        require(_maxSupply > 0, "Max supply must be > 0");
        require(_initialMint <= _maxSupply, "Initial mint exceeds max supply");
        require(_tokenPrice > 0, "Token price must be > 0");

        maxSupply = _maxSupply;
        tokenPrice = _tokenPrice;
        saleActive = false;

        _mint(initialOwner, _initialMint);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
    }

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be > 0");
        uint256 oldPrice = tokenPrice;
        tokenPrice = newPrice;
        emit TokenPriceUpdated(oldPrice, newPrice);
    }

    function setSaleActive(bool status) external onlyOwner {
        saleActive = status;
        emit SaleStatusUpdated(status);
    }

    /**
     * @dev Buy tokens by specifying the number of whole tokens.
     * Example: tokenAmount = 10 means buying 10 DCRT.
     */
    function buyTokens(uint256 tokenAmount) external payable {
        require(saleActive, "Sale is not active");
        require(tokenAmount > 0, "Amount must be > 0");

        uint256 amountWithDecimals = tokenAmount * 10 ** decimals();
        uint256 cost = tokenAmount * tokenPrice;

        require(msg.value == cost, "Incorrect ETH sent");
        require(balanceOf(owner()) >= amountWithDecimals, "Owner has insufficient tokens");

        _transfer(owner(), msg.sender, amountWithDecimals);

        emit TokensPurchased(msg.sender, tokenAmount, cost);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        payable(owner()).transfer(balance);
        emit Withdrawn(owner(), balance);
    }
}
