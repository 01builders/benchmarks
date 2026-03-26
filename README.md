# benchmarks

Tooling and recorded results for ev-node performance benchmarking.

## objectives

The benchmark suite answers: "at a given block utilization level, what throughput, latency, and stability should an operator expect?"

Specifically, we measure:

- **throughput by utilization** — at each block fullness level (10% through 120% of gas limit), what Mgas/s, TPS, and block production timing does the system achieve?
- **workload sensitivity** — how do different transaction types (ERC-20 transfers, DeFi/Uniswap swaps, compute-heavy gas burns, storage-write-heavy state pressure) affect execution performance at the same utilization level?
- **gas limit scaling** — how does increasing the gas limit from 30M to 100M change throughput and stability? where does the system hit diminishing returns?
- **block time headroom** — how much idle time remains in each block interval? at what point does block production time exceed the target interval, causing stalls and catch-up blocks?
- **degradation cliff** — at what utilization level does the system start producing empty blocks, retrying block production (ExecuteTxs retries), or stalling for multiple seconds?
- **ev-node overhead** — the orchestration cost of ev-node (ProduceBlock minus ExecuteTxs) as a percentage of total block production time. how does this scale with block size?
- **reth execution efficiency** — how does reth's Ggas/s rate vary with block size, transaction weight, and workload type?

## test types

| Test | Workload | Gas/Tx (approx) | What it measures |
|------|----------|-----------------|-----------------|
| GasBurner | deterministic compute | 1M | pure execution throughput, ev-node overhead |
| ERC-20 | token transfers | ~65k | high-TPS light workload, per-tx overhead |
| DeFi (Uniswap V2) | swap transactions | ~200k | realistic DeFi with deep call chains |
| State Pressure | storage writes | 1M | state growth and write-heavy execution |
| Smoke | mixed (EOA + GasBurner) | varies | sanity check, not for performance measurement |

## test matrices

Each matrix is a JSON file in `matrices/` containing an array of scenario configs. Every scenario specifies a `BENCH_*` environment variable set that controls gas limit, block time, injection rate, and load parameters.

Naming convention: `{gas_limit}_{utilization}` for core runs (e.g. `30m_80pct`), with a suffix for variants (e.g. `30m_80pct_250ms` for block time, `30m_80pct_heavy_write` for write intensity).

### gas-burner.json (15 configs)

| Category | Configs | Gas Limit | Block Time | Utilization |
|----------|---------|-----------|-----------|-------------|
| core sweep | 6 | 30M | 100ms | 10%, 20%, 40%, 80%, 100%, 120% |
| core sweep | 6 | 100M | 100ms | 10%, 20%, 40%, 80%, 100%, 120% |
| block time | 3 | 30M | 250ms, 500ms, 1s | 80% |

### defi-simulation.json (13 configs)

| Category | Configs | Gas Limit | Block Time | Utilization |
|----------|---------|-----------|-----------|-------------|
| core sweep | 6 | 30M | 100ms | 10%, 20%, 40%, 80%, 100%, 120% |
| core sweep | 4 | 100M | 100ms | 10%, 20%, 40%, 80% |
| block time | 2 | 30M | 250ms, 1s | 80% |
| contract diversity | 1 | 30M | 100ms | 80% (pair_count=5) |

### erc20-throughput.json (13 configs)

| Category | Configs | Gas Limit | Block Time | Utilization |
|----------|---------|-----------|-----------|-------------|
| core sweep | 6 | 30M | 100ms | 10%, 20%, 40%, 80%, 100%, 120% |
| core sweep | 3 | 100M | 100ms | 10%, 20%, 40% |
| block time | 4 | 30M | 50ms, 250ms, 500ms, 1s | 40% |

100M is capped at 40% because higher tiers require 12k+ tx/s injection, which tests the load generator rather than the chain. Block time sweep uses 40% utilization (not 80%) because ERC-20 injection rates at 80% are already high.

### state-pressure.json (13 configs)

| Category | Configs | Gas Limit | Block Time | Utilization |
|----------|---------|-----------|-----------|-------------|
| core sweep | 6 | 30M | 100ms | 10%, 20%, 40%, 80%, 100%, 120% |
| core sweep | 4 | 100M | 100ms | 10%, 20%, 40%, 80% |
| block time | 2 | 30M | 250ms, 1s | 80% |
| write intensity | 1 | 30M | 100ms | 80% (2M gas/tx) |

The write intensity variant uses 2M gas per tx instead of 1M — half as many txs, each doing twice the storage writes. This isolates whether per-tx storage depth or total storage volume is the bottleneck.

### spamoor-smoke.json (10 configs)

Sanity checks across gas limits and block times. Not intended for performance measurement.

## running

### version tags

Every run requires `EV_RETH_TAG` and `EV_NODE_TAG` to be set. These are used to:

1. name the results directory (`results/evreth-{tag}_evnode-{tag}/`)
2. tag each result JSON file (`tags.ev_reth`, `tags.ev_node`) so results are traceable to exact builds
3. pass to ansible for infrastructure deployment

Set them in your `.env` file or export them directly:

```bash
export EV_RETH_TAG=v0.3.1
export EV_NODE_TAG=v1.0.0
```

The script will refuse to run if either is missing.

### examples

```bash
# run a full matrix (pauses between runs for operator confirmation)
./scripts/bench-matrix.sh TestGasBurner matrices/gas-burner.json \
  --test-runner <host> \
  --env-file .env

# run without pausing between runs
./scripts/bench-matrix.sh TestGasBurner matrices/gas-burner.json \
  --test-runner <host> \
  --env-file .env \
  --no-pause

# run only the first 3 entries (for testing)
./scripts/bench-matrix.sh TestGasBurner matrices/gas-burner.json \
  --test-runner <host> \
  --env-file .env \
  --limit 3

# skip ansible redeploy (if chain is already configured)
./scripts/bench-matrix.sh TestGasBurner matrices/gas-burner.json \
  --test-runner <host> \
  --env-file .env \
  --no-ansible
```

Test names for each matrix:

| Matrix | Test Name |
|--------|-----------|
| gas-burner.json | TestGasBurner |
| erc20-throughput.json | TestERC20Throughput |
| defi-simulation.json | TestDeFiSimulation |
| state-pressure.json | TestStatePressure |
| spamoor-smoke.json | TestSpamoorSmoke |

## generating reports

```bash
# generate report for a specific version combo
python3 generate_report.py results/evreth-v0.3.1_evnode-abc1234

# generate report across all results (recursive scan)
python3 generate_report.py results
```

Reads all `*.json` files (recursively) from the given directory and writes `report.md` into that directory.

## results

Results are organized by version combo:

```
results/
  evreth-{tag}_evnode-{tag}/
    TestGasBurner_{objective}_{timestamp}.json
    TestGasBurner_{objective}_{timestamp}.log
    TestERC20Throughput_{objective}_{timestamp}.json
    ...
    report.md
```

The directory is created automatically by `bench-matrix.sh` from the `EV_RETH_TAG` and `EV_NODE_TAG` environment variables. JSON files are committed; log files are gitignored.

Each result file contains: test config, host environment, throughput metrics (Mgas/s, TPS, blocks/s), block production timing (ProduceBlock, GetPayload, NewPayload), per-block gas/tx distributions (avg, p50, p99), and spamoor send/fail counts.
