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
    assets: uint256
    shares: uint256

event Withdraw:
    withdrawer: indexed(address)
    receiver: indexed(address)
    assets: uint256
    shares: uint256


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
    totalSupply: uint256 = self.totalSupply
    if totalSupply == 0:
        return 0

    # NOTE: `shareAmount = 0` is extremely rare case, not optimizing for it
    # NOTE: `totalAssets = 0` is extremely rare case, not optimizing for it
    return shareAmount * self.asset.balanceOf(self) / totalSupply


@view
@external
def assetsPerShare() -> uint256:
    assets: uint256 = self._calculateAssets(10**convert(DECIMALS, uint256))

    if assets == 0 and self.asset.balanceOf(self) == 0:
        return 10**convert(DECIMALS, uint256)  # NOTE: Assume 1:1 price if nothing deposited yet

    return assets


@view
@external
def assetsOf(owner: address) -> uint256:
    return self._calculateAssets(self.balanceOf[owner])


@view
@internal
def _calculateShares(assetAmount: uint256) -> uint256:
    totalSupply: uint256 = self.totalSupply
    totalAssets: uint256 = self.asset.balanceOf(self)
    if totalAssets == 0 or totalSupply == 0:
        return assetAmount  # 1:1 price

    # NOTE: `assetAmount = 0` is extremely rare case, not optimizing for it
    return assetAmount * totalSupply / totalAssets


@view
@external
def maxDeposit() -> uint256:
    return MAX_UINT256


@view
@external
def previewDeposit(assets: uint256) -> uint256:
    return self._calculateShares(assets)


@external
def deposit(assets: uint256, receiver: address=msg.sender) -> uint256:
    shares: uint256 = self._calculateShares(assets)
    self.asset.transferFrom(msg.sender, self, assets)

    self.totalSupply += shares
    self.balanceOf[receiver] += shares
    log Deposit(msg.sender, receiver, assets, shares)
    return shares


@view
@external
def maxMint() -> uint256:
    return MAX_UINT256


@view
@external
def previewMint(shares: uint256) -> uint256:
    assets: uint256 = self._calculateAssets(shares)

    if assets == 0 and self.asset.balanceOf(self) == 0:
        return shares  # NOTE: Assume 1:1 price if nothing deposited yet

    return assets


@external
def mint(shares: uint256, receiver: address=msg.sender) -> uint256:
    assets: uint256 = self._calculateAssets(shares)

    if assets == 0 and self.asset.balanceOf(self) == 0:
        assets = shares  # NOTE: Assume 1:1 price if nothing deposited yet

    self.asset.transferFrom(msg.sender, self, assets)

    self.totalSupply += shares
    self.balanceOf[receiver] += shares
    log Deposit(msg.sender, receiver, assets, shares)
    return assets


@view
@external
def maxWithdraw() -> uint256:
    return MAX_UINT256  # real max is `self.asset.balanceOf(self)`


@view
@external
def previewWithdraw(assets: uint256) -> uint256:
    shares: uint256 = self._calculateShares(assets)

    # NOTE: Vyper does lazy eval on if, so this avoids SLOADs most of the time
    if shares == assets and self.totalSupply == 0:
        return 0  # NOTE: Nothing to redeem

    return shares


@external
def withdraw(assets: uint256, receiver: address=msg.sender, sender: address=msg.sender) -> uint256:
    shares: uint256 = self._calculateShares(assets)

    # NOTE: Vyper does lazy eval on if, so this avoids SLOADs most of the time
    if shares == assets and self.totalSupply == 0:
        raise  # Nothing to redeem

    if sender != msg.sender:
        self.allowance[sender][msg.sender] -= shares

    self.totalSupply -= shares
    self.balanceOf[sender] -= shares

    self.asset.transfer(receiver, assets)
    log Withdraw(sender, receiver, assets, shares)
    return shares


@view
@external
def maxRedeem() -> uint256:
    return MAX_UINT256  # real max is `self.totalSupply`


@view
@external
def previewRedeem(shares: uint256) -> uint256:
    return self._calculateAssets(shares)


@external
def redeem(shares: uint256, receiver: address=msg.sender, sender: address=msg.sender) -> uint256:
    if sender != msg.sender:
        self.allowance[sender][msg.sender] -= shares

    assets: uint256 = self._calculateAssets(shares)
    self.totalSupply -= shares
    self.balanceOf[sender] -= shares

    self.asset.transfer(receiver, assets)
    log Withdraw(sender, receiver, assets, shares)
    return assets


@external
def DEBUG_steal_tokens(amount: uint256):
    # NOTE: This is the primary method of mocking share price changes
    self.asset.transfer(msg.sender, amount)
