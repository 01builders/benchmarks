# ev-node / ev-reth benchmark evaluation

cross-workload performance analysis with deployment recommendations.

**date:** 2026-03-31
**versions:** ev-reth v0.3.0-beta, ev-node v1.0.0
**platform:** linux/amd64, 8 vCPU (x86_64), 15 GiB RAM
**host:** stg-benchmarking-evstack-evm-node-1 (sequencer role)
**state:** near-genesis (fresh chain, minimal trie depth)
**total results:** 68 JSON files across 5 workload types

## glossary

| term | definition |
|------|-----------|
| Mgas/s | millions of gas processed per second of steady-state time. higher = more throughput. computed as `totalGasUsed / steadyStateSec / 1e6` |
| TPS | transactions per second during steady state. `totalTxCount / steadyStateSec` |
| pb_avg (ms) | average duration of `BlockExecutor.ProduceBlock` — the full block lifecycle in ev-node, including ev-reth execution and all Engine API round-trips |
| pb_max (ms) | maximum ProduceBlock duration. values near 10,000ms indicate a retry stall (see below) |
| headroom (ms) | `block_time - pb_avg`. positive = blocks finish before the next slot. negative = system falls behind target block rate |
| overhead (%) | `(ProduceBlock - ExecuteTxs) / ProduceBlock`. ev-node's orchestration cost as a fraction of total block time. 1-5% when blocks are full, 40-75% when blocks are mostly empty. example: if ProduceBlock takes 60ms and ExecuteTxs takes 57ms, overhead = (60-57)/60 = 5%. the 3ms is ev-node's cost for RetrieveBatch, CreateBlock, RPC round-trips, and context propagation |
| reth Ggas/s | gigagas per second computed from `Engine.NewPayload` time only: `totalGasUsed / cumulativeNewPayloadTime / 1e9`. this measures ev-reth's **validation and state commit** throughput, not block building. `GetPayload` (tx selection, EVM execution, state root computation) is excluded. the ratio of GetPayload to NewPayload time varies by tx type, so this metric is **not comparable across workloads or to external benchmarks** that measure end-to-end block build time. it is useful for tracking regressions within the same workload across versions |
| steady state | wall-clock time between the first and last non-empty block in the measurement window. excludes warmup (contract deployment, initial tx injection) and drain (mempool emptying) |
| non-empty % | percentage of blocks containing at least one transaction. low values indicate the system is producing empty blocks due to stalls or insufficient tx injection |
| gas limit | maximum gas per block (genesis config). tested at 30M (`0x1C9C380`) and 100M (`0x5F5E100`) |
| block time | target block production interval. ev-node attempts to produce one block per interval |
| scrape interval | how frequently ev-node's metrics pipeline collects data. should be 1/4 to 1/5 of block time |

## block production pipeline

```
ProduceBlock (ev-node)
├── RetrieveBatch         — fetch txs from sequencer
├── CreateBlock           — construct block header + data
└── ApplyBlock            — execute via ev-reth
    └── ExecuteTxs        — full Engine API flow
        ├── reconcileExecutionAtHeight  — idempotency check
        ├── getBlockInfo                — fetch parent block
        ├── Engine.ForkchoiceUpdated    — trigger payload build
        ├── Engine.GetPayload           — retrieve built payload (tx selection + EVM execution + state root)
        ├── Engine.NewPayload           — validate payload
        └── Engine.ForkchoiceUpdated    — finalize (set head/safe/finalized)
```

## 10-second stall: root cause

23 of 68 results show `pb_max` near 10,000ms. root cause confirmed in code:

**ev-node `executeTxsWithRetry`** (`ev-node/block/internal/common/retry.go`) has a fixed 10s backoff (`MaxRetriesTimeout = 10 * time.Second`). when `ExecuteTxs` fails — typically because ev-reth returns `429 Too Many Requests` when its RPC connection pool is saturated by spamoor tx injection — ev-node waits exactly 10s before retrying. this produces ~100 empty blocks at 100ms block time.

