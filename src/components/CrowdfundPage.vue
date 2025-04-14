<template>

  <div>
    <div v-if="!connected">
    <h3>创建众筹项目</h3>
    <p>{{projectList}}</p>
    <input v-model="form.title" placeholder="项目名称" />
      <input v-model="form.price" placeholder="项目名称" />
    <input v-model.number="form.goal" placeholder="目标数量" />
    <input type="datetime-local" v-model="form.endTime" />

    <button @click="newProject">创建众筹项目</button>
    <p v-if="message">{{ message }}</p>
    </div>



  </div>
  <div v-if="!connected">
    <h4>可选择的众筹项目</h4>
    <select v-model="selectedProjectId">

      <option disabled value="">请选择项目</option>
      <option v-for="(proj, id) in projectList" :key="id" :value="proj.id">
        {{ proj.title }} {{proj.id}}
      </option>
    </select>
    <button @click="switchProject">选择该项目</button>
    <p>{{selectedProjectId}}</p>
  </div>






<!--  <div v-if="!connected">-->
<!--    <h2>连接合约</h2>-->
<!--    <select v-model="switch_acc">-->
<!--      <option disabled value="">请选择账户</option>-->
<!--      <option v-for="(pj, id) in projectList" :key="id" :value="id">-->
<!--        {{ pj.title }}-->
<!--      </option>-->
<!--    </select>-->
<!--    <button :disabled="!switch_acc" @click="connectContract">连接合约</button>-->
<!--  </div>-->

  <div v-else>
  <div class="app-container">
    <div class="centered-content">
      <h3>众筹</h3>
    <span class="subtitle">获取<b>{{project.title}} </b></span>
      <!-- 众筹的总体状态 -->
      <div class="status">
        <div v-if="!closed">已众筹资金：<b>{{cumSum}} ETH </b></div>
        <div v-if="closed">众筹已完成</div>
        <div>众筹截止时间：{{ endDate }}</div>
      </div>
      <!-- 众筹的总体状态 -->
      <div class="status">
        <div>address id：{{idx}}</div>
        <div>address:{{selectedAccount}}</div>
        <div>nums:{{nums}}</div>
        <p>id {{selectedProjectId}}</p>
        <p>amount {{project.cumsum_amount}}</p>

        <p>target {{project.goal}} </p>
      </div>
      <p>当前账户索引：{{ idx }} {{isAuthor}} ({{ selectedAccount }})</p>

        <div class="award-des">
          <span>参与价格</span>
          <b>{{ joinPrice }} ETH</b>
        </div>


        <button :disabled="closed" @click="withdraw">赎回</button>


      <label for="donation">输入你想买的个数</label>
      <input
          id="donation"
          v-model="nums"
          type="number"
          min="1"
          step="1"
          placeholder="例如：1"
      />

      <button @click="join">确认参与</button>

      <p v-if="message">{{ message }}</p>


      <button @click="confirmReceiveGoods">确认收货</button>


      <div v-if="isAuthor" style="width: fit-content; margin: 0 auto;">
        <button @click="withdrawFund">提取资金</button>
      </div>


    </div>
  </div>
  </div>
</template>

<style scoped>
.app-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 2rem;
}

