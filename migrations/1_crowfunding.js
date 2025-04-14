const Crowdfunding = artifacts.require("Crowdfunding");
module.exports = function (deployer, network, accounts) {
    const deployerAccount = accounts[0]; // 或者使用 accounts[1], accounts[2] 等
    deployer.deploy(Crowdfunding, { from: deployerAccount });

};
