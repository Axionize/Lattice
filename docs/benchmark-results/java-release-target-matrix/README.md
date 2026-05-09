# Java Release Target Matrix

This snapshot checks whether compiling Lattice with a Java 17 classfile/API
target is materially slower than compiling the same source with newer targets
when the result is run on modern JVMs.

The result does not support a broad claim that Java 17-compatible bytecode is
slower for the fused static pipeline path. Runtime JVM choice mattered more
than `--release` target in these runs.

## Runs

| Host | Profile | Report |
| --- | --- | --- |
| AMD Ryzen 9 9950X dedicated host, Ubuntu `6.8.0-101-generic` | 3 forks, 4x2s warmup, 6x2s measure | [ryzen-9-9950x.md](ryzen-9-9950x.md) |
| Intel Xeon E5-2699A v4 container, Linux `6.18.22-1-lts` | 3 forks, 4x2s warmup, 6x2s measure | [xeon-e5-2699av4.md](xeon-e5-2699av4.md) |

Both runs used:

- JMH 1.36.
- `-Xms2g -Xmx2g -XX:+AlwaysPreTouch`.
- `OptimalPathBenchmark.latticePhysicalCompleted`.
- `OptimalPathBenchmark.latticeInlineFusedCompleted`.
- `OptimalPathBenchmark.disruptorManualFusedCompleted`.
- Java release targets 17, 21, and 25 where supported by the runtime.
- Temurin, Azul Zulu, Oracle GraalVM, and OpenJDK runtimes.

## Key Result

The most relevant row for a fixed, source-inline static path is
`latticeInlineFusedCompleted`.

On the Ryzen 9 9950X dedicated-host run, every release-target comparison for
that benchmark was `inconclusive-overlap`, with ratios from `0.979x` to
`1.021x`. Treat this as the cleaner signal. The Xeon E5-2699A v4 run was
inside a container and had much noisier error intervals, so it is supporting
context rather than the primary evidence.

| Runtime | Release 17 | Release 21 | Release 25 |
| --- | ---: | ---: | ---: |
| graal21 | 59.676M | 59.686M |  |
| graal25 | 60.738M | 59.813M | 59.484M |
| jdknet26 | 99.550M | 99.776M | 100.389M |
| temurin21 | 84.589M | 85.232M |  |
| temurin25 | 98.659M | 98.400M | 100.001M |
| zulu21 | 83.346M | 85.093M |  |
| zulu25 | 97.774M | 98.732M | 99.406M |

The same run did show a clear runtime-generation effect:

- JDK 21 HotSpot runtimes were around `83M-85M ops/s`.
- JDK 25/26 HotSpot runtimes were around `98M-100M ops/s`.
- Oracle GraalVM runtimes were around `59M-61M ops/s` on this benchmark.

## Interpretation

The defensible conclusion from these runs is:

> Running on a newer JVM can be materially faster. Compiling this code with
> `--release 17` did not appear materially slower than compiling with
> `--release 21` or `--release 25` for Lattice's fused static pipeline path.

The few significant `target-higher` and `target-lower` results were not
consistent across runtimes, benchmarks, and machines. Treat them as follow-up
profiling candidates rather than a general bytecode-target rule.

## Reproduction

Run the checked-in harness from the repository root:

```bash
PROFILE=proof RUN_ID=target-proof-$(hostname)-$(date -u +%Y%m%dT%H%M%SZ) scripts/jmh-matrix/run-target-proof.sh
```

The script writes all temporary JDKs, jars, logs, JSON, and generated reports
under `.jmh-matrix/`.
