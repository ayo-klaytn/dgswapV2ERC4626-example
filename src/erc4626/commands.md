## Dgswap Interactions

Pancake V2Router 0x8203cBc504CE43c3Cad07Be0e057f25B1d4DB578
Pancake V2 Factory: 0x224302153096E3ba16c4423d9Ba102D365a94B2B 

## Compilation

forge build

[⠊] Compiling...
[⠃] Compiling 31 files with Solc 0.8.30
[⠊] Solc 0.8.30 finished in 2.97s

## Vault Deployment

```bash
forge script --chain 8217 script/DGswapV2ERC4626.s.sol:DGswapV2ERC4626Script --rpc-url $KAIA_RPC_URL --broadcast -vvvv --account vault-deployer
```

// 0x0D71982FFb590aBA1B4a11eaa84313de05c9575E

## Fork Mainnet example

```bash
anvil --fork-url $KAIA_RPC_URL --fork-block-number 201274793 --fork-chain-id 8217 
```

## Run test command 

### deposit

```bash
forge test --match-test test_DepositAndEarnFees --fork-url $LOCAL_RPC_URL -vv
```

### deposit and redeem

```bash
forge test --match-test test_RedeemAfterFees --fork-url $LOCAL_RPC_URL -vv
```

