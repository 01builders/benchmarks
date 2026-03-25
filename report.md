# GasBurner benchmark report

**Date:** 2026-03-25  
**Platform:** linux/amd64  
**ev-reth:** `latest`  
**ev-node:** `unknown`

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
| baseline_30m_100ms | 100ms | 30M | 148.3 | 149.7 | 10.0 | 98.7 | 2.1 | 0.547 |
| baseline_100m_100ms | 100ms | 100M | 223.1 | 225.1 | 9.8 | 95.5 | 1.9 | 0.637 |
| high_gas_per_tx_100m | 100ms | 100M | 326.1 | 65.3 | 6.4 | 97.4 | 0.8 | 0.833 |
| max_mgas_300m | 100ms | 300M | 406.7 | 204.3 | 2.9 | 100 | 11.7 | 0.938 |
| max_mgas_500m | 100ms | 500M | 371.7 | 186.7 | 3.0 | 100 | 16.6 | 0.924 |
| max_mgas_1g | 100ms | 1G | 132.6 | 90.8 | 6.5 | 80.6 | 24.1 | 0.640 |
| slow_blocks_250ms_100m | 250ms | 100M | 98.9 | 99.8 | 4.0 | 100 | 1.5 | 0.634 |
| slow_blocks_500ms_300m | 500ms | 300M | 119.7 | 60.1 | 2.0 | 100 | 0.9 | 0.803 |
| slow_blocks_1s_500m | 1s | 500M | 62.5 | 31.4 | 1.0 | 100 | 0.9 | 0.814 |
| small_burn_high_volume_100m | 100ms | 100M | 63.0 | 226.0 | 8.9 | 98.0 | 3.6 | 0.484 |
| large_burn_low_volume_300m | 100ms | 300M | 397.7 | 79.7 | 8.0 | 100 | 0.9 | 0.793 |
| fast_blocks_50ms_100m | 50ms | 100M | 281.1 | 290.8 | 8.2 | 100 | 1.4 | 0.771 |

## block production timing

| Scenario | ProduceBlock avg | ProduceBlock max | GetPayload avg | GetPayload max | NewPayload avg | NewPayload max |
|----------|-----------------|-----------------|----------------|---------------|---------------|---------------|
| baseline_30m_100ms | 59.8ms | 108.7ms | 27.9ms | 55.2ms | 26.5ms | 52.6ms |
| baseline_100m_100ms | 74.0ms | 112.1ms | 33.9ms | 54.0ms | 34.6ms | 55.5ms |
| high_gas_per_tx_100m | 124.2ms | 243.3ms | 59.7ms | 119.9ms | 59.4ms | 134.0ms |
| max_mgas_300m | 340.3ms | 10,349.9ms | 143.5ms | 684.0ms | 149.2ms | 267.6ms |
| max_mgas_500m | 317.7ms | 10,368.2ms | 126.1ms | 202.5ms | 133.3ms | 201.0ms |
| max_mgas_1g | 73.2ms | 20,025.8ms | 24.7ms | 349.8ms | 25.0ms | 355.1ms |
| slow_blocks_250ms_100m | 89.0ms | 132.4ms | 43.1ms | 80.7ms | 39.5ms | 65.7ms |
| slow_blocks_500ms_300m | 159.4ms | 215.6ms | 77.0ms | 119.0ms | 75.3ms | 103.4ms |
| slow_blocks_1s_500m | 166.9ms | 274.4ms | 82.8ms | 182.9ms | 77.6ms | 118.5ms |
| small_burn_high_volume_100m | 36.2ms | 147.3ms | 15.1ms | 71.5ms | 14.0ms | 64.0ms |
| large_burn_low_volume_300m | 125.4ms | 209.9ms | 58.1ms | 131.5ms | 62.2ms | 86.1ms |
| fast_blocks_50ms_100m | 93.1ms | 315.1ms | 42.8ms | 208.0ms | 43.7ms | 126.7ms |

## per-block distribution

