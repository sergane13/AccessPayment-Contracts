const chai = require("chai");
const { ethers } = require("hardhat");
const {solidity} = require("ethereum-waffle");

chai.use(solidity);

const { expect } = require("chai");

describe("Contracts", function () {

  let accessContract;
  let paymentContract;

  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function(){
    const access = await ethers.getContractFactory("Access");
    const payment = await ethers.getContractFactory("Payment");
    
    accessContract = await access.deploy();
    paymentContract = await payment.deploy(accessContract.address);

    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

  })

  describe("Payment", async function(){
    it("Create services", async function () {
    
      await paymentContract.createService(5, 0);
      await paymentContract.createService(50, 1);
      await paymentContract.createService(500, 2);
      await paymentContract.createService(5000, 0);
  
      expect(await paymentContract.getNumberOfServices()).to.equal(4);
    });

    it("Shall Stop service", async function() {

      await paymentContract.createService(5, 0);

      await paymentContract.stopService(0);

      const [activ, ...other] = await paymentContract.getService(0);

      expect(activ).to.equal(false);
    });

    it("Shall Start service", async function() {
      await paymentContract.createService(5, 0); 

      await paymentContract.stopService(0);

      await paymentContract.startService(0);

      const [activ, ...other] = await paymentContract.getService(0);

      expect(activ).to.equal(true);
    })
    
    //it("Shall revert", async function() {

      //   await paymentContract.createService(5, 0);
  
      //   expect(paymentContract.startService(0)).to.be.reverted; // huge problems
      // });
  })
});
