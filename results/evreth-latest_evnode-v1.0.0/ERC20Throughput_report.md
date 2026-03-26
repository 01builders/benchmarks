# ERC20Throughput benchmark report

**Date:** 2026-03-26  
**Platform:** linux/amd64  
**ev-reth:** `latest`  
**ev-node:** `v1.0.0`

## environment

| Property | Value |
|----------|-------|
| Host | stg-benchmarking-evstack-evm-node-1 |
| CPU | 8 vCPU (x86_64) |
| Memory | 15GiB |
| OS | Linux 6.8.0-90-generic |
| Role | sequencer |

## summary

| Scenario | Block Time | Gas Limit | Mgas/s | TPS | Blocks/s | Non-Empty % | Overhead % | Reth Ggas/s |
|----------|-----------|-----------|--------|-----|----------|-------------|-----------|-------------|
| 30m_10pct | 100ms | 30M | 27.8 | 703.1 | 9.4 | 92.8 | 4.9 | 0.323 |
| 30m_20pct | 100ms | 30M | 15.2 | 400.7 | 5.3 | 60.2 | 42.2 | 0.286 |
| 30m_40pct | 100ms | 30M | 13.8 | 364.8 | 5.3 | 67.9 | 57.3 | 0.271 |
| 30m_80pct | 100ms | 30M | 3.8 | 128.0 | 2.7 | 38.8 | 74.6 | 0.145 |
| 100m_10pct | 100ms | 100M | 6.5 | 200.3 | 3.2 | 35.7 | 47.0 | 0.165 |
| 100m_20pct | 100ms | 100M | 3.5 | 107.8 | 1.5 | 18.6 | 68.1 | 0.135 |
| 100m_40pct | 100ms | 100M | 3.7 | 122.0 | 1.9 | 25.7 | 71.9 | 0.139 |
| 30m_40pct_50ms | 50ms | 30M | 8.9 | 292.5 | 7.3 | 55.0 | 61.8 | 0.161 |
| 30m_40pct_250ms | 250ms | 30M | 28.5 | 715.6 | 2.7 | 86.9 | 52.5 | 0.534 |
| 30m_40pct_500ms | 500ms | 30M | 12.0 | 285.5 | 2.0 | 95.6 | 3.3 | 0.443 |
| 30m_40pct_1s | 1s | 30M | 6.2 | 146.4 | 1.0 | 98.9 | 3.2 | 0.483 |

## block production timing

| Scenario | ProduceBlock avg | ProduceBlock max | GetPayload avg | GetPayload max | NewPayload avg | NewPayload max |
|----------|-----------------|-----------------|----------------|---------------|---------------|---------------|
| 30m_10pct | 32.6ms | 96.1ms | 15.4ms | 32.5ms | 8.3ms | 24.0ms |
| 30m_20pct | 41.3ms | 10,013.6ms | 11.8ms | 53.9ms | 5.9ms | 56.7ms |
| 30m_40pct | 58.3ms | 10,056.0ms | 11.8ms | 96.1ms | 6.4ms | 47.6ms |
| 30m_80pct | 59.3ms | 10,142.2ms | 5.8ms | 175.4ms | 3.7ms | 71.4ms |
| 100m_10pct | 33.9ms | 10,047.4ms | 7.7ms | 90.0ms | 4.3ms | 52.1ms |
| 100m_20pct | 41.9ms | 10,085.6ms | 4.9ms | 53.3ms | 3.2ms | 72.1ms |
| 100m_40pct | 51.6ms | 10,041.2ms | 5.6ms | 95.8ms | 3.5ms | 266.5ms |
| 30m_40pct_50ms | 40.1ms | 20,143.9ms | 5.9ms | 61.9ms | 4.0ms | 49.7ms |
| 30m_40pct_250ms | 144.8ms | 10,097.8ms | 41.1ms | 94.9ms | 17.0ms | 54.0ms |
| 30m_40pct_500ms | 52.8ms | 188.7ms | 27.9ms | 55.2ms | 13.6ms | 50.7ms |
| 30m_40pct_1s | 50.0ms | 156.6ms | 27.6ms | 70.5ms | 12.9ms | 59.5ms |

