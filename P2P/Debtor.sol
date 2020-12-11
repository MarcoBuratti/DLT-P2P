pragma solidity ^0.4.17;

contract Borrow {
    // Global Variables
    mapping (address => uint) balances; // Either investor or borrower => balance
    mapping (address => Borrower) public borrowers; // Borrower public key => Borrower


    mapping (uint => LoanApplication) public applications;
    mapping (uint => Loan) public loans;

    mapping(address => bool) hasOngoingLoan;
    mapping(address => bool) hasOngoingApplication;
    mapping(address => bool) hasOngoingInvestment;

    // Structs
    struct Borrower{
        address borrower_public_key;
        string name;
        bool EXISTS;
    }
    struct LoanApplication{
        //For traversal and indexing
        bool openApp;
        uint applicationId;

        address borrower;
        uint duration; // In months
        uint credit_amount; // Loan amount
        uint interest_rate; //From form
        string otherData; // Encoded string with delimiters (~)

    }
    struct Loan{

        //For traversal and indexing
        bool openLoan;
        uint loanId;

        address borrower;
        address investor;
        uint interest_rate;
        uint duration;
        uint principal_amount;
        uint original_amount;
        uint amount_paid;
        uint startTime;
        uint monthlyCheckpoint;
        uint appId;
        
    }
    // Methods
    constructor(){
        // TODO Constructor may be added later
    }

    function createBorrower(string name){
        Borrower borrower;
        borrower.name = name;
        borrower.borrower_public_key = msg.sender;
        borrower.EXISTS = true;
        require (investors[msg.sender].EXISTS != true);
        borrowers[msg.sender] = borrower;
        hasOngoingLoan[msg.sender] = false;
        hasOngoingApplication[msg.sender] = false;
        balances[msg.sender] = 0; // Init balance
    }
    
    function viewBalance() public returns (uint){
        return balances[msg.sender];
    }
    
    //versamento sul conto corrente
    function deposit() payable public{
        balances[msg.sender] += msg.value;
    }
    
    //richiesta per il prelievo 
    function withdraw() returns (uint) {
        require(msg.value <= balances[msg.sender]);
        balances[msg.sender] -= msg.value;
        return msg.value;
    }
    
    function createApplication(uint duration, uint interest_rate, uint credit_amount, string otherData){
        //richiedente non deve avere debiti ne richieste di debito attive
        require(hasOngoingLoan[msg.sender] == false);
        require(hasOngoingApplication[msg.sender] == false);
        require(isBorrower(msg.sender));
        
        applications[numApplications] = LoanApplication(true, numApplications, msg.sender, duration, credit_amount, interest_rate, otherData);

        numApplications += 1;
        hasOngoingApplication[msg.sender] = true;
    }

    
    function ifApplicationOpen(uint index) returns (bool){
        LoanApplication storage app = applications[index];
        if(app.openApp) return true; else return false;
    }
    function ifLoanOpen(uint index) returns (bool){
        Loan storage loan = loans[index];
        if (loan.openLoan == true) return true; else return false;
    }
    
    function getApplicationData(uint index) returns (uint[], string, address){
        string storage otherData = applications[index].otherData;
        uint[] memory numericalData = new uint[](4);
        numericalData[0] = index;
        numericalData[1] = applications[index].duration;
        numericalData[2] = applications[index].credit_amount;
        numericalData[3] = applications[index].interest_rate;

        address borrower = applications[index].borrower;
        return (numericalData, otherData, borrower);
        // numericalData format = [index, duration, amount, interestrate]
    }
    function getLoanData(uint index) returns (uint[], address, address){
        uint[] memory numericalData = new uint[](9);
        numericalData[0] = index;
        numericalData[1] = loans[index].interest_rate;
        numericalData[2] = loans[index].duration;
        numericalData[3] = loans[index].principal_amount;
        numericalData[4] = loans[index].original_amount;
        numericalData[5] = loans[index].amount_paid;
        numericalData[6] = loans[index].startTime;
        numericalData[7] = loans[index].monthlyCheckpoint;
        numericalData[8] = loans[index].appId;

        return (numericalData, loans[index].borrower, loans[index].investor);
    }
    
}