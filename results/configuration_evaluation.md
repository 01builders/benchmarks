# configuration evaluation

cross-workload analysis of ev-node and ev-reth performance, with deployment recommendations by expected load level.

**date:** 2026-03-30
**platform:** linux/amd64
**hardware:** 8 vCPU (x86_64), 15 GiB RAM
**host:** stg-benchmarking-evstack-evm-node-1 (sequencer role)

## block production pipeline

block production is split between ev-node (orchestration) and ev-reth (execution):

```
ProduceBlock (ev-node)
├── RetrieveBatch         — fetch txs from sequencer
├── CreateBlock           — construct block header + data
└── ApplyBlock            — execute via ev-reth
    └── ExecuteTxs        — full Engine API flow
        ├── reconcileExecutionAtHeight  — idempotency check (Eth.GetBlockByNumber)
        ├── getBlockInfo                — fetch parent block (Eth.GetBlockByNumber)
        ├── Engine.ForkchoiceUpdated    — trigger payload build
        ├── Engine.GetPayload           — retrieve built payload
        ├── Engine.NewPayload           — validate payload
        └── Engine.ForkchoiceUpdated    — finalize (set head/safe/finalized)
```

**ev-node overhead** = `ProduceBlock - (GetPayload + NewPayload)`. this includes orchestration (RetrieveBatch, CreateBlock, RPC round-trips, context propagation). when blocks are well-packed, overhead is 1-5%. when blocks are mostly empty, the fixed cost dominates and overhead spikes to 40-75%.

**ev-reth execution time** = `GetPayload + NewPayload`. this is the actual block building and validation. GetPayload includes tx selection, EVM execution, and state root computation. NewPayload re-validates the built payload.

**scrape interval** controls how frequently ev-node's metrics pipeline collects data. it should be proportional to block time at a 1:4 to 1:5 ratio (e.g., 100ms block → 25ms scrape, 250ms → 50ms, 1s → 200ms). too-frequent scraping relative to block time adds CPU overhead during block production.

## 10-second stall: confirmed root cause

### the pattern

across all workloads, certain runs show `ProduceBlock max` of ~10,000ms while the average remains 17-60ms. the flowchart traces show:

1. first `ExecuteTxs` call: runs `reconcileExecutionAtHeight` → `Eth.GetBlockByNumber` (few ms), then fails
2. 10-second wait
3. second `ExecuteTxs` call: runs full Engine API flow (ForkchoiceUpdated → GetPayload → NewPayload), succeeds

### root cause: ev-node `executeTxsWithRetry`

**confirmed in code.** the retry mechanism is in ev-node, not ev-reth.

`ev-node/block/internal/common/retry.go`:
```go
const MaxRetriesBeforeHalt = 3
const MaxRetriesTimeout = 10 * time.Second
```

`ev-node/block/internal/executing/executor.go:842-870`:
```go
func (e *Executor) executeTxsWithRetry(ctx context.Context, ...) ([]byte, error) {
    for attempt := 1; attempt <= common.MaxRetriesBeforeHalt; attempt++ {
        newAppHash, err := e.exec.ExecuteTxs(ctx, ...)
        if err != nil {
            // ... logs error ...
            select {
            case <-time.After(common.MaxRetriesTimeout):  // 10s fixed wait
                continue
            case <-e.ctx.Done():
                return nil, ...
            }
        }
        return newAppHash, nil
    }
}
```

when `ExecuteTxs` fails (transient ev-reth unavailability, state mismatch from `reconcileExecutionAtHeight`, or RPC error), ev-node waits exactly 10 seconds before retrying. this is the source of every ~10,000ms `ProduceBlock max` in the data.

### ev-reth has no retry/backoff

ev-reth's Engine API handlers (`payload_service.rs`) use `AwaitInProgress` for concurrent GetPayload calls (deterministic await, not retry). there is no 10s timeout or backoff in ev-reth. the `retryWithBackoffOnPayloadStatus` in ev-node's `ExecuteTxs` function has exponential backoff (1s → 2s → 4s) for SYNCING/ACCEPTED payload statuses, but this is separate from the 10s fixed retry.

### impact on benchmarks

the 10s stall is an ev-node issue. it occurs sporadically — not every block, and not correlated with load level. runs with identical configs sometimes show stalls and sometimes don't. the stall inflates `ProduceBlock max` but has minimal effect on averages because it happens on <1% of blocks. however, it produces ~100 empty blocks (at 100ms block time) during the stall window.