## per-block distribution

| Scenario | Avg Gas/Block | Gas p50 | Gas p99 | Avg Tx/Block | Tx p50 | Tx p99 |
|----------|--------------|---------|---------|-------------|--------|--------|
| 30m_10pct | 2,957,735 | 2871980 | 4,154,280 | 74.7 | 63 | 107 |
| 30m_20pct | 2,858,257 | 2691580 | 14,312,772 | 75.2 | 74 | 300 |
| 30m_40pct | 2,612,058 | 2510115 | 6,344,210 | 69.0 | 70 | 127 |
| 30m_80pct | 1,417,294 | 1258857 | 4,965,492 | 47.7 | 42 | 147 |
| 100m_10pct | 2,069,337 | 1944425 | 6,723,818 | 63.5 | 64 | 125 |
| 100m_20pct | 2,385,663 | 2323056 | 5,390,560 | 74.3 | 76 | 161 |
| 100m_40pct | 1,947,325 | 1838836 | 4,001,655 | 65.1 | 64 | 134 |
| 30m_40pct_50ms | 1,222,153 | 1014498 | 4,574,156 | 40.1 | 35 | 137 |
| 30m_40pct_250ms | 10,426,213 | 11670970 | 15,649,699 | 261.6 | 302 | 330 |
| 30m_40pct_500ms | 6,143,658 | 7451580 | 10,753,933 | 146.1 | 108 | 192 |
| 30m_40pct_1s | 6,208,406 | 7923416 | 15,546,723 | 145.6 | 22 | 278 |

## scenario details

### 30m_10pct

**Timestamp:** 2026-03-26T09:25:36Z  
**File:** `TestERC20Throughput_30m_10pct_20260326T092151.json`

**Config:**

- Block time: 100ms, Gas limit: 30M (0x1C9C380)
- Spammers: 4 x 12000 txs @ 115 tx/s each
- Gas per tx: 1,000,000, Wallets: 200
- Warmup: 300 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 27.8 Mgas/s, 703.1 TPS, 9.4 blocks/s
- **Reth execution:** 0.323 Ggas/s (35.9 s/Ggas)
- **Overhead:** 4.9%
- **Duration:** 53s steady-state, 54.0s wall clock
- **Blocks:** 538 total, 499 non-empty (92.8%)
- **Transactions:** 48,016 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 32.6 | 5.2 | 96.1 |
| GetPayload | 15.4 | 0.3 | 32.5 |
| NewPayload | 8.3 | 1.2 | 24.0 |

### 30m_20pct

**Timestamp:** 2026-03-26T09:29:02Z  
**File:** `TestERC20Throughput_30m_20pct_20260326T092537.json`

**Config:**

- Block time: 100ms, Gas limit: 30M (0x1C9C380)
- Spammers: 6 x 15000 txs @ 155 tx/s each
- Gas per tx: 1,000,000, Wallets: 300
- Warmup: 500 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 15.2 Mgas/s, 400.7 TPS, 5.3 blocks/s
- **Reth execution:** 0.286 Ggas/s (65.7 s/Ggas)
- **Overhead:** 42.2%
- **Duration:** 70s steady-state, 72.2s wall clock
- **Blocks:** 620 total, 373 non-empty (60.2%)
- **Transactions:** 94,578 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 41.3 | 5.7 | 10,013.6 |
| GetPayload | 11.8 | 0.8 | 53.9 |
| NewPayload | 5.9 | 1.0 | 56.7 |

### 30m_40pct

**Timestamp:** 2026-03-26T09:32:45Z  
**File:** `TestERC20Throughput_30m_40pct_20260326T092903.json`

**Config:**