the stalls are **non-deterministic**: identical configs can stall in one run but not another. they correlate with spammer count (more concurrent connections = more contention) and disappear at longer block times (250ms+), which reduce the rate of ev-node's internal RPC calls.

**429 errors confirmed in logs:** 8 of 14 DeFi round 2 runs had `"failed to get tx pool content: 429 Too Many Requests"` in ev-node logs. severity scaled with spammer count: 100m_80pct (10 spammers) had 403 occurrences, lower-concurrency runs had 5-13. no 429s were found in GasBurner, ERC20, StatePressure, or MixedWorkload logs.

## disregarded results

the following DeFi results are **excluded from recommendations** due to confirmed 429 RPC contention causing 10s stalls. the stalls are an artifact of spamoor saturating ev-reth's connection pool, not a block production limitation:

| config | spammers | pb_max (ms) | 429 count | Mgas/s |
|--------|----------|-------------|-----------|--------|
| `100m_80pct` | 10 | 10,276 | 403 | 2.0 |
| `100m_40pct` | 10 | 10,137 | 127 | 3.4 |
| `30m_80pct` | 8 | 10,145 | 20 | 2.2 |
| `30m_80pct_multi_pair` | 8 | 10,289 | — (r1) | 3.9 |
| `30m_40pct` (r1, Mar 26) | 6 | 10,020 | — (r1) | 2.8 |

these ran with 6-10 spammers, all targeting the sequencer RPC on port 8545. ev-node's internal `getBlockInfo` call competes for the same connection pool and gets rejected. production would not have this problem unless external tx submission reached similar concurrency levels. the production fix is a dedicated internal RPC endpoint for ev-node ↔ ev-reth, separate from public tx submission.

the remaining DeFi results (30m_10pct, 30m_20pct, 30m_100pct, 30m_120pct, 100m_10pct r1, 100m_20pct, and all block time variants) are retained. two runs had minor 429s (5 occurrences each) with no stalls.

## peak stable performance per test

optimal config per workload, maximizing Mgas/s while ensuring `pb_avg < block_time` and `pb_max < 5000ms`.

| test | config | gas limit | block time | Mgas/s | TPS | pb_avg (ms) | headroom (ms) | pb_max (ms) | reth Ggas/s |
|------|--------|-----------|-----------|--------|-----|-------------|---------------|-------------|-------------|
| StatePressure | `100m_20pct` | 100M | 100ms | 291.4 | 279.5 | 93.5 | 6.5 | 198.2 | 1.143 |
| MixedWorkload | `100m_10pct` | 100M | 100ms | 245.2 | 491.3 | 78.1 | 21.9 | 285.2 | 0.934 |
| GasBurner | `baseline_100m_100ms` | 100M | 100ms | 223.1 | 225.1 | 74.0 | 26.0 | 112.1 | 0.637 |
| DeFi | `30m_10pct` | 30M | 100ms | 33.1 | 373.2 | 32.5 | 67.5 | 59.1 | 0.318 |
| ERC20 | `30m_10pct` | 30M | 100ms | 27.8 | 703.1 | 32.6 | 67.4 | 96.1 | 0.323 |

all optimal configs use 100ms block time. large-tx workloads (StatePressure 1M gas/tx, GasBurner 1-5M gas/tx) peak at 100M gas limit because blocks can hold more gas without needing more transactions. small-tx workloads (DeFi ~90k, ERC20 ~65k gas/tx) peak at 30M because the test matrix uses more spammers for 100M configs, triggering contention before the gas limit becomes relevant.

## workload analysis

### GasBurner (pure compute, 1-5M gas/tx)

12 configs tested. GasBurner uses a deterministic gasburner contract where each tx consumes a configurable amount of gas through pure computation (no storage). this is the simplest workload and the most predictable.