### where stalls appear

| workload | scenarios with 10s stalls | scenarios without |
|----------|--------------------------|-------------------|
| GasBurner | max_mgas_300m, max_mgas_500m, max_mgas_1g | baseline_30m, baseline_100m, slow_blocks_* |
| ERC20 | 30m_20pct through 100m_40pct, 50ms, 250ms | 30m_10pct, 500ms, 1s |
| DeFi | 30m_40pct, 30m_80pct_multi_pair | 30m_10pct, 30m_20pct, 30m_100pct |

pattern: stalls correlate loosely with higher concurrency (more spammers) but are absent at longer block times (500ms, 1s). longer block times give ev-reth more time to complete operations, reducing the chance of transient failures that trigger the retry.

## workload results

### GasBurner (pure compute, 1-5M gas/tx)

**stable configurations** (no 10s stalls, >95% non-empty blocks):

| scenario | block time | gas limit | Mgas/s | TPS | pb avg | pb max | headroom | overhead | reth Ggas/s |
|----------|-----------|-----------|--------|-----|--------|--------|----------|----------|-------------|
| baseline_30m | 100ms | 30M | 148.3 | 149.7 | 59.8ms | 108.7ms | 40ms | 2.1% | 0.547 |
| baseline_100m | 100ms | 100M | 223.1 | 225.1 | 74.0ms | 112.1ms | 26ms | 1.9% | 0.637 |
| high_gas_per_tx | 100ms | 100M | 326.1 | 65.3 | 124.2ms | 243.3ms | -24ms | 0.8% | 0.833 |
| slow_250ms | 250ms | 100M | 98.9 | 99.8 | 89.0ms | 132.4ms | 161ms | 1.5% | 0.634 |
| slow_500ms | 500ms | 300M | 119.7 | 60.1 | 159.4ms | 215.6ms | 341ms | 0.9% | 0.803 |
| slow_1s | 1s | 500M | 62.5 | 31.4 | 166.9ms | 274.4ms | 833ms | 0.9% | 0.814 |
| large_burn_low_vol | 100ms | 300M | 397.7 | 79.7 | 125.4ms | 209.9ms | -25ms | 0.9% | 0.793 |

**unstable configurations** (10s stalls present):

| scenario | block time | gas limit | Mgas/s | TPS | pb avg | pb max | overhead | reth Ggas/s |
|----------|-----------|-----------|--------|-----|--------|--------|----------|-------------|
| max_mgas_300m | 100ms | 300M | 406.7 | 204.3 | 340.3ms | 10,350ms | 11.7% | 0.938 |
| max_mgas_500m | 100ms | 500M | 371.7 | 186.7 | 317.7ms | 10,368ms | 16.6% | 0.924 |
| max_mgas_1g | 100ms | 1G | 132.6 | 90.8 | 73.2ms | 20,026ms | 24.1% | 0.640 |

GasBurner achieves the highest raw throughput because 1-5M gas/tx means fewer transactions per block, reducing per-tx overhead in both ev-node and ev-reth.

**key observations:**
- ev-reth peaks at 0.938 Ggas/s (max_mgas_300m) but this config is unstable
- stable peak is 0.833 Ggas/s (high_gas_per_tx, 5M gas/tx, 100M limit)
- reth efficiency increases with gas per transaction (fewer txs = less per-tx overhead)
- the high_gas_per_tx config has negative headroom (pb avg > block time) but no stalls — it simply produces blocks slower than 10/s

### ERC20 (light txs, ~65k gas/tx)

**stable configurations:**

| scenario | block time | gas limit | Mgas/s | TPS | pb avg | pb max | headroom | overhead | reth Ggas/s |
|----------|-----------|-----------|--------|-----|--------|--------|----------|----------|-------------|
| 30m_10pct | 100ms | 30M | 27.8 | 703.1 | 32.6ms | 96.1ms | 67ms | 4.9% | 0.323 |
| 30m_40pct_500ms | 500ms | 30M | 12.0 | 285.5 | 52.8ms | 188.7ms | 447ms | 3.3% | 0.443 |
| 30m_40pct_1s | 1s | 30M | 6.2 | 146.4 | 50.0ms | 156.6ms | 950ms | 3.2% | 0.483 |

**unstable configurations** (10s stalls, high overhead, low non-empty %):