| Scenario | Avg Gas/Block | Gas p50 | Gas p99 | Avg Tx/Block | Tx p50 | Tx p99 |
|----------|--------------|---------|---------|-------------|--------|--------|
| baseline_30m_100ms | 14,858,126 | 9910670 | 21803474 | 15.0 | 10 | 22 |
| baseline_100m_100ms | 22,866,392 | 22794541 | 28740943 | 23.1 | 23 | 29 |
| high_gas_per_tx_100m | 51,177,138 | 89838918 | 99821260 | 10.3 | 18 | 20 |
| max_mgas_300m | 139,887,410 | 131409630 | 167248620 | 70.3 | 66 | 84 |
| max_mgas_500m | 124,511,286 | 133400259 | 165257565 | 62.5 | 67 | 83 |
| max_mgas_1g | 20,454,108 | 14021385 | 97,922,382 | 14.0 | 10 | 69 |
| slow_blocks_250ms_100m | 24,763,083 | 27749876 | 31714144 | 25.0 | 28 | 32 |
| slow_blocks_500ms_300m | 59,700,897 | 71677980 | 71677980 | 30.0 | 36 | 36 |
| slow_blocks_1s_500m | 62,273,475 | 63713376 | 77651145 | 31.3 | 32 | 39 |
| small_burn_high_volume_100m | 7,092,110 | 2665255 | 34,838,166 | 25.4 | 10 | 119 |
| large_burn_low_volume_300m | 49,910,626 | 49910630 | 49910630 | 10 | 10 | 10 |
| fast_blocks_50ms_100m | 34,416,384 | 6937469 | 97124566 | 35.6 | 7 | 105 |

## scenario details

### baseline_30m_100ms

**Timestamp:** 2026-03-25T14:07:03Z  
**File:** `TestGasBurner_baseline_30m_100ms_20260325T140346.json`

**Config:**

- Block time: 100ms, Gas limit: 30M (0x1C9C380)
- Spammers: 2 x 5000 txs @ 50 tx/s each
- Gas per tx: 1,000,000, Wallets: 100
- Warmup: 200 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 148.3 Mgas/s, 149.7 TPS, 10.0 blocks/s
- **Reth execution:** 0.547 Ggas/s (6.7 s/Ggas)
- **Overhead:** 2.1%
- **Duration:** 63s steady-state, 64.0s wall clock
- **Blocks:** 637 total, 629 non-empty (98.7%)
- **Transactions:** 20,004 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 59.8 | 8.0 | 108.7 |
| GetPayload | 27.9 | 1.1 | 55.2 |
| NewPayload | 26.5 | 1.4 | 52.6 |

### baseline_100m_100ms

**Timestamp:** 2026-03-25T14:09:59Z  
**File:** `TestGasBurner_baseline_100m_100ms_20260325T140708.json`

**Config:**

- Block time: 100ms, Gas limit: 100M (0x5F5E100)
- Spammers: 2 x 5000 txs @ 50 tx/s each
- Gas per tx: 1,000,000, Wallets: 100
- Warmup: 200 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 223.1 Mgas/s, 225.1 TPS, 9.8 blocks/s
- **Reth execution:** 0.637 Ggas/s (4.5 s/Ggas)
- **Overhead:** 1.9%
- **Duration:** 41s steady-state, 42.2s wall clock
- **Blocks:** 419 total, 400 non-empty (95.5%)
- **Transactions:** 20,004 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 74.0 | 5.3 | 112.1 |
| GetPayload | 33.9 | 0.8 | 54.0 |
| NewPayload | 34.6 | 1.2 | 55.5 |

### high_gas_per_tx_100m

**Timestamp:** 2026-03-25T14:13:52Z  
**File:** `TestGasBurner_high_gas_per_tx_100m_20260325T141008.json`

**Config:**

- Block time: 100ms, Gas limit: 100M (0x5F5E100)
- Spammers: 2 x 5000 txs @ 50 tx/s each
- Gas per tx: 5,000,000, Wallets: 100
- Warmup: 200 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 326.1 Mgas/s, 65.3 TPS, 6.4 blocks/s
- **Reth execution:** 0.833 Ggas/s (3.1 s/Ggas)
- **Overhead:** 0.8%
- **Duration:** 94s steady-state, 94.4s wall clock
- **Blocks:** 615 total, 599 non-empty (97.4%)
- **Transactions:** 15,044 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 124.2 | 6.2 | 243.3 |
| GetPayload | 59.7 | 0.6 | 119.9 |
| NewPayload | 59.4 | 1.3 | 134.0 |

### max_mgas_300m

**Timestamp:** 2026-03-25T14:20:00Z  
**File:** `TestGasBurner_max_mgas_300m_20260325T141423.json`

**Config:**

