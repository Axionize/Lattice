#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROFILE="${PROFILE:-proof}"
case "$PROFILE" in
    quick)
        DEFAULT_FORKS=1
        DEFAULT_WARMUP_ITER=2
        DEFAULT_MEASURE_ITER=3
        DEFAULT_WARMUP_TIME=1s
        DEFAULT_MEASURE_TIME=1s
        ;;
    proof)
        DEFAULT_FORKS=3
        DEFAULT_WARMUP_ITER=4
        DEFAULT_MEASURE_ITER=6
        DEFAULT_WARMUP_TIME=2s
        DEFAULT_MEASURE_TIME=2s
        ;;
    long)
        DEFAULT_FORKS=5
        DEFAULT_WARMUP_ITER=6
        DEFAULT_MEASURE_ITER=10
        DEFAULT_WARMUP_TIME=3s
        DEFAULT_MEASURE_TIME=3s
        ;;
    *)
        die "unknown PROFILE: $PROFILE"
        ;;
esac

JDK_SET="${JDK_SET:-temurin21 temurin25 zulu21 zulu25 graal21 graal25 jdknet26}"
BUILD_JDK="${BUILD_JDK:-temurin25}"
TARGETS="${TARGETS:-17 21 25}"
RUNTIMES="${RUNTIMES:-$JDK_SET}"
BENCH_REGEX="${BENCH_REGEX:-io.github.elevateddev.lattice.benchmark.OptimalPathBenchmark.(latticePhysicalCompleted|latticeInlineFusedCompleted|disruptorManualFusedCompleted)$}"
FORKS="${FORKS:-$DEFAULT_FORKS}"
WARMUP_ITER="${WARMUP_ITER:-$DEFAULT_WARMUP_ITER}"
MEASURE_ITER="${MEASURE_ITER:-$DEFAULT_MEASURE_ITER}"
WARMUP_TIME="${WARMUP_TIME:-$DEFAULT_WARMUP_TIME}"
MEASURE_TIME="${MEASURE_TIME:-$DEFAULT_MEASURE_TIME}"
JVM_ARGS="${JVM_ARGS:--Xms2g -Xmx2g -XX:+AlwaysPreTouch}"
RUN_ID="${RUN_ID:-target-proof-$(hostname)-$(date -u +%Y%m%dT%H%M%SZ)}"

cd "$ROOT_DIR"

if [[ "${SKIP_DOWNLOAD:-0}" != "1" ]]; then
    # shellcheck disable=SC2086
    "$SCRIPT_DIR/download-jdks.sh" $JDK_SET
fi

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
    BUILD_JDK="$BUILD_JDK" TARGETS="$TARGETS" "$SCRIPT_DIR/build-jmh-jars.sh"
fi

RUN_ID="$RUN_ID" \
TARGETS="$TARGETS" \
RUNTIMES="$RUNTIMES" \
BENCH_REGEX="$BENCH_REGEX" \
FORKS="$FORKS" \
WARMUP_ITER="$WARMUP_ITER" \
MEASURE_ITER="$MEASURE_ITER" \
WARMUP_TIME="$WARMUP_TIME" \
MEASURE_TIME="$MEASURE_TIME" \
JVM_ARGS="$JVM_ARGS" \
"$SCRIPT_DIR/run-matrix.sh"

RUN_DIR="$RESULTS_DIR/$RUN_ID"
REPORT="$RUN_DIR/target-proof-report.md"
"$SCRIPT_DIR/proof-report.py" "$RUN_DIR" > "$REPORT"

printf '\nProof report written to %s\n\n' "$REPORT"
printf '%s\n' '----- PASTE FROM HERE -----'
cat "$REPORT"
printf '%s\n' '----- PASTE TO HERE -----'
