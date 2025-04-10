<!-- src/views/LoginPage.vue -->
<template>
  <div>
    <h2>请选择一个账户</h2>
    <select v-model="selectedAccount">
      <option disabled value="">请选择账户</option>
      <option v-for="acc in accounts" :key="acc" :value="acc">{{ acc }}</option>
    </select>
    <button :disabled="!selectedAccount" @click="goToCrowdfund">进入众筹</button>
  </div>
</template>

<script>
import Web3 from 'web3';

export default {
  data() {
    return {
      web3: null,
      accounts: [],
      selectedAccount: ''
    };
  },
  async mounted() {
    if (window.ethereum) {
      this.web3 = new Web3(window.ethereum);
      await window.ethereum.request({ method: "eth_requestAccounts" });
    } else if (window.web3) {
      this.web3 = new Web3(window.web3.currentProvider);
    } else {
      this.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:7545"));


    }
    this.accounts = await this.web3.eth.getAccounts();
  },
  methods: {
    goToCrowdfund() {
      this.$router.push({
        name: 'Crowdfund',
        query: {
          selectedAccount: this.selectedAccount
        }
      });
    }
  }
};
</script>