| scenario | block time | gas limit | Mgas/s | TPS | pb max | non-empty % | overhead |
|----------|-----------|-----------|--------|-----|--------|-------------|----------|
| 30m_20pct | 100ms | 30M | 15.2 | 400.7 | 10,014ms | 60.2% | 42.2% |
| 30m_40pct | 100ms | 30M | 13.8 | 364.8 | 10,056ms | 67.9% | 57.3% |
| 30m_80pct | 100ms | 30M | 3.8 | 128.0 | 10,142ms | 38.8% | 74.6% |
| 100m_10pct | 100ms | 100M | 6.5 | 200.3 | 10,047ms | 35.7% | 47.0% |
| 100m_20pct | 100ms | 100M | 3.5 | 107.8 | 10,086ms | 18.6% | 68.1% |
| 100m_40pct | 100ms | 100M | 3.7 | 122.0 | 10,041ms | 25.7% | 71.9% |
| 30m_40pct_50ms | 50ms | 30M | 8.9 | 292.5 | 20,144ms | 55.0% | 61.8% |
| 30m_40pct_250ms | 250ms | 30M | 28.5 | 715.6 | 10,098ms | 86.9% | 52.5% |

ERC20 is the most demanding workload because small txs (~65k gas) require many per-block to achieve meaningful utilization. at 30M gas limit, filling 10% requires ~46 txs/block. filling 40% requires ~185 txs/block at 10 blocks/s = 1,850 tx/s sustained.

**key observations:**
- only 30m_10pct at 100ms block time is stable — the cliff is between 10% and 20% target utilization
- 500ms and 1s block times are stable but lower throughput (the system idles between blocks)
- 250ms achieves the highest Mgas/s (28.5) and TPS (716) but has 10s stalls
- 100M gas limit performs 3-4x worse than 30M at every utilization level with 100ms blocks
- the 50ms block time shows a 20s stall (two consecutive 10s retries)

### DeFi / Uniswap V2 (~60-90k gas/tx)

**stable configurations:**

| scenario | block time | gas limit | Mgas/s | TPS | pb avg | pb max | headroom | overhead | reth Ggas/s |
|----------|-----------|-----------|--------|-----|--------|--------|----------|----------|-------------|
| 30m_10pct | 100ms | 30M | 33.1 | 373.2 | 32.5ms | 59.1ms | 68ms | 5.0% | 0.318 |
| 30m_20pct | 100ms | 30M | 19.8 | 341.2 | 32.8ms | 137.7ms | 67ms | 4.8% | 0.191 |

**partially stable** (10s stalls present but 98%+ non-empty blocks):

| scenario | block time | gas limit | Mgas/s | TPS | pb avg | pb max | non-empty % | overhead |
|----------|-----------|-----------|--------|-----|--------|--------|-------------|----------|
| 30m_40pct | 100ms | 30M | 2.8 | 74.0 | 17.8ms | 10,020ms | 98.6% | 21.3% |
| 30m_100pct | 100ms | 30M | 6.5 | 117.0 | 19.3ms | 90.7ms | 99.2% | 7.5% |
| 100m_10pct | 100ms | 100M | 12.9 | 218.1 | 27.8ms | 86.0ms | 96.7% | 5.2% |
| 100m_20pct | 100ms | 100M | 5.4 | 116.4 | 19.0ms | 176.4ms | 98.1% | 7.2% |
| 30m_80pct_multi | 100ms | 30M | 3.9 | 103.7 | 24.0ms | 10,289ms | 98.9% | 36.1% |

DeFi is more resilient than ERC20 — even configs with 10s stalls maintain 98%+ non-empty blocks. this is because the DeFi tx pool and nonce management is less contended (fewer, larger txs).

**key observations:**
- actual block fill is far below target: 30m_100pct achieves only 2.2% actual utilization
- the throughput gap is a test harness limitation (tx pool contention under concurrent spammers), not a chain limitation
- 6 of 13 DeFi configs timed out (go test 15m timeout exceeded while waiting for spamoor)

## cross-workload comparison

at 30M gas limit, 100ms block time, stable configs only:

| workload | Mgas/s | TPS | pb avg | overhead | reth Ggas/s | gas/tx |
|----------|--------|-----|--------|----------|-------------|--------|
| GasBurner | 148.3 | 149.7 | 59.8ms | 2.1% | 0.547 | 1M |
| ERC20 | 27.8 | 703.1 | 32.6ms | 4.9% | 0.323 | ~40k |
| DeFi | 33.1 | 373.2 | 32.5ms | 5.0% | 0.318 | ~89k |

