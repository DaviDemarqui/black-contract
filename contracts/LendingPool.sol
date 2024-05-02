// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract LendingPool {

    using SafeERC20 for IERC20;

    // Storage
    uint256 public liquidity;
    uint256 public interestRate;
    uint256 public totalSupplied;
    uint256 public totalBorrowed;

    IERC20 immutable public token;
    address immutable public creator;

    mapping(address => LiquidityProvider) providers;

    // structs
    struct LiquidityProvider {
        uint256 amount;
        address provider;
    }

    // Constructor, Functions and Modifiers
    constructor(
        IERC20 _token,
        address _creator
    ) {
        token = _token;
        creator = _creator;
    }

    modifier onlyLP {
        require(msg.sender == providers[msg.sender].provider, "The sender must be a provider to withdraw!");
        _;
    }

    function depositFunds(uint256 _amount) public {
        LiquidityProvider memory lp = providers[msg.sender]; 

        if (msg.sender == lp.provider) { 
            lp.amount += _amount; 
        } else {
            lp.amount = _amount;
            lp.provider = msg.sender;
        }

        liquidity += _amount;
        totalSupplied += _amount;
        providers[msg.sender] = lp;

        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdrawFunds(uint256 _amount) onlyLP public {
        LiquidityProvider memory lp = providers[msg.sender]; 
        require(_amount <= lp.amount, "The amount is more than provided");

        if(lp.amount == _amount) {
            delete providers[msg.sender];
        } else {
            lp.amount -= _amount;
            providers[msg.sender] = lp;
        }

        liquidity -= _amount;
        token.safeTransfer(msg.sender, _amount);
    }

}
