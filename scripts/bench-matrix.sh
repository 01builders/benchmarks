#!/usr/bin/env bash
#
# bench-matrix.sh — run a benchmark test across a matrix of configurations.
#
# each matrix entry runs as an independent go test invocation. before each run
# the script runs an ansible playbook to redeploy the chain with the correct
# infrastructure config (block time, gas limit, etc).
#
# the script runs on the orchestrator but executes tests on a remote node
# (the test runner) via SSH.
#
# assumes external mode: BENCH_ETH_RPC_URL, BENCH_PRIVATE_KEY, and
# BENCH_TRACE_QUERY_URL must be set (via .env or environment).
#
# usage:
#   ./scripts/bench-matrix.sh <test-name> <matrix.json> [options]
#
# options:
#   --no-ansible          skip ansible between runs
#   --no-pause            don't wait for confirmation between runs
#   --ansible-playbook P  path to ansible playbook (overrides ANSIBLE_PLAYBOOK)
#   --ansible-inventory I ansible inventory (overrides ANSIBLE_INVENTORY)
#   --results-dir DIR     local output directory for results (default: ./results)
#   --timeout DUR         go test timeout per run (default: 15m)
#   --ev-node-dir DIR     path to ev-node checkout on the test runner (default: /root/ev-node)
#   --env-file FILE       .env file to source base config from
#   --limit N             only run the first N matrix entries (useful for testing)
#   --test-runner HOST    SSH host for the test runner node (required)
#   --test-runner-user U  SSH user for the test runner (default: root)
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
# the script maps BENCH_* env vars to ansible extra vars automatically:
#   BENCH_BLOCK_TIME       -> benchmarking_ev_node_block_time
#   BENCH_GAS_LIMIT        -> benchmarking_ev_reth_gas_limit
#   BENCH_SCRAPE_INTERVAL  -> benchmarking_ev_node_scrape_interval
#   EV_NODE_TAG            -> benchmarking_ev_node_tag
#   EV_RETH_TAG            -> benchmarking_ev_reth_tag
#
# requires: jq, ssh, ansible-playbook (unless --no-ansible)
# requires on test runner: go (with evm build tag support), ev-node checkout

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
EV_NODE_DIR="/root/ev-node"
ENV_FILE=""
LIMIT=0
TEST_RUNNER=""
TEST_RUNNER_USER="root"
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
        --limit)              LIMIT="$2"; shift 2 ;;
        --test-runner)        TEST_RUNNER="$2"; shift 2 ;;
        --test-runner-user)   TEST_RUNNER_USER="$2"; shift 2 ;;
        *)                    die "unknown option: $1" ;;
    esac
done

command -v jq &>/dev/null || die "jq is required but not installed"
[[ -f "$MATRIX_FILE" ]] || die "matrix file not found: $MATRIX_FILE"
[[ -n "$TEST_RUNNER" ]] || die "--test-runner is required"

if [[ "$RUN_ANSIBLE" == "true" ]]; then
    [[ -n "$PLAYBOOK" ]] || die "ansible enabled but no playbook specified (use --ansible-playbook or ANSIBLE_PLAYBOOK)"
    [[ -f "$PLAYBOOK" ]] || die "ansible playbook not found: $PLAYBOOK"
    command -v ansible-playbook &>/dev/null || die "ansible-playbook is required but not installed"
fi

SSH_TARGET="${TEST_RUNNER_USER}@${TEST_RUNNER}"
SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o BatchMode=yes)

run_remote() {
    ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "$@"
}

TOTAL=$(jq 'length' "$MATRIX_FILE")
[[ "$TOTAL" -gt 0 ]] || die "matrix is empty"

if [[ "$LIMIT" -gt 0 && "$LIMIT" -lt "$TOTAL" ]]; then
    TOTAL="$LIMIT"
fi

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
echo "test:         TestSpamoorSuite/$TEST_NAME"
echo "matrix:       $MATRIX_FILE ($TOTAL entries)"
echo "results:      $RESULTS_DIR/"
echo "timeout:      $TIMEOUT"
echo "test runner:  $SSH_TARGET"
echo "ev-node:      $EV_NODE_DIR (on test runner)"
echo "rpc:          $BENCH_ETH_RPC_URL"
echo "ansible:      $RUN_ANSIBLE"
if [[ "$RUN_ANSIBLE" == "true" ]]; then
    echo "  playbook:   $PLAYBOOK"
    echo "  inventory:  ${INVENTORY:-<default>}"
fi
echo ""

PASSED=0
FAILED=0
SKIPPED=0

# build_ansible_args reads BENCH_* env vars (already exported for this run)
# and maps them to ansible extra vars for the play_benchmarks.yml playbook.
build_ansible_args() {
    local args=()
    [[ -n "${BENCH_BLOCK_TIME:-}" ]]      && args+=(-e "benchmarking_ev_node_block_time=${BENCH_BLOCK_TIME}")
    [[ -n "${BENCH_GAS_LIMIT:-}" ]]       && args+=(-e "benchmarking_ev_reth_gas_limit=${BENCH_GAS_LIMIT}")
    [[ -n "${BENCH_SCRAPE_INTERVAL:-}" ]] && args+=(-e "benchmarking_ev_node_scrape_interval=${BENCH_SCRAPE_INTERVAL}")
    [[ -n "${EV_NODE_TAG:-}" ]]           && args+=(-e "benchmarking_ev_node_tag=${EV_NODE_TAG}")
    [[ -n "${EV_RETH_TAG:-}" ]]           && args+=(-e "benchmarking_ev_reth_tag=${EV_RETH_TAG}")
    echo "${args[@]}"
}

