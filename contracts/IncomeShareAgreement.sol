pragma solidity 0.8.0;
// SPDX-License-Identifier: MIT

import {
    ISuperfluid,
    ISuperToken,
    ISuperApp,
    ISuperAgreement,
    SuperAppDefinitions
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol"; //"@superfluid-finance/ethereum-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {
    IConstantFlowAgreementV1
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {
    SuperAppBase
} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

contract IncomeShareAgreement is SuperAppBase {
    mapping(address => uint256) public investorsAmounts;
    uint256 public totalValueLocked;
    uint256 public totalValueBorrowed;

    //BORROWERS
    mapping(address => uint256) public outstandingBorrowers;

    uint256 public minimumInvestableAmount;
    uint256 public maximumBorrowPercentage;
    uint256 public minimumIncomeFlowRate;
    uint256 public interestRate;

    event Received(address, uint256);

    ISuperfluid private _host; // host
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    ISuperToken private _acceptedToken; // accepted token
    address private _receiver;

    constructor(
        uint256 _minimumInvestableAmount,
        uint256 _maximumBorrowPercentage,
        uint256 _minimumIncomeFlowRate,
        uint256 _interestRate,
        ISuperfluid host,
        IConstantFlowAgreementV1 cfa,
        ISuperToken acceptedToken,
        address receiver
    ) {
        require(address(host) != address(0), "host is zero address");
        require(address(cfa) != address(0), "cfa is zero address");
        require(
            address(acceptedToken) != address(0),
            "acceptedToken is zero address"
        );
        require(address(receiver) != address(0), "receiver is zero address");
        require(!host.isApp(ISuperApp(receiver)), "receiver is an app");

        minimumInvestableAmount = _minimumInvestableAmount;
        maximumBorrowPercentage = _maximumBorrowPercentage;
        minimumIncomeFlowRate = _minimumIncomeFlowRate;
        interestRate = _interestRate;

        _host = host;
        _cfa = cfa;
        _acceptedToken = acceptedToken;
        _receiver = receiver;

        uint256 configWord =
            SuperAppDefinitions.APP_LEVEL_FINAL |
                SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
                SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
                SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;

        _host.registerApp(configWord);
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

    /**************************************************************************
     * SuperApp callbacks
     *************************************************************************/

    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata, /*_agreementData*/
        bytes calldata, // _cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        return _updateOutflow(_ctx);
    }

    function afterAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, //_agreementId,
        bytes calldata agreementData,
        bytes calldata, //_cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        return _updateOutflow(_ctx);
    }

    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, //_agreementId,
        bytes calldata, /*_agreementData*/
        bytes calldata, //_cbdata,
        bytes calldata _ctx
    ) external override onlyHost returns (bytes memory newCtx) {
        // According to the app basic law, we should never revert in a termination callback
        if (!_isSameToken(_superToken) || !_isCFAv1(_agreementClass))
            return _ctx;
        return _updateOutflow(_ctx);
    }

    function _isSameToken(ISuperToken superToken) private view returns (bool) {
        return address(superToken) == address(_acceptedToken);
    }

    function _isCFAv1(address agreementClass) private view returns (bool) {
        return
            ISuperAgreement(agreementClass).agreementType() ==
            keccak256(
                "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
            );
    }

    modifier onlyHost() {
        require(
            msg.sender == address(_host),
            "RedirectAll: support only one host"
        );
        _;
    }

    modifier onlyExpected(ISuperToken superToken, address agreementClass) {
        require(_isSameToken(superToken), "RedirectAll: not accepted token");
        require(_isCFAv1(agreementClass), "RedirectAll: only CFAv1 supported");
        _;
    }
}
