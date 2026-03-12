// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

/**
 * @title stETH Depeg Sentinel
 * @author DAOmindbreaker
 * @notice Production-ready Drosera Trap that monitors Lido stETH health on Hoodi testnet
 * @dev Detects potential depeg events by monitoring:
 *      1. Total pooled ETH drop > 5% across 3 consecutive samples
 *      2. Abnormal share/pooled ratio changes
 *      3. Minimum absolute value checks to prevent false triggers
 *
 * Use Case Reference: Liquid Restaking — Mitigating Depegs (dev.drosera.io/use-cases)
 * Lido stETH on Hoodi: 0x3508A952176b3c15387C97BE809eaffB1982176a
 */

interface IStETH {
    /// @notice Returns total ETH pooled in Lido protocol
    function getTotalPooledEther() external view returns (uint256);
    /// @notice Returns total stETH shares in existence
    function getTotalShares() external view returns (uint256);
}

contract StEthDepegSentinel is ITrap {

    /// @notice Lido stETH contract on Hoodi testnet (official)
    address public constant STETH = 0x3508A952176b3c15387C97BE809eaffB1982176a;

    /// @notice Trigger if pooled ETH drops below 95% of previous sample (5% drop)
    uint256 public constant DEPEG_THRESHOLD = 95;

    /// @notice Minimum pooled ETH to prevent false triggers on low liquidity
    /// @dev Set to 1 ETH minimum — below this value we skip the check
    uint256 public constant MIN_POOLED_ETH = 1 ether;

    /// @notice Maximum allowed ratio change per sample to catch gradual depegs
    /// @dev If shares/pooled ratio changes more than 10% = suspicious
    uint256 public constant MAX_RATIO_CHANGE = 10;

    /**
     * @notice Collects current stETH health metrics
     * @dev Reads totalPooledEther and totalShares from Lido stETH contract
     * @return Encoded (totalPooledEther, totalShares, ratio)
     *         ratio = (totalShares * 1e18) / totalPooledEther
     */
    function collect() external view returns (bytes memory) {
        IStETH steth = IStETH(STETH);

        uint256 totalPooledEther = steth.getTotalPooledEther();
        uint256 totalShares = steth.getTotalShares();

        // Calculate share/pooled ratio scaled to 1e18 for precision
        uint256 ratio = 0;
        if (totalPooledEther > 0) {
            ratio = (totalShares * 1e18) / totalPooledEther;
        }

        return abi.encode(totalPooledEther, totalShares, ratio);
    }

    /**
     * @notice Analyzes 3 data samples to detect depeg patterns
     * @dev Checks two conditions:
     *      1. Pooled ETH drop > 5% between latest and oldest sample
     *      2. Share ratio change > 10% indicating abnormal behavior
     * @param data Array of encoded (totalPooledEther, totalShares, ratio) per block
     * @return (true, encodedData) if depeg detected, (false, "") otherwise
     */
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory) {
        // Need at least 3 data points for reliable detection
        if (data.length < 3) return (false, bytes(""));

        (uint256 currentPooled, , uint256 currentRatio) =
            abi.decode(data[0], (uint256, uint256, uint256));

        (, , uint256 midRatio) =
            abi.decode(data[1], (uint256, uint256, uint256));

        (uint256 oldestPooled, , uint256 oldestRatio) =
            abi.decode(data[2], (uint256, uint256, uint256));

        // Skip if pooled ETH is below minimum — not enough liquidity to monitor
        if (currentPooled < MIN_POOLED_ETH || oldestPooled < MIN_POOLED_ETH) {
            return (false, bytes(""));
        }

        // Check 1: Significant pooled ETH drop across 3 samples
        uint256 pooledRatio = (currentPooled * 100) / oldestPooled;
        if (pooledRatio < DEPEG_THRESHOLD) {
            return (true, abi.encode(currentPooled, oldestPooled, currentRatio, oldestRatio));
        }

        // Check 2: Abnormal ratio change across all 3 samples
        // Both mid and current ratios should be consistent with oldest
        if (oldestRatio > 0) {
            uint256 ratioChange = (currentRatio * 100) / oldestRatio;
            uint256 midRatioChange = (midRatio * 100) / oldestRatio;

            bool currentAbnormal = ratioChange > (100 + MAX_RATIO_CHANGE) ||
                                   ratioChange < (100 - MAX_RATIO_CHANGE);
            bool midAbnormal = midRatioChange > (100 + MAX_RATIO_CHANGE) ||
                               midRatioChange < (100 - MAX_RATIO_CHANGE);

            // Trigger only if BOTH mid and current are abnormal = sustained anomaly
            if (currentAbnormal && midAbnormal) {
                return (true, abi.encode(currentPooled, oldestPooled, currentRatio, oldestRatio));
            }
        }

        return (false, bytes(""));
    }
}
