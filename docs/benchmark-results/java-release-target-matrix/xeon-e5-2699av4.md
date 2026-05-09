# Xeon E5-2699A v4 Container Java Release Target Proof

Run directory: `/home/dev/Lattice/.jmh-matrix/results/target-proof-xeon-e5-2699av4-20260508T141551Z`

This run was captured inside a container on a shared Xeon E5-2699A v4 host.
Its JMH error intervals were much noisier than the Ryzen 9 9950X dedicated-host
run, so use it as supporting context rather than primary evidence.

- `run_id=target-proof-xeon-e5-2699av4-20260508T141551Z`
- `kernel=6.18.22-1-lts`
- `bench_regex=io.github.elevateddev.lattice.benchmark.OptimalPathBenchmark.(latticePhysicalCompleted|latticeInlineFusedCompleted|disruptorManualFusedCompleted)$`
- `targets=17 21 25`
- `runtimes=temurin21 temurin25 zulu21 zulu25 graal21 graal25 jdknet26`
- `forks=3 warmup=4x2s measure=6x2s threads=1`
- `jvm_args=-Xms2g -Xmx2g -XX:+AlwaysPreTouch`

Interpretation rule: compare targets only within the same runtime and benchmark.
Verdicts use non-overlapping JMH error intervals and a 5% ratio threshold.

## disruptorManualFusedCompleted

| runtime | release 17 | release 21 | release 25 |
|---|---:|---:|---:|
| graal21 | 1.411M | 1.242M |  |
| graal25 | 1.329M | 1.239M | 1.289M |
| jdknet26 | 1.230M | 1.432M | 1.454M |
| temurin21 | 1.450M | 1.465M |  |
| temurin25 | 1.395M | 1.459M | 1.526M |
| zulu21 | 1.550M | 1.437M |  |
| zulu25 | 1.346M | 1.428M | 1.441M |

| runtime | r21/r17 | r25/r17 | r21 verdict | r25 verdict | max error/score |
|---|---:|---:|---|---|---:|
| graal21 | 0.880x |  | inconclusive-overlap |  | 16.4% |
| graal25 | 0.932x | 0.970x | inconclusive-overlap | inconclusive-overlap | 15.3% |
| jdknet26 | 1.164x | 1.182x | inconclusive-overlap | inconclusive-overlap | 24.6% |
| temurin21 | 1.011x |  | inconclusive-overlap |  | 3.1% |
| temurin25 | 1.046x | 1.094x | inconclusive-overlap | inconclusive-overlap | 14.1% |
| zulu21 | 0.927x |  | target-lower |  | 3.9% |
| zulu25 | 1.060x | 1.070x | inconclusive-overlap | inconclusive-overlap | 6.5% |

## latticeInlineFusedCompleted

| runtime | release 17 | release 21 | release 25 |
|---|---:|---:|---:|
| graal21 | 4.236M | 2.767M |  |
| graal25 | 3.602M | 4.077M | 3.817M |
| jdknet26 | 4.254M | 4.768M | 4.195M |
| temurin21 | 4.261M | 3.909M |  |
| temurin25 | 4.578M | 4.455M | 5.012M |
| zulu21 | 4.036M | 4.583M |  |
| zulu25 | 3.874M | 4.482M | 3.735M |

| runtime | r21/r17 | r25/r17 | r21 verdict | r25 verdict | max error/score |
|---|---:|---:|---|---|---:|
| graal21 | 0.653x |  | target-lower |  | 24.8% |
| graal25 | 1.132x | 1.060x | inconclusive-overlap | inconclusive-overlap | 12.6% |
| jdknet26 | 1.121x | 0.986x | inconclusive-overlap | inconclusive-overlap | 14.4% |
| temurin21 | 0.917x |  | inconclusive-overlap |  | 17.5% |
| temurin25 | 0.973x | 1.095x | inconclusive-overlap | inconclusive-overlap | 8.9% |
| zulu21 | 1.136x |  | target-higher |  | 4.0% |
| zulu25 | 1.157x | 0.964x | inconclusive-overlap | inconclusive-overlap | 16.2% |

## latticePhysicalCompleted

| runtime | release 17 | release 21 | release 25 |
|---|---:|---:|---:|
| graal21 | 474.0k | 423.9k |  |
| graal25 | 451.0k | 410.5k | 496.4k |
| jdknet26 | 467.6k | 443.6k | 535.4k |
| temurin21 | 499.6k | 534.5k |  |
| temurin25 | 492.3k | 556.7k | 593.9k |
| zulu21 | 442.8k | 482.5k |  |
| zulu25 | 428.0k | 550.3k | 465.4k |

| runtime | r21/r17 | r25/r17 | r21 verdict | r25 verdict | max error/score |
|---|---:|---:|---|---|---:|
| graal21 | 0.894x |  | inconclusive-overlap |  | 7.8% |
| graal25 | 0.910x | 1.101x | inconclusive-overlap | inconclusive-overlap | 15.7% |
| jdknet26 | 0.949x | 1.145x | inconclusive-overlap | inconclusive-overlap | 44.1% |
| temurin21 | 1.070x |  | inconclusive-overlap |  | 4.8% |
| temurin25 | 1.131x | 1.206x | inconclusive-overlap | target-higher | 13.0% |
| zulu21 | 1.090x |  | inconclusive-overlap |  | 20.3% |
| zulu25 | 1.286x | 1.087x | target-higher | inconclusive-overlap | 21.9% |

## Notes

- `inconclusive-overlap` means the JMH error intervals overlap; do not treat the point-estimate ratio as proof.
- `target-higher` or `target-lower` means the intervals did not overlap and the point estimate moved by at least the threshold.
- For the Java target question, the strongest evidence is consistency across runtimes and across both machines.
