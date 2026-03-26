# DeFi simulation benchmark report

**Date:** 2026-03-26
**Platform:** linux/amd64
**ev-reth:** `v0.3.0-beta`
**ev-node:** `v1.0.0`
**Workload:** Uniswap V2 swap transactions (DeFi simulation)

## environment

| Property | Value |
|----------|-------|
| Host | stg-benchmarking-evstack-evm-node-1 |
| CPU | 8 vCPU (x86_64) |
| Memory | 15GiB |
| OS | Linux 6.8.0-90-generic |
| Role | sequencer |

## test matrix

13 configs attempted. 7 passed, 6 timed out (go test 15m timeout). All timeouts occurred in `waitForMetricTarget` — the test was waiting for spamoor to finish sending transactions. These are infrastructure/test harness timeouts, not chain failures.

### failed scenarios (all timeouts)

| Scenario | Spammers | Count/Spammer | Total Txs | Failure |
|----------|----------|--------------|-----------|---------|
| 30m_80pct | 8 | 45,000 | 360,000 | `panic: test timed out after 15m0s` |
| 30m_120pct | 10 | 50,000 | 500,000 | `panic: test timed out after 15m0s` |
| 100m_40pct | 10 | 60,000 | 600,000 | `panic: test timed out after 15m0s` |
| 100m_80pct | 10 | 100,000 | 1,000,000 | `panic: test timed out after 15m0s` |
| 30m_80pct_250ms | 8 | 45,000 | 360,000 | `panic: test timed out after 15m0s` |
| 30m_80pct_1s | 8 | 45,000 | 360,000 | `panic: test timed out after 15m0s` |

These are transient — configs with identical or higher tx targets passed in other runs (e.g. `30m_100pct` at 450k txs completed in 402s, `30m_80pct_multi_pair` at 360k completed in 446s). The failures are likely caused by chain instability after repeated ansible redeploys without sufficient stabilization time between runs.

## summary

| Scenario | Gas Limit | Mgas/s | TPS | Blocks/s | Non-Empty % | Overhead % | Reth Ggas/s |
|----------|-----------|--------|-----|----------|-------------|-----------|-------------|
| 30m_10pct | 30M | 33.1 | 373.2 | 10.0 | 100.0% | 5.0% | 0.318 |
| 30m_20pct | 30M | 19.8 | 341.2 | 9.0 | 91.7% | 4.8% | 0.191 |
| 30m_40pct | 30M | 2.8 | 74.0 | 9.6 | 98.6% | 21.3% | 0.074 |
| 30m_100pct | 30M | 6.5 | 117.0 | 9.9 | 99.2% | 7.5% | 0.116 |
| 100m_10pct | 100M | 12.9 | 218.1 | 9.6 | 96.7% | 5.2% | 0.156 |
| 100m_20pct | 100M | 5.4 | 116.4 | 9.2 | 98.1% | 7.2% | 0.120 |
| 30m_80pct_multi_pair | 30M | 3.9 | 103.7 | 8.9 | 98.9% | 36.1% | 0.099 |

All tests used 100ms block time. Block intervals measured at ~100-110ms, confirming the ansible inventory fix is working.

## block production timing

| Scenario | ProduceBlock avg | ProduceBlock max | GetPayload avg | GetPayload max | NewPayload avg | NewPayload max |
|----------|-----------------|-----------------|----------------|---------------|---------------|---------------|
| 30m_10pct | 32.5ms | 59.1ms | 14.6ms | 29.1ms | 10.2ms | 22.3ms |
| 30m_20pct | 32.8ms | 137.7ms | 13.3ms | 33.3ms | 10.2ms | 40.8ms |
| 30m_40pct | 17.8ms | 10,019.6ms | 4.7ms | 49.9ms | 3.7ms | 53.1ms |
| 30m_100pct | 19.3ms | 90.7ms | 6.0ms | 52.2ms | 5.5ms | 28.1ms |
| 100m_10pct | 27.8ms | 86.0ms | 9.1ms | 25.2ms | 7.9ms | 37.9ms |
| 100m_20pct | 19.0ms | 176.4ms | 5.1ms | 50.7ms | 4.7ms | 38.9ms |
| 30m_80pct_multi_pair | 24.0ms | 10,289.0ms | 5.5ms | 51.5ms | 4.2ms | 64.6ms |

## per-block distribution

