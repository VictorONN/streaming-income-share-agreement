// SAVING & LENDING APP FOR STREAMING INCOME
// A smart contract that enables people to secure loans from investors by locking their future-income streams using Superfluid constant flow agreements.
// Instantiate the contract with a few

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT

// import ‘./SuperTokenInterface.sol’;

contract IncomeShareAgreement {
    mapping(address => uint256) public investorsAmounts;
    uint256 public totalValueLocked;
    uint256 public totalValueBorrowed;

    //BORROWERS
    mapping(address => uint256) public outstandingBorrowers;
    // mapping(address => uint256) public addressToIncomeFlowRate;
    // mapping(address => uint256) public monthlyIncome;
    // mapping(address => uint256) public incomePercentage;
    // mapping(address => uint256) public addressToTimeLocked;

    // uint256 public inflowOutflowPoolRatio; //at least over 0.5??
    uint256 public minimumInvestableAmount;
    uint256 public maximumBorrowPercentage;
    uint256 public minimumIncomeFlowRate;
    uint256 public interestRate;

    event Received(address, uint256);

    constructor(
        uint256 _minimumInvestableAmount,
        uint256 _maximumBorrowPercentage,
        uint256 _minimumIncomeFlowRate,
        uint256 _interestRate
    ) {
        minimumInvestableAmount = _minimumInvestableAmount;
        maximumBorrowPercentage = _maximumBorrowPercentage;
        minimumIncomeFlowRate = _minimumIncomeFlowRate;
        interestRate = _interestRate;
    }

    //    function savingsToBorrowRatio(
    //         uint256 totalValueLocked,
    //         uint256 totalValueBorrowed
    //     ) internal returns (uint256) {
    //         uint256 ratio = totalValueBorrowed / totalValueLocked;
    //         return ratio;
    //     }

    // //deposit ether into the pool
    // receive() external payable {
    //     emit Received(msg.sender, msg.value);
    //     //keep track of the ether
    // }

    function calculateIncomePercentage(
        uint256 _amountToBorrow,
        uint256 _incomePerSecond,
        uint256 _incomeFlowRate
    ) internal returns (uint256) {
        uint256 loanDuration = _amountToBorrow / _incomeFlowRate;
        uint256 totalMoneyEarnedDuringLoan = incomePerSecond * loanDuration;
        uint256 borrowPercent =
            (_amountToBorrow / totalMoneyEarnedDuringLoan) * 100;
        require(
            borrowPercent <= maximumBorrowPercentage,
            "reduce amount to Borrow"
        );
        return borrowPercent;
    }

    //Investors deposit other tokens
    //higher interest rate
    function supplyFullAmount(address _superToken, uint256 _amount) external {
        require(_amount >= minimumInvestableAmount, "amount too low");
        SuperToken superToken = SuperToken(_superToken);
        IERC20(_superToken).approve(address(this), _mount);
        superToken.transfer{value: _amount}(address(this));
        totalValueLocked += _amount;
    }

    //lower interest rate
    //to be called externally by other contracts
    function supplyStream(address superToken, uint256 _amount) external {
        //initiate Superfluidstream to address(this)
        totalValueLocked += _amount;
    }

    // function qualifyBorrower(
    //     uint256 _amountToBorrow,
    //     uint256 _incomePerSecond,
    //     uint256 _incomeFlowRate //repaying suggested
    // ) internal {
    //     uint256 borrowPercent =
    //         calculateIncomePercentage(_amountToBorrow, _incomeFlowRate);
    //     require(
    //         borrowPercent <= maximumBorrowPercentage,
    //         "above borrow limit, reduce borrowAmount"
    //     );
    //     // addressToIncomeFlowRate[msg.sender] = _incomeFlowRate;
    //     qualifiedToBorrow[msg.sender] = true;
    // }

    function borrow(
        uint256 _amountToBorrow,
        uint256 _incomePerSecond,
        uint256 _incomeFlowRate
    ) public {
        uint256 borrowPercent =
            calculateIncomePercentage(_amountToBorrow, _incomeFlowRate);
        require(
            borrowPercent <= maximumBorrowPercentage,
            "above borrow limit, reduce borrowAmount"
        );
        payable(msg.sender).transfer(_amountToBorrow);
        repayBorrow(_amountBorrowed);
        outstandingBorrowers[msg.sender] = _amountToBorrow;
    }

    function repayBorrow(uint256 _amountBorrowed) internal {
        amountToPay = _amountBorrowed + interestRate * _amountBorrowed;
        //SUPERFLUID STREAM TO TRANSFER FUNDS INSTEAD OF TRANSFERFROM
        address(this).transferFrom(msg.sender, _amountBorrowed);
    }
}
