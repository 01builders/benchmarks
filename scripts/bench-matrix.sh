#!/usr/bin/env bash
#
# bench-matrix.sh — run a benchmark test across a matrix of configurations.
#
# each matrix entry runs as an independent go test invocation. between runs the
# script runs an ansible playbook to reset the environment, then continues.
#
# assumes external mode: BENCH_ETH_RPC_URL, BENCH_PRIVATE_KEY, and
# BENCH_TRACE_QUERY_URL must be set (via .env or environment).
#
# usage:
#   ./scripts/bench-matrix.sh <test-name> <matrix.json> [options]
#
# options:
#   --no-ansible          skip ansible cleanup between runs
#   --no-pause            don't wait for confirmation between runs
#   --ansible-playbook P  path to ansible playbook (overrides ANSIBLE_PLAYBOOK)
#   --ansible-inventory I ansible inventory (overrides ANSIBLE_INVENTORY)
#   --results-dir DIR     output directory for results (default: ./results)
#   --timeout DUR         go test timeout per run (default: 15m)
#   --ev-node-dir DIR     path to ev-node checkout (default: ~/checkouts/evstack/ev-node)
#   --env-file FILE       .env file to source base config from
#
# matrix.json format:
#   [
#     {
#       "objective": "max_mgas",
#       "env": {
#         "BENCH_BLOCK_TIME": "100ms",
#         "BENCH_GAS_LIMIT": "0x11E1A300",
#         "BENCH_NUM_SPAMMERS": "6",
#         "BENCH_THROUGHPUT": "60",
#         "BENCH_COUNT_PER_SPAMMER": "30000"
#       }
#     }
#   ]
#
# requires: jq, go (with evm build tag support)

set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

if [[ $# -lt 2 ]]; then
    sed -n '3,/^$/s/^# \?//p' "$0"
    exit 1
fi

TEST_NAME="$1"
MATRIX_FILE="$2"
shift 2

# defaults
RUN_ANSIBLE=true
PAUSE=true
RESULTS_DIR="./results"
TIMEOUT="15m"
EV_NODE_DIR="${HOME}/checkouts/evstack/ev-node"
ENV_FILE=""
PLAYBOOK="${ANSIBLE_PLAYBOOK:-}"
INVENTORY="${ANSIBLE_INVENTORY:-}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-ansible)         RUN_ANSIBLE=false; shift ;;
        --no-pause)           PAUSE=false; shift ;;
        --ansible-playbook)   PLAYBOOK="$2"; shift 2 ;;
        --ansible-inventory)  INVENTORY="$2"; shift 2 ;;
        --results-dir)        RESULTS_DIR="$2"; shift 2 ;;
        --timeout)            TIMEOUT="$2"; shift 2 ;;
        --ev-node-dir)        EV_NODE_DIR="$2"; shift 2 ;;
        --env-file)           ENV_FILE="$2"; shift 2 ;;
        *)                    die "unknown option: $1" ;;
    esac
done

command -v jq &>/dev/null || die "jq is required but not installed"
[[ -f "$MATRIX_FILE" ]] || die "matrix file not found: $MATRIX_FILE"

if [[ "$RUN_ANSIBLE" == "true" ]]; then
    [[ -n "$PLAYBOOK" ]] || die "ansible enabled but no playbook specified (use --ansible-playbook or ANSIBLE_PLAYBOOK)"
    [[ -f "$PLAYBOOK" ]] || die "ansible playbook not found: $PLAYBOOK"
    command -v ansible-playbook &>/dev/null || die "ansible-playbook is required but not installed"
fi

TOTAL=$(jq 'length' "$MATRIX_FILE")
[[ "$TOTAL" -gt 0 ]] || die "matrix is empty"

# source base env if provided
if [[ -n "$ENV_FILE" ]]; then
    [[ -f "$ENV_FILE" ]] || die "env file not found: $ENV_FILE"
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
fi

# validate external mode requirements
[[ -n "${BENCH_ETH_RPC_URL:-}" ]] || die "BENCH_ETH_RPC_URL must be set (external mode)"
[[ -n "${BENCH_PRIVATE_KEY:-}" ]] || die "BENCH_PRIVATE_KEY must be set (external mode)"
[[ -n "${BENCH_TRACE_QUERY_URL:-}" ]] || die "BENCH_TRACE_QUERY_URL must be set (external mode)"

mkdir -p "$RESULTS_DIR"

