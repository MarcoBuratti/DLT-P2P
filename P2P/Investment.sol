pragma solidity ^0.4.24;

contract Investment {
    // Global Variables
    mapping (address => uint) balances; // Either investor or borrower => balance
    mapping (address => Investor) public investors; // Investor public key => Investor
    mapping (address => Evaluator) public evaluators;
    mapping(address => bool) hasOngoingEvaluate;

    mapping(address => bool) hasOngoingInvestment;

    // Structs
    struct Investor{
        address investor_public_key;
        string name;
        bool EXISTS;
    }
    struct Evaluator{
        address evaluator_public_key;
        string name;
        bool EXISTS;
    }

    // Methods
    constructor(string name) public{
        // TODO Constructor 
        createInvestor(name);
    }
    
    function createInvestor(string name) private{
        Investor storage investor = investor;
        investor.name = name;
        investor.investor_public_key = msg.sender;
        investor.EXISTS = true;
        // cerca che il nuovo investitore non sia un debitore 
        //inserisce il nuovo investirore nella mappa(lista) degli investirori
        investors[msg.sender] = investor;
        // inizialiazza ongoing inv a false perche non ha mai investito
        hasOngoingInvestment[msg.sender] = false;
        //inizialiazza la mappa balances a zero perche non ha mai versato una lira
        balances[msg.sender] = 0;
    }
    
    function createEvaluator(string name) public{
        require(balances[msg.sender] >= 10 ether, 'Minimum amount to evaluate prject => 10 ether');
        Evaluator storage evaluator = evaluator;
        evaluator.name = name;
        evaluator.evaluator_public_key = msg.sender;
        evaluator.EXISTS = true;
        // cerca che il nuovo investitore non sia un debitore 
        //inserisce il nuovo investirore nella mappa(lista) degli investirori
        evaluators[msg.sender] = evaluator;
        // inizialiazza ongoing inv a false perche non ha mai investito
        hasOngoingEvaluate[msg.sender] = false;
    }
    
    function viewBalance() public view returns (string, uint){
        return ('Your balance is:', balances[msg.sender]);
    }
    
    //versamento sul conto corrente
    function deposit() public payable{
        balances[msg.sender] += msg.value;
    }
    
    //richiesta per il prelievo 
    function withdraw(uint amount) public returns (uint){
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        return amount;
    }
    
    //finanzia un progetto/debitore
    function transfer(address giver, address taker, uint amount) public{
        require(balances[giver] >= amount);
        balances[giver] -= amount;
        balances[taker] += amount;
    }

    function isInvestor(address account) private view returns (bool) {return investors[account].EXISTS;}
}