- Block time: 100ms, Gas limit: 30M (0x1C9C380)
- Spammers: 8 x 22000 txs @ 230 tx/s each
- Gas per tx: 1,000,000, Wallets: 400
- Warmup: 500 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 13.8 Mgas/s, 364.8 TPS, 5.3 blocks/s
- **Reth execution:** 0.271 Ggas/s (72.4 s/Ggas)
- **Overhead:** 57.3%
- **Duration:** 79s steady-state, 82.0s wall clock
- **Blocks:** 616 total, 418 non-empty (67.9%)
- **Transactions:** 183,664 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 58.3 | 4.8 | 10,056.0 |
| GetPayload | 11.8 | 0.3 | 96.1 |
| NewPayload | 6.4 | 1.1 | 47.6 |

### 30m_80pct

**Timestamp:** 2026-03-26T09:41:34Z  
**File:** `TestERC20Throughput_30m_80pct_20260326T093248.json`

**Config:**

- Block time: 100ms, Gas limit: 30M (0x1C9C380)
- Spammers: 10 x 35000 txs @ 370 tx/s each
- Gas per tx: 1,000,000, Wallets: 500
- Warmup: 1000 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 3.8 Mgas/s, 128.0 TPS, 2.7 blocks/s
- **Reth execution:** 0.145 Ggas/s (262.8 s/Ggas)
- **Overhead:** 74.6%
- **Duration:** 359s steady-state, 360.0s wall clock
- **Blocks:** 2485 total, 964 non-empty (38.8%)
- **Transactions:** 361,270 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 59.3 | 4.4 | 10,142.2 |
| GetPayload | 5.8 | 0.5 | 175.4 |
| NewPayload | 3.7 | 0.9 | 71.4 |

### 100m_10pct

**Timestamp:** 2026-03-26T10:15:49Z  
**File:** `TestERC20Throughput_100m_10pct_20260326T101053.json`

**Config:**

- Block time: 100ms, Gas limit: 100M (0x5F5E100)
- Spammers: 8 x 18000 txs @ 190 tx/s each
- Gas per tx: 1,000,000, Wallets: 400
- Warmup: 500 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 6.5 Mgas/s, 200.3 TPS, 3.2 blocks/s
- **Reth execution:** 0.165 Ggas/s (153.3 s/Ggas)
- **Overhead:** 47.0%
- **Duration:** 151s steady-state, 154.0s wall clock
- **Blocks:** 1332 total, 476 non-empty (35.7%)
- **Transactions:** 146,936 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 33.9 | 4.5 | 10,047.4 |
| GetPayload | 7.7 | 0.5 | 90.0 |
| NewPayload | 4.3 | 0.8 | 52.1 |

### 100m_20pct

**Timestamp:** 2026-03-26T10:26:08Z  
**File:** `TestERC20Throughput_100m_20pct_20260326T101551.json`

**Config:**

- Block time: 100ms, Gas limit: 100M (0x5F5E100)
- Spammers: 10 x 30000 txs @ 310 tx/s each
- Gas per tx: 1,000,000, Wallets: 500
- Warmup: 1000 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 3.5 Mgas/s, 107.8 TPS, 1.5 blocks/s
- **Reth execution:** 0.135 Ggas/s (288.9 s/Ggas)
- **Overhead:** 68.1%
- **Duration:** 457s steady-state, 458.0s wall clock
- **Blocks:** 3565 total, 663 non-empty (18.6%)
- **Transactions:** 318,940 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 41.9 | 4.3 | 10,085.6 |
| GetPayload | 4.9 | 0.5 | 53.3 |
| NewPayload | 3.2 | 0.9 | 72.1 |

### 100m_40pct

**Timestamp:** 2026-03-26T10:39:29Z  
**File:** `TestERC20Throughput_100m_40pct_20260326T102612.json`

**Config:**

- Block time: 100ms, Gas limit: 100M (0x5F5E100)
- Spammers: 10 x 60000 txs @ 615 tx/s each
- Gas per tx: 1,000,000, Wallets: 500
- Warmup: 1000 txs, Timeout: 15m0s