# run_ansible redeploys the chain with infrastructure config from the current
# run's env vars. this wipes existing state and starts fresh containers.
run_ansible() {
    echo ">>> running ansible redeploy..."
    local cmd=(ansible-playbook "$PLAYBOOK")
    if [[ -n "$INVENTORY" ]]; then
        cmd+=(-i "$INVENTORY")
    fi

    # map BENCH_* env vars to ansible extra vars
    local extra_args
    extra_args=$(build_ansible_args)
    if [[ -n "$extra_args" ]]; then
        # shellcheck disable=SC2086
        cmd+=($extra_args)
    fi

    echo ">>> ansible command: ${cmd[*]}"
    local rc=0
    "${cmd[@]}" || rc=$?
    if [[ $rc -eq 0 ]]; then
        echo ">>> ansible redeploy complete"
    else
        echo ">>> WARNING: ansible redeploy failed (exit code $rc)"
        if [[ "$PAUSE" == "true" ]]; then
            echo ">>> press Enter to continue anyway, or 'q' to quit"
            read -r REPLY
            [[ "$REPLY" == "q" || "$REPLY" == "Q" ]] && exit 1
        fi
    fi
}

# BENCH_ENV_KEYS tracks which BENCH_* vars were exported so we can unset them
# between runs to prevent config leaking from one matrix entry to the next.
BENCH_ENV_KEYS=()

for i in $(seq 0 $((TOTAL - 1))); do
    IDX=$((i + 1))

    # unset env vars from the previous run
    for key in "${BENCH_ENV_KEYS[@]}"; do
        unset "$key"
    done
    BENCH_ENV_KEYS=()

    OBJECTIVE=$(jq -r ".[$i].objective // \"run_$IDX\"" "$MATRIX_FILE")
    TIMESTAMP=$(date +%Y%m%dT%H%M%S)
    RESULT_FILE="${RESULTS_DIR}/${TEST_NAME}_${OBJECTIVE}_${TIMESTAMP}.json"
    LOG_FILE="${RESULTS_DIR}/${TEST_NAME}_${OBJECTIVE}_${TIMESTAMP}.log"

    echo "--- run $IDX/$TOTAL: $OBJECTIVE ---"

    # extract env vars for this run and export them so ansible can read them
    ENV_VARS=$(jq -r ".[$i].env // {} | to_entries[] | \"\(.key)=\(.value)\"" "$MATRIX_FILE")

    EXPORT_CMD=""
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            EXPORT_CMD="${EXPORT_CMD} export ${line};"
            BENCH_ENV_KEYS+=("${line%%=*}")
        fi
    done <<< "$ENV_VARS"

    echo "  config:"
    while IFS= read -r line; do
        [[ -n "$line" ]] && echo "    $line"
    done <<< "$ENV_VARS"
    echo "  output: $RESULT_FILE"
    echo ""

    # export env vars before ansible so it picks up the infrastructure config
    eval "$EXPORT_CMD"

    # redeploy the chain with this run's infrastructure config
    if [[ "$RUN_ANSIBLE" == "true" ]]; then
        run_ansible
    fi

    REMOTE_RESULT="/tmp/bench_result_${TIMESTAMP}.json"

    # build env var exports for the remote shell
    REMOTE_ENV="export BENCH_OBJECTIVE='${OBJECTIVE}';"
    REMOTE_ENV+=" export BENCH_RESULT_OUTPUT='${REMOTE_RESULT}';"
    REMOTE_ENV+=" export BENCH_ETH_RPC_URL='${BENCH_ETH_RPC_URL}';"
    REMOTE_ENV+=" export BENCH_PRIVATE_KEY='${BENCH_PRIVATE_KEY}';"
    REMOTE_ENV+=" export BENCH_TRACE_QUERY_URL='${BENCH_TRACE_QUERY_URL}';"
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            REMOTE_ENV+=" export ${line};"
        fi
    done <<< "$ENV_VARS"

    set +e
    run_remote bash -lc "'
        ${REMOTE_ENV}
        export PATH=/snap/bin:\$PATH;
        cd ${EV_NODE_DIR}/test/e2e &&
        go test -tags evm \
            -run \"^TestSpamoorSuite\\\$/^${TEST_NAME}\\\$\" \
            -v -count=1 -timeout ${TIMEOUT} \
            ./benchmark/...
    '" 2>&1 | tee "$LOG_FILE"
    EXIT_CODE=${PIPESTATUS[0]}
    set -e

    if [[ $EXIT_CODE -eq 0 ]]; then
        echo "  status: PASS"
        PASSED=$((PASSED + 1))
    else
        echo "  status: FAIL (exit code $EXIT_CODE)"
        FAILED=$((FAILED + 1))
    fi

    # fetch result file from test runner
    scp "${SSH_OPTS[@]}" "${SSH_TARGET}:${REMOTE_RESULT}" "$RESULT_FILE" 2>/dev/null && \
        run_remote rm -f "$REMOTE_RESULT" 2>/dev/null

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
