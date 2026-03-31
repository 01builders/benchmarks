# ev-node / ev-reth benchmark evaluation

cross-workload performance analysis with deployment recommendations.

**date:** 2026-03-31
**versions:** ev-reth v0.3.0-beta, ev-node v1.0.0
**platform:** linux/amd64, 8 vCPU (x86_64), 15 GiB RAM
**host:** stg-benchmarking-evstack-evm-node-1 (sequencer role)
**state:** near-genesis (fresh chain, minimal trie depth)
**total results:** 68 JSON files across 5 workload types

> **note:** 23 of 68 results exhibited a known 10s block production stall caused by RPC connection contention in the test harness. these are excluded from recommendations where relevant. see [appendix: 10-second stall](#appendix-10-second-stall) for details.

## glossary

| term | definition |
|------|-----------|
| Mgas/s | millions of gas processed per second of steady-state time. higher = more throughput. computed as `totalGasUsed / steadyStateSec / 1e6` |
| TPS | transactions per second during steady state. `totalTxCount / steadyStateSec` |
| pb_avg (ms) | average duration of `BlockExecutor.ProduceBlock` — the full block lifecycle in ev-node, including ev-reth execution and all Engine API round-trips |
| pb_max (ms) | maximum ProduceBlock duration. values near 10,000ms indicate a retry stall (see [appendix](#appendix-10-second-stall)) |
| headroom (ms) | `block_time - pb_avg`. positive = blocks finish before the next slot. negative = system falls behind target block rate |
| overhead (%) | `(ProduceBlock - ExecuteTxs) / ProduceBlock`. ev-node's orchestration cost as a fraction of total block time. 1-5% when blocks are full, 40-75% when blocks are mostly empty. example: if ProduceBlock takes 60ms and ExecuteTxs takes 57ms, overhead = (60-57)/60 = 5%. the 3ms is ev-node's cost for RetrieveBatch, CreateBlock, RPC round-trips, and context propagation |
| reth Ggas/s | gigagas per second computed from `Engine.NewPayload` time only: `totalGasUsed / cumulativeNewPayloadTime / 1e9`. this measures ev-reth's **validation and state commit** throughput, not block building. `GetPayload` (tx selection, EVM execution, state root computation) is excluded. the ratio of GetPayload to NewPayload time varies by tx type, so this metric is **not comparable across workloads or to external benchmarks** that measure end-to-end block build time. it is useful for tracking regressions within the same workload across versions |
| steady state | wall-clock time between the first and last non-empty block in the measurement window. excludes warmup (contract deployment, initial tx injection) and drain (mempool emptying) |
| non-empty % | percentage of blocks containing at least one transaction. low values indicate the system is producing empty blocks due to stalls or insufficient tx injection |
| gas limit | maximum gas per block (genesis config). tested at 30M (`0x1C9C380`) and 100M (`0x5F5E100`) |
| block time | target block production interval. ev-node attempts to produce one block per interval |
| scrape interval | how frequently ev-node's metrics pipeline collects data. should be 1/4 to 1/5 of block time |
| within cadence | block production avg (pb_avg) is less than the configured block time. blocks keep pace with the target rate. the system produces blocks at or near the expected blocks/s |
| behind cadence | block production avg (pb_avg) exceeds the configured block time. ev-reth takes longer to build/validate blocks than the interval allows, producing a sawtooth pattern: one full block followed by empty blocks while ev-reth catches up. the system still functions but at a slower effective block rate than configured |

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

## default configuration

for most deployments, use:

| parameter | value | why |
|-----------|-------|-----|
| block time | **100ms** | see [why 100ms](#why-100ms-is-the-standard-block-time) |
| gas limit | **30M** | optimal for small-tx workloads (ERC20, DeFi) which dominate typical chain traffic. 100M only benefits chains with >30% large-tx activity (1M+ gas/tx) |
| scrape interval | **25ms** | 1:4 ratio with block time |

this configuration is within cadence across all workloads at low-to-moderate utilization (<20% peak block fullness) and provides the lowest block confirmation latency. it is the starting point — adjust only when the chain's workload profile or utilization demands it.

### why 100ms is the standard block time

100ms is used as the default because it sits at the intersection of three constraints:

1. **it is the fastest viable block time.** the Engine API round-trip (ForkchoiceUpdated → GetPayload → NewPayload → ForkchoiceUpdated) takes 30-43ms minimum even with empty blocks. at 100ms, this leaves 57-70ms for EVM execution — enough for all workloads at low utilization. at 50ms, headroom shrinks to 7-20ms, which is not enough to absorb normal execution variance. 50ms was tested (ERC20, 40% util) and produced 55% non-empty blocks with a 20s stall. sub-50ms is architecturally impossible without replacing the Engine API request/response cycle with a streaming or shared-memory pipeline.

2. **it maximizes throughput at low utilization.** all five workloads achieve their peak within-cadence Mgas/s at 100ms. longer block times (250ms, 500ms, 1s) reduce throughput because ev-reth idles between blocks. at 100ms with 30M gas limit: GasBurner achieves 148 Mgas/s, StatePressure 74, MixedWorkload 70, DeFi 23-33, ERC20 28.

3. **it provides the lowest confirmation latency.** users see transactions included in ~100ms vs 250ms-1s at longer intervals. for interactive applications (wallets, DEX trading, gaming), this is a meaningful UX difference.

the tradeoff: 100ms falls behind cadence at higher utilization for small-tx workloads. when peak block fullness exceeds 20% for ERC20 or 40% for DeFi/MixedWorkload, increase block time to 250ms or 500ms. see [configuration knobs](#configuration-knobs) for the full picture.

**what happens when block time is too short for the workload:** when ev-reth's execution time exceeds the block time, a sawtooth pattern emerges. ev-reth builds one large block (consuming the full gas limit), but takes longer than the block interval to do so. while it's building, ev-node has been waiting and now has a backlog. the next block is produced immediately but is empty (or near-empty) because ev-reth just drained the tx pool into the previous block. this repeats: one fat block followed by several empty blocks, then another fat block. the result is low non-empty % (40-60%) and high overhead (40-75%) despite the system processing gas at a reasonable rate. this was observed in GasBurner configs where pb_avg exceeded 100ms (e.g., `high_gas_per_tx_100m` at pb_avg=124ms produced blocks at ~8/s instead of 10/s) and in ERC20/DeFi configs at higher utilization. the system doesn't crash — it just produces blocks at a slower effective cadence than configured.

## recommended configurations by workload

### deployment profiles

| profile | use case | avg util | peak util | block time | gas limit | scrape interval |
|---------|----------|---------|----------|-----------|-----------|----------------|
| 1. low traffic | early-stage chain, dev/test, low-activity L2 | <5% | <20% | 100ms | 30M | 25ms |
| 2. moderate | growing chain, moderate DeFi activity | 5-10% | <50% | 250ms | 30M | 50ms |
| 3. high traffic | sustained DeFi, high transfer volume | 10-30% | <80% | 500ms | 30M | 100ms |
| 4. max stability | heavy sustained load, throughput-optimized L2 | 30%+ | 80%+ | 1s | 30M | 200ms |
| 5. max throughput | compute/storage-heavy workloads (1M+ gas/tx) | any | any | 100ms | 100M | 25ms |

profile 5 is for chains dominated by large-tx activity (batch operations, storage-heavy contracts). do not use with ERC20/DeFi-heavy traffic — 100M gas limit with many small txs requires more concurrent senders to fill blocks, which causes RPC contention.

### expected performance per profile

#### profile 1 (100ms / 30M) — default

at ~10% target utilization:

| workload | Mgas/s | TPS | cadence |
|----------|--------|-----|---------|
| GasBurner | 148 | 150 | within |
| StatePressure | 74 | 71 | within |
| MixedWorkload | 70 | 109 | within |
| DeFi | 23-33 | 285-373 | within |
| ERC20 | 28 | 703 | within |

at ~40% target utilization (still 100ms / 30M):

| workload | Mgas/s | TPS | cadence |
|----------|--------|-----|---------|
| StatePressure | 191 | 183 | within |
| MixedWorkload | 135 | 289 | within |
| DeFi | 3.5 | 84 | within (1 of 2 runs stalled) |
| ERC20 | — | — | behind (stalled) |

profile 1 remains within cadence at 40% for compute/storage-heavy and mixed workloads. ERC20-dominated chains should move to profile 2 (250ms) above ~10% utilization.

#### profile 2 (250ms / 30M)

| workload | Mgas/s | TPS | cadence |
|----------|--------|-----|---------|
| GasBurner | 99 | 100 | within |
| StatePressure | 58 | 56 | within |
| MixedWorkload | 89 | 164 | within |
| DeFi | 3.9 | 90 | within |
| ERC20 | 29 | 716 | marginal (1 stall observed) |

validated by MixedWorkload: `30m_80pct_250ms` produced 88.6 Mgas/s, 164 TPS, no stalls.

#### profile 3 (500ms / 30M)

| workload | Mgas/s | TPS | cadence |
|----------|--------|-----|---------|
| GasBurner | 120 | 60 | within |
| MixedWorkload | 47 | 91 | within |
| ERC20 | 12 | 286 | within |

#### profile 4 (1s / 30M)

| workload | Mgas/s | TPS | cadence |
|----------|--------|-----|---------|
| GasBurner | 63 | 31 | within |
| StatePressure | 20 | 19 | within |
| MixedWorkload | 21 | 43 | within |
| DeFi | 0.6 | 16 | within |
| ERC20 | 6 | 146 | within |

## CI benchmark specifications

### recommended scenario per test

all CI scenarios use 100ms / 30M (profile 1) to catch regressions at the standard configuration.

| test | scenario | spammers | pass criteria | rationale |
|------|----------|----------|--------------|-----------|
| TestGasBurner | `30m_80pct` | 8 | pb_max < 500ms, Mgas/s > 100, non-empty > 90% | GasBurner is within cadence at 100ms across all utilization — 80% exercises block building throughput at the high end |
| TestERC20Throughput | `30m_10pct` | 4 | pb_max < 500ms, Mgas/s > 20, TPS > 500 | ERC20 is only within cadence at 100ms up to ~10% util — this is the highest within-cadence config and tests peak TPS (703 observed) |
| TestDeFiSimulation | `30m_20pct` | 3 | pb_max < 500ms, Mgas/s > 15, TPS > 200 | DeFi is within cadence at 100ms up to ~20% util — this tests the DeFi cadence boundary with realistic Uniswap swap load |
| TestStatePressure | `30m_40pct` | 6 | pb_max < 500ms, Mgas/s > 100, non-empty > 90% | StatePressure is within cadence at all 30M configs — 40% exercises storage-write-heavy execution at moderate load |
| TestMixedWorkload | `30m_20pct` | 4 | pb_max < 500ms, Mgas/s > 50, TPS > 100 | mixed workload validates the all-round default config with realistic traffic (40% ERC20, 30% DeFi, 20% GasBurner, 10% StatePressure) |

### regression flags

flag as regression if any of:
- `produce_block_max_ms` > 500ms (stall or latency spike)
- `non_empty_ratio_pct` < 90% (excessive empty blocks)
- `overhead_pct` > 15% (ev-node orchestration cost too high)
- `mgas_per_sec` drops > 30% from baseline
- `spamoor.failed` > 0 (tx submission failures)

## configuration knobs

### block time

block time is the primary lever for trading latency against stability.

| block time | blocks/s | confirmation latency | what happens |
|-----------|----------|---------------------|-------------|
| 100ms | 10 | ~100ms | fastest confirmation. pb_avg is 30-75ms depending on workload, leaving 25-70ms headroom. within cadence for all workloads at low utilization. as blocks get fuller, ev-reth needs more time for EVM execution and state root computation. small-tx workloads (ERC20, DeFi) fall behind cadence first because they require many txs per block |
| 250ms | 4 | ~250ms | keeps MixedWorkload and DeFi within cadence through 80% target utilization. ev-reth has 2.5x more time per block to build and validate. ERC20 remains marginal (1 stall observed) |
| 500ms | 2 | ~500ms | first interval where ERC20 is fully within cadence. all workloads within cadence. blocks are larger and better-packed. the system idles between blocks, so Mgas/s decreases compared to 100ms despite blocks containing more gas each |
| 1s | 1 | ~1s | all workloads within cadence at all utilization levels. highest per-block gas, lowest Mgas/s. 75-99% non-empty blocks |

**when to increase block time:** when peak block fullness exceeds the stability threshold for your workload:

| workload type | within cadence at 100ms up to | increase to 250ms at | increase to 500ms at |
|--------------|----------------------|---------------------|---------------------|
| StatePressure / GasBurner (1M+ gas/tx) | all tested utilization levels | — | — |
| MixedWorkload / DeFi (~60-90k gas/tx) | ~40% peak util | >40% peak util | >80% peak util |
| ERC20 (~65k gas/tx) | ~10% peak util | >10% peak util | >40% peak util |

### gas limit

gas limit controls the maximum gas per block. the optimal value depends on transaction size, not just target utilization.

| gas limit | effect |
|-----------|--------|
| **30M** | optimal for small-tx workloads (ERC20 ~65k, DeFi ~90k gas/tx). filling 10% of 30M requires fewer concurrent senders than filling 10% of 100M, avoiding RPC contention. ERC20 at 30M achieves 28 Mgas/s; at 100M, only 6.5 Mgas/s (4.3x worse) |
| **100M** | optimal for large-tx workloads (StatePressure 1M, GasBurner 1-5M gas/tx). large txs fill bigger blocks with fewer transactions, so the extra capacity is used efficiently. StatePressure at 100M achieves 291 Mgas/s vs 74 at 30M (3.9x better). also beneficial for mixed workloads where ≥30% of traffic is large-tx |
| **300M+** | tested with GasBurner only. 300M achieves 398 Mgas/s but pb_avg=125ms exceeds 100ms block time. only viable with longer block times (500ms+) or when falling behind cadence is acceptable |

**rule of thumb:** start with 30M. increase to 100M when the workload includes significant large-tx activity (1M+ gas/tx) and blocks regularly fill to >40% of 30M.

### scrape interval

scrape interval controls how often ev-node's metrics pipeline collects data. it should be proportional to block time:

| block time | scrape interval | ratio |
|-----------|----------------|-------|
| 100ms | 25ms | 1:4 |
| 250ms | 50ms | 1:5 |
| 500ms | 100ms | 1:5 |
| 1s | 200ms | 1:5 |

too frequent (e.g., 10ms scrape at 100ms blocks) adds CPU overhead during block production. too infrequent (e.g., 200ms scrape at 100ms blocks) means metrics miss blocks entirely. the 1:4 to 1:5 range gives 4-5 scrape opportunities per block interval. this ratio is derived from configs that were within cadence — it has not been experimentally validated with mismatched values.

## peak within-cadence performance per test

optimal config per workload, maximizing Mgas/s while ensuring `pb_avg < block_time` and `pb_max < 500ms`.

| test | config | gas limit | block time | Mgas/s | TPS | pb_avg (ms) | headroom (ms) | pb_max (ms) |
|------|--------|-----------|-----------|--------|-----|-------------|---------------|-------------|
| StatePressure | `100m_20pct` | 100M | 100ms | 291.4 | 279.5 | 93.5 | 6.5 | 198.2 |
| MixedWorkload | `100m_10pct` | 100M | 100ms | 245.2 | 491.3 | 78.1 | 21.9 | 285.2 |
| GasBurner | `baseline_100m_100ms` | 100M | 100ms | 223.1 | 225.1 | 74.0 | 26.0 | 112.1 |
| DeFi | `30m_10pct` | 30M | 100ms | 33.1 | 373.2 | 32.5 | 67.5 | 59.1 |
| ERC20 | `30m_10pct` | 30M | 100ms | 27.8 | 703.1 | 32.6 | 67.4 | 96.1 |

## workload analysis

### GasBurner (pure compute, 1-5M gas/tx)

12 configs tested. each tx consumes a configurable amount of gas through pure computation (no storage). simplest and most predictable workload.

- **most resilient to fast block times.** every config at ≤100M gas limit with 100ms blocks is within cadence. only extreme gas limits (300M-1G) that push pb_avg well beyond block time caused issues.
- **reth efficiency increases with gas per tx.** 5M gas/tx achieves 0.833 Ggas/s vs 0.547 at 1M gas/tx. fewer txs = less per-tx overhead in ev-reth (validation, nonce check, receipt generation).
- **negative headroom is survivable.** `high_gas_per_tx_100m` has pb_avg=124ms (>100ms block time) but no stalls. the system produces blocks at ~8/s instead of 10/s — it falls behind cadence but doesn't fail.
- **block time has minimal impact on cadence.** 100ms is within cadence for all reasonable gas limits. longer block times reduce Mgas/s without improving cadence.
- **overhead is consistently low** (0.8-3.6%). compute-heavy txs spend most of ProduceBlock inside ev-reth, leaving little fixed-cost fraction.

### ERC20 (light txs, ~65k gas/tx)

11 configs tested. simple ERC-20 token transfers. the most demanding workload because filling blocks requires many transactions.

- **narrowest within-cadence window at 100ms.** only `30m_10pct` (4 spammers) is within cadence at 100ms. the cliff is between 10% and 20% target utilization — `30m_20pct` (6 spammers) already shows issues.
- **100M gas limit performs 3-4x worse than 30M** at every utilization level. filling 10% of 100M requires ~3.3x more txs than 10% of 30M. the test matrix achieves this by adding spammers (8 for 100m_10pct vs 4 for 30m_10pct), saturating the RPC pool.
- **highest TPS of any workload** (703 at 30m_10pct) because each tx uses the least gas.
- **block time sweep: 500ms is the first fully within-cadence interval.** 250ms still showed one stall. 1s is within cadence but low throughput (6 Mgas/s, 146 TPS).
- **50ms block time is not viable** for high-tx-count workloads. tested once (30m_40pct_50ms): 55% non-empty blocks, 62% overhead. the Engine API round-trip takes 30-43ms minimum, leaving only 7-20ms for EVM execution at 50ms. any non-trivial block fill pushes pb_avg past 50ms, causing the system to fall behind cadence.

### DeFi / Uniswap V2 (~60-90k gas/tx)

21 results across 13 configs and two rounds. each tx is a Uniswap V2 swap with deep call chains, event emission, and multi-contract storage operations. 5 results disregarded due to RPC contention (see [appendix](#appendix-disregarded-defi-results)).

- **significant run-to-run variance.** `30m_100pct` went from 6.5 to 14.3 Mgas/s between rounds (2.2x). three repeated `30m_10pct` runs scored 22.9, 33.1, and 23.9 Mgas/s (1.4x range). single-run results should be treated as approximate.
- **actual utilization far below target** at high concurrency. `30m_100pct` best run achieved ~4.8% actual utilization (target 100%). tx pool contention and nonce conflicts at 10 spammers prevent the chain from seeing the injected load.
- **block time sweep confirms pattern.** `30m_80pct` is behind cadence at 100ms, within cadence at 250ms and 1s.
- **100M underperforms 30M** at equivalent targets. DeFi txs are small enough that the extra spammers needed for 100M cause contention without filling larger blocks.

### StatePressure (storage writes, 1-2M gas/tx)

13 configs tested. each tx maximizes SSTORE operations, stressing state root computation in ev-reth's `builder.finish()`.

- **most resilient workload overall.** only 1 of 13 configs had issues. all 30M configs at 100ms are within cadence, even at 120% target utilization. 1-2M gas/tx means very few txs per block, minimizing contention.
- **ev-reth achieves its highest efficiency** with storage writes: 1.143 Ggas/s within cadence (100m_20pct). 3.5x higher than DeFi/ERC20.
- **100M gas limit is beneficial.** `100m_20pct` achieves 291 Mgas/s vs `30m_40pct` at 191 Mgas/s. large txs fill bigger blocks with fewer transactions.
- **heavy write variant** (2M gas/tx) performs similarly to standard 1M: 142 vs 145 Mgas/s. per-tx storage depth is not a bottleneck.
- **overhead is the lowest of any workload** (1.3-3.9%).
- **critical caveat:** these results are from near-genesis state. StatePressure explicitly grows the state trie, so production performance will degrade as the trie deepens.

### MixedWorkload (40% ERC20, 30% DeFi, 20% GasBurner, 10% StatePressure)

13 configs tested. the closest approximation to real chain traffic. spammers are distributed across tx types using a largest-remainder allocation (minimum 1 per type, minimum 4 total).

- **cadence tracks DeFi, not ERC20.** within cadence at 100ms through 40% target utilization. the stall cliff is between 40% and 80%. ERC20 alone is behind cadence at >10%, but the GasBurner/StatePressure components (30% of spammers) fill blocks with large txs efficiently, compensating.
- **throughput is high relative to DeFi/ERC20.** 140 Mgas/s at `30m_20pct`, 136 at `30m_40pct`. the large-tx components contribute disproportionately to gas throughput.
- **250ms restores cadence.** `30m_80pct_250ms` (88.6 Mgas/s, 164 TPS, within cadence) vs `30m_80pct` at 100ms (116.1 Mgas/s, 222 TPS, behind cadence). validates profile 2 recommendation.
- **100M gas limit shows a sharp cliff.** `100m_10pct` is within cadence at 245.2 Mgas/s. `100m_20pct` and above are all behind cadence.
- **all-round recommendation validated.** profile 1 (`30m_10pct` and `30m_20pct` at 100ms) produces 100% non-empty blocks, <3.5% overhead.

## comparison with production L2s

these benchmarks run against **near-genesis state** on modest hardware (8 vCPU, 15 GiB). production L2s operate against accumulated state (billions of txs, millions of accounts) on larger machines. the comparison contextualizes results but does not equate them.

| metric | ev-node/ev-reth (benchmark) | Base (production) | Arbitrum One | Optimism |
|--------|----------------------------|-------------------|-------------|----------|
| block time | 100ms - 1s | 2s | 250ms | 2s |
| gas limit | 30M - 100M | 375M | 32M | 30M |
| gas target | — | 187.5M | 15M | 15M |
| gas throughput | 28-291 Mgas/s (varies by tx type¹) | ~93.75 Mgas/s sustained | ~60 Mgas/s | ~5.8 Mgas/s |
| TPS | 109-703 | ~92 | ~21 | ~19 |
| block build p50 | 33-94ms | 260ms (op-reth) | — | — |
| execution client | ev-reth (reth fork) | op-reth | Nitro (geth fork) | op-geth |
| state depth | near-genesis | billions of txs | billions of txs | billions of txs |

¹ the 10x range (28-291 Mgas/s) is due to transaction size. large txs (1M+ gas, StatePressure/GasBurner) amortize per-tx overhead and achieve 223-291 Mgas/s. small txs (~65-90k gas, ERC20/DeFi) are dominated by per-tx overhead and achieve 28-33 Mgas/s. production chains with mixed traffic would fall somewhere in between — the MixedWorkload test (40% ERC20, 30% DeFi, 20% GasBurner, 10% StatePressure) achieved 245 Mgas/s because the large-tx components contribute disproportionately to gas throughput.

### near-genesis state caveat

> **all benchmark results in this report are from near-genesis state.** the chain starts fresh with minimal trie depth for every test run. production L2s like Base operate against state accumulated from billions of transactions and millions of accounts. state root computation in ev-reth's `builder.finish()` scales with trie depth — storage reads become the dominant cost as state grows. Base identified this as their primary bottleneck and their TrieDB project targets 8-10x improvement in storage read speed. the throughput and latency numbers in this report **will degrade** as the chain accumulates state. quantifying this degradation is the most important open question for production readiness.

### different design tradeoffs

> **Base operates with 375M gas limit and 2s block time** — 12.5x our default gas limit and 20x our block time. this produces massive blocks: each block can hold up to 375M gas, with an EIP-1559 target of 187.5M. ev-reth has 2 full seconds to build and validate each block. this is also constrained by fault proof verification time — the block must be provable within the dispute game window.

**ev-node/ev-reth** at the default config uses 30M gas limit with 100ms blocks — small blocks at fast cadence. the theoretical max is 300M gas/s (30M x 10 blocks/s), but actual throughput is lower because blocks don't fill completely. this optimizes for confirmation latency (100ms vs 2s) at the cost of per-block capacity.

the approaches are complementary, not competing: Base prioritizes per-block capacity for high gas throughput, ev-node prioritizes fast confirmation for interactive applications. a chain using ev-node could adopt Base-like parameters (larger gas limit, longer block time) if throughput matters more than latency — profile 4 (1s / 30M) and profile 5 (100ms / 100M) move in that direction.

### what the numbers mean

- **block build latency is 4-8x faster** in these benchmarks (33-94ms p50 vs Base's 260ms). this is a direct consequence of near-genesis state — not architectural superiority. as ev-reth accumulates state, block build times will converge toward Base's numbers.
- **gas throughput appears higher** — ev-reth at 100M gas limit achieves 245-291 Mgas/s within cadence vs Base's ~93.75 Mgas/s sustained. but Base runs against deep state with fault proof constraints. a direct comparison is not meaningful until ev-reth is tested against comparable state depth.
- **Arbitrum uses a similar gas limit (32M) and faster blocks (250ms)** to our default, making it the most structurally comparable L2. ev-node at profile 1 exceeds Arbitrum's ~60 Mgas/s, but again on near-genesis state.

## coverage gaps

- **fullnode sync latency:** all benchmarks target the sequencer directly. fullnode block sync and read query performance under load are untested.
- **load balancer path:** the Hetzner LB round-robins across all nodes, but fullnode tx pools are disconnected from block building. `eth_sendRawTransaction` to a fullnode succeeds but txs silently go nowhere (no forwarding, no gossip relay).
- **state growth:** all results are from near-genesis. state root computation in `builder.finish()` scales with trie depth.
- **sustained load:** tests run 60-700s. 30-60 minute runs would reveal memory leaks and GC pressure.
- **hardware scaling:** all results from 8 vCPU / 15 GiB. 4 vCPU and 16 vCPU profiles not tested.

## open questions

1. **does ev-reth performance degrade with state size?** the StatePressure results (1.1 Ggas/s on fresh state) will degrade as state grows. quantifying this is critical for production sizing.
2. **why does actual utilization diverge from target at high concurrency?** at 6+ spammers, actual utilization collapses well below target. likely tx pool contention or RPC saturation, not a chain limitation.
3. **run-to-run variance:** DeFi showed up to 2.2x variance on identical configs. 3+ runs per config with median selection would improve confidence.

---

## appendix: 10-second stall

23 of 68 results show `pb_max` near 10,000ms. root cause confirmed in code:

**ev-node `executeTxsWithRetry`** (`ev-node/block/internal/common/retry.go`) has a fixed 10s backoff (`MaxRetriesTimeout = 10 * time.Second`). when `ExecuteTxs` fails — typically because ev-reth returns `429 Too Many Requests` when its RPC connection pool is saturated by concurrent tx injection — ev-node waits exactly 10s before retrying. this produces ~100 empty blocks at 100ms block time.

the stalls are **non-deterministic**: identical configs can stall in one run but not another. they correlate with spammer count (more concurrent connections = more contention) and disappear at longer block times (250ms+), which reduce the rate of ev-node's internal RPC calls. importantly, pb_avg remains well below block time even in stalled runs (33-59ms for 100ms configs) — the block production itself has headroom, the stall is caused by RPC connection contention.

**429 errors confirmed in logs:** 8 of 14 DeFi round 2 runs had `"failed to get tx pool content: 429 Too Many Requests"` in ev-node logs. severity scaled with spammer count: 100m_80pct (10 spammers) had 403 occurrences, lower-concurrency runs had 5-13. no 429s were found in GasBurner, ERC20, StatePressure, or MixedWorkload logs.

**production relevance:** the stalls are a test harness artifact — spamoor floods the sequencer RPC endpoint with transactions, saturating ev-reth's connection pool. ev-node's internal `getBlockInfo` call competes for the same pool and gets rejected. production would not have this problem unless external tx submission reached similar concurrency levels (6+ concurrent heavy senders). the fix is a dedicated internal RPC endpoint for ev-node ↔ ev-reth, separate from public tx submission. the 10s fixed backoff could also be reduced to 100-500ms exponential since the underlying 429 is transient.

## appendix: disregarded DeFi results

the following DeFi results are excluded from recommendations due to confirmed 429 RPC contention:

| config | spammers | pb_max (ms) | 429 count | Mgas/s |
|--------|----------|-------------|-----------|--------|
| `100m_80pct` | 10 | 10,276 | 403 | 2.0 |
| `100m_40pct` | 10 | 10,137 | 127 | 3.4 |
| `30m_80pct` | 8 | 10,145 | 20 | 2.2 |
| `30m_80pct_multi_pair` | 8 | 10,289 | — (r1) | 3.9 |
| `30m_40pct` (r1, Mar 26) | 6 | 10,020 | — (r1) | 2.8 |

the remaining DeFi results (30m_10pct, 30m_20pct, 30m_100pct, 30m_120pct, 100m_10pct r1, 100m_20pct, and all block time variants) are retained. two runs had minor 429s (5 occurrences each) with no stalls.