**Results:**

- **Throughput:** 3.7 Mgas/s, 122.0 TPS, 1.9 blocks/s
- **Reth execution:** 0.139 Ggas/s (273.9 s/Ggas)
- **Overhead:** 71.9%
- **Duration:** 633s steady-state, 634.0s wall clock
- **Blocks:** 4617 total, 1187 non-empty (25.7%)
- **Transactions:** 607,830 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 51.6 | 3.5 | 10,041.2 |
| GetPayload | 5.6 | 0.3 | 95.8 |
| NewPayload | 3.5 | 0.8 | 266.5 |

### 30m_40pct_50ms

**Timestamp:** 2026-03-26T10:44:43Z  
**File:** `TestERC20Throughput_30m_40pct_50ms_20260326T103939.json`

**Config:**

- Block time: 50ms, Gas limit: 30M (0x1C9C380)
- Spammers: 8 x 22000 txs @ 230 tx/s each
- Gas per tx: 1,000,000, Wallets: 400
- Warmup: 500 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 8.9 Mgas/s, 292.5 TPS, 7.3 blocks/s
- **Reth execution:** 0.161 Ggas/s (112.1 s/Ggas)
- **Overhead:** 61.8%
- **Duration:** 151s steady-state, 152.0s wall clock
- **Blocks:** 2003 total, 1102 non-empty (55.0%)
- **Transactions:** 189,272 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 40.1 | 4.0 | 20,143.9 |
| GetPayload | 5.9 | 0.3 | 61.9 |
| NewPayload | 4.0 | 0.8 | 49.7 |

### 30m_40pct_250ms

**Timestamp:** 2026-03-26T10:48:27Z  
**File:** `TestERC20Throughput_30m_40pct_250ms_20260326T104445.json`

**Config:**

- Block time: 250ms, Gas limit: 30M (0x1C9C380)
- Spammers: 8 x 22000 txs @ 230 tx/s each
- Gas per tx: 1,000,000, Wallets: 400
- Warmup: 500 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 28.5 Mgas/s, 715.6 TPS, 2.7 blocks/s
- **Reth execution:** 0.534 Ggas/s (35.1 s/Ggas)
- **Overhead:** 52.5%
- **Duration:** 87s steady-state, 88.0s wall clock
- **Blocks:** 274 total, 238 non-empty (86.9%)
- **Transactions:** 199,976 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 144.8 | 6.0 | 10,097.8 |
| GetPayload | 41.1 | 1.0 | 94.9 |
| NewPayload | 17.0 | 1.1 | 54.0 |

### 30m_40pct_500ms

**Timestamp:** 2026-03-26T10:52:39Z  
**File:** `TestERC20Throughput_30m_40pct_500ms_20260326T104830.json`

**Config:**

- Block time: 500ms, Gas limit: 30M (0x1C9C380)
- Spammers: 8 x 22000 txs @ 230 tx/s each
- Gas per tx: 1,000,000, Wallets: 400
- Warmup: 500 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 12.0 Mgas/s, 285.5 TPS, 2.0 blocks/s
- **Reth execution:** 0.443 Ggas/s (83.3 s/Ggas)
- **Overhead:** 3.3%
- **Duration:** 110s steady-state, 112.0s wall clock
- **Blocks:** 225 total, 215 non-empty (95.6%)
- **Transactions:** 176,800 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 52.8 | 7.3 | 188.7 |
| GetPayload | 27.9 | 1.2 | 55.2 |
| NewPayload | 13.6 | 1.7 | 50.7 |

### 30m_40pct_1s

**Timestamp:** 2026-03-26T10:58:01Z  
**File:** `TestERC20Throughput_30m_40pct_1s_20260326T105242.json`

**Config:**

