// SAVING & LENDING APP FOR STREAMING INCOME
// A smart pool that enables investors to secure loans through locking their future-income streams.
// Instantiate the contract with a few

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT

// import ‘./SuperTokenInterface.sol’;

contract IncomeShareAgreement {
    mapping(address => uint256) public investorsAmounts;
    uint256 public totalValueLocked;

    //BORROWERS
    mapping(address => uint256) public addressToIncomeFlowRate;
    mapping(address => uint256) public monthlyIncome;
    mapping(address => uint256) public incomePercentage;
    mapping(address => uint256) public addressToTimeLocked;

    uint256 public inflowOutflowPoolRatio; //at least over 0.5??
    uint256 public minimumInvestableAmount;
    uint256 public maximumBorrowPercentage;
    uint public _minimumIncomeFlowRate;
    
    event Received(address, uint256);

    modifier onlyMembers() {
        require(!addressToIncomeFlowRate[msg.sender] == 0, "not member");
        _;
    }

    constructor(
        uint256 _minimumInvestableAmount,
        uint256 _maximumBorrowPercentage
    ) {
        minimumInvestableAmount = _minimumInvestableAmount;
        maximumBorrowPercentage = _maximumBorrowPercentage;
    }

    //deposit ether into the pool
    receive() external payable {
        emit Received(msg.sender, msg.value);
        //keep track of the ether
    }

    function calculateIncomePercentage(
        uint256 _amountToBorrow,
        uint256 _incomeFlowRate
    ) internal returns (uint256) {
        uint256 totalMoneyEarnedDuringLoan =
            monthlyIncome[address] * _loanDuration;
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

    function borrow(uint256 _borrowAmount) public onlyMembers() {
        require(
            addressToAmount[msg.sender] >= maximumBorrowAmount,
            "not enough money available to withdraw"
        );
        _calculateIncomePercentage();
    }

    function qualifyBorrower(
        uint _amountToBorrow,
        uint256 _monthlyIncome,
        uint256 _incomeFlowRate,
        uint256 _duration
    ) external {
        addressToIncomeFlowRate[msg.sender]
    }
}
