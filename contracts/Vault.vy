# @version 0.3.2
from vyper.interfaces import ERC20

import ERC4626 as ERC4626

implements: ERC20
implements: ERC4626

##### ERC20 #####

totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

NAME: constant(String[10]) = "Test Vault"
SYMBOL: constant(String[5]) = "vTEST"
DECIMALS: constant(uint8) = 18

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    allowance: uint256

##### ERC4626 #####

asset: public(ERC20)

event Deposit:
    depositor: indexed(address)
    receiver: indexed(address)
    amount: uint256

event Withdraw:
    withdrawer: indexed(address)
    receiver: indexed(address)
    amount: uint256


@external
def __init__(asset: ERC20):
    self.asset = asset


@view
@external
def name() -> String[10]:
    return NAME


@view
@external
def symbol() -> String[5]:
    return SYMBOL


@view
@external
def decimals() -> uint8:
    return DECIMALS


@external
def transfer(receiver: address, amount: uint256) -> bool:
    self.balanceOf[msg.sender] -= amount
    self.balanceOf[receiver] += amount
    log Transfer(msg.sender, receiver, amount)
    return True


@external
def approve(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] = amount
    log Approval(msg.sender, spender, amount)
    return True


@external
def transferFrom(sender: address, receiver: address, amount: uint256) -> bool:
    self.allowance[sender][msg.sender] -= amount
    self.balanceOf[sender] -= amount
    self.balanceOf[receiver] += amount
    log Transfer(sender, receiver, amount)
    return True


@view
@external
def totalAssets() -> uint256:
    return self.asset.balanceOf(self)


@view
@internal
def _calculateAssets(shareAmount: uint256) -> uint256:
    return shareAmount * self.asset.balanceOf(self) / self.totalSupply


@view
@external
def pricePerShare() -> uint256:
    return self._calculateAssets(10**convert(DECIMALS, uint256))


@view
@external
def assetsOf(owner: address) -> uint256:
    return self._calculateAssets(self.balanceOf[owner])


@view
@internal
def _calculateShares(assetAmount: uint256) -> uint256:
    return assetAmount * self.totalSupply / self.asset.balanceOf(self)


@view
@external
def previewDeposit(amount: uint256) -> (uint256, uint256):
    return amount, self._calculateShares(amount)


@external
def deposit(amount: uint256, receiver: address=msg.sender) -> uint256:
    shares: uint256 = self._calculateShares(amount)
    self.asset.transferFrom(msg.sender, self, amount)

    self.totalSupply += shares
    self.balanceOf[receiver] += shares
    log Deposit(msg.sender, receiver, amount)
    return shares


@view
@external
def previewMint(shares: uint256) -> (uint256, uint256):
    return self._calculateAssets(shares), shares


@external
def mint(shares: uint256, receiver: address=msg.sender) -> uint256:
    amount: uint256 = self._calculateAssets(shares)
    self.asset.transferFrom(msg.sender, self, amount)

    self.totalSupply += shares
    self.balanceOf[receiver] += shares
    log Deposit(msg.sender, receiver, amount)
    return amount


@view
@external
def previewWithdraw(amount: uint256) -> (uint256, uint256):
    return self._calculateShares(amount), amount


@external
def withdraw(amount: uint256, receiver: address=msg.sender, sender: address=msg.sender) -> uint256:
    shares: uint256 = self._calculateShares(amount)

    if sender != msg.sender:
        self.allowance[sender][msg.sender] -= shares

    self.totalSupply -= shares
    self.balanceOf[sender] -= shares

    self.asset.transfer(receiver, amount)
    log Withdraw(sender, receiver, amount)
    return shares


@view
@external
def previewRedeem(shares: uint256) -> (uint256, uint256):
    return shares, self._calculateAssets(shares)


@external
def redeem(shares: uint256, receiver: address=msg.sender, sender: address=msg.sender) -> uint256:
    if sender != msg.sender:
        self.allowance[sender][msg.sender] -= shares

    amount: uint256 = self._calculateAssets(shares)
    self.totalSupply -= shares
    self.balanceOf[sender] -= shares

    self.asset.transfer(receiver, amount)
    log Withdraw(sender, receiver, amount)
    return amount


@external
def DEBUG_steal_tokens(amount: uint256):
    # NOTE: This is the primary method of mocking share price changes
    self.asset.transfer(msg.sender, amount)
