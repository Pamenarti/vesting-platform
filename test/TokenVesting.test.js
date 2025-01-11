const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TokenVesting", function () {
    let TokenVesting, vesting, TestToken, token;
    let owner, beneficiary, addr2;
    
    const amount = ethers.utils.parseEther("1000");
    const duration = 1000;
    const slicePeriod = 1;
    
    beforeEach(async function () {
        [owner, beneficiary, addr2] = await ethers.getSigners();
        
        // Deploy test token
        TestToken = await ethers.getContractFactory("TestToken");
        token = await TestToken.deploy();
        await token.deployed();
        
        // Deploy vesting contract
        TokenVesting = await ethers.getContractFactory("TokenVesting");
        vesting = await TokenVesting.deploy(token.address);
        await vesting.deployed();
        
        // Transfer tokens to vesting contract
        await token.transfer(vesting.address, amount);
    });
    
    describe("Deployment", function () {
        it("Should set the right token", async function () {
            expect(await vesting.getToken()).to.equal(token.address);
        });
    });
    
    describe("Vesting Schedule Creation", function () {
        it("Should create vesting schedule", async function () {
            const now = Math.floor(Date.now() / 1000);
            
            await vesting.createVestingSchedule(
                beneficiary.address,
                now,
                0,
                duration,
                slicePeriod,
                true,
                amount
            );
            
            const scheduleId = await vesting.computeNextVestingScheduleIdForHolder(beneficiary.address);
            const schedule = await vesting.getVestingSchedule(scheduleId);
            
            expect(schedule.beneficiary).to.equal(beneficiary.address);
            expect(schedule.amountTotal).to.equal(amount);
        });
    });
    
    describe("Token Release", function () {
        it("Should release tokens after cliff", async function () {
            const now = Math.floor(Date.now() / 1000);
            const cliff = 100;
            
            await vesting.createVestingSchedule(
                beneficiary.address,
                now,
                cliff,
                duration,
                slicePeriod,
                true,
                amount
            );
            
            // Time travel after cliff
            await network.provider.send("evm_increaseTime", [cliff + 1]);
            await network.provider.send("evm_mine");
            
            const scheduleId = await vesting.computeNextVestingScheduleIdForHolder(beneficiary.address);
            await vesting.connect(beneficiary).release(scheduleId, amount.div(2));
            
            expect(await token.balanceOf(beneficiary.address)).to.equal(amount.div(2));
        });
    });
}); 