- **most resilient to stalls.** only 3 of 12 configs stalled, all with extreme gas limits (300M-1G) that push pb_avg well beyond block time. every config at ≤100M gas limit with 100ms blocks is stable.
- **reth efficiency increases with gas per tx.** 5M gas/tx achieves 0.833 Ggas/s vs 0.547 at 1M gas/tx. fewer txs = less per-tx overhead in ev-reth (validation, nonce check, receipt generation).
- **negative headroom is survivable.** `high_gas_per_tx_100m` has pb_avg=124ms (>100ms block time) but no stalls. the system produces blocks at ~8/s instead of 10/s. it falls behind the target cadence but doesn't fail.
- **block time has minimal impact on stability.** GasBurner is stable at 100ms for all reasonable gas limits. longer block times (250ms, 500ms, 1s) reduce Mgas/s without improving stability.
- **overhead is consistently low** (0.8-3.6%). compute-heavy txs spend most of ProduceBlock inside ev-reth, leaving little fixed-cost fraction.

### ERC20 (light txs, ~65k gas/tx)

11 configs tested. each tx is a simple ERC-20 token transfer (~65k gas). this is the most demanding workload for block production because filling blocks requires many transactions.

- **narrowest stable window at 100ms.** only `30m_10pct` (2 spammers) is stable at 100ms. the cliff is between 10% and 20% target utilization — `30m_20pct` (6 spammers) already stalls.
- **100M gas limit performs 3-4x worse than 30M** at every utilization level. filling 10% of 100M requires ~3.3x more txs than 10% of 30M. the matrix achieves this by adding spammers (8 for 100m_10pct vs 4 for 30m_10pct), saturating the RPC pool.
- **highest TPS of any workload** (703 at 30m_10pct) because each tx uses the least gas. Mgas/s is low (28) but the chain processes the most transactions per second.
- **block time sweep: 500ms is the first fully stable interval.** 250ms still showed one stall. 1s is stable but low throughput (6 Mgas/s, 146 TPS).
- **50ms block time tested once** (30m_40pct_50ms): 55% non-empty blocks, 62% overhead, 20s stall (double retry). sub-100ms is not viable for high-tx-count workloads because the Engine API round-trip (ForkchoiceUpdated → GetPayload → NewPayload → ForkchoiceUpdated) takes 30-43ms minimum even with empty blocks. at 50ms block time, that leaves 7-20ms for actual EVM execution. any non-trivial block fill pushes pb_avg past 50ms, causing the system to fall behind cadence. when it falls far enough behind, the retry mechanism fires (10s fixed backoff), compounding into 20s stalls as seen here.
- **high overhead when unstable** (42-75%). the 10s stall produces ~100 empty blocks, which are fast but count toward ProduceBlock total, inflating the orchestration fraction.

### DeFi / Uniswap V2 (~60-90k gas/tx)

21 results across 13 configs and two rounds (March 26 and March 30). each tx is a Uniswap V2 swap involving deep call chains, event emission, and multi-contract storage operations. round 1 had 7 passes and 6 timeouts (15m go test limit). round 2 completed all 13 with `--timeout 45m`.

- **stalls are non-deterministic.** `30m_40pct` stalled in round 1 (pb_max=10,020ms) but not round 2 (pb_max=164ms). this is the clearest evidence that stalls are triggered by transient RPC contention, not deterministic load.
- **significant run-to-run variance.** `30m_100pct` went from 6.5 to 14.3 Mgas/s between rounds (2.2x). three repeated `30m_10pct` runs scored 22.9, 33.1, and 23.9 Mgas/s (1.4x range).
- **actual utilization far below target** at high concurrency. `30m_100pct` best run achieved ~4.8% actual utilization (target 100%). tx pool contention and nonce conflicts at 10 spammers prevent the chain from seeing the injected load.
- **block time sweep confirms stall elimination.** `30m_80pct` stalls at 100ms, stable at 250ms and 1s. same pattern as ERC20.
- **100M underperforms 30M** at equivalent targets. DeFi txs are small enough that the extra spammers needed for 100M cause contention without filling larger blocks.
- **429 errors confirmed in 8 of 14 round 2 runs** but only 5 caused 10s stalls (those are disregarded above). 3 runs had minor 429s (5-13 occurrences) with no impact on throughput.

