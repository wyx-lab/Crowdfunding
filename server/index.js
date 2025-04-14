const express = require('express');
const app = express();
// const cors = require('cors')
//
// app.use(cors())
app.get('/', (req, res) => res.send('Hello World'))

app.listen(3000, () => console.log('Start Server, listening on port 3000!'))

// 引入web库
var Web3 = require('web3');
// 使用WebSocket协议 连接节点
let web3 = new Web3(new Web3.providers.WebsocketProvider('ws://127.0.0.1:7545'));

// 获取合约实例
var Crowdfunding = require('../build/contracts/Crowdfunding.json');
const crowdFund = new web3.eth.Contract(
    Crowdfunding.abi,
    Crowdfunding.networks[5777].address
);

//  监听Join事件
crowdFund.events.Join(function(error, event) {
    if (error) {
        console.log(error);
    }

    // 打印出交易hash 及区块号
    console.log("交易hash:" + event.transactionHash);
    console.log("区块高度:" + event.blockNumber);

    // 获得监听到的数据：
    console.log("参与地址:" + event.returnValues.user);
    console.log("参与单价:" + event.returnValues.price);
    console.log("参与总额:" + event.returnValues.value);
    console.log("参与项目ID:" + event.returnValues.projectid);

    insertJoins(event.returnValues.user,
        // 把以wei为单位的价格转为ether单位
        web3.utils.fromWei(event.returnValues.price),
        event.returnValues.title,
        web3.utils.fromWei(event.returnValues.value),
        event.returnValues.projectid,
        )

});

var mysql  = require('mysql2');

function getConn() {
    return mysql.createConnection({
        host     : 'localhost',
        user     : 'root',
        password : '123456',
        port     : '3306',
        database : 'crowdfund'
    });
}

crowdFund.events.ConfirmReceiveGoods(function(error, event) {
    if (error) {
        console.log(error);
    }
    var connection = getConn();
    connection.connect()
    const query = `UPDATE join_records
                          SET confirmed = ?
                          WHERE address = ? and projectid = ?`;

    console.log("确认收货:"+ event.returnValues.user,event.returnValues.projectid)
    const params = [true,event.returnValues.user,event.returnValues.projectid];

    connection.query(query, params,(err, result) => {
        if (err) {
            console.log(err);
        }
        console.log(result);
    })

});


function insertJoins(user,price,title,value,projectid) {
    // 连接数据库
    var connection = getConn();

    connection.connect();


    // 构建插入语句
    const query = `INSERT into join_records (
        
        projectid,name,price,
        value,
        confirmed,
        address,
        created_at
   ) Values (?,?,?,?,?,?,NOW())`;



    const params = [Number(projectid),title,0.2,0.2,false,user ];

    // 执行插入操作
    connection.query(query, params, function (error, results) {
        if (error) throw error;

    });

    connection.end();
}

// 通过一个回调函数把结果返回出去
function getJoins(callback) {
    // 获取数据库链接
    var connection = getConn();
    connection.connect();

    // 查询 SQL
    const query = `SELECT projectid,address,value,confirmed from join_records`;
    const params = [];

    // 查询数据库
    connection.query(query, params, (err, rows)=>{
        if(err){
            return callback(err);
        }

        callback(rows);
    });

    connection.end();
}



app.get('/joins', (req, res) => {
    getJoins( rows=> {
        //  设置允许跨域访问
        res.set({'Access-Control-Allow-Origin': '*'})
            .send(rows)
    });
})