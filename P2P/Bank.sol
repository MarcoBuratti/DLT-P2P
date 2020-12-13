pragma solidity ^0.5.0;

contract P2PLending {
    // Global Variables
    mapping (address => uint) balances;                     // conti correnti degli investitori 

    mapping (address => Investor) private investors;         // lista degli investitori 
    mapping (address => Borrower) private borrowers;         // lista dei richiedenti di finanziamento 

    mapping (address => LoanApplication) private applications;  // richieste dei finanziamenti 
    mapping (address => Loan) private loans;                    // finanziamenti
    address [] private tableProject;                            // lista di tutte le richieste di debito

    address private contractOwner;

    mapping(address => bool) private hasOngoingLoan;                // lista di chi ha all'attivo prestiti da saldare            
    mapping(address => bool) private hasOngoingApplication;         // lista di chi ha all'attivo richieste di finanziamento
    mapping(address => bool) private hasOngoingInvestment;          // lista di chi ha all'attivo investimenti 

    event PayBack(address indexed from, address indexed to, uint value, uint amount);   //event usato per esporre a tutti chi paga e quando

    // Structs actors
    struct Investor {
        address investor_public_key;
        bool EXISTS;
    }
    struct Borrower {
        address borrower_public_key;
        bool EXISTS;
    }
    // Struct products
    struct LoanApplication {
        bool openApplications;
        address borrower;
        uint credit_amount; // Loan amount
        uint interest_rate; //From form
        string otherData; // Encoded string with delimiters
    }
    struct Loan {

        bool openLoan;
        address borrower;
        address investor;
        uint interest_rate;
        uint original_amount;

    }
    
    // Methods
    constructor() public {
        contractOwner = msg.sender;
    }
    
    function createInvestor() public {
        // cerca che il nuovo investitore non sia un debitore 
        require (borrowers[msg.sender].EXISTS != true, 'You are already a Borrower, you can\'t be an Investor');
        Investor memory investor;
        investor.investor_public_key = msg.sender;
        investor.EXISTS = true;
        //inserisce il nuovo investirore nella mappa(lista) degli investirori
        investors[msg.sender] = investor;
        // inizialiazza ongoing inv a false perche non ha mai investito
        hasOngoingInvestment[msg.sender] = false;
        //inizialiazza la mappa balances a zero perche non ha mai versato una lira
        balances[msg.sender] = 0;
    }
    
    function createBorrower() public {
        require (investors[msg.sender].EXISTS != true, 'You are already an Investor, you can\'t be a Borrower');
        Borrower memory borrower;
        borrower.borrower_public_key = msg.sender;
        borrower.EXISTS = true;
        borrowers[msg.sender] = borrower;
        hasOngoingLoan[msg.sender] = false;
        hasOngoingApplication[msg.sender] = false;
        balances[msg.sender] = 0; // Init balance
    }
    
    function createApplication(uint credit_amount, string memory description) public {
        //richiedente non deve avere debiti ne richieste di debito attive
        require(hasOngoingLoan[msg.sender] == false, 'You have an ongoing Loan');
        require(hasOngoingApplication[msg.sender] == false, 'You have an ongoing Application');
        require(isBorrower(msg.sender), 'You aren\'t subscribe as a borrower');
        applications[msg.sender] = LoanApplication(true, msg.sender, credit_amount, 5, description);

        hasOngoingApplication[msg.sender] = true;
        tableProject.push(msg.sender);
    }
    
    //versamento sul conto corrente
    function deposit() payable public {
        balances[msg.sender] += msg.value;
    }
    
    //richiesta per il prelievo 
    /*function withdraw(int amount) public {
        uint withdrawAmount = uint(amount);
        require(withdrawAmount * 1000000000000000000 <= balances[msg.sender], 'Not enough funds');
        balances[msg.sender] -= withdrawAmount * 1000000000000000000;
        msg.sender.transfer(withdrawAmount);
    }*/
    
    function withdrawAll() public {
        require(balances[msg.sender] > 0, 'Nothing to withdraw');
        msg.sender.transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }
    
    //finanzia un progetto/debitore
    function transfer(address reciever, uint amount) private {
        require(borrowers[reciever].EXISTS == true || investors[reciever].EXISTS == true, 'This address do not exists!');
        require(balances[msg.sender] >= amount * 1000000000000000000 );
        balances[msg.sender] -= amount * 1000000000000000000;
        balances[reciever] += amount * 1000000000000000000;
    }
    
    function grantLoan(address ApplicationsID, uint amount) payable public {
        //Check sufficient balance
        require(isInvestor(msg.sender), 'You are not an Investor');
        require(balances[msg.sender] >= applications[ApplicationsID].credit_amount, 'Not enough money on your BankAccount');
        require(hasOngoingInvestment[msg.sender] == false, 'You already have an ongoing Investment');
        require(applications[ApplicationsID].openApplications == true, 'This application does not exist');
        require(amount == applications[ApplicationsID].credit_amount, 'Give the same amount requested from Apllications');

        // Take from sender and give to reciever
        transfer(ApplicationsID, amount);
        
        // Populate loan object
        uint newAmount = applications[ApplicationsID].credit_amount * 1000000000000000000;
        loans[ApplicationsID] = Loan(true, ApplicationsID, msg.sender, 5, newAmount);
        //applications[appId].credit_amount, applications[appId].credit_amount, 0, now, 0, appId);
        delete applications[ApplicationsID];
        
        hasOngoingApplication[ApplicationsID] = false;
        hasOngoingLoan[ApplicationsID] = true;
        hasOngoingInvestment[msg.sender] = true;
    }
    
    function repayLoan(uint amount) payable public {
        require(isBorrower(msg.sender), 'You are not an Borrower');
        require(balances[msg.sender] >= amount, 'Not enough money on your BankAccount');
        require(hasOngoingLoan[msg.sender] == true, 'You do not have an ongoing Loan');
        require(ifLoanOpen(msg.sender) == true, 'You have already paid your debt');
        
        address reciever = loans[msg.sender].investor;
        loans[msg.sender].original_amount -= msg.value;

        transfer(reciever, amount);
        hasOngoingInvestment[reciever] = false;
        hasOngoingLoan[msg.sender] = false;
        emit PayBack(msg.sender, reciever, msg.value, loans[msg.sender].original_amount);
        delete loans[msg.sender];
    }
    
    function viewBalance() public view returns (int) {
        return int(balances[msg.sender]);
    }    
    function getListApplication() public view returns (address [] memory) {
        return tableProject;
    }
    function getApplicationData(address index) public view returns (address, uint, uint, string memory, bool) {
        
        address borrower = applications[index].borrower;
        uint amount = applications[index].credit_amount;
        uint interest = applications[index].interest_rate;
        string storage description = applications[index].otherData;
        bool isTaken = applications[index].openApplications;
        return (borrower, amount, interest, description, isTaken);

    }
    function getLoanData(address index) public view returns (bool, address, address, uint, uint) {
        require(loans[index].openLoan == true, 'This loan do not exist');
        require(msg.sender == index, 'You are not the debt owner');
        bool isOpen = loans[index].openLoan;
        address owner = loans[index].borrower;
        address whoInvest = loans[index].investor;
        uint interest = loans[index].interest_rate;
        uint amount = loans[index].original_amount;
        return (isOpen, owner, whoInvest, interest, amount);
    }
    
    function ifLoanOpen(address index) private view returns (bool) {
        if (loans[index].original_amount > 0) return true; else return false;
    }
    function isInvestor(address account) private view returns (bool) {return investors[account].EXISTS;}
    function isBorrower(address account) private view returns (bool) {return borrowers[account].EXISTS;}

}