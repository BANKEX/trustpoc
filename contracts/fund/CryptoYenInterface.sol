pragma solidity ^0.4.18;

import "../token/ERC20/ERC20.sol";

contract CryptoYenInterface is ERC20 {
    function transferOwnership(address newOwner) public;
    function mint(address _to, uint256 _amount) public returns (bool);
    function finishMinting() public returns (bool);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
}