.centered-content {
  max-width: 600px;
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

h3 {
  font-size: 2rem;
  text-align: center;
  margin-bottom: 0.5rem;
}

.subtitle {
  display: block;
  text-align: center;
  margin-bottom: 2rem;
}

.status,
.card-bkg,
.box {
  padding: 1.5rem;
  border-radius: 0.5rem;
  background: #f8f9fa;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.card-bkg {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.award-des {
  display: flex;
  justify-content: space-between;
}

button {
  padding: 0.75rem 1.5rem;
  background: #4e6ef2;
  color: white;
  border: none;
  border-radius: 0.25rem;
  cursor: pointer;
  transition: background 0.2s;
}

button:hover {
  background: #3a56d4;
}

button:disabled {
  background: #cccccc;
  cursor: not-allowed;
}


</style>

<script>

import Web3 from "web3";
import crowd from "../../build/contracts/Crowdfunding.json";
//import crowd2 from "../../build/contracts/Crowdfunding2.json";
import axios from 'axios';
//import {web3} from "@truffle/contract/lib/contract/constructorMethods";

export default {
  name: "CrowdFund",
  data() {
    return {
      web3: null,
      account: null,
      crowdFund: null,
      price: null,
      total: 0,
      nums : 0,
      goal : 0,
      closed: false,
      joinPrice: null,
      joined:false,
      message: "",

      connected: false,
      cumSum : "",

      endDate: "null",
      isAuthor: false,
      accounts: [],  // 所有可用账户列表
      fixed_accounts:[],
      contributionRecords: {}, // 全局字典
      selectedAccount: null, // 当前选中账户
      time_now : null,
      form: {
        title: 'doll',

        price: 0.2,
        goal: 10, // 默认目标 10个
        endTime: this.getDefaultEndTime()
      },

      project: {
        title: '',
        price: 0.2,
        goal: null,
        cumsum_amount:0,
        available:0,
        endTime: ''
      },
      joinList : [],
      selectedProjectId: 0,
      projectList: [],
      idx :0,
    };
  },

  async created() {
    await this.initWeb3Account();
    await this.initContract();
    await this.getCrowdInfo();
    await this.loadProjectsFromChain()

    //this.getJoins()
    // if (window.ethereum) {
    //     window.ethereum.on('accountsChanged', (accounts) => {
    //       //this.accounts = accounts;
    //       this.selectedAccount = accounts[0];
    //       const index = this.fixed_accounts.findIndex(
    //           item => item.toLowerCase() === this.selectedAccount.toLowerCase()
    //       );
    //       this.idx = index
    //
    //
    //
    //
    //     }
    //     );
    // }
  },
  async mounted() {
    this.selectedAccount = this.$route.query.selectedAccount;

    // try {
    //   const response = await axios.get('http://your-api.com/data');
    //   this.dataList = response.data;
    // } catch (error) {
    //   console.error('数据加载失败:', error);
    // }

  },
  methods: {


    // 初始化 Web3 和账户
    async initWeb3Account() {
      if (window.ethereum) {
        this.web3 = new Web3(window.ethereum);
        await window.ethereum.request({method: "eth_requestAccounts"});
      } else if (window.web3) {
        this.web3 = new Web3(window.web3.currentProvider);
      } else {
        this.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:7545"));


      }

      const accounts = await this.web3.eth.getAccounts();
      this.accounts = accounts;
      for (const acc of accounts) {
        this.fixed_accounts.push(acc);
      }

      this.account = accounts[0];


    },

    // 初始化合约
    async initContract() {
      const networkId = await this.web3.eth.net.getId();

      const deployedNetwork = crowd.networks[networkId];


      this.crowdFund = new this.web3.eth.Contract(crowd.abi, deployedNetwork.address);
    },
    async loadProjectsFromChain() {
      try {
        const totalProjects = await this.crowdFund.methods.numFundings().call();
        this.projectList = [];
        console.log('项目总数:',totalProjects)
        for (let id = 1; id <= Number(totalProjects); id++) {
          //console.log(id)
          const results =await this.crowdFund.methods.getFunding(id).call();
          const title = results[1];
          const author = results[0];
          const price  = this.web3.utils.fromWei(results[4].toString(), "ether");
          const goal = results[2].toString();
          const cumsum_amount = results[6].toString();

          this.projectList.push({
            author,
            title,
            goal,
            price,
            cumsum_amount,
            id:id.toString(),
          });
        }
      } catch (error) {
        console.error('加载项目失败:', error);
      }
    },

    async newProject() {
      try {
        const {title, price ,goal, endTime} = this.form;

        if (!title ||!price|| !goal || !endTime) {
          alert("请完整填写项目信息");
          return;
        }

        //const accounts = await this.web3.eth.getAccounts();
        const initiator = this.selectedAccount

        //const goalInWei = this.web3.utils.toWei(goal.toString(), "ether");
        const priceInWei = this.web3.utils.toWei(price.toString(), "ether");
        const endTime_js = Math.floor(new Date(this.form.endTime).getTime() / 1000);

        // 调用 Solidity 的 newFunding 函数
        console.log("author:",initiator);
        console.log("title:",title);
        console.log(priceInWei);
        console.log(goal);
        console.log("time:",endTime_js);
        await this.crowdFund.methods.newFunding(
            initiator,
            title,
            priceInWei,
            goal,
            endTime_js
        ).send({
          from: this.selectedAccount,
          gas: 300000000,
        });
        await this.loadProjectsFromChain();
        console.log("select:",this.selectedProjectId);
        // 获取当前项目数量（即新项目的 ID）
        // const newId = await this.crowdFund.methods.numFundings(
        // ).call();
        // //console.log(newId);
        // // // 加入本地项目列表（更新 UI）
        // // this.projectList.push({
        // //   title,
        // //   price,
        // //   goal,
        // //   endTime,
        // //   id: newId.toString(),
        // // });


        //
        // this.selectedProjectId = newId;
        this.message = `创建成功`;


      } catch (err) {
        console.error(err);
        this.message = "创建项目失败：" + (err?.message || '未知错误');


      }
    },

    // async connectContract() {
    //
    //   const networkId = await this.web3.eth.net.getId();
    //
    //   let contractJson = null;
    //   let contractAddress = null;
    //
    //   // 假设 accounts[0] 对应 crowd1, accounts[1] 对应 crowd2
    //   if (this.switch_acc === 'a1') {
    //     contractJson = crowd;
    //     contractAddress = crowd.networks[networkId]?.address;
    //   } else if (this.switch_acc === 'a2') {
    //     contractJson = crowd2;
    //     contractAddress = crowd2.networks[networkId]?.address;
    //   } else {
    //     alert('当前账户没有绑定合约实例');
    //     return;
    //   }
    //
    //   if (!contractAddress) {
    //     alert('找不到合约部署地址，请确认已经部署到当前网络');
    //     return;
    //   }
    //
    //   this.crowdFund = new this.web3.eth.Contract(contractJson.abi, contractAddress);
    //   this.connected = true;
    //
    // },
    async switchProject() {
      if (!this.selectedProjectId) {
        alert("请选择一个项目！");
        return;
      }

      const selected = this.projectList.find(project => project.id == this.selectedProjectId);

      if (!selected) {
        alert("项目数据加载错误！");
        return;
      }

      this.project.title = selected.title;

      this.project.goal = selected.goal
      this.project.cumsum_amount = selected.cumsum_amount;
      this.project.price = selected.price;
      //this.total = await this.crowdFund.methods.fundings(this.selectedProjectId).amount.call()
      this.connected = true;
      await this.getCrowdInfo();
    },



    // 获取众筹状态信息
    async getCrowdInfo() {
      // 获取合约余额
      this.idx = this.fixed_accounts.findIndex(
          item => item.toLowerCase() === this.selectedAccount.toLowerCase()
      );

      // const balance = await this.web3.eth.getBalance(this.crowdFund.options.address);
      // console.log(balance)
      const results =await this.crowdFund.methods.getFunding(this.selectedProjectId).call()

      this.project.cumsum_amount  = results[6];
      this.project.goal = results[2];
      this.project.available = results[7];
      this.closed = results[5];
      const cumsumAmnt = results[6];
      this.cumSum = this.web3.utils.fromWei(cumsumAmnt.toString(), "ether");

      // 是否参与

      // const index = this.fixed_accounts.findIndex(
      //   item => item.toLowerCase() === this.selectedAccount.toLowerCase()
      // );
      // const joinedAmount = await this.crowdFund.methods.joined(this.account).call();
      // if (joinedAmount > 0) {
      //
      //   this.joineds[index] = true;
      //   this.joinPrice = this.web3.utils.fromWei(joinedAmount.toString(), 'ether');
      // } else{
      //   this.joineds[index] = false;
      // }
      //
      // 获取关闭状态

      //
      // 获取当前众筹价格
      //const price = await this.crowdFund.methods.price().call();
      //this.price = this.web3.utils.fromWei(price.toString(), 'ether');

      // 获取截止时间
      const endTime = await this.crowdFund.methods.getTime(Number(this.selectedProjectId)).call();
      const endDateObj = new Date(Number(endTime) * 1000);
      this.project.closed = await this.crowdFund.methods.checkTime(Number(this.selectedProjectId)).call();
      console.log("get from sol:",endTime)
      this.endDate =
          endDateObj.toLocaleDateString().replace(/\//g, "-") +
          " " +
          endDateObj.toTimeString();

      // 判断是否为作者
      const author = await this.crowdFund.methods.author().call();
      this.isAuthor = this.selectedAccount.toLowerCase() === author.toLowerCase();

    },

    // 参与众筹
    async join() {

      this.message = ''
      if (!this.selectedAccount) {
        alert("请先选择转账账户");
        return;
      }


      // try {
      //   const ethAmount = parseFloat(this.price)
      //
      //   // if (isNaN(ethAmount) || ethAmount < 0.02) {
      //   //   this.message = '最少捐赠金额为 0.02 ETH'
      //   //   return
      //   }
      try{
      const ethAmount = parseFloat(this.project.price) * this.nums

      console.log("amount:",ethAmount);

      await this.crowdFund.methods.contribute(this.selectedProjectId).send({
        from: this.selectedAccount,
        to: this.crowdFund.options.address,
        value: this.web3.utils.toWei(ethAmount.toString(), "ether")
      });



      // await this.web3.eth.sendTransaction({
      //   from: this.selectedAccount,
      //   to: this.crowdFund.options.address,
      //   value: this.web3.utils.toWei(this.price.toString(), 'ether'),
      //   gas: 300000
      // });

      const amnt = this.nums * this.project.price
      await this.getCrowdInfo();
      this.message = `参团成功：${amnt} ETH`
      this.price = null;

      }catch (err) {
      this.message = "参团失败：" + (err?.message || '未知错误');


    }

    },

    // 赎回
    async withdraw() {
    try {
      this.getJoins();


      let amount = 0;
      for (const { projectid, address, value,confirmed } of this.joinList) {
        console.log(projectid, address,value,confirmed.data[0]);
        console.log(confirmed.data[0] == false);
        if (
            projectid == this.selectedProjectId &&
            address === this.selectedAccount &&
            confirmed.data[0] == false
        ) {
          amount += value;
        }
      }

      if (amount !== 0) {
        console.log("withdraw:",amount);
        const amnt = this.web3.utils.toWei(amount.toString(),'ether')
        console.log("withdraw:",amnt);
        await this.crowdFund.methods.withdraw(this.selectedProjectId,amnt).send({from: this.selectedAccount});
      }
      await this.getCrowdInfo();

      this.message = "赎回金额成功"
    }
    catch (err) {
        this.message = "赎回金额失败：" + (err?.message || '未知错误');

      }
    },
    getJoins() {
      axios.get('http://localhost:3000/joins')
          .then(response => {
            this.joinList = response.data
          })
          .catch(function (error) { // Ajax请求失败处理
            console.log(error);
          });
    },
    async confirmReceiveGoods(){
      try {
        this.getJoins();


        let value = 0;

        for (const { projectid, address, confirmed, value: val } of this.joinList) {
          console.log(projectid, address,confirmed,val);
          if (
              projectid == this.selectedProjectId &&
              address === this.selectedAccount &&
              confirmed === false
          ) {
            value += val;
          }
        }

        console.log(value)
        await this.crowdFund.methods.confirmReceiveGoods(Number(this.selectedProjectId),
            this.web3.utils.toWei(value.toString(), "ether")
        ).send(
            {
              from: this.selectedAccount,
            }
        );
        this.message = "确认收货成功"
      }catch (error) {
        this.message = "确认收货失败：" + (error?.message || '未知错误');
      }
    },
    // 提取资金
    async withdrawFund() {
      try {
        this.getJoins();
        console.log(this.joinList);

        await this.crowdFund.methods.withdrawFund(this.selectedProjectId).send({from: this.selectedAccount});
        await this.getCrowdInfo();
      }catch (error) {
        this.message = "提取金额失败：" + (error?.message || '未知错误');
      }
    },

    getDefaultEndTime() {
      const now = new Date();
      now.setDate(now.getDate() + 7); // 当前时间+7天
      return now.toISOString().slice(0, 16); // 格式为 datetime-local 支持的格式
    }

  },
};
</script>