echo "=== bench-matrix ==="
echo "test:       TestSpamoorSuite/$TEST_NAME"
echo "matrix:     $MATRIX_FILE ($TOTAL entries)"
echo "results:    $RESULTS_DIR/"
echo "timeout:    $TIMEOUT"
echo "ev-node:    $EV_NODE_DIR"
echo "rpc:        $BENCH_ETH_RPC_URL"
echo "ansible:    $RUN_ANSIBLE"
if [[ "$RUN_ANSIBLE" == "true" ]]; then
    echo "  playbook:  $PLAYBOOK"
    echo "  inventory: ${INVENTORY:-<default>}"
fi
echo ""

PASSED=0
FAILED=0
SKIPPED=0

run_ansible() {
    echo ">>> running ansible cleanup..."
    local cmd=(ansible-playbook "$PLAYBOOK")
    if [[ -n "$INVENTORY" ]]; then
        cmd+=(-i "$INVENTORY")
    fi
    if "${cmd[@]}"; then
        echo ">>> ansible cleanup complete"
    else
        echo ">>> WARNING: ansible cleanup failed (exit code $?)"
        if [[ "$PAUSE" == "true" ]]; then
            echo ">>> press Enter to continue anyway, or 'q' to quit"
            read -r REPLY
            [[ "$REPLY" == "q" || "$REPLY" == "Q" ]] && exit 1
        fi
    fi
}

for i in $(seq 0 $((TOTAL - 1))); do
    IDX=$((i + 1))
    OBJECTIVE=$(jq -r ".[$i].objective // \"run_$IDX\"" "$MATRIX_FILE")
    TIMESTAMP=$(date +%Y%m%dT%H%M%S)
    RESULT_FILE="${RESULTS_DIR}/${TEST_NAME}_${OBJECTIVE}_${TIMESTAMP}.json"
    LOG_FILE="${RESULTS_DIR}/${TEST_NAME}_${OBJECTIVE}_${TIMESTAMP}.log"

    echo "--- run $IDX/$TOTAL: $OBJECTIVE ---"

    # run ansible cleanup before each run (including the first)
    if [[ "$RUN_ANSIBLE" == "true" ]]; then
        run_ansible
    fi

    # extract and display env vars for this run
    ENV_VARS=$(jq -r ".[$i].env // {} | to_entries[] | \"\(.key)=\(.value)\"" "$MATRIX_FILE")

    EXPORT_CMD=""
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            EXPORT_CMD="${EXPORT_CMD} export ${line};"
        fi
    done <<< "$ENV_VARS"

    echo "  config:"
    while IFS= read -r line; do
        [[ -n "$line" ]] && echo "    $line"
    done <<< "$ENV_VARS"
    echo "  output: $RESULT_FILE"
    echo ""

    set +e
    (
        eval "$EXPORT_CMD"
        export BENCH_OBJECTIVE="$OBJECTIVE"
        export BENCH_RESULT_OUTPUT="$RESULT_FILE"
        cd "${EV_NODE_DIR}/test/e2e"
        go test -tags evm \
            -run "^TestSpamoorSuite\$/^${TEST_NAME}\$" \
            -v -count=1 -timeout "$TIMEOUT" \
            ./benchmark/...
    ) 2>&1 | tee "$LOG_FILE"
    EXIT_CODE=${PIPESTATUS[0]}
    set -e

    if [[ $EXIT_CODE -eq 0 ]]; then
        echo "  status: PASS"
        PASSED=$((PASSED + 1))
    else
        echo "  status: FAIL (exit code $EXIT_CODE)"
        FAILED=$((FAILED + 1))
    fi

    if [[ -f "$RESULT_FILE" ]]; then
        MGAS=$(jq -r '.metrics.mgas_per_sec // "n/a"' "$RESULT_FILE")
        echo "  mgas/s: $MGAS"
    else
        echo "  warning: no result file written"
    fi

    echo ""

    # optional pause between runs
    if [[ "$PAUSE" == "true" && $IDX -lt $TOTAL ]]; then
        echo ">>> press Enter to continue to run $((IDX + 1))/$TOTAL (or 's' to skip remaining, 'q' to quit)"
        read -r REPLY
        case "$REPLY" in
            s|S) echo "skipping remaining runs"; SKIPPED=$((TOTAL - IDX)); break ;;
            q|Q) echo "quitting"; SKIPPED=$((TOTAL - IDX)); break ;;
        esac
    fi
done

echo ""
echo "=== summary ==="
echo "total:   $TOTAL"
echo "passed:  $PASSED"
echo "failed:  $FAILED"
echo "skipped: $SKIPPED"
echo "results: $RESULTS_DIR/"