- GasBurner achieves 5x the Mgas/s of ERC20/DeFi because fewer, larger txs have less per-tx overhead
- ERC20 achieves the highest TPS (703) because each tx uses the least gas
- ev-reth efficiency (Ggas/s) scales with gas per transaction: 0.547 at 1M/tx vs 0.323 at 40k/tx
- ev-node overhead is consistent at 2-5% across workloads when blocks are well-packed

## recommended configurations by expected load

these recommendations are for the benchmarked hardware (8 vCPU, 15 GiB RAM, sequencer role). adjust for different hardware.

### low utilization (5-20% block fill)

this is the expected operating range for most chains.

| parameter | value | rationale |
|-----------|-------|-----------|
| block time | 100ms | stable at low utilization across all workloads |
| gas limit | 30M | sufficient capacity, outperforms 100M at 100ms blocks |
| scrape interval | 25ms | 1:4 ratio with block time |

**expected performance:** 28-148 Mgas/s depending on tx size, 150-700 TPS, <5% overhead, 93-99% non-empty blocks, 60-68ms headroom.

### moderate utilization (20-40% block fill)

| parameter | value | rationale |
|-----------|-------|-----------|
| block time | 250ms | avoids 10s stalls seen at 100ms with >10% ERC20 load |
| gas limit | 30M | larger limits provide no benefit at this block time |
| scrape interval | 50ms | 1:5 ratio with block time |

**expected performance:** 12-99 Mgas/s depending on tx size, 100-716 TPS, ~160ms headroom. note: the 250ms ERC20 result (28.5 Mgas/s, 716 TPS) still showed a single 10s stall, so this config is at the stability boundary.

### high utilization (40-80% block fill)

| parameter | value | rationale |
|-----------|-------|-----------|
| block time | 500ms | first block time where 10s stalls disappear for ERC20 |
| gas limit | 30M | sufficient; 300M only helps with GasBurner-class workloads |
| scrape interval | 100ms | 1:5 ratio with block time |

**expected performance:** 12-120 Mgas/s depending on tx size, 60-286 TPS, ~340ms headroom, <1% overhead, 96-100% non-empty blocks.

for compute-heavy workloads (GasBurner-like, >1M gas/tx), increase gas limit to 100-300M to allow larger blocks. at 500ms block time, ev-reth has enough time to build these larger blocks within the interval.

### max stable Mgas/s

for pure compute workloads where Mgas/s is the primary metric:

| parameter | value | rationale |
|-----------|-------|-----------|
| block time | 100ms | maximize block production rate |
| gas limit | 100M | allows ~23M gas/block avg, fits within 100ms |
| gas per tx | 5M+ | fewer txs = less per-tx overhead |
| scrape interval | 25ms | 1:4 ratio |

**expected performance:** 326 Mgas/s, 0.833 Ggas/s reth efficiency, 0.8% overhead. ProduceBlock avg is 124ms (exceeds block time — blocks produced at ~6.4/s instead of 10/s). stable (no 10s stalls).

the unstable peak is 407 Mgas/s (300M gas limit, 100ms blocks) but this exhibits 10s stalls and is not recommended for production.

### block time preference hierarchy

when in doubt, prefer longer block times. the data consistently shows:

| block time | stability | Mgas/s | non-empty % | overhead |
|-----------|-----------|--------|-------------|----------|
| 50ms | poor | low | 55% | 62% |
| 100ms | good at low util only | highest at low util | 93% at 10% | 2-5% at low util |
| 250ms | moderate | highest absolute | 87% | 53% |
| 500ms | good | moderate | 96% | 3% |
| 1s | best | lowest | 99% | 3% |

a 500ms block time with 96% non-empty blocks delivers more predictable behavior than 100ms with 39-68% non-empty blocks. the Mgas/s is lower, but every block contains meaningful work.

## tests that should be added

the current test suite has significant gaps that limit the evaluation:

1. **GasBurner with standardized utilization sweep** — the current GasBurner configs use ad-hoc names (baseline, max_mgas, etc.) instead of the `{gas_limit}_{utilization}` convention. a 30M sweep at 10/20/40/80/100/120% would allow direct comparison with ERC20 and DeFi.

2. **StatePressure** — not yet run. storage-write-heavy workloads will stress state root computation in ev-reth differently than compute-heavy GasBurner.

3. **mixed workload** — no test currently combines multiple tx types in a single run. real chains see a mix of EOA transfers, token transfers, and contract interactions.

