pragma solidity ^0.4.18;

import "../token/ERC20/MintableToken.sol";
import "./CryptoYenInterface.sol";

contract CryptoYen is MintableToken {
  string public name = "CryptoYen testing token";
  string public symbol = "YEN";
  uint8 public decimals = 18;
}