### StatePressure (storage writes, 1-2M gas/tx)

13 configs tested. each tx maximizes SSTORE operations, creating rapid state growth. this stresses state root computation in ev-reth's `builder.finish()`.

- **most resilient workload overall.** only 1 of 13 configs stalled (`100m_40pct`, 4 spammers). all 30M configs at 100ms are stable, even at 120% target utilization. this is because 1-2M gas/tx means very few txs per block, minimizing RPC and tx pool contention.
- **ev-reth achieves its highest efficiency** with storage writes: 1.143 Ggas/s stable (100m_20pct), 1.458 Ggas/s unstable (100m_40pct). this is 3.5x higher than DeFi/ERC20. SSTORE operations are well-optimized in reth's EVM.
- **100M gas limit is beneficial** for StatePressure, unlike other workloads. `100m_20pct` achieves 291 Mgas/s vs `30m_40pct` at 191 Mgas/s. large txs fill bigger blocks with fewer transactions, so the extra capacity is used without contention.
- **heavy write variant** (2M gas/tx) performs similarly to standard 1M: 142 vs 145 Mgas/s at 30m_80pct. per-tx storage depth is not a bottleneck.
- **overhead is the lowest of any workload** (1.3-3.9%). storage writes have minimal per-tx orchestration cost and blocks are well-packed.
- **critical caveat:** these results are from near-genesis state. StatePressure explicitly grows the state trie, so production performance will degrade as the trie deepens. this is the test most likely to show state-size regression.

### MixedWorkload (40% ERC20, 30% DeFi, 20% GasBurner, 10% StatePressure)

13 configs tested. the closest approximation to real chain traffic. implemented on `cian/mixed-benchmark-test` branch. spammers are distributed across tx types using a largest-remainder allocation (minimum 1 per type, minimum 4 total).

- **stability tracks the DeFi/MixedWorkload boundary, not ERC20.** stable at 100ms through 40% target utilization. the stall cliff is between 40% and 80%. ERC20 alone stalls at >10%, but the GasBurner/StatePressure components (30% of spammers) fill blocks with large txs efficiently, compensating.
- **throughput is high relative to DeFi/ERC20.** 140 Mgas/s at `30m_20pct`, 136 at `30m_40pct`. this is closer to GasBurner/StatePressure than DeFi/ERC20 because the large-tx components contribute disproportionately to gas throughput.
- **250ms eliminates stalls.** `30m_80pct_250ms` (88.6 Mgas/s, 164 TPS, no stalls) vs `30m_80pct` (116.1 Mgas/s, 222 TPS, 10s stall). this validates the profile 2 recommendation (250ms / 30M for peak <50%).
- **100M gas limit shows a sharp cliff.** `100m_10pct` is stable and the second-highest Mgas/s in the entire dataset (245.2). but `100m_20pct` and above all stall. the extra spammers needed for higher utilization at 100M push past the contention threshold.
- **all-round recommendation validated.** profile 1 (`30m_10pct` and `30m_20pct` at 100ms) produces 100% non-empty blocks, <3.5% overhead, no stalls. profile 2 (`30m_80pct_250ms`) is stable at higher load.

## key findings

### ev-reth efficiency scales with tx size

| workload | gas/tx | reth Ggas/s (best stable) |
|----------|--------|--------------------------|
| StatePressure | 1M | 1.143 |
| GasBurner | 1-5M | 0.833 |
| MixedWorkload | mixed | 0.934 |
| ERC20 | ~65k | 0.323 |
| DeFi | ~90k | 0.318 |

each transaction has fixed per-tx overhead (validation, nonce check, gas accounting, receipt generation). large txs amortize this cost. a chain processing 1M-gas state writes achieves 3-4x more Mgas/s than one processing 65k-gas token transfers.

### block time determines stability

| block time | stable for |
|-----------|------------|
| 100ms | StatePressure/GasBurner (all configs), MixedWorkload/DeFi (<40% util), ERC20 (<10% util) |
| 250ms | MixedWorkload/DeFi (<80% util) |
| 500ms | ERC20 (<40% util) |
| 1s | all workloads, all utilization levels |

