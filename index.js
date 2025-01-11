const ethers = require('ethers');
const Web3 = require('web3');
const dotenv = require('dotenv');
const contractABI = require('./artifacts/contracts/TokenVesting.sol/TokenVesting.json').abi;

class VestingPlatform {
    constructor() {
        dotenv.config();
        this.provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
        this.web3 = new Web3(process.env.RPC_URL);
        this.contractAddress = process.env.VESTING_CONTRACT_ADDRESS;
        this.wallet = new ethers.Wallet(process.env.PRIVATE_KEY, this.provider);
    }

    async initializeContract() {
        this.contract = new ethers.Contract(
            this.contractAddress,
            contractABI,
            this.provider
        );
        this.contractWithSigner = this.contract.connect(this.wallet);
    }

    async createVestingSchedule(
        beneficiary,
        startTime,
        cliffDuration,
        duration,
        slicePeriod,
        revocable,
        amount
    ) {
        const tx = await this.contractWithSigner.createVestingSchedule(
            beneficiary,
            startTime,
            cliffDuration,
            duration,
            slicePeriod,
            revocable,
            ethers.utils.parseEther(amount.toString())
        );
        return await tx.wait();
    }

    async getVestingSchedule(scheduleId) {
        const schedule = await this.contract.getVestingSchedule(scheduleId);
        return {
            beneficiary: schedule.beneficiary,
            cliff: schedule.cliff.toString(),
            start: schedule.start.toString(),
            duration: schedule.duration.toString(),
            slicePeriodSeconds: schedule.slicePeriodSeconds.toString(),
            revocable: schedule.revocable,
            amountTotal: ethers.utils.formatEther(schedule.amountTotal),
            released: ethers.utils.formatEther(schedule.released),
            revoked: schedule.revoked
        };
    }

    async releaseTokens(scheduleId, amount) {
        const tx = await this.contractWithSigner.release(
            scheduleId,
            ethers.utils.parseEther(amount.toString())
        );
        return await tx.wait();
    }

    async revokeSchedule(scheduleId) {
        const tx = await this.contractWithSigner.revoke(scheduleId);
        return await tx.wait();
    }

    async getWithdrawableAmount() {
        const amount = await this.contract.getWithdrawableAmount();
        return ethers.utils.formatEther(amount);
    }

    // Event Listeners
    async listenToEvents() {
        this.contract.on("VestingScheduleCreated", (id, beneficiary, amount, event) => {
            console.log(`Yeni vesting planı oluşturuldu:
                ID: ${id}
                Beneficiary: ${beneficiary}
                Amount: ${ethers.utils.formatEther(amount)} tokens`);
        });

        this.contract.on("TokensReleased", (id, amount, event) => {
            console.log(`Tokenlar serbest bırakıldı:
                ID: ${id}
                Amount: ${ethers.utils.formatEther(amount)} tokens`);
        });

        this.contract.on("VestingScheduleRevoked", (id, event) => {
            console.log(`Vesting planı iptal edildi: ${id}`);
        });
    }

    // Yardımcı fonksiyonlar
    computeVestingScheduleId(beneficiary) {
        return this.contract.computeNextVestingScheduleIdForHolder(beneficiary);
    }
}

module.exports = VestingPlatform; 