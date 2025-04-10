<template>
  <div v-if="!connected">
    <h2>连接合约</h2>
    <select v-model="switch_acc">
      <option disabled value="">请选择账户</option>
      <option v-for="acc in account_to_switch" :key="acc" :value="acc">
        {{ acc }}
      </option>
    </select>
    <button :disabled="!switch_acc" @click="connectContract">连接合约</button>
  </div>

  <div v-else>
  <div class="app-container">
    <div class="centered-content">
      <h3>新书众筹</h3>
      <span class="subtitle">以最低的价格获取我的新书</span>
      <!-- 众筹的总体状态 -->
      <div class="status">
        <div v-if="!closed">已众筹资金：<b>{{ total }} ETH </b></div>
        <div v-if="closed">众筹已完成</div>
        <div>众筹截止时间：{{ endDate }}</div>
      </div>
      <!-- 众筹的总体状态 -->
      <div class="status">
        <div>address idx：{{idx}}</div>
        <div>address：{{selectedAccount}}</div>
        <div>accounts：{{fixed_accounts}}</div>
        <div>joined：{{joinList}}</div>
      </div>
      <p>当前账户索引：{{ idx }} {{isAuthor}} ({{ selectedAccount }})</p>

        <div class="award-des">
          <span>参与价格</span>
          <b>{{ joinPrice }} ETH</b>
        </div>
        <button :disabled="closed" @click="withdraw">赎回</button>

      <button :disabled="closed" @click="ChooseAccount">选择账户</button>
      <select v-model="selectedAccount" @change="handleAccountChange">
        <option v-for="acc in accounts" :key="acc">{{ acc }}</option>
      </select>

      <!-- 如果未参与 -->
<!--      <div v-if="!joineds[idx]" class="card-bkg">-->
        <div class="award-des">
          <span>当前众筹价格</span>
          <b>{{ price }} ETH</b>
        </div>
        <button :disabled="closed" @click="join">参与众筹</button>
      <!-- 如果是创作者 -->
      <div class="award-des" v-if="isAuthor" style="width: fit-content; margin: 0 auto;">
<!--        <div >-->
<!--          <p v-bind:key="item" v-for="item in joinList" >-->
<!--            <label> 地址：{{ item.address.substring(0, 30) + "..."  }}</label>-->
<!--            金额：<b> {{ item.price }} </b>-->
<!--          </p>-->
<!--        </div>-->
        <button :disabled="closed" @click="withdrawFund">提取资金</button>
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
import crowd2 from "../../build/contracts/Crowdfunding2.json";
import axios from 'axios';

export default {
  name: "CrowdFund",
  data() {
    return {
      web3: null,
      account: null,
      crowdFund: null,
      price: null,
      total: 0,
      closed: true,
      joinPrice: null,
      joined:false,
      joineds: [],
      joinList: [],
      connected: false,
      account_to_switch:['a1','a2'],
      switch_acc: null,
      endDate: "null",
      isAuthor: false,
      accounts: [],  // 所有可用账户列表
      fixed_accounts:[],
      selectedAccount: null, // 当前选中账户
      idx :0,
    };
  },

  async created() {
    await this.initWeb3Account();
    await this.initContract();
    await this.getCrowdInfo();

    this.getJoins()
    if (window.ethereum) {
        window.ethereum.on('accountsChanged', (accounts) => {
          //this.accounts = accounts;
          this.selectedAccount = accounts[0];
          const index = this.fixed_accounts.findIndex(
              item => item.toLowerCase() === this.selectedAccount.toLowerCase()
          );
          this.idx = index




        });
    }




  },
  async mounted() {
    this.selectedAccount = this.$route.query.selectedAccount;

  },
  methods: {



    // 初始化 Web3 和账户
    async initWeb3Account() {
      if (window.ethereum) {
        this.web3 = new Web3(window.ethereum);
        await window.ethereum.request({ method: "eth_requestAccounts" });
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

      this.joineds = Array(accounts.length).fill(false);
      this.selectedAccount = accounts[0];
    },

    // 初始化合约
    async initContract() {
      const networkId = await this.web3.eth.net.getId();

      const deployedNetwork = crowd.networks[networkId];


      this.crowdFund = new this.web3.eth.Contract(crowd.abi, deployedNetwork.address);
    },
    async connectContract() {
      const networkId = await this.web3.eth.net.getId();

      let contractJson = null;
      let contractAddress = null;

      // 假设 accounts[0] 对应 crowd1, accounts[1] 对应 crowd2
      if (this.selectedAccount === this.accounts[0]) {
        contractJson = crowd;
        contractAddress = crowd.networks[networkId]?.address;
      } else if (this.selectedAccount === this.accounts[1]) {
        contractJson = crowd2;
        contractAddress = crowd2.networks[networkId]?.address;
      } else {
        alert('当前账户没有绑定合约实例');
        return;
      }

      if (!contractAddress) {
        alert('找不到合约部署地址，请确认已经部署到当前网络');
        return;
      }

      this.crowdFund = new this.web3.eth.Contract(contractJson.abi, contractAddress);
      this.connected = true;

    },
    // 获取众筹状态信息
    async getCrowdInfo() {
      // 获取合约余额
      this.idx = this.fixed_accounts.findIndex(
          item => item.toLowerCase() === this.selectedAccount.toLowerCase()
      );

      const balance = await this.web3.eth.getBalance(this.crowdFund.options.address);
      console.log(balance)
      this.total = this.web3.utils.fromWei(balance.toString(), 'ether');
      //
      // 是否参与
      const joinedAmount = await this.crowdFund.methods.joined(this.account).call();
      const index = this.fixed_accounts.findIndex(
          item => item.toLowerCase() === this.selectedAccount.toLowerCase()
      );
      if (joinedAmount > 0) {

        this.joineds[index] = true;
        this.joinPrice = this.web3.utils.fromWei(joinedAmount.toString(), 'ether');
      } else{
        this.joineds[index] = false;
      }
      //
      // 获取关闭状态
      this.closed = await this.crowdFund.methods.closed().call();
      //
      // 获取当前众筹价格
      const price = await this.crowdFund.methods.price().call();
      this.price = this.web3.utils.fromWei(price.toString(), 'ether');

      // 获取截止时间
      const endTime = await this.crowdFund.methods.endTime().call();
      const endDateObj = new Date(Number(endTime) * 1000);
      console.log(endDateObj)
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
      if (!this.selectedAccount) {
        alert("请先选择转账账户");
        return;
      }

      await this.web3.eth.sendTransaction({
        from: this.selectedAccount,
        to: this.crowdFund.options.address,
        value: this.web3.utils.toWei(this.price.toString(), 'ether'),
        gas: 300000
      });
      await this.getCrowdInfo();
    },

    // 赎回
    async withdraw() {
      await this.crowdFund.methods.withdraw().send({ from: this.selectedAccount });
      await this.getCrowdInfo();
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
    // 提取资金
    async withdrawFund() {
      await this.crowdFund.methods.withdrawFund().send({ from: this.selectedAccount });
      await this.getCrowdInfo();
    },
    async ChooseAccount() {
      await this.getCrowdInfo();
    }
  },
};
</script>
