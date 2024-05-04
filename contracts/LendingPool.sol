// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract LendingPool {

    using SafeERC20 for IERC20;

    // Storage
    uint256 public liquidity;
    uint256 public fixedInterestRate;
    uint256 public totalSupplied;
    uint256 public totalBorrowed;

    IERC20 immutable public token;
    address immutable public creator;

    mapping(address => LiquidityProvider) providers;

    // structs and Enums
    enum LoanStatus {
        ACTIVE,
        REPAID,
        DEFAULTED
    }
    struct Loan {
        uint256 amount;
        address borrower;
        uint256 collateral;
        uint256 interestRate;
        uint256 loanDuration;
        LoanStatus loanStatus;
    }
    struct LiquidityProvider {
        uint256 amount;
        address provider;
    }

    // Constructor, Functions and Modifiers
    constructor(
        IERC20 _token,
        address _creator,
        uint256 _initialIP
    ) {
        token = _token;
        creator = _creator;
        interestRate = _initialIP;
    }

    modifier onlyLP {
        require(msg.sender == providers[msg.sender].provider, "The sender must be a provider to withdraw!");
        _;
    }

    function getLP() public view returns(LiquidityProvider memory lp) {
        lp = providers[msg.sender];
        return lp;
    }

    function getPoolBalance() public view returns(uint256) {
        return liquidity;
    }

    function getTotalSupplied() public view returns(uint256){
        return totalSupplied;
    }

    function supplyFunds(uint256 _amount) public {
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

    function borrow(uint256 _amount, uint256 _collateral, uint256 _duration) public {
        require(_amount == _collateral, "Invalid Collateral");
        Loan memory newLoad = Loan({
            amount: _amount,
            borrower: msg.sender,
            collateral: _collateral,
            interestRate: calculateInterestRate(_amount, _duaration),
            loanDuration: _duaration,
            loanStatus: LoanStatus.ACTIVE
        });

        liquidity -= _amount;
        totalBorrowed += _amount;
        token.safeTransfer(msg.sender, _amount);
    }

    function payLoan() public {

    }

    // Calulate the interest rate when needed
    // this function is only called by other
    // functions in this contract
    function calculateInterestRate(uint256 _amount, uint256 _loanDuration) internal {
        return (_amount * fixedInterestRate * _loanDuration) / 365;
    }

}
