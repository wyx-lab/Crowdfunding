// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;

contract Crowdfunding {
    address public author;
    mapping(address => uint) public joined;
    uint constant Target = 0.1 ether;
    uint public endTime;
    uint public price = 0.02 ether;
    bool public closed = false;

    event Join(address indexed user, uint price);

    constructor() payable {
        author = msg.sender;

        endTime = block.timestamp + 2 minutes;
    }

    function updatePrice() internal {
        uint rise = address(this).balance / 1 ether * 0.002 ether;
        price = 0.02 ether + rise;
    }


    receive() external payable {


        require(block.timestamp < endTime && !closed ,"finished");
        require(joined[msg.sender] == 0, "you have joined");
        require(msg.value >= price, "too low");
        joined[msg.sender] = msg.value;

        updatePrice();
        emit Join(msg.sender, msg.value);
    }

    function withdrawFund() external {
        require(msg.sender == author, "you are not author");
        require(address(this).balance >= Target, "balance is not enough");
        closed = true;

        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw() external {
        require(block.timestamp > endTime, "time is not up");
        require(!closed, "money is withdrawn");
        require(Target > address(this).balance, "you can not withdraw");
        payable(msg.sender).transfer(joined[msg.sender]);
    }
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

}


contract Crowdfunding2 {
    address public author;
    mapping(address => uint) public joined;
    uint constant Target = 0.1 ether;
    uint public endTime;
    uint public price = 0.02 ether;
    bool public closed = false;

    event Join(address indexed user, uint price);

    constructor() payable {
        author = msg.sender;

        endTime = block.timestamp + 2 minutes;
    }

    function updatePrice() internal {
        uint rise = address(this).balance / 1 ether * 0.002 ether;
        price = 0.02 ether + rise;
    }


    receive() external payable {


        require(block.timestamp < endTime && !closed ,"finished");
        require(joined[msg.sender] == 0, "you have joined");
        require(msg.value >= price, "too low");
        joined[msg.sender] = msg.value;

        updatePrice();
        emit Join(msg.sender, msg.value);
    }

    function withdrawFund() external {
        require(msg.sender == author, "you are not author");
        require(address(this).balance >= Target, "balance is not enough");
        closed = true;

        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw() external {
        require(block.timestamp > endTime, "time is not up");
        require(!closed, "money is withdrawn");
        require(Target > address(this).balance, "you can not withdraw");
        payable(msg.sender).transfer(joined[msg.sender]);
    }
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}