workloads with larger gas/tx are more resilient at fast block times because fewer txs per block means less RPC contention. ERC20 is the most fragile.

### minimum viable block time

100ms is the proven production floor. the Engine API round-trip (ForkchoiceUpdated → GetPayload → NewPayload → ForkchoiceUpdated) takes 30-43ms at minimum even with empty blocks. 50ms was tested once (ERC20, 40% util) and produced 55% non-empty blocks with a 20s stall. sub-50ms is not viable without eliminating the Engine API request/response cycle.

### run-to-run variance

DeFi results show up to 2.2x variance on identical configs:

| config | run 1 Mgas/s | run 2 Mgas/s |
|--------|-------------|-------------|
| 30m_10pct | 33.1 | 22.9 / 33.1 / 23.9 |
| 30m_100pct | 6.5 | 14.3 |
| 100m_10pct | 12.9 | 2.4 (429-affected) |

single-run results should be treated as approximate. 3+ runs per config with median selection would improve confidence.

### gas limit selection

- **small-tx workloads (ERC20, DeFi):** use 30M. 100M performs 3-4x worse because more spammers are needed to fill larger blocks, causing RPC contention.
- **large-tx workloads (StatePressure, GasBurner):** use 100M+. blocks fill with fewer txs, so contention is not an issue and larger blocks hold more gas.
- **mixed workloads:** 100M is better when ≥30% of traffic is large-tx (GasBurner/StatePressure). otherwise 30M.

## recommended configurations

### deployment profiles

| profile | avg util | peak util | block time | gas limit | scrape interval |
|---------|---------|----------|-----------|-----------|----------------|
| 1. low traffic | <5% | <20% | 100ms | 30M | 25ms |
| 2. moderate | 5-10% | <50% | 250ms | 30M | 50ms |
| 3. high traffic | 10-30% | <80% | 500ms | 30M | 100ms |
| 4. max stability | 30%+ | 80%+ | 1s | 30M | 200ms |
| 5. max throughput | any | any | 100ms | 100M | 25ms |

profile 5 is for compute/storage-heavy workloads only (1M+ gas/tx). do not use with ERC20/DeFi-heavy traffic.

### expected performance per profile

#### profile 1 (100ms / 30M)

| workload | Mgas/s | TPS | stable |
|----------|--------|-----|--------|
| GasBurner | 148 | 150 | yes |
| StatePressure | 74 | 71 | yes |
| MixedWorkload | 70 | 109 | yes |
| DeFi | 23-33 | 285-373 | yes |
| ERC20 | 28 | 703 | yes |

#### profile 2 (250ms / 30M)

| workload | Mgas/s | TPS | stable |
|----------|--------|-----|--------|
| GasBurner | 99 | 100 | yes |
| StatePressure | 58 | 56 | yes |
| MixedWorkload | 89 | 164 | yes |
| DeFi | 3.9 | 90 | yes |
| ERC20 | 29 | 716 | marginal (1 stall observed) |

validated by MixedWorkload: `30m_80pct_250ms` produced 88.6 Mgas/s, 164 TPS, no stalls.

#### profile 3 (500ms / 30M)

| workload | Mgas/s | TPS | stable |
|----------|--------|-----|--------|
| GasBurner | 120 | 60 | yes |
| MixedWorkload | 47 | 91 | yes |
| ERC20 | 12 | 286 | yes |

#### profile 4 (1s / 30M)

| workload | Mgas/s | TPS | stable |
|----------|--------|-----|--------|
| GasBurner | 63 | 31 | yes |
| StatePressure | 20 | 19 | yes |
| MixedWorkload | 21 | 43 | yes |
| DeFi | 0.6 | 16 | yes |
| ERC20 | 6 | 146 | yes |

## CI benchmark specifications

### recommended scenario per test

