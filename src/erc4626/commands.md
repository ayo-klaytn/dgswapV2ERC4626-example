## Dgswap Interactions

Pancake V2Router 0x8203cBc504CE43c3Cad07Be0e057f25B1d4DB578
Pancake V2 Factory: 0x224302153096E3ba16c4423d9Ba102D365a94B2B 
USDT / BORA Liquidity Pair : 0x4e6de3b8d9c3a773df245590e80e229b0deaffa0

cast call 0x224302153096E3ba16c4423d9Ba102D365a94B2B "getPair(address, address)" 0xd077a400968890eacc75cdc901f0356c943e4fdb 0x02cbe46fb8a1f579254a9b485788f2d86cad51aa --rpc-url $KAIA_RPC_URL

Smart Router calls factory
// cast call 0x5ea3e22c41b08dd7dc7217549939d987ed410354 "factory()"  --rpc-url $KAIA_RPC_URL
// returns 0x7431a23897eca6913d5c81666345d39f27d946a4 which is DG Swap V3 Factory

https://dgswap.io/v2/add/0xd077a400968890eacc75cdc901f0356c943e4fdb/0x02cbe46fb8a1f579254a9b485788f2d86cad51aa/

## Compilation

forge build

[⠊] Compiling...
[⠃] Compiling 31 files with Solc 0.8.30
[⠊] Solc 0.8.30 finished in 2.97s

## Vault Deployment

# To deploy our contract
forge script --chain 8217 script/UniswapV2ERC4626.s.sol:UniswapV2ERC4626Script --rpc-url $KAIA_RPC_URL --broadcast -vvvv --account vault-deployer

// 0xe04806BCFe0eA9e3158591D5312f88407b5b8143,
// 0xf3aa4Bbe5A0d668C931997046FfBd53603D94049,
// 0x0D71982FFb590aBA1B4a11eaa84313de05c9575E

## Vault Interaction

### Balances

USDT
cast call --rpc-url $KAIA_RPC_URL 0xd077A400968890Eacc75cdc901F0356c943e4fDb "balanceOf(address)(uint256)" 0xbce63229e7b545b2de6fff5d98cf677e7346ee7b

BORA
cast call --rpc-url $KAIA_RPC_URL 0x02cbE46fB8A1F579254a9B485788f2D86Cad51aa "balanceOf(address)(uint256)" 0xbce63229e7b545b2de6fff5d98cf677e7346ee7b


### Approvals 

Enable UniswapV2ERC4626 to be able to spend both USDT and BORA tokens by calling approve function

USDT APPROVE
cast send --rpc-url $KAIA_RPC_URL 0xd077A400968890Eacc75cdc901F0356c943e4fDb "approve(address, uint256)" 0xf3aa4Bbe5A0d668C931997046FfBd53603D94049 500000000 --account vault-deployer
cast send --rpc-url $KAIA_RPC_URL 0xd077A400968890Eacc75cdc901F0356c943e4fDb "approve(address,uint256)" 0x0D71982FFb590aBA1B4a11eaa84313de05c9575E 115792089237316195423570985008687907853269984665640564039457584007913129639935 --account vault-deployer

BORA APPROVE
cast send --rpc-url $KAIA_RPC_URL 0x02cbE46fB8A1F579254a9B485788f2D86Cad51aa "approve(address, uint256)" 0xf3aa4Bbe5A0d668C931997046FfBd53603D94049 500000000000000000000 --account vault-deployer
cast send --rpc-url $KAIA_RPC_URL 0x02cbE46fB8A1F579254a9B485788f2D86Cad51aa "approve(address,uint256)" 0x0D71982FFb590aBA1B4a11eaa84313de05c9575E 115792089237316195423570985008687907853269984665640564039457584007913129639935 --account vault-deployer

### Allowance

USDT
cast call --rpc-url $KAIA_RPC_URL 0xd077A400968890Eacc75cdc901F0356c943e4fDb "allowance(address,address)(uint256)" 0xbce63229e7b545b2de6fff5d98cf677e7346ee7b 0x0D71982FFb590aBA1B4a11eaa84313de05c9575E

BORA
cast call --rpc-url $KAIA_RPC_URL 0x02cbE46fB8A1F579254a9B485788f2D86Cad51aa "allowance(address,address)(uint256)" 0xbce63229e7b545b2de6fff5d98cf677e7346ee7b 0x0D71982FFb590aBA1B4a11eaa84313de05c9575E


### Call getAssetAmount 
getAssetAmount: 0.00001000 LP tokens passed in
cast call 0xe04806BCFe0eA9e3158591D5312f88407b5b8143 "getAssetsAmounts(uint256)" 10000000000000 --rpc-url $KAIA_RPC_URL
cast call --rpc-url $KAIA_RPC_URL 0x0D71982FFb590aBA1B4a11eaa84313de05c9575E "getAssetsAmounts(uint256)(uint256,uint256)" 4000000000000


### Call deposit (make sure to have noth tokens)
deposit(getUniLpFromAssets_, receiver_)

cast send --rpc-url $KAIA_RPC_URL 0x0D71982FFb590aBA1B4a11eaa84313de05c9575E "deposit(uint256,address)" 4000000000000 0xbce63229e7b545b2de6fff5d98cf677e7346ee7b --account vault-deployer


Check Vault LP balance:
cast call --rpc-url $KAIA_RPC_URL 0x0D71982FFb590aBA1B4a11eaa84313de05c9575E "totalAssets()(uint256)"

## After Swap

### Check reserve

cast call --rpc-url $KAIA_RPC_URL 0x4E6DE3b8D9C3a773df245590E80e229B0deafFa0 "getReserves()(uint112,uint112,uint32)"


### Withdraw

cast send --rpc-url $KAIA_RPC_URL 0x0D71982FFb590aBA1B4a11eaa84313de05c9575E "withdraw(uint256,address,address)" 4000000000000 0xbce63229e7b545b2de6fff5d98cf677e7346ee7b 0xbce63229e7b545b2de6fff5d98cf677e7346ee7b --account vault-deployer


# Fork Mainnet example
anvil --fork-url $KAIA_RPC_URL --fork-block-number 201274793 --fork-chain-id 8217 

# run test command 

## deposit
forge test --match-test test_DepositAndEarnFees --fork-url $LOCAL_RPC_URL -vv

## deposit and redeem
forge test --match-test test_RedeemAfterFees --fork-url $LOCAL_RPC_URL -vv


