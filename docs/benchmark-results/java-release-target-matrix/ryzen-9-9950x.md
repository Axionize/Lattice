# Ryzen 9 9950X Dedicated-Host Java Release Target Proof

Run directory: `/root/Projects/Lattice/.jmh-matrix/results/target-proof-9950x-20260508T225439Z`

This was the cleaner dedicated-host run and is the primary signal for the
release-target comparison.

- `run_id=target-proof-9950x-20260508T225439Z`
- `kernel=6.8.0-101-generic`
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
| graal21 | 7.001M | 6.944M |  |
| graal25 | 6.600M | 6.766M | 6.772M |
| jdknet26 | 6.239M | 6.562M | 7.463M |
| temurin21 | 7.255M | 7.244M |  |
| temurin25 | 7.419M | 7.425M | 7.658M |
| zulu21 | 7.597M | 7.571M |  |
| zulu25 | 7.507M | 7.401M | 7.473M |

| runtime | r21/r17 | r25/r17 | r21 verdict | r25 verdict | max error/score |
|---|---:|---:|---|---|---:|
| graal21 | 0.992x |  | inconclusive-overlap |  | 4.3% |
| graal25 | 1.025x | 1.026x | inconclusive-overlap | inconclusive-overlap | 5.1% |
| jdknet26 | 1.052x | 1.196x | inconclusive-overlap | target-higher | 11.0% |
| temurin21 | 0.998x |  | inconclusive-overlap |  | 5.8% |
| temurin25 | 1.001x | 1.032x | inconclusive-overlap | inconclusive-overlap | 4.2% |
| zulu21 | 0.997x |  | inconclusive-overlap |  | 4.2% |
| zulu25 | 0.986x | 0.995x | inconclusive-overlap | inconclusive-overlap | 4.2% |

## latticeInlineFusedCompleted

| runtime | release 17 | release 21 | release 25 |
|---|---:|---:|---:|
| graal21 | 59.676M | 59.686M |  |
| graal25 | 60.738M | 59.813M | 59.484M |
| jdknet26 | 99.550M | 99.776M | 100.389M |
| temurin21 | 84.589M | 85.232M |  |
| temurin25 | 98.659M | 98.400M | 100.001M |
| zulu21 | 83.346M | 85.093M |  |
| zulu25 | 97.774M | 98.732M | 99.406M |

| runtime | r21/r17 | r25/r17 | r21 verdict | r25 verdict | max error/score |
|---|---:|---:|---|---|---:|
| graal21 | 1.000x |  | inconclusive-overlap |  | 2.4% |
| graal25 | 0.985x | 0.979x | inconclusive-overlap | inconclusive-overlap | 3.1% |
| jdknet26 | 1.002x | 1.008x | inconclusive-overlap | inconclusive-overlap | 3.5% |
| temurin21 | 1.008x |  | inconclusive-overlap |  | 3.3% |
| temurin25 | 0.997x | 1.014x | inconclusive-overlap | inconclusive-overlap | 3.4% |
| zulu21 | 1.021x |  | inconclusive-overlap |  | 2.9% |
| zulu25 | 1.010x | 1.017x | inconclusive-overlap | inconclusive-overlap | 4.6% |

## latticePhysicalCompleted

| runtime | release 17 | release 21 | release 25 |
|---|---:|---:|---:|
| graal21 | 1.951M | 1.851M |  |
| graal25 | 2.030M | 1.859M | 1.137M |
| jdknet26 | 1.769M | 1.688M | 1.806M |
| temurin21 | 1.845M | 1.807M |  |
| temurin25 | 1.848M | 1.796M | 1.755M |
| zulu21 | 1.791M | 1.817M |  |
| zulu25 | 1.800M | 1.804M | 1.830M |

| runtime | r21/r17 | r25/r17 | r21 verdict | r25 verdict | max error/score |
|---|---:|---:|---|---|---:|
| graal21 | 0.949x |  | inconclusive-overlap |  | 8.8% |
| graal25 | 0.916x | 0.560x | inconclusive-overlap | target-lower | 32.4% |
| jdknet26 | 0.954x | 1.021x | inconclusive-overlap | inconclusive-overlap | 9.7% |
| temurin21 | 0.980x |  | inconclusive-overlap |  | 11.2% |
| temurin25 | 0.972x | 0.950x | inconclusive-overlap | inconclusive-overlap | 11.4% |
| zulu21 | 1.014x |  | inconclusive-overlap |  | 18.3% |
| zulu25 | 1.002x | 1.017x | inconclusive-overlap | inconclusive-overlap | 9.4% |

## Notes

- `inconclusive-overlap` means the JMH error intervals overlap; do not treat the point-estimate ratio as proof.
- `target-higher` or `target-lower` means the intervals did not overlap and the point estimate moved by at least the threshold.
- For the Java target question, the strongest evidence is consistency across runtimes and across both machines.
