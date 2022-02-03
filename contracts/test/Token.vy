# @version 0.3.1
from vyper.interfaces import ERC20

implements: ERC20

totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

NAME: constant(String[10]) = "Test Token"
SYMBOL: constant(String[4]) = "TEST"
DECIMALS: constant(uint8) = 18

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    allowance: uint256


@view
@external
def name() -> String[10]:
    return NAME


@view
@external
def symbol() -> String[4]:
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


@external
def DEBUG_mint(receiver: address, amount: uint256):
    self.balanceOf[receiver] += amount
    self.totalSupply += amount