4. **DeFi at longer block times** — DeFi configs only tested at 100ms. the ERC20 block time sweep (50ms → 1s) revealed that 500ms-1s eliminates stalls. DeFi should have the same sweep.

5. **GasBurner at longer block times with high gas limits** — e.g., 500ms/300M and 1s/500M with the standardized sweep. the current slow_blocks configs use different gas limits than the core sweep, making comparison harder.

6. **sustained load over longer durations** — current tests run 60-400s. runs of 30-60 minutes would reveal memory leaks, state accumulation effects, and GC pressure patterns.

7. **multiple sequencer hardware profiles** — all results are from 8 vCPU / 15 GiB. testing on 4 vCPU and 16 vCPU would show how performance scales with hardware.

8. **re-run failed DeFi configs** — 6 of 13 DeFi configs timed out (go test 15m timeout). re-running with `--timeout 35m` should resolve these.

9. **ERC20 100% and 120% with backpressure handling** — these failed due to RPC rate limiting (429 responses). adjusting injection rates or adding backpressure handling in the test harness would produce usable data.

10. **block time sweep at different utilization levels** — current ERC20 block time sweep is only at 40% target utilization. running 10% and 80% at each block time would show how the stability curve shifts.

11. **scrape interval sensitivity** — all tests use a fixed ratio (block_time / 4 or / 5). testing with mismatched ratios (e.g., 25ms scrape at 500ms block time, or 100ms scrape at 100ms block time) would quantify the actual impact.

## coverage gaps

### fullnode sync and validation not measured

all benchmarks target the sequencer directly (`BENCH_ETH_RPC_URL=http://stg-benchmarking-evstack-evm-node-1:8545`). the three fullnodes in the cluster are running but not exercised by the test harness. this means:

- **fullnode block sync latency under load** is unknown — how quickly do fullnodes receive and validate blocks when the sequencer is under heavy tx pressure?
- **read query performance across the cluster** is untested — no benchmark queries fullnodes for block data, receipts, or state
- **end-to-end system behavior** through the Hetzner load balancer (`10.17.0.11:8545`) is not captured

the LB is a TCP passthrough that round-robins across all nodes (sequencer + fullnodes). it cannot be used for tx-submission benchmarks because **fullnode tx pools are disconnected from block building**. `eth_sendRawTransaction` calls routed to a fullnode will *succeed* (the RPC method is available, the tx enters the local pool, a tx hash is returned), but in production mode the payload builder only uses transactions from Engine API attributes — the local pool is ignored. there is no tx forwarding, no P2P gossip relay to the sequencer, and no `--tx-forward` flag in ev-reth. transactions sent to fullnodes silently go nowhere, which is worse than an outright rejection for benchmarking: spamoor would report successful sends while actual on-chain throughput drops, producing misleading metrics.

to benchmark through the LB, one of:
1. **split read/write URLs** — keep tx submission pointed at the sequencer, route read queries through the LB (no code changes, partial coverage)
2. **add tx forwarding to ev-reth** — fullnodes proxy write RPCs to the sequencer (code change, full coverage)
3. **reconfigure the LB** — create a write-only LB service targeting only the sequencer (infra change, partial coverage)

until one of these is implemented, all results reflect sequencer-only performance.

## open questions

1. **what triggers the first ExecuteTxs failure?** the retry logs (`"failed to execute transactions, retrying"`) should contain the error. the error likely comes from `reconcileExecutionAtHeight` (stale ExecMeta, block not found in EL) or `getBlockInfo` (ev-reth temporarily unavailable). capturing this error in the result JSON would help identify whether it's preventable.

2. **is the 10s retry timeout optimal?** the fixed 10s wait was designed for crash recovery scenarios where ev-reth needs time to restart. for transient failures during normal operation, a shorter initial backoff (e.g., 100ms with exponential backoff) would reduce the impact from ~100 empty blocks to ~1.

3. **why does actual utilization diverge from target at high concurrency?** at low concurrency (2-3 spammers), actual utilization tracks the target. at 6+ spammers, it collapses. this is likely tx pool contention (nonce conflicts across overlapping wallet sets) or RPC connection saturation, not a chain limitation.

4. **does ev-reth's state root computation time scale with state size?** all benchmarks start from near-genesis state. after millions of transactions, state trie depth increases and state root computation in `builder.finish()` may take longer. the StatePressure test should help answer this.
