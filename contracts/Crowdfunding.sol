// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;

contract Crowdfunding {
    address public author;

    uint Target;



    bool public closed = false;
    uint public minimum_price = 0.01 ether;
    uint public availableToWithdraw;
    mapping(address => uint256) public joinedBitmaps;

    event Join(address indexed user, string title,uint price,uint value,uint projectid);
    event ConfirmReceiveGoods(address indexed user, uint amount,uint projectid);
    event tx_record(address indexed user,uint amount);

    // 投资人结构定义
    struct Funder {
        address payable addr;   // 投资人的地址
        uint amount;            // 出资数额
        bool confirmed;
    }


    struct Funding {
        address payable initiator;       // 发起人
        string title;                    // 项目标题
        uint goal;                       // 目标金额
        uint endTime;                    // 结束时间
        uint single_price;
        bool closed;                     // 是否关闭，成功则 amount 含义为项目剩余的钱
        uint cum_sum_amount;             // 当前已经筹集到的金额
        uint available;

    }

    uint public numFundings = 0;

    mapping(uint => Funding) public fundings; // 所有的众筹项目


    function newFunding(address payable initiator, string memory title, uint single_price,uint goal_num,uint endtime) public{
        numFundings = numFundings + 1;
        Funding storage f = fundings[numFundings];
        f.initiator = initiator;
        f.title = title;
        f.single_price = single_price;
        f.goal = goal_num * single_price;
        f.endTime = endtime;
        f.closed = false;
        f.cum_sum_amount = 0;
        f.available = 0;

        return;
    }


    constructor() {
        author = msg.sender;


    }
    function contribute(uint ID) public payable {
        // 贡献的钱必须大于0，不能超过差额
        Funding storage f = fundings[ID];
        require(msg.value > 0 && msg.value <= f.goal - f.cum_sum_amount, "money > 0");
        // 时间上必须还没结束
        require(f.endTime > block.timestamp, 'time limited');
        // 必须是未完成的众筹
        require(fundings[ID].closed == false, 'non finished');


        f.cum_sum_amount += msg.value;
        f.available += msg.value;

        ///emit Join(msg.sender,msg.value,false);

        f.closed = (f.cum_sum_amount >= f.goal);
        emit Join(msg.sender,f.title,f.single_price,msg.value,ID);
    }



    function withdrawFund(uint ID) external {
        Funding storage f = fundings[ID];
        author = f.initiator;
        Target = f.goal * f.single_price;

        require(msg.sender == author, "you are not author");
        require(f.cum_sum_amount >= Target, "balance is not enough");
        require(f.available > 0);
        closed = true;
        f.available = 0;
        payable(msg.sender).transfer(f.available);
    }

    function withdraw(uint ID,uint amount) external {

        Funding storage f = fundings[ID];

        require(block.timestamp < f.endTime, "time is up");
        require(!closed, "money is withdrawn");
        payable(msg.sender).transfer(amount);
        f.available -= amount;
        f.cum_sum_amount -= amount;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getFunding(uint ID) public view returns (
        address initiator,
        string memory title,
        uint goal,
        uint endTime,
        uint single_price,
        bool closed,
        uint cum_sum_amount,
        uint available
    ) {
        Funding storage f = fundings[ID];
        return (f.initiator,
            f.title,
            f.goal,
            f.endTime,
            f.single_price,
            f.closed,
            f.cum_sum_amount,
            f.available
        );
    }



    function confirmReceiveGoods(uint ID,uint amount) external {
        Funding storage f = fundings[ID];
        //require(amount > 0, "nothing to confirm");
        f.available += amount;
        emit ConfirmReceiveGoods(msg.sender, amount,ID);

    }
    function checkTime(uint ID) public
    {
        Funding storage f = fundings[ID];
        if (block.timestamp > f.endTime) {
            f.closed = true;
        }
    }
    function getTime(uint ID)public view returns(uint)
    {
        Funding storage f = fundings[ID];
        return f.endTime;
    }

}