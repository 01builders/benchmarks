#!/usr/bin/env python3
"""Generate a markdown report from GasBurner benchmark JSON results."""

import json
import sys
from datetime import datetime
from pathlib import Path


def load_results(results_dir: Path) -> list[dict]:
    results = []
    for f in sorted(results_dir.glob("*.json")):
        with open(f) as fp:
            data = json.load(fp)
            data["_filename"] = f.name
            results.append(data)
    # sort by timestamp
    results.sort(key=lambda r: r.get("timestamp", ""))
    return results


def hex_gas_to_human(hex_gas: str) -> str:
    val = int(hex_gas, 16)
    if val >= 1_000_000_000:
        return f"{val / 1_000_000_000:.0f}G"
    if val >= 1_000_000:
        return f"{val / 1_000_000:.0f}M"
    return str(val)


def fmt(val, decimals=1) -> str:
    if isinstance(val, float):
        return f"{val:,.{decimals}f}"
    return str(val)


def generate_report(results: list[dict]) -> str:
    lines: list[str] = []

    def w(s=""):
        lines.append(s)

    # use first result for host/environment info (same host for all runs)
    first = results[0]
    host = first.get("host", {})
    ts_first = first.get("timestamp", "")
    ts_last = results[-1].get("timestamp", "")
    run_date = ts_first[:10] if ts_first else "unknown"

    w("# GasBurner benchmark report")
    w()
    w(f"**Date:** {run_date}  ")
    w(f"**Platform:** {first.get('platform', 'unknown')}  ")
    w(f"**ev-reth:** `{first.get('tags', {}).get('ev_reth', 'unknown')}`  ")
    w(f"**ev-node:** `{first.get('tags', {}).get('ev_node', 'unknown')}`")
    w()

    w("## environment")
    w()
    w("| Property | Value |")
    w("|----------|-------|")
    w(f"| Host | {host.get('host_name', 'unknown')} |")
    w(f"| CPU | {host.get('host_cpu', '?')} vCPU ({host.get('host_type', '?')}) |")
    w(f"| Memory | {host.get('host_memory', '?')} |")
    w(f"| OS | {host.get('os_name', '?')} {host.get('os_version', '?')} |")
    w(f"| Role | {host.get('service_type', '?').rstrip(chr(39))} |")
    w()

    # summary table
    w("## summary")
    w()
    w("| Scenario | Block Time | Gas Limit | Mgas/s | TPS | Blocks/s | Non-Empty % | Overhead % | Reth Ggas/s |")
    w("|----------|-----------|-----------|--------|-----|----------|-------------|-----------|-------------|")
    for r in results:
        m = r["metrics"]
        c = r["config"]
        gas_limit = hex_gas_to_human(c["gas_limit"])
        w(
            f"| {r['objective']} "
            f"| {c['block_time']} "
            f"| {gas_limit} "
            f"| {fmt(m['mgas_per_sec'])} "
            f"| {fmt(m['tps'])} "
            f"| {fmt(m['blocks_per_sec'])} "
            f"| {fmt(m['non_empty_ratio_pct'])} "
            f"| {fmt(m['overhead_pct'])} "
            f"| {fmt(m['ev_reth_ggas_per_sec'], 3)} |"
        )
    w()

    # block production timing table
    w("## block production timing")
    w()
    w("| Scenario | ProduceBlock avg | ProduceBlock max | GetPayload avg | GetPayload max | NewPayload avg | NewPayload max |")
    w("|----------|-----------------|-----------------|----------------|---------------|---------------|---------------|")
    for r in results:
        m = r["metrics"]
        w(
            f"| {r['objective']} "
            f"| {fmt(m['produce_block_avg_ms'])}ms "
            f"| {fmt(m['produce_block_max_ms'])}ms "
            f"| {fmt(m['get_payload_avg_ms'])}ms "
            f"| {fmt(m['get_payload_max_ms'])}ms "
            f"| {fmt(m['new_payload_avg_ms'])}ms "
            f"| {fmt(m['new_payload_max_ms'])}ms |"
        )
    w()

    # per-block gas/tx distribution table
    w("## per-block distribution")
    w()
    w("| Scenario | Avg Gas/Block | Gas p50 | Gas p99 | Avg Tx/Block | Tx p50 | Tx p99 |")
    w("|----------|--------------|---------|---------|-------------|--------|--------|")
    for r in results:
        m = r["metrics"]
        w(
            f"| {r['objective']} "
            f"| {fmt(m['avg_gas_per_block'], 0)} "
            f"| {fmt(m['gas_block_p50'], 0)} "
            f"| {fmt(m['gas_block_p99'], 0)} "
            f"| {fmt(m['avg_tx_per_block'])} "
            f"| {fmt(m['tx_block_p50'], 0)} "
            f"| {fmt(m['tx_block_p99'], 0)} |"
        )
    w()

    # detailed sections per scenario
    w("## scenario details")
    w()
    for r in results:
        m = r["metrics"]
        c = r["config"]
        br = r["block_range"]
        sp = r["spamoor"]
        gas_limit = hex_gas_to_human(c["gas_limit"])

        w(f"### {r['objective']}")
        w()
        w(f"**Timestamp:** {r['timestamp']}  ")
        w(f"**File:** `{r['_filename']}`")
        w()

        w("**Config:**")
        w()
        w(f"- Block time: {c['block_time']}, Gas limit: {gas_limit} ({c['gas_limit']})")
        w(f"- Spammers: {c['num_spammers']} x {c['count_per_spammer']} txs @ {c['throughput']} tx/s each")
        w(f"- Gas per tx: {c['gas_units_to_burn']:,}, Wallets: {c['max_wallets']}")
        w(f"- Warmup: {c['warmup_txs']} txs, Timeout: {c['wait_timeout']}")
        w()

        w("**Results:**")
        w()
        w(f"- **Throughput:** {fmt(m['mgas_per_sec'])} Mgas/s, {fmt(m['tps'])} TPS, {fmt(m['blocks_per_sec'])} blocks/s")
        w(f"- **Reth execution:** {fmt(m['ev_reth_ggas_per_sec'], 3)} Ggas/s ({fmt(m['secs_per_gigagas'])} s/Ggas)")
        w(f"- **Overhead:** {fmt(m['overhead_pct'])}%")
        w(f"- **Duration:** {m['steady_state_sec']}s steady-state, {fmt(m['wall_clock_sec'])}s wall clock")
        w(f"- **Blocks:** {br['total']} total, {br['non_empty']} non-empty ({fmt(m['non_empty_ratio_pct'])}%)")
        w(f"- **Transactions:** {sp['sent']:,} sent, {sp['failed']:,} failed")
        w()

        w("**Timing (ms):**")
        w()
        w("| Span | Avg | Min | Max |")
        w("|------|-----|-----|-----|")
        w(f"| ProduceBlock | {fmt(m['produce_block_avg_ms'])} | {fmt(m['produce_block_min_ms'])} | {fmt(m['produce_block_max_ms'])} |")
        w(f"| GetPayload | {fmt(m['get_payload_avg_ms'])} | {fmt(m['get_payload_min_ms'])} | {fmt(m['get_payload_max_ms'])} |")
        w(f"| NewPayload | {fmt(m['new_payload_avg_ms'])} | {fmt(m['new_payload_min_ms'])} | {fmt(m['new_payload_max_ms'])} |")
        w()

    return "\n".join(lines)


def main():
    results_dir = Path(__file__).parent / "results"
    if not results_dir.is_dir():
        print(f"error: results directory not found: {results_dir}", file=sys.stderr)
        sys.exit(1)

    results = load_results(results_dir)
    if not results:
        print("error: no JSON result files found", file=sys.stderr)
        sys.exit(1)

    report = generate_report(results)

    output_path = Path(__file__).parent / "report.md"
    output_path.write_text(report)
    print(f"wrote {output_path} ({len(results)} scenarios)")


if __name__ == "__main__":
    main()