| test | scenario | block time | gas limit | spammers | pass criteria |
|------|----------|-----------|-----------|----------|--------------|
| TestGasBurner | `30m_80pct` | 100ms | 30M | 8 | pb_max < 500ms, Mgas/s > 100, non-empty > 90% |
| TestERC20Throughput | `30m_10pct` | 100ms | 30M | 4 | pb_max < 500ms, Mgas/s > 20, TPS > 500 |
| TestDeFiSimulation | `30m_20pct` | 100ms | 30M | 3 | pb_max < 500ms, Mgas/s > 15, TPS > 200 |
| TestStatePressure | `30m_40pct` | 100ms | 30M | 6 | pb_max < 500ms, Mgas/s > 100, non-empty > 90% |
| TestMixedWorkload | `30m_20pct` | 100ms | 30M | 4 | pb_max < 500ms, Mgas/s > 50, TPS > 100 |

### regression flags

flag as regression if any of:
- `produce_block_max_ms` > 500ms (stall or latency spike)
- `non_empty_ratio_pct` < 90% (excessive empty blocks)
- `overhead_pct` > 15% (ev-node orchestration cost too high)
- `mgas_per_sec` drops > 30% from baseline
- `spamoor.failed` > 0 (tx submission failures)

## comparison with production L2s

these benchmarks run against **near-genesis state** on modest hardware. production L2s operate against accumulated state (billions of txs, millions of accounts) on larger machines. the comparison contextualizes results but does not equate them.

| metric | ev-node/ev-reth (benchmark) | Base (production) |
|--------|----------------------------|-------------------|
| block time | 100ms - 1s | 2s |
| gas limit | 30M - 100M (tested) | 375M |
| gas throughput | 70-291 Mgas/s (stable) | ~187.5 Mgas/s target |
| peak Mgas/s | 291 (stable), 407 (unstable) | ramp target 400-500 |
| block build p50 | 33-94ms | 260ms (op-reth) |
| reth Ggas/s | 0.3-1.1 | — |
| state depth | near-genesis | billions of txs |

| chain | block time | gas throughput | TPS | execution client |
|-------|-----------|---------------|-----|-----------------|
| ev-node/ev-reth | 100ms | 70-291 Mgas/s | — | ev-reth (reth fork) |
| Base | 2s | ~187.5 Mgas/s | ~92 | op-reth |
| Arbitrum One | 250ms | ~60 Mgas/s | ~21 | Nitro (geth fork) |
| Optimism | 2s | ~5.8 Mgas/s | ~19 | op-geth |

block build latency is 4-8x faster in these benchmarks because they run against near-genesis state with minimal trie depth. Base identified storage reads as their primary bottleneck. as ev-reth accumulates state, block build times will increase toward Base's numbers. quantifying this state growth effect is the most important open question for production readiness.

## coverage gaps

- **fullnode sync latency:** all benchmarks target the sequencer directly. fullnode block sync and read query performance under load are untested.
- **load balancer path:** the Hetzner LB round-robins across all nodes, but fullnode tx pools are disconnected from block building. `eth_sendRawTransaction` to a fullnode succeeds but txs silently go nowhere (no forwarding, no gossip relay). benchmarking through the LB requires a dedicated write-only LB or tx forwarding in ev-reth.
- **state growth:** all results are from near-genesis. state root computation in `builder.finish()` scales with trie depth.
- **sustained load:** tests run 60-700s. 30-60 minute runs would reveal memory leaks and GC pressure.
- **hardware scaling:** all results from 8 vCPU / 15 GiB. 4 vCPU and 16 vCPU profiles not tested.

## open questions

1. **is the 10s retry timeout optimal?** the fixed 10s wait was designed for crash recovery. for transient 429 errors, a shorter backoff (100ms exponential) would reduce impact from ~100 empty blocks to ~1.
2. **does ev-reth performance degrade with state size?** the StatePressure results (1.1 Ggas/s on fresh state) will degrade as state grows. quantifying this is critical for production sizing.
3. **why does actual utilization diverge from target at high concurrency?** at 6+ spammers, actual utilization collapses well below target. likely tx pool contention or RPC saturation, not a chain limitation.
