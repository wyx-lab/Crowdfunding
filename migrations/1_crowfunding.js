const Crowdfunding = artifacts.require("Crowdfunding");
const Crowdfunding2 = artifacts.require("Crowdfunding2");
module.exports = function (deployer, network, accounts) {
    const deployerAccount = accounts[0]; // 或者使用 accounts[1], accounts[2] 等

    deployer.deploy(Crowdfunding, { from: deployerAccount });

    const deployerAccount2 = accounts[1];
    deployer.deploy(Crowdfunding2, { from: deployerAccount2 });
};
