var owner = "OWNER";
var abi = ABI;
var code = "0xCODE";

web3.eth.contract(abi).new({ from: owner, data: code, value: web3.toWei(0.01, "ether"), gas: 3000000 });
