// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenVesting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
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

    // Token adresi
    IERC20 private immutable _token;
    
    // Vesting planları
    bytes32[] private vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) private vestingSchedules;
    mapping(address => uint256) private holdersVestingCount;

    // Events
    event VestingScheduleCreated(bytes32 indexed id, address beneficiary, uint256 amount);
    event VestingScheduleRevoked(bytes32 indexed id);
    event TokensReleased(bytes32 indexed id, uint256 amount);
    
    uint256 private vestingSchedulesCount;
    uint256 private vestingSchedulesTotalAmount;
    
    constructor(address token_) {
        require(token_ != address(0x0));
        _token = IERC20(token_);
    }
    
    receive() external payable {}
    
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _amount
    ) external onlyOwner {
        require(getWithdrawableAmount() >= _amount, "TokenVesting: cannot create vesting schedule");
        require(_duration > 0, "TokenVesting: duration must be > 0");
        require(_amount > 0, "TokenVesting: amount must be > 0");
        require(_slicePeriodSeconds >= 1, "TokenVesting: slicePeriodSeconds must be >= 1");
        
        bytes32 vestingScheduleId = computeNextVestingScheduleIdForHolder(_beneficiary);
        
        vestingSchedules[vestingScheduleId] = VestingSchedule(
            true,
            _beneficiary,
            _cliff,
            _start,
            _duration,
            _slicePeriodSeconds,
            _revocable,
            _amount,
            0,
            false
        );
        
        vestingSchedulesIds.push(vestingScheduleId);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.add(_amount);
        holdersVestingCount[_beneficiary] = holdersVestingCount[_beneficiary].add(1);
        
        emit VestingScheduleCreated(vestingScheduleId, _beneficiary, _amount);
    }
    
    function revoke(bytes32 vestingScheduleId) external onlyOwner {
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        require(vestingSchedule.initialized, "TokenVesting: vesting schedule not initialized");
        require(vestingSchedule.revocable, "TokenVesting: vesting schedule not revocable");
        require(!vestingSchedule.revoked, "TokenVesting: vesting schedule already revoked");
        
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        if (vestedAmount > 0) {
            release(vestingScheduleId, vestedAmount);
        }
        
        uint256 unreleased = vestingSchedule.amountTotal.sub(vestingSchedule.released);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(unreleased);
        vestingSchedule.revoked = true;
        
        emit VestingScheduleRevoked(vestingScheduleId);
    }
    
    function release(bytes32 vestingScheduleId, uint256 amount) public nonReentrant {
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        require(vestingSchedule.initialized, "TokenVesting: vesting schedule not initialized");
        require(!vestingSchedule.revoked, "TokenVesting: vesting schedule revoked");
        require(msg.sender == vestingSchedule.beneficiary || msg.sender == owner(), "TokenVesting: only beneficiary and owner can release vested tokens");
        
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount >= amount, "TokenVesting: cannot release tokens, not enough vested tokens");
        
        vestingSchedule.released = vestingSchedule.released.add(amount);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(amount);
        
        require(_token.transfer(vestingSchedule.beneficiary, amount), "TokenVesting: transfer failed");
        emit TokensReleased(vestingScheduleId, amount);
    }
    
    function _computeReleasableAmount(VestingSchedule memory vestingSchedule) internal view returns (uint256) {
        if (block.timestamp < vestingSchedule.start.add(vestingSchedule.cliff)) {
            return 0;
        }
        
        if (block.timestamp >= vestingSchedule.start.add(vestingSchedule.duration)) {
            return vestingSchedule.amountTotal.sub(vestingSchedule.released);
        }
        
        uint256 timeFromStart = block.timestamp.sub(vestingSchedule.start);
        uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
        uint256 vestedSlicePeriods = timeFromStart.div(secondsPerSlice);
        uint256 vestedSeconds = vestedSlicePeriods.mul(secondsPerSlice);
        uint256 vestedAmount = vestingSchedule.amountTotal.mul(vestedSeconds).div(vestingSchedule.duration);
        
        return vestedAmount.sub(vestingSchedule.released);
    }
    
    function computeNextVestingScheduleIdForHolder(address holder) public view returns (bytes32) {
        return keccak256(abi.encodePacked(holder, holdersVestingCount[holder], block.timestamp));
    }
    
    function getVestingSchedule(bytes32 vestingScheduleId) public view returns (VestingSchedule memory) {
        return vestingSchedules[vestingScheduleId];
    }
    
    function getWithdrawableAmount() public view returns (uint256) {
        return _token.balanceOf(address(this)).sub(vestingSchedulesTotalAmount);
    }
} 