var Fund = artifacts.require("./Fund.sol");
var CryptoYen = artifacts.require("./CryptoYen.sol");


const beneficiaryRights=[["642049472718928697076575779687416339932499715049", "1000000000000000000000000000", "1417467900017242443628120807885768880646888665646", "500000000000000000000000000", "767031563640145617608824793238411852198197014057", "1030000000000000000000000000"], ["664113161924030706415498330219093881960718987062", "426266162000000000000000000", "862756450305631929804909355672888694510284967705", "287273771000000000000000000", "98228692725380650051062289533337010954411206535", "187685530000000000000000000"]];
const initData = ["13000000000000000000000000", "2500000000000000", "1080000000000000", "1503619200", "1504137600"];

module.exports = function(deployer, network, accounts) {
  const operator = accounts[0];
  (async () => {
    await deployer.deploy(CryptoYen, {"from" : operator});
    let cryptoYen = await CryptoYen.deployed();

    await deployer.deploy(Fund, cryptoYen.address, {"from" : operator});
    let fund = await Fund.deployed();

    await cryptoYen.transferOwnership(fund.address, {"from" : operator});
    
    if (network == "geth_dev"){
      await fund.initBeneficiary(beneficiaryRights[0], beneficiaryRights[1], {"from" : operator});
      await fund.initData(initData, {"from" : operator});
    }

  })();

  
};
