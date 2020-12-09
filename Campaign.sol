pragma solidity ^0.4.17;

contract Campaign {
    
    struct Request{
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }
    
    Request[] public requests;
    address public manager;
    uint minumumContribution;
    mapping(address => bool) public approvers;
    
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
    
    constructor(uint minimum) public{
        manager = msg.sender;
        minumumContribution = minimum;
    }
    
    function contribute() public payable{
        require(msg.value > minumumContribution);
        approvers[msg.sender] = true;
    }
    
    function createRequest( string newDescription, uint newValue, address newRecipient) public restricted {
        Request memory newRequest = Request({
            description: newDescription,
            value: newValue,
            recipient: newRecipient,
            complete: false,
            approvalCount: 0
        });
        
        requests.push(newRequest);
    }
    
    function approvaRequest(uint index) public {
        Request storage request = requests[index];
        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);
        
        //incrementa contatore delle approvazioni e setta a true la map per "identificare" il votante
        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }
    
}