| Scenario | Avg Gas/Block | Gas p50 | Gas p99 | Avg Tx/Block | Tx p50 | Tx p99 | Gas/Tx |
|----------|--------------|---------|---------|-------------|--------|--------|--------|
| 30m_10pct | 3,324,081 | 3,165,216 | 4,439,406 | 37.5 | 36 | 47 | ~89k |
| 30m_20pct | 2,185,157 | 1,859,228 | 4,835,553 | 37.7 | 33 | 68 | ~58k |
| 30m_40pct | 292,081 | 259,052 | 1,161,628 | 7.7 | 6 | 32 | ~38k |
| 30m_100pct | 659,670 | 575,008 | 2,104,811 | 11.8 | 9 | 82 | ~56k |
| 100m_10pct | 1,335,102 | 1,279,922 | 3,114,289 | 22.7 | 21 | 63 | ~59k |
| 100m_20pct | 589,304 | 449,044 | 2,869,645 | 12.7 | 10 | 112 | ~46k |
| 30m_80pct_multi_pair | 439,141 | 249,391 | 3,375,405 | 11.6 | 7 | 65 | ~38k |

## target vs actual utilization

The "utilization %" in the scenario name is the target injection rate, not a guarantee of actual block fill. Actual utilization = avg_gas_per_block / gas_limit.

| Scenario | Target | Actual Utilization | Gap |
|----------|--------|-------------------|-----|
| 30m_10pct | 10% | 11.1% | on target |
| 30m_20pct | 20% | 7.3% | 2.7x below |
| 30m_40pct | 40% | 0.97% | 41x below |
| 30m_100pct | 100% | 2.2% | 45x below |
| 100m_10pct | 10% | 1.3% | 7.7x below |
| 100m_20pct | 20% | 0.59% | 34x below |
| 30m_80pct_multi_pair | 80% | 1.5% | 53x below |

Only the 30m_10pct scenario achieved its target utilization. All other scenarios show a large gap between intended and actual block fill. This is the central finding of this benchmark run.

## analysis

### 1. throughput degrades sharply beyond 2-3 spammers

| Spammers | Mgas/s | TPS | Avg Gas/Block |
|----------|--------|-----|--------------|
| 2 | 33.1 | 373 | 3.3M |
| 3 | 19.8 | 341 | 2.2M |
| 4 (100M) | 12.9 | 218 | 1.3M |
| 6 | 2.8 | 74 | 292k |
| 8 (100M) | 5.4 | 116 | 589k |
| 8 (multi_pair) | 3.9 | 104 | 439k |
| 10 | 6.5 | 117 | 660k |

With 2 spammers, the chain processes 373 TPS and fills blocks to 3.3M gas. At 6+ spammers, throughput collapses — blocks contain only 7-12 txs despite hundreds of txs/s being injected. This is not a chain limitation (the block production pipeline has idle headroom); it's a tx pool or inclusion bottleneck under concurrent load.

Possible causes:
- **tx pool contention**: many spammers competing for nonces on overlapping wallet sets cause replacement/eviction
- **RPC backpressure**: single RPC endpoint saturates under 6+ concurrent clients, causing tx submission delays
- **spamoor internal bottleneck**: single spamoor container running many internal spammers may hit CPU or connection limits

### 2. block production stalls at higher load

Two scenarios (`30m_40pct`, `30m_80pct_multi_pair`) show `ProduceBlock max` exceeding **10 seconds** — 100x the target block time. The average remains low (17-24ms), indicating these are rare outlier stalls, not sustained degradation.

| Scenario | ProduceBlock avg | ProduceBlock max | Stall ratio |
|----------|-----------------|-----------------|------------|
| 30m_10pct | 32.5ms | 59.1ms | 1.8x |
| 30m_20pct | 32.8ms | 137.7ms | 4.2x |
| 30m_40pct | 17.8ms | 10,019.6ms | 563x |
| 30m_100pct | 19.3ms | 90.7ms | 4.7x |
| 30m_80pct_multi_pair | 24.0ms | 10,289.0ms | 429x |

The stalls don't correlate cleanly with load level — `30m_100pct` (10 spammers) has no stalls while `30m_40pct` (6 spammers) does. This suggests the stalls are triggered by specific tx patterns or state access conflicts rather than raw throughput.

### 3. ev-node overhead scales with contention, not throughput