- Block time: 1s, Gas limit: 30M (0x1C9C380)
- Spammers: 8 x 22000 txs @ 230 tx/s each
- Gas per tx: 1,000,000, Wallets: 400
- Warmup: 500 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 6.2 Mgas/s, 146.4 TPS, 1.0 blocks/s
- **Reth execution:** 0.483 Ggas/s (160.2 s/Ggas)
- **Overhead:** 3.2%
- **Duration:** 182s steady-state, 184.0s wall clock
- **Blocks:** 185 total, 183 non-empty (98.9%)
- **Transactions:** 177,136 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 50.0 | 8.5 | 156.6 |
| GetPayload | 27.6 | 2.5 | 70.5 |
| NewPayload | 12.9 | 1.8 | 59.5 |

## failed scenarios

Two scenarios failed and produced no result JSON.

### 30m_100pct (FAIL)

- **Config:** 30M gas limit, 100ms block time, 10 spammers x 45,000 txs @ 460 tx/s each
- **Error:** `timed out waiting for spamoor to send 450000 txs (sent 3,110): context deadline exceeded`
- **Log file:** `TestERC20Throughput_30m_100pct_20260326T094141.log` (50MB)
- **Duration:** 742.7s (test timeout)

The load generator was unable to inject transactions. Only 3,110 of 450,000 txs were sent before the 10m wait timeout. Logs show the RPC endpoint returning `429 Too Many Requests` and mass `context canceled` errors. The sequencer's connection limit was saturated by the 10 spammers x 500 wallets sending at 460 tx/s aggregate.

### 30m_120pct (FAIL)

- **Config:** 30M gas limit, 100ms block time, 10 spammers x 55,000 txs @ 550 tx/s each
- **Error:** `timed out waiting for spamoor to send 550000 txs (sent 111,160): context deadline exceeded`
- **Log file:** `TestERC20Throughput_30m_120pct_20260326T095550.log` (73MB)
- **Duration:** 795.3s (test timeout)

Got further than 100pct (111k vs 3k sent) but still timed out. Logs show nonce gaps and filler transactions, indicating the mempool was heavily congested. At the end of the test, blocks were being produced empty (0 tx confirmed, 538k+ txs pending) as the chain could not drain the backlog.

## analysis

### throughput by utilization (30M gas limit, 100ms block time)

| Utilization | Mgas/s | TPS | Non-Empty % | Overhead % | Status |
|-------------|--------|-----|-------------|------------|--------|
| 10% | 27.8 | 703 | 92.8% | 4.9% | pass |
| 20% | 15.2 | 401 | 60.2% | 42.2% | pass |
| 40% | 13.8 | 365 | 67.9% | 57.3% | pass |
| 80% | 3.8 | 128 | 38.8% | 74.6% | pass |
| 100% | - | - | - | - | **fail** |
| 120% | - | - | - | - | **fail** |

Throughput degrades significantly as utilization increases. The system achieves peak Mgas/s at low utilization (10%) and drops 86% by 80%. The non-empty block ratio falls from 93% to 39%, meaning the majority of blocks at 80% are empty -- the system is struggling to build blocks within the 100ms window.

### degradation cliff

The cliff is between 80% and 100% utilization at 30M/100ms. At 80%, the system is already severely degraded (74.6% overhead, 38.8% non-empty blocks, only 3.8 Mgas/s). At 100%, the load generator itself fails because the RPC endpoint becomes unresponsive under the tx submission pressure (429 rate limiting). The bottleneck shifts from block production to tx ingestion.

### ev-node overhead

Overhead (ProduceBlock minus ExecuteTxs as a percentage of ProduceBlock) scales with utilization:

- 10%: 4.9% -- negligible orchestration cost
- 20%: 42.2% -- a large jump; ev-node spends almost half its time on orchestration
- 40%: 57.3% -- majority of block production time is non-execution
- 80%: 74.6% -- three quarters of ProduceBlock is orchestration

At 500ms and 1s block times, overhead drops to ~3%, suggesting the fixed-cost orchestration is amortized over longer block intervals. The 100ms block time is too tight for the current orchestration path once load increases.

### reth execution efficiency

