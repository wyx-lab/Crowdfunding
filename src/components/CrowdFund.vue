<template>
  <div class="content">
    <h3> 新书众筹</h3>
    <span>以最低的价格获取我的新书 </span>

    <!-- 众筹的总体状态 -->
    <div class="status">
      <div v-if="!closed">已众筹资金：<b>{{ total }} ETH </b></div>
      <div v-if="closed"> 众筹已完成 </div>
      <div>众筹截止时间：{{ endDate }}</div>
    </div>

    <!-- 如果已参与 -->
    <div v-if="joined" class="card-bkg">
      <div class="award-des">
        <span> 参与价格 </span>
        <b> {{ joinPrice }} ETH </b>
      </div>
      <button :disabled="closed" @click="withdraw">赎回</button>
    </div>

    <!-- 如果未参与 -->
    <div v-if="!joined" class="card-bkg">
      <div class="award-des">
        <span> 当前众筹价格 </span>
        <b> {{ price }} ETH </b>
      </div>
      <button :disabled="closed" @click="join">参与众筹</button>
    </div>

    <!--  如果是创作者，显示 -->
    <div class="box" v-if="isAuthor">
      <div >
        <p v-bind:key="item" v-for="item in joinList" >
          <label> 地址：{{ item.address.substring(0, 30) + "..."  }}</label>
          金额：<b> {{ item.price }} </b>
        </p>
      </div>

      <button :disabled="closed" @click="withdrawFund"> 提取资金</button>
    </div>
  </div>
</template>

<!-- 这里把truffle-contract包换掉了，因为setProvider会报错&ndash;&gt;-->
<script>
import Web3 from "web3";
import crowd from "../../build/contracts/Crowdfunding.json";
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
      joined: false,
      endDate: "null",
      isAuthor: false,
      joinList: []
    };
  },

  async created() {
    await this.initWeb3Account();
    await this.initContract();
    await this.getCrowdInfo();
    this.getJoins();
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
      this.account = accounts[0];
    },

    // 初始化合约
    async initContract() {
      const networkId = await this.web3.eth.net.getId();
      const deployedNetwork = crowd.networks[networkId];
      this.crowdFund = new this.web3.eth.Contract(crowd.abi, deployedNetwork.address);
    },

    // 获取众筹状态信息
    async getCrowdInfo() {
      // 获取合约余额
      const balance = await this.web3.eth.getBalance(this.crowdFund.options.address);
      console.log(balance)
      this.total = this.web3.utils.fromWei(balance.toString(), 'ether');
      //
      // 是否参与
      const joinedAmount = await this.crowdFund.methods.joined(this.account).call();
      if (joinedAmount > 0) {
        this.joined = true;
        this.joinPrice = this.web3.utils.fromWei(joinedAmount.toString(), 'ether');
      } else {
        this.joined = false;
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
          endDateObj.toTimeString().substr(0, 8);

      // 判断是否为作者
      const author = await this.crowdFund.methods.author().call();
      this.isAuthor = this.account.toLowerCase() === author.toLowerCase();
    },

    // 参与众筹
    async join() {
      await this.web3.eth.sendTransaction({
        from: this.account,
        to: this.crowdFund.options.address,
        value: this.web3.utils.toWei(this.price.toString(), 'ether'),
        gas: 3000000
      });
      await this.getCrowdInfo();
    },

    // 赎回
    async withdraw() {
      await this.crowdFund.methods.withdraw().send({ from: this.account });
      await this.getCrowdInfo();
    },

    // 提取资金
    async withdrawFund() {
      await this.crowdFund.methods.withdrawFund().send({ from: this.account });
      await this.getCrowdInfo();
    },
    // 获取众筹列表
    getJoins() {
      axios.get('http://localhost:3000/joins')
          .then(response => {
            this.joinList = response.data
          })
          .catch(function (error) { // Ajax请求失败处理
            console.log(error);
          });
    },
  },
};
</script>
