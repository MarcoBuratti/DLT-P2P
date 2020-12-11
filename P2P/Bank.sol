pragma solidity ^0.4.17;

contract P2PLending {
    // Global Variables
    mapping (address => uint) balances;                     // conti correnti degli investitori 

    mapping (address => Investor) public investors;         // lista degli investitori 
    mapping (address => Borrower) public borrowers;         // lista dei richiedenti di finanziamento 

    mapping (address => LoanApplication) public applications;  // richieste dei finanziamenti 
    mapping (address => Loan) public loans;                    // finanziamenti
    address [] private elementi;


    mapping(address => bool) hasOngoingLoan;                // lista di chi ha all'attivo prestiti da saldare            
    mapping(address => bool) hasOngoingApplication;         // lista di chi ha all'attivo richieste di finanziamento
    mapping(address => bool) hasOngoingInvestment;          // lista di chi ha all'attivo investimenti 

    //TODO event PayBack(address indexed from, address indexed to, uint256 value);
    //TODO emit PayBack(....);

    // Structs actors
    struct Investor{
        address investor_public_key;
        bool EXISTS;
    }
    struct Borrower{
        address borrower_public_key;
        bool EXISTS;
    }
    // Struct products
    struct LoanApplication{
        //For traversal and indexing
        bool openApplications;
        //uint applicationId;

        address borrower;
        //uint duration; // In months
        uint credit_amount; // Loan amount
        uint interest_rate; //From form
        string otherData; // Encoded string with delimiters
    }
    
    struct Loan{

        //For traversal and indexing
        bool openLoan;
        //uint loanId;

        address borrower;
        address investor;
        uint interest_rate;
        //uint duration;
        //uint principal_amount;
        uint original_amount;
        //uint startTime;
        //uint monthlyCheckpoint;
        //uint appId;
    }
    
    
    // Methods
    constructor() public{
        // TODO Constructor may be added later
    }
    
    
    function createInvestor() public{
        // cerca che il nuovo investitore non sia un debitore 
        require (borrowers[msg.sender].EXISTS != true, 'You are already a Borrower, you can\'t be an Investor');
        Investor storage investor = investor;
        investor.investor_public_key = msg.sender;
        investor.EXISTS = true;
        //inserisce il nuovo investirore nella mappa(lista) degli investirori
        investors[msg.sender] = investor;
        // inizialiazza ongoing inv a false perche non ha mai investito
        hasOngoingInvestment[msg.sender] = false;
        //inizialiazza la mappa balances a zero perche non ha mai versato una lira
        balances[msg.sender] = 0;
    }
    
    function createBorrower() public{
        require (investors[msg.sender].EXISTS != true, 'You are already an Investor, you can\'t be a Borrower');
        Borrower storage borrower = borrower;
        borrower.borrower_public_key = msg.sender;
        borrower.EXISTS = true;
        borrowers[msg.sender] = borrower;
        hasOngoingLoan[msg.sender] = false;
        hasOngoingApplication[msg.sender] = false;
        balances[msg.sender] = 0; // Init balance
    }
    
    function viewBalance() public view returns (uint){
        return balances[msg.sender];
    }
    
    //versamento sul conto corrente
    function deposit() payable public {
        balances[msg.sender] += msg.value;
    }
    
    //richiesta per il prelievo 
    function withdraw() payable public {
        require(msg.value <= balances[msg.sender], 'Not enough funds');
        balances[msg.sender] -= msg.value;
        msg.sender.transfer(msg.value);
    }
    
    function withdrawAll() payable public {
        require(balances[msg.sender] > 0, 'Nothing to withdraw');
        msg.sender.transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }
    
    //finanzia un progetto/debitore
    function transfer(address reciever) private{
        require(borrowers[reciever].EXISTS == true, 'This address do not exists!');
        require(balances[msg.sender] >= msg.value);
        balances[msg.sender] -= msg.value;
        balances[reciever] += msg.value;
    }
    
    function createApplication(uint credit_amount, string description) public{
        //richiedente non deve avere debiti ne richieste di debito attive
        require(hasOngoingLoan[msg.sender] == false);
        require(hasOngoingApplication[msg.sender] == false);
        require(isBorrower(msg.sender));
        
        applications[msg.sender] = LoanApplication(true, msg.sender, credit_amount, 5, description);

        hasOngoingApplication[msg.sender] = true;
        elementi.push(msg.sender);
    }
    //
    function grantLoan(address ApplicationsID) payable public{
        //Check sufficient balance
        require(isInvestor(msg.sender), 'You are not an Investor');
        require(balances[msg.sender] >= applications[ApplicationsID].credit_amount, 'Not enough money on your BankAccount');
        require(hasOngoingInvestment[msg.sender] == false, 'You already have an ongoing Investment');
        require(applications[ApplicationsID].openApplications == true, 'This application does not exist');
        require(msg.value == applications[ApplicationsID].credit_amount, 'You have the same amount of the Application');

        // Take from sender and give to reciever
        transfer(ApplicationsID);
        
        // Populate loan object
        loans[ApplicationsID] = Loan(true, ApplicationsID, msg.sender, 5, applications[ApplicationsID].credit_amount);
        //applications[appId].credit_amount, applications[appId].credit_amount, 0, now, 0, appId);
        delete applications[ApplicationsID];
        
        hasOngoingApplication[ApplicationsID] = false;
        hasOngoingLoan[ApplicationsID] = true;
        hasOngoingInvestment[msg.sender] = true;
    }
    
    function repayLoan()payable public{
        require(isBorrower(msg.sender), 'You are not an Borrower');
        require(balances[msg.sender] >= msg.value, 'Not enough money on your BankAccount');
        require(hasOngoingLoan[msg.sender] == true, 'You do not have an ongoing Loan');
        
        address reciever = loans[msg.sender].investor;
        loans[msg.sender].original_amount -= msg.value;
        transfer(reciever);
    }
    
    
    function ifLoanOpen(address index) private view returns (bool){
        if (loans[index].original_amount > 0) return true; else return false;
    }
    
    function getListApplicationData() public view returns (address []){
        return elementi;
    }
    

    function getApplicationData(address index)public view returns (address, uint, uint, string, bool){
        
        address borrower = applications[index].borrower;
        uint amount = applications[index].credit_amount;
        uint interest = applications[index].interest_rate;
        string storage description = applications[index].otherData;
        bool isTaken = applications[index].openApplications;

        return (borrower, amount, interest, description, isTaken);

    }
    
    /*function getLoanData(uint index) returns (uint[], address, address){
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
    }*/

    function isInvestor(address account) private view returns (bool) {return investors[account].EXISTS;}
    function isBorrower(address account) private view returns (bool) {return borrowers[account].EXISTS;}

}