- Block time: 100ms, Gas limit: 300M (0x11E1A300)
- Spammers: 6 x 30000 txs @ 60 tx/s each
- Gas per tx: 2,000,000, Wallets: 200
- Warmup: 200 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 406.7 Mgas/s, 204.3 TPS, 2.9 blocks/s
- **Reth execution:** 0.938 Ggas/s (2.5 s/Ggas)
- **Overhead:** 11.7%
- **Duration:** 184s steady-state, 184.0s wall clock
- **Blocks:** 535 total, 535 non-empty (100%)
- **Transactions:** 302,460 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 340.3 | 22.0 | 10,349.9 |
| GetPayload | 143.5 | 7.8 | 684.0 |
| NewPayload | 149.2 | 9.3 | 267.6 |

### max_mgas_500m

**Timestamp:** 2026-03-25T14:26:00Z  
**File:** `TestGasBurner_max_mgas_500m_20260325T142012.json`

**Config:**

- Block time: 100ms, Gas limit: 500M (0x1DCD6500)
- Spammers: 8 x 30000 txs @ 80 tx/s each
- Gas per tx: 2,000,000, Wallets: 300
- Warmup: 200 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 371.7 Mgas/s, 186.7 TPS, 3.0 blocks/s
- **Reth execution:** 0.924 Ggas/s (2.7 s/Ggas)
- **Overhead:** 16.6%
- **Duration:** 199s steady-state, 196.0s wall clock
- **Blocks:** 594 total, 594 non-empty (100%)
- **Transactions:** 390,328 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 317.7 | 126.1 | 10,368.2 |
| GetPayload | 126.1 | 58.5 | 202.5 |
| NewPayload | 133.3 | 58.7 | 201.0 |

### max_mgas_1g

**Timestamp:** 2026-03-25T14:35:43Z  
**File:** `TestGasBurner_max_mgas_1g_20260325T142623.json`

**Config:**

- Block time: 100ms, Gas limit: 1G (0x3B9ACA00)
- Spammers: 10 x 30000 txs @ 100 tx/s each
- Gas per tx: 2,000,000, Wallets: 500
- Warmup: 200 txs, Timeout: 15m0s

**Results:**

- **Throughput:** 132.6 Mgas/s, 90.8 TPS, 6.5 blocks/s
- **Reth execution:** 0.640 Ggas/s (7.5 s/Ggas)
- **Overhead:** 24.1%
- **Duration:** 370s steady-state, 370.0s wall clock
- **Blocks:** 2977 total, 2398 non-empty (80.6%)
- **Transactions:** 426,620 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 73.2 | 4.3 | 20,025.8 |
| GetPayload | 24.7 | 0.4 | 349.8 |
| NewPayload | 25.0 | 0.9 | 355.1 |

### slow_blocks_250ms_100m

**Timestamp:** 2026-03-25T14:40:19Z  
**File:** `TestGasBurner_slow_blocks_250ms_100m_20260325T143554.json`

**Config:**

- Block time: 250ms, Gas limit: 100M (0x5F5E100)
- Spammers: 4 x 10000 txs @ 40 tx/s each
- Gas per tx: 1,000,000, Wallets: 200
- Warmup: 200 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 98.9 Mgas/s, 99.8 TPS, 4.0 blocks/s
- **Reth execution:** 0.634 Ggas/s (10.1 s/Ggas)
- **Overhead:** 1.5%
- **Duration:** 128s steady-state, 128.0s wall clock
- **Blocks:** 511 total, 511 non-empty (100%)
- **Transactions:** 61,984 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 89.0 | 19.4 | 132.4 |
| GetPayload | 43.1 | 7.8 | 80.7 |
| NewPayload | 39.5 | 8.2 | 65.7 |

### slow_blocks_500ms_300m

**Timestamp:** 2026-03-25T14:47:19Z  
**File:** `TestGasBurner_slow_blocks_500ms_300m_20260325T144158.json`

**Config:**

- Block time: 500ms, Gas limit: 300M (0x11E1A300)
- Spammers: 6 x 10000 txs @ 30 tx/s each
- Gas per tx: 2,000,000, Wallets: 200
- Warmup: 200 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 119.7 Mgas/s, 60.1 TPS, 2.0 blocks/s
- **Reth execution:** 0.803 Ggas/s (8.4 s/Ggas)
- **Overhead:** 0.9%
- **Duration:** 194s steady-state, 194.0s wall clock
- **Blocks:** 389 total, 389 non-empty (100%)
- **Transactions:** 80,208 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 159.4 | 30.7 | 215.6 |
| GetPayload | 77.0 | 11.8 | 119.0 |
| NewPayload | 75.3 | 12.1 | 103.4 |

