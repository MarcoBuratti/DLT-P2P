pragma solidity ^0.7;

contract PocketMoney {
    
    uint limit;
    address owner;
    uint time;
    
    constructor(uint _limit) public {
        limit = _limit;
        owner = msg.sender;
    }

    function deposit() public payable {
        // tutti opzionali il metodo puoò essere vuoto
        time = block.timestamp;
    }
    
    function withdraw(uint amount) public {
        require(amount <= address(this).balance, 'Not enough money');
        //require(amount/100 <= 2 ether, 'Fee to high');
        require(amount <= limit, 'Limit exceeded');
        require(block.timestamp > time + 3 minutes, 'Too early');
        msg.sender.transfer(amount);
        //owner.transfer(amount/100);
    }
    
    function withdrawAll() public {
        require(msg.sender == owner, 'not allowed');
        msg.sender.transfer(address(this).balance);
    }
}