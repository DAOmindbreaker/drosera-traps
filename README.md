# stETH Depeg Sentinel — Drosera Trap

A production-ready Drosera Trap that monitors Lido stETH health on Hoodi testnet
and triggers an automated alert when a potential depeg event is detected.

## Overview

Lido stETH is one of the most widely used liquid staking tokens in DeFi with
billions in TVL. A sudden depeg between stETH and ETH can trigger cascading
liquidations across lending protocols and destabilize the broader DeFi ecosystem.

This Trap provides an **automated early warning system** by continuously
monitoring on-chain stETH health metrics across multiple block samples.

## Use Case Reference

**Liquid Restaking — Mitigating Depegs**
Source: [dev.drosera.io/use-cases](https://dev.drosera.io/use-cases)

## How It Works

### Data Collection — `collect()`
Reads two key metrics from Lido stETH contract every block sample:
- `getTotalPooledEther()` — total ETH pooled in Lido protocol
- `getTotalShares()` — total stETH shares in existence
- Calculates share/pooled ratio scaled to 1e18 for precision

### Detection Logic — `shouldRespond()`
Analyzes **3 consecutive data samples** for two independent checks:

**Check 1 — Pooled ETH Drop**
Compares current pooled ETH vs oldest sample.
If drop exceeds 5% threshold → trigger alert.

**Check 2 — Ratio Anomaly**
Monitors share/pooled ratio change across all 3 samples.
If BOTH mid and current samples show >10% ratio deviation → trigger alert.
Requiring two consecutive anomalies prevents false triggers from single-block spikes.

## Parameters

| Parameter | Value | Description |
|---|---|---|
| `DEPEG_THRESHOLD` | 95% | Trigger if pooled ETH drops below 95% of oldest sample |
| `MIN_POOLED_ETH` | 1 ETH | Skip check if liquidity too low |
| `MAX_RATIO_CHANGE` | 10% | Maximum allowed ratio deviation per sample |
| `block_sample_size` | 10 blocks | Number of blocks per sample window |
| `cooldown_period_blocks` | 33 blocks | Minimum blocks between responses |

## Detection Coverage

This Trap is designed to catch:
- ✅ Sudden large ETH withdrawals from Lido
- ✅ Gradual sustained depeg over multiple blocks
- ✅ Abnormal share/pooled ratio manipulation
- ✅ Protocol-level liquidity drain events

## Deployed Contracts (Hoodi Testnet)

| Contract | Address |
|---|---|
| Lido stETH (official) | `0x3508A952176b3c15387C97BE809eaffB1982176a` |
| Trap Config | `0x85E9047F1FCB5C4A14D99Ff7e702605db1D975AB` |
| Drosera Response Contract | `0x25E2CeF36020A736CF8a4D2cAdD2EBE3940F4608` |

## Performance

| Metric | Value |
|---|---|
| collect() gas used | 58,776 |
| shouldRespond() gas used | 47,760 |
| Deploy block | 2402270 |
| Status | ✅ Live with green blocks |

## References

- [Drosera Use Cases — Liquid Restaking](https://dev.drosera.io/use-cases)
- [Lido Deployed Contracts — Hoodi](https://docs.lido.fi/deployed-contracts/hoodi)
- [Drosera Docs](https://dev.drosera.io)

## Author

- Discord: aymgeprexlevmax
- GitHub: [DAOmindbreaker](https://github.com/DAOmindbreaker)
