# 🔒 Token Vesting Platform

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Solidity](https://img.shields.io/badge/solidity-%5E0.8.0-blue)
![Node](https://img.shields.io/badge/node-%3E%3D14.0.0-green)
![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)

## 📝 Description

A comprehensive token vesting platform for managing token distributions with customizable schedules, cliff periods, and revocation capabilities. Perfect for ICOs, team tokens, and investor allocations.

### 🚀 Features

- ⏰ Customizable vesting schedules
- 🔄 Linear and cliff vesting
- 🔐 Revocable vesting plans
- 📊 Real-time vesting tracking
- 💼 Multi-beneficiary support
- ⚡ Gas-optimized releases
- 🛡️ Secure token locks

## 🛠 Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/vesting-platform

# Navigate to project directory
cd vesting-platform

# Install dependencies
npm install

# Create environment file
cp .env.example .env
```

## ⚙️ Configuration

Configure your \`.env\` file:

```env
RPC_URL=your_rpc_url
PRIVATE_KEY=your_private_key
VESTING_CONTRACT_ADDRESS=deployed_contract_address
```

## 📖 Usage Examples

### Create Vesting Schedule

```javascript
const VestingPlatform = require('./index.js');
const vesting = new VestingPlatform();

// Team tokens vesting
const MONTH = 30 * 24 * 60 * 60; // 30 days in seconds
await vesting.createVestingSchedule(
    teamAddress,
    Date.now(),      // start time
    6 * MONTH,       // 6 month cliff
    24 * MONTH,      // 2 year duration
    MONTH,           // Monthly releases
    true,            // Revocable
    "1000000"        // 1M tokens
);
```

### Release Tokens

```javascript
// Release available tokens
const scheduleId = await vesting.computeVestingScheduleId(beneficiaryAddress);
await vesting.releaseTokens(scheduleId, amount);
```

## 📊 Vesting Templates

| Type | Cliff | Duration | Release Frequency |
|------|-------|----------|------------------|
| Team | 6 months | 24 months | Monthly |
| Advisors | 3 months | 18 months | Monthly |
| Private Sale | 1 month | 12 months | Weekly |
| Public Sale | None | 6 months | Daily |

## 🔒 Security Features

### Schedule Management
```javascript
// Revoke vesting schedule
await vesting.revokeSchedule(scheduleId);

// Check withdrawable amount
const available = await vesting.getWithdrawableAmount();
```

### Vesting Checks
```solidity
// Built-in security checks
require(vestingSchedule.initialized, "Not initialized");
require(!vestingSchedule.revoked, "Schedule revoked");
require(vestedAmount >= amount, "Insufficient vested amount");
```

## 📈 Event Monitoring

```javascript
// Listen to vesting events
vesting.listenToEvents();

// Events available:
// - VestingScheduleCreated
// - TokensReleased
// - VestingScheduleRevoked
```

## 🧪 Testing

```bash
# Run all tests
npx hardhat test

# Run specific test file
npx hardhat test test/TokenVesting.test.js

# Get coverage report
npx hardhat coverage
```

## 📈 Contract Functions

| Function | Description | Access |
|----------|-------------|--------|
| \`createVestingSchedule\` | Create new vesting schedule | Owner |
| \`release\` | Release vested tokens | Beneficiary/Owner |
| \`revoke\` | Revoke vesting schedule | Owner |
| \`getVestingSchedule\` | Get schedule details | Public |

## 🛡️ Security Measures

- ✅ Reentrancy protection
- ✅ SafeMath operations
- ✅ Access controls
- ✅ Schedule validation
- ✅ Emergency pause
- ✅ Gas optimization

## 🔍 Implementation Details

```solidity
struct VestingSchedule {
    bool initialized;
    address beneficiary;
    uint256 cliff;
    uint256 start;
    uint256 duration;
    uint256 slicePeriodSeconds;
    bool revocable;
    uint256 amountTotal;
    uint256 released;
    bool revoked;
}
```

## 🤝 Contributing

1. Fork the Project
2. Create your Feature Branch (\`git checkout -b feature/AmazingFeature\`)
3. Commit your Changes (\`git commit -m 'Add some AmazingFeature'\`)
4. Push to the Branch (\`git push origin feature/AmazingFeature\`)
5. Open a Pull Request

## 📜 License

Distributed under the MIT License. See \`LICENSE\` for more information.

## 📞 Contact

Paro - [@Pamenarti](https://twitter.com/pamenarti)
Email - [pamenarti@gmail.com](pamenarti@gmail.com)
Project Link: [https://github.com/pamenarti/vesting-platform](https://github.com/pamenarti/vesting-platform)

## 🙏 Acknowledgments

- OpenZeppelin Contracts
- Hardhat
- Ethers.js
- Web3.js 