### slow_blocks_1s_500m

**Timestamp:** 2026-03-25T14:57:35Z  
**File:** `TestGasBurner_slow_blocks_1s_500m_20260325T144931.json`

**Config:**

- Block time: 1s, Gas limit: 500M (0x1DCD6500)
- Spammers: 8 x 10000 txs @ 20 tx/s each
- Gas per tx: 2,000,000, Wallets: 300
- Warmup: 200 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 62.5 Mgas/s, 31.4 TPS, 1.0 blocks/s
- **Reth execution:** 0.814 Ggas/s (16.0 s/Ggas)
- **Overhead:** 0.9%
- **Duration:** 346s steady-state, 346.0s wall clock
- **Blocks:** 347 total, 347 non-empty (100%)
- **Transactions:** 93,088 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 166.9 | 105.4 | 274.4 |
| GetPayload | 82.8 | 43.8 | 182.9 |
| NewPayload | 77.6 | 43.5 | 118.5 |

### small_burn_high_volume_100m

**Timestamp:** 2026-03-25T15:03:21Z  
**File:** `TestGasBurner_small_burn_high_volume_100m_20260325T145841.json`

**Config:**

- Block time: 100ms, Gas limit: 100M (0x5F5E100)
- Spammers: 6 x 20000 txs @ 200 tx/s each
- Gas per tx: 500,000, Wallets: 500
- Warmup: 500 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 63.0 Mgas/s, 226.0 TPS, 8.9 blocks/s
- **Reth execution:** 0.484 Ggas/s (15.9 s/Ggas)
- **Overhead:** 3.6%
- **Duration:** 127s steady-state, 120.0s wall clock
- **Blocks:** 1152 total, 1129 non-empty (98.0%)
- **Transactions:** 236,370 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 36.2 | 7.0 | 147.3 |
| GetPayload | 15.1 | 0.7 | 71.5 |
| NewPayload | 14.0 | 1.6 | 64.0 |

### large_burn_low_volume_300m

**Timestamp:** 2026-03-25T15:11:59Z  
**File:** `TestGasBurner_large_burn_low_volume_300m_20260325T150810.json`

**Config:**

- Block time: 100ms, Gas limit: 300M (0x11E1A300)
- Spammers: 2 x 5000 txs @ 20 tx/s each
- Gas per tx: 5,000,000, Wallets: 100
- Warmup: 200 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 397.7 Mgas/s, 79.7 TPS, 8.0 blocks/s
- **Reth execution:** 0.793 Ggas/s (2.5 s/Ggas)
- **Overhead:** 0.9%
- **Duration:** 92s steady-state, 92.0s wall clock
- **Blocks:** 733 total, 733 non-empty (100%)
- **Transactions:** 18,708 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 125.4 | 90.5 | 209.9 |
| GetPayload | 58.1 | 43.2 | 131.5 |
| NewPayload | 62.2 | 43.7 | 86.1 |

### fast_blocks_50ms_100m

**Timestamp:** 2026-03-25T15:15:30Z  
**File:** `TestGasBurner_fast_blocks_50ms_100m_20260325T151207.json`

**Config:**

- Block time: 50ms, Gas limit: 100M (0x5F5E100)
- Spammers: 4 x 10000 txs @ 100 tx/s each
- Gas per tx: 1,000,000, Wallets: 200
- Warmup: 300 txs, Timeout: 10m0s

**Results:**

- **Throughput:** 281.1 Mgas/s, 290.8 TPS, 8.2 blocks/s
- **Reth execution:** 0.771 Ggas/s (3.6 s/Ggas)
- **Overhead:** 1.4%
- **Duration:** 72s steady-state, 68.0s wall clock
- **Blocks:** 588 total, 588 non-empty (100%)
- **Transactions:** 133,336 sent, 0 failed

**Timing (ms):**

| Span | Avg | Min | Max |
|------|-----|-----|-----|
| ProduceBlock | 93.1 | 11.6 | 315.1 |
| GetPayload | 42.8 | 2.6 | 208.0 |
| NewPayload | 43.7 | 2.4 | 126.7 |
