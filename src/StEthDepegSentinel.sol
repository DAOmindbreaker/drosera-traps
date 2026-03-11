// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

/**
 * @title stETH Depeg Sentinel
 * @notice Monitors Lido stETH total pooled ETH on Hoodi testnet
 * @dev Triggers if total pooled ETH drops more than 5% between samples
 * Use Case: Liquid Restaking — Mitigating Depegs (Drosera Docs)
 * stETH on Hoodi: 0x3508A952176b3c15387C97BE809eaffB1982176a
 */

interface IStETH {
    function getTotalPooledEther() external view returns (uint256);
    function getTotalShares() external view returns (uint256);
}

contract StEthDepegSentinel is ITrap {

    /// @notice stETH contract on Hoodi testnet (Lido official)
    address public constant STETH = 0x3508A952176b3c15387C97BE809eaffB1982176a;

    /// @notice Trigger if pooled ETH drops more than 5%
    uint256 public constant DEPEG_THRESHOLD = 95;

    function collect() external view returns (bytes memory) {
        IStETH steth = IStETH(STETH);
        uint256 totalPooledEther = steth.getTotalPooledEther();
        uint256 totalShares = steth.getTotalShares();
        return abi.encode(totalPooledEther, totalShares);
    }

    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory) {
        if (data.length < 2) return (false, bytes(""));

        (uint256 currentPooled,) = abi.decode(data[0], (uint256, uint256));
        (uint256 previousPooled,) = abi.decode(data[1], (uint256, uint256));

        if (previousPooled == 0) return (false, bytes(""));

        uint256 ratio = (currentPooled * 100) / previousPooled;

        if (ratio < DEPEG_THRESHOLD) {
            return (true, abi.encode(currentPooled, previousPooled));
        }

        return (false, bytes(""));
    }
}
