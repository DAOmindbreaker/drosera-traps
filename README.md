# Lido Protocol Anomaly Sentinel

> A production-ready Drosera Trap that monitors Lido protocol internal health metrics on Hoodi testnet and triggers automated on-chain responses when anomalous accounting behavior is detected across consecutive block samples.

---

## Overview

This repository contains two contracts that work together as a complete Drosera Trap system:

| Contract | Role | Address |
|---|---|---|
| `LidoProtocolAnomalySentinel` | Drosera Trap — collects & analyses Lido state | `0x85E9047F1FCB5C4A14D99Ff7e702605db1D975AB` |
| `LidoSentinelResponse` | Response contract — records anomalies on-chain | `0xD66D199B1583876D914B4ff2Bc2F14e5B64906ce` |

**Use Case Reference:** [Liquid Restaking — Mitigating Depegs](https://dev.drosera.io/use-cases)

---

## What This Trap Monitors

This Trap monitors **Lido protocol-level accounting state** — not market prices. It detects on-chain anomalies that indicate potential protocol health issues before they manifest in market prices.

> For market depeg detection, a DEX/oracle-based Trap would be required. This Trap is intentionally scoped to protocol-level accounting health.

### Contracts Monitored (Lido official on Hoodi testnet)

| Contract | Address |
|---|---|
| stETH | `0x3508A952176b3c15387C97BE809eaffB1982176a` |
| wstETH | `0x7E99eE3C66636DE415D2d7C880938F2f40f94De4` |

---

## Detection Logic

Every block sample, `collect()` captures a `LidoSnapshot` struct containing:
```solidity
struct LidoSnapshot {
    uint256 totalPooledEther;   // Total ETH held by Lido (wei)
    uint256 totalShares;        // Total stETH shares outstanding
    uint256 wstEthRate;         // ETH per 1e18 wstETH shares (scaled 1e18)
    uint256 shareRatioBps;      // Share-to-pooled ratio (basis points)
    bool    valid;              // False if any external call reverted
}
```

`shouldRespond()` analyses 3 consecutive snapshots for sustained anomalies:

### Check A — Pooled ETH Collapse
Immediate trigger if `totalPooledEther` drops more than **5% (500 bps)** versus the oldest sample. No mid-sample confirmation needed — a 5%+ drop is already extreme.

### Check B — wstETH Redemption Rate Drop
Triggers if wstETH rate drops more than **3% (300 bps)** from oldest to current **AND** the mid-sample also shows a drop. Requiring two consecutive declining samples filters noise.

### Check C — Share Ratio Deviation
Triggers if `shareRatioBps` deviates more than **10% (1000 bps)** in **both** mid and current samples. Sustained divergence is a stronger signal than a single-block spike.

---

## Response Contract

`LidoSentinelResponse` receives structured anomaly reports from the Trap and emits fully typed events for off-chain indexers, alert systems, or governance modules.

### Access Control
Only the authorised Trap address (`0x85E9047F1FCB5C4A14D99Ff7e702605db1D975AB`) can call response functions. Any unauthorised call emits `UnauthorisedCall` and reverts with `NotAuthorisedTrap`.

### Response Functions

| Function | Triggered By | Event Emitted |
|---|---|---|
| `recordPooledEthCollapse()` | Check A | `PooledEthCollapse` |
| `recordWstEthRateDrop()` | Check B | `WstEthRateDrop` |
| `recordShareRatioDeviation()` | Check C | `ShareRatioDeviation` |

### Events
```solidity
event PooledEthCollapse(
    uint256 indexed id,
    uint256 currentValue,
    uint256 baselineValue,
    uint256 dropBps,
    uint256 timestamp
);

event WstEthRateDrop(
    uint256 indexed id,
    uint256 currentRate,
    uint256 baselineRate,
    uint256 dropBps,
    uint256 timestamp
);

event ShareRatioDeviation(
    uint256 indexed id,
    uint256 currentRatioBps,
    uint256 baselineRatioBps,
    uint256 deviationBps,
    uint256 timestamp
);
```

---

## Trap Configuration
```toml
[traps.lido_anomaly_sentinel]
path                   = "out/LidoProtocolAnomalySentinel.sol/LidoProtocolAnomalySentinel.json"
response_contract      = "0xD66D199B1583876D914B4ff2Bc2F14e5B64906ce"
response_function      = "recordPooledEthCollapse(uint256,uint256,uint256)"
cooldown_period_blocks = 33
min_number_of_operators = 1
max_number_of_operators = 2
block_sample_size      = 10
private_trap           = true
```

---

## Dryrun Stats
```
trap_name       : lido_anomaly_sentinel
trap_hash       : 0xb3a9af857220406744510e638b257624d1012f386e5c880731da66ccebf12f00
collect() gas   : 62,079
shouldRespond() : 51,670
accounts queried: 6
slots queried   : 7
```

---

## Repository Structure
```
src/
├── LidoProtocolAnomalySentinel.sol   Drosera Trap — ITrap implementation
└── LidoSentinelResponse.sol          Response contract — on-chain anomaly recorder
script/
└── Deploy.s.sol                      Forge deployment script
```

---

## Author

**DAOmindbreaker** — Built for the Drosera Network Hoodi testnet.
X: [@admirjae](https://x.com/admirjae)
