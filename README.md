# stETH Depeg Sentinel — Drosera Trap

A Drosera Trap that monitors the Lido stETH total pooled ETH on Hoodi testnet
and triggers an alert if a potential depeg event is detected.

## Use Case

**Liquid Restaking — Mitigating Depegs**

Lido stETH is one of the most widely used liquid staking tokens in DeFi.
A sudden depeg between stETH and ETH can cause cascading liquidations
across lending protocols and destabilize the broader DeFi ecosystem.

This Trap provides an automated early warning system for such events.

## How It Works

1. **collect()** — Reads `getTotalPooledEther()` and `getTotalShares()` from
   Lido stETH contract on Hoodi testnet every block sample
2. **shouldRespond()** — Compares current pooled ETH vs previous sample
3. If pooled ETH drops more than **5%** → Trap triggers an alert

## Threshold

| Parameter | Value |
|---|---|
| Depeg Threshold | 5% drop |
| Block Sample Size | 10 blocks |
| Cooldown Period | 33 blocks |

## Deployed Contracts (Hoodi Testnet)

| Contract | Address |
|---|---|
| stETH (Lido official) | `0x3508A952176b3c15387C97BE809eaffB1982176a` |
| Trap Config | `0x85E9047F1FCB5C4A14D99Ff7e702605db1D975AB` |
| Drosera Response Contract | `0x25E2CeF36020A736CF8a4D2cAdD2EBE3940F4608` |

## Dryrun Results

- ✅ collect() gas used: 58,154
- ✅ shouldRespond() gas used: 42,130
- ✅ No errors
- ✅ Green blocks confirmed on-chain

## References

- [Drosera Use Cases — Liquid Restaking](https://dev.drosera.io/use-cases)
- [Lido Deployed Contracts — Hoodi](https://docs.lido.fi/deployed-contracts/hoodi)

## Author

- Discord: aymgeprexlevmax
- GitHub: DAOmindbreaker