| Scenario | Reth Ggas/s | Note |
|----------|-------------|------|
| 30m_10pct | 0.323 | best at 100ms block time |
| 30m_40pct_250ms | 0.534 | best overall |
| 30m_40pct_1s | 0.483 | longer intervals help |
| 30m_80pct | 0.145 | heavily degraded |
| 100m_20pct | 0.135 | worst |

Reth executes most efficiently when blocks are larger and less frequent. The 250ms block time at 40% utilization achieves 0.534 Ggas/s -- the highest observed. At 100ms block time, reth's efficiency drops as utilization increases, likely because smaller, more frequent blocks create per-block fixed costs that dominate.

### gas limit scaling (30M vs 100M)

Comparing at the same utilization level and 100ms block time:

| Utilization | 30M Mgas/s | 100M Mgas/s | 30M TPS | 100M TPS |
|-------------|-----------|-------------|---------|----------|
| 10% | 27.8 | 6.5 | 703 | 200 |
| 20% | 15.2 | 3.5 | 401 | 108 |
| 40% | 13.8 | 3.7 | 365 | 122 |

100M gas limit performs significantly worse than 30M at every utilization level. At 10% utilization, 100M achieves only 23% of 30M's throughput. The larger gas limit creates diminishing returns -- the system cannot fill the larger block budget within the 100ms window, and the non-empty ratio drops to 18-36% at 100M vs 39-93% at 30M. The 100ms block time is the binding constraint, not the gas limit.

### block time headroom

Comparing 30M at 40% utilization across block times:

| Block Time | Mgas/s | ProduceBlock avg | ProduceBlock max | Non-Empty % | Overhead % |
|-----------|--------|-----------------|-----------------|-------------|------------|
| 50ms | 8.9 | 40.1ms | 20,144ms | 55.0% | 61.8% |
| 100ms | 13.8 | 58.3ms | 10,056ms | 67.9% | 57.3% |
| 250ms | 28.5 | 144.8ms | 10,098ms | 86.9% | 52.5% |
| 500ms | 12.0 | 52.8ms | 188.7ms | 95.6% | 3.3% |
| 1s | 6.2 | 50.0ms | 156.6ms | 98.9% | 3.2% |

At 50ms, ProduceBlock avg (40ms) nearly fills the entire interval, leaving no headroom. The max spikes to 20s indicate severe stalls. At 250ms, the system has enough headroom for the best Mgas/s (28.5) while keeping overhead at 52.5%. At 500ms and 1s, overhead drops to ~3% and non-empty blocks approach 100%, but Mgas/s drops because the system idles between blocks.

The 250ms block time appears to be the sweet spot for this workload: high non-empty ratio, best absolute throughput, and reasonable overhead. The 10s ProduceBlock max spikes seen at 50-250ms (but absent at 500ms-1s) suggest that block production occasionally stalls for ~10 seconds, likely from execution retries or GC pauses.

### key takeaways

1. **100ms block time is too aggressive for high utilization.** Overhead exceeds 50% by 40% utilization, and the system fails entirely at 100%.
2. **250ms block time is the current throughput sweet spot** for ERC-20 workloads at 30M gas limit (28.5 Mgas/s, 716 TPS).
3. **100M gas limit provides no benefit at 100ms block time.** The system cannot fill the larger blocks fast enough.
4. **The degradation cliff is at 80-100% utilization** (30M/100ms). At 80%, throughput is already 7x worse than 10%. At 100%, the RPC layer collapses under tx submission pressure.
5. **10-second ProduceBlock spikes** appear across most scenarios with 100ms and 250ms block times. These warrant investigation -- they may be execution retries, state commit stalls, or garbage collection pauses.
6. **The two test failures are load-generator-side, not chain-side.** The sequencer's RPC rate limiter rejects connections before spamoor can inject enough txs to start the measurement window. Increasing `BENCH_WAIT_TIMEOUT` alone won't fix this -- the injection rate needs to be sustainable under backpressure.