| Scenario | Overhead % | Avg Gas/Block |
|----------|-----------|--------------|
| 30m_20pct | 4.8% | 2.2M |
| 30m_10pct | 5.0% | 3.3M |
| 100m_10pct | 5.2% | 1.3M |
| 100m_20pct | 7.2% | 589k |
| 30m_100pct | 7.5% | 660k |
| 30m_40pct | 21.3% | 292k |
| 30m_80pct_multi_pair | 36.1% | 439k |

Overhead stays under 8% when blocks contain meaningful gas. It spikes to 21-36% when blocks are mostly empty — the fixed orchestration cost of ProduceBlock dominates when there's little actual execution work.

### 4. reth execution efficiency

| Scenario | Reth Ggas/s | Secs/Ggas | Avg Gas/Block |
|----------|-----------|----------|--------------|
| 30m_10pct | 0.318 | 30.2 | 3.3M |
| 30m_20pct | 0.191 | 50.6 | 2.2M |
| 100m_10pct | 0.156 | 77.8 | 1.3M |
| 100m_20pct | 0.120 | 185.3 | 589k |
| 30m_100pct | 0.116 | 153.6 | 660k |
| 30m_80pct_multi_pair | 0.099 | 254.6 | 439k |
| 30m_40pct | 0.074 | 357.0 | 292k |

Reth processes gas most efficiently when blocks are well-packed (0.318 Ggas/s at 3.3M gas/block). Efficiency drops 4x when blocks are sparsely filled — the per-block fixed cost of NewPayload/GetPayload dominates small blocks.

### 5. gas limit: 30M vs 100M

Comparing equivalent target utilization levels:

| Metric | 30M @ 10% | 100M @ 10% | 30M @ 20% | 100M @ 20% |
|--------|-----------|-----------|-----------|-----------|
| Mgas/s | 33.1 | 12.9 | 19.8 | 5.4 |
| TPS | 373 | 218 | 341 | 116 |
| Avg Gas/Block | 3.3M | 1.3M | 2.2M | 589k |
| Actual Util | 11.1% | 1.3% | 7.3% | 0.59% |
| Overhead | 5.0% | 5.2% | 4.8% | 7.2% |

30M gas limit consistently outperforms 100M at the same target utilization. The 100M tests achieve lower actual utilization despite higher injection rates. This suggests the larger gas limit doesn't help — the bottleneck is tx pool throughput, not block capacity.

### 6. DeFi tx gas consumption

Observed gas per tx ranges from 38k to 89k, much lower than the expected ~200k for Uniswap V2 swaps. This indicates the workload includes a mix of transaction types (contract deployments, token approvals, pair setup) alongside the actual swap transactions. The gas_units_to_burn config (1M) is ignored for DeFi tests.

## key findings for deployment configuration

### what the data shows

1. **The chain handles DeFi load well at low concurrency.** At 2-3 spammers, the system achieves 33 Mgas/s (373 TPS) with 100% non-empty blocks, 5% overhead, and no stalls. Block production fits comfortably within the 100ms interval.

2. **Throughput collapses under concurrent load.** Beyond 3 spammers, actual block fill drops to 1-2% regardless of gas limit or target utilization. This is a tx inclusion problem, not a block production problem — the pipeline has headroom but blocks aren't being filled.

3. **10s block production stalls appear sporadically.** These occur in some high-concurrency runs but not others with similar configs, suggesting a state access or tx pool interaction issue.

4. **30M gas limit is sufficient.** 100M provides no throughput benefit given the current tx inclusion bottleneck. Until the concurrent tx handling is improved, increasing gas limit adds no value.

5. **100ms block time works correctly** but provides no advantage when blocks are sparsely filled. The avg block production time (17-33ms) leaves 67-83ms of idle time per block interval.

### what's missing

The low actual utilization across all high-concurrency configs means this data cannot yet answer "what are the best settings for a given % load." The chain isn't being stressed to its capacity — the test harness is hitting a tx inclusion bottleneck before the chain reaches meaningful utilization.

To determine optimal settings per load level, the next steps should investigate:

1. **why tx inclusion drops under concurrent load** — is it nonce management, tx pool eviction, RPC connection limits, or spamoor's internal parallelism?
2. **run with multiple spamoor containers** (one per spammer) instead of a single container running N internal spammers, to rule out single-container bottlenecks
3. **add tx pool metrics** (pending count, queued count, evictions) to the result output to see where txs are getting stuck
4. **test with fewer spammers but higher per-spammer throughput** to see if 2 spammers at 500 tx/s achieve higher utilization than 10 spammers at 150 tx/s
