pragma solidity ^0.8;

import { IERC4626 } from "ERC4626.sol";
import { ERC20 } from "@OpenZeppelin/token/ERC20/ERC20.sol";

contract SolidityVault is IERC4626, ERC20 {
    address public asset;

    constructor(address _asset) ERC20("Test Vault", "vTEST") {
        asset = _asset;
    }

    function totalAssets() public view returns (uint256) {
        return ERC20(asset).balanceOf(address(this));
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) return 0;
        return shares * totalAssets() / _totalSupply;
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        uint256 _totalAssets = totalAssets();
        if (_totalAssets == 0 || _totalSupply == 0) return assets;
        return assets * _totalSupply / _totalAssets;
    }

    function maxDeposit(address receiver) external view returns (uint256) {
        return type(uint256).max;
    }

    function previewDeposit(uint256 assets) external view returns (uint256) {
        return convertToShares(assets);
    }

    function deposit(uint256 assets, address receiver) public returns (uint256) {
        uint256 shares = convertToShares(assets);
        ERC20(asset).transferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);

        return shares;
    }

    function deposit(uint256 assets) external returns (uint256) {
        return deposit(assets, msg.sender);
    }

    function maxMint(address receiver) external view returns (uint256) {
        return type(uint256).max;
    }

    function previewMint(uint256 shares) external view returns (uint256) {
        uint256 assets = convertToAssets(shares);
        if (assets == 0 && totalAssets() == 0) return shares;
        return assets;
    }

    function mint(uint256 shares, address receiver) public returns (uint256) {
        uint256 assets = convertToAssets(shares);

        if (totalAssets() == 0) assets = shares;

        ERC20(asset).transferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);

        return assets;
    }

    function mint(uint256 shares) external returns (uint256) {
        return mint(shares, msg.sender);
    }

    function maxWithdraw(address owner) external view returns (uint256) {
        return type(uint256).max;
    }

    function previewWithdraw(uint256 assets) external view returns (uint256) {
        uint256 shares = convertToShares(assets);
        if (totalSupply() == 0) return 0;
        return shares;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        public
        returns (uint256)
    {
        uint256 shares = convertToShares(assets);

        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);

        ERC20(asset).transfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }

    function withdraw(uint256 assets, address receiver) external returns (uint256) {
        return withdraw(assets, receiver, msg.sender);
    }

    function withdraw(uint256 assets) external returns (uint256) {
        return withdraw(assets, msg.sender, msg.sender);
    }

    function maxRedeem(address owner) external view returns (uint256) {
        return type(uint256).max;
    }

    function previewRedeem(uint256 shares) external view returns (uint256) {
        return convertToAssets(shares);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    )
        public
        returns (uint256)
    {
        uint256 assets = convertToAssets(shares);

        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);

        ERC20(asset).transfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }

    function redeem(uint256 shares, address receiver) external returns (uint256) {
        return redeem(shares, receiver, msg.sender);
    }

    function redeem(uint256 shares) external returns (uint256) {
        return redeem(shares, msg.sender, msg.sender);
    }

    function DEBUG_steal_tokens(uint256 amount) external {
        ERC20(asset).transfer(msg.sender, amount);
    }
}
