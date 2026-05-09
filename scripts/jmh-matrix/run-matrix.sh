#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

need_cmd date
need_cmd tee

BENCH_REGEX="${BENCH_REGEX:-io.github.elevateddev.lattice.benchmark.OptimalPathBenchmark.(latticePhysicalCompleted|latticeInlineFusedCompleted|disruptorManualFusedCompleted)}"
TARGETS="${TARGETS:-17 21 25}"
RUNTIMES="${RUNTIMES:-$(runtime_names | tr '\n' ' ')}"
FORKS="${FORKS:-1}"
WARMUP_ITER="${WARMUP_ITER:-3}"
WARMUP_TIME="${WARMUP_TIME:-1s}"
MEASURE_ITER="${MEASURE_ITER:-5}"
MEASURE_TIME="${MEASURE_TIME:-1s}"
THREADS="${THREADS:-1}"
JVM_ARGS="${JVM_ARGS:--Xms2g -Xmx2g -XX:+AlwaysPreTouch}"
JMH_EXTRA_ARGS="${JMH_EXTRA_ARGS:-}"
RUN_ID="${RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
OUT_DIR="$RESULTS_DIR/$RUN_ID"

mkdir -p "$OUT_DIR"

{
    printf 'run_id=%s\n' "$RUN_ID"
    printf 'kernel=%s\n' "$(uname -r)"
    printf 'bench_regex=%s\n' "$BENCH_REGEX"
    printf 'targets=%s\n' "$TARGETS"
    printf 'runtimes=%s\n' "$RUNTIMES"
    printf 'forks=%s warmup=%sx%s measure=%sx%s threads=%s\n' \
        "$FORKS" "$WARMUP_ITER" "$WARMUP_TIME" "$MEASURE_ITER" "$MEASURE_TIME" "$THREADS"
    printf 'jvm_args=%s\n' "$JVM_ARGS"
    printf '\nCPU:\n'
    lscpu 2>/dev/null || true
    printf '\nMemory:\n'
    free -h 2>/dev/null || true
} | tee "$OUT_DIR/environment.txt"

for runtime in $RUNTIMES; do
    home="$(jdk_home "$runtime")"
    [[ -x "$home/bin/java" ]] || {
        printf 'skipping missing runtime %s\n' "$runtime"
        continue
    }
    runtime_major_value="$(runtime_major "$home")"

    for target in $TARGETS; do
        jar="$JARS_DIR/lattice-jmh-release-${target}.jar"
        if [[ ! -f "$jar" ]]; then
            printf 'skipping release %s on %s; missing jar %s\n' "$target" "$runtime" "$jar"
            continue
        fi
        if (( target > runtime_major_value )); then
            printf 'skipping release %s on %s; runtime Java is %s\n' "$target" "$runtime" "$runtime_major_value"
            continue
        fi

        base="$OUT_DIR/${runtime}-release${target}"
        printf '\nRunning %s, release %s\n' "$runtime" "$target" | tee "$base.log"
        "$home/bin/java" -version 2>&1 | tee -a "$base.log"
        "$home/bin/java" $JVM_ARGS -jar "$jar" "$BENCH_REGEX" \
            -f "$FORKS" \
            -wi "$WARMUP_ITER" -w "$WARMUP_TIME" \
            -i "$MEASURE_ITER" -r "$MEASURE_TIME" \
            -t "$THREADS" \
            -rf json -rff "$base.json" \
            $JMH_EXTRA_ARGS \
            2>&1 | tee -a "$base.log"
    done
done

printf '\nResults written to %s\n' "$OUT_DIR"
