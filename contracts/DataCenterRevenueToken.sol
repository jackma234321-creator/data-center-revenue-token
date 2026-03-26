// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// OpenZeppelin imports
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title DataCenterRevenueToken
 * @dev ERC-20 token for a tokenised data centre revenue participation model.
 *
 * IMPORTANT:
 * This smart contract only represents tokenised units on-chain.
 * Actual ownership, revenue distribution, governance rights, and legal claims
 * must be defined separately through off-chain legal agreements.
 */
contract DataCenterRevenueToken is ERC20, Ownable, ERC20Burnable {
    // Maximum supply cap
    uint256 public immutable maxSupply;

    // Token sale price in wei
    uint256 public tokenPrice;

    // Whether public sale is active
    bool public saleActive;

    // Events
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event TokenPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event SaleStatusUpdated(bool status);
    event Withdrawn(address indexed owner, uint256 amount);

    /**
     * @param initialOwner Owner address
     * @param _maxSupply Maximum token supply (including decimals)
     * @param _initialMint Initial supply minted to owner
     * @param _tokenPrice Token price in wei
     */
    constructor(
        address initialOwner,
        uint256 _maxSupply,
        uint256 _initialMint,
        uint256 _tokenPrice
    ) ERC20("DataCenterRevenueToken", "DCRT") Ownable(initialOwner) {
        require(_maxSupply > 0, "Max supply must be > 0");
        require(_initialMint <= _maxSupply, "Initial mint exceeds max supply");

        maxSupply = _maxSupply;
        tokenPrice = _tokenPrice;
        saleActive = false;

        _mint(initialOwner, _initialMint);
    }

    /**
     * @dev Mint new tokens to a specific address.
     * Only owner can mint, subject to max supply cap.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
    }

    /**
     * @dev Update token sale price.
     */
    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be > 0");
        uint256 oldPrice = tokenPrice;
        tokenPrice = newPrice;
        emit TokenPriceUpdated(oldPrice, newPrice);
    }

    /**
     * @dev Toggle public sale status.
     */
    function setSaleActive(bool status) external onlyOwner {
        saleActive = status;
        emit SaleStatusUpdated(status);
    }

    /**
     * @dev Public purchase function for demo purposes.
     * Buyers send ETH to receive DCRT from owner-held supply.
     */
    function buyTokens(uint256 amount) external payable {
        require(saleActive, "Sale is not active");
        require(amount > 0, "Amount must be > 0");

        uint256 cost = amount * tokenPrice;
        require(msg.value == cost, "Incorrect ETH sent");
        require(balanceOf(owner()) >= amount, "Owner has insufficient tokens");

        _transfer(owner(), msg.sender, amount);

        emit TokensPurchased(msg.sender, amount, cost);
    }

    /**
     * @dev Withdraw ETH collected from token purchases.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        payable(owner()).transfer(balance);
        emit Withdrawn(owner(), balance);
    }
}
