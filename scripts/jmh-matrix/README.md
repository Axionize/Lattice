# JMH JVM Matrix

This directory contains a rootless, copyable benchmark harness for comparing
Lattice JMH results across Java classfile targets and JVM distributions.

## Quick Start

```bash
cd ~/Lattice
scripts/jmh-matrix/download-jdks.sh
scripts/jmh-matrix/build-jmh-jars.sh
scripts/jmh-matrix/run-matrix.sh
scripts/jmh-matrix/summarize-results.sh
```

Everything is written under `.jmh-matrix/`:

- `.jmh-matrix/jdks`: downloaded JDKs
- `.jmh-matrix/jars`: JMH jars built with `--release 17`, `21`, and `25`
- `.jmh-matrix/results`: per-run logs, JSON, and environment capture

## Common Remote Run

For the target-version proof run, use:

```bash
cd ~/Lattice
PROFILE=proof RUN_ID=target-proof-$(hostname)-$(date -u +%Y%m%dT%H%M%SZ) scripts/jmh-matrix/run-target-proof.sh
```

At the end, paste the generated `target-proof-report.md` from the printed run
directory. The proof profile uses 3 forks, 4 warmup iterations, and 6
measurement iterations against the core fixed-path benchmarks.

For a shorter smoke run on a new machine:

```bash
cd ~/Lattice
scripts/jmh-matrix/download-jdks.sh temurin21 temurin25 zulu21 zulu25 graal21 graal25 jdknet26
BUILD_JDK=temurin25 TARGETS="17 21 25" scripts/jmh-matrix/build-jmh-jars.sh
FORKS=1 WARMUP_ITER=2 MEASURE_ITER=3 scripts/jmh-matrix/run-matrix.sh
scripts/jmh-matrix/summarize-results.sh
```

For a longer run:

```bash
FORKS=3 WARMUP_ITER=5 MEASURE_ITER=10 WARMUP_TIME=2s MEASURE_TIME=2s scripts/jmh-matrix/run-matrix.sh
```

## Knobs

- `TARGETS`: classfile/API release targets, default `17 21 25`
- `RUNTIMES`: JDK directory names from `.jmh-matrix/jdks`
- `BUILD_JDK`: JDK used to build the JMH jars, default `temurin25`
- `BENCH_REGEX`: JMH regex, default focuses on `OptimalPathBenchmark`
- `JVM_ARGS`: default `-Xms2g -Xmx2g -XX:+AlwaysPreTouch`
- `JMH_EXTRA_ARGS`: appended to the JMH command

Oracle GraalVM 21/25 downloads use the public script-friendly Oracle GraalVM
URLs. If you need an entitled Oracle GraalVM Enterprise build from MOS/Software
Delivery Cloud, extract it into `.jmh-matrix/jdks/<name>` with `bin/java`
present and include `<name>` in `RUNTIMES`.
