#!/usr/bin/env python3
import json
import math
import pathlib
import re
import sys
from collections import defaultdict


def fmt_score(value):
    if value is None:
        return ""
    if abs(value) >= 1_000_000:
        return f"{value / 1_000_000:.3f}M"
    if abs(value) >= 1_000:
        return f"{value / 1_000:.1f}k"
    return f"{value:.3f}"


def fmt_pct(value):
    if value is None or math.isnan(value):
        return ""
    return f"{value * 100:.1f}%"


def interval(row):
    score = row.get("score")
    err = row.get("error")
    if score is None or err is None or math.isnan(err):
        return None
    return score - err, score + err


def overlaps(a, b):
    ia = interval(a)
    ib = interval(b)
    if ia is None or ib is None:
        return True
    return max(ia[0], ib[0]) <= min(ia[1], ib[1])


def verdict(base, other, threshold):
    if base is None or other is None:
        return ""
    ratio = other["score"] / base["score"] if base["score"] else float("nan")
    overlap = overlaps(base, other)
    if overlap:
        return "inconclusive-overlap"
    if ratio >= 1.0 + threshold:
        return "target-higher"
    if ratio <= 1.0 - threshold:
        return "target-lower"
    return "same-band"


def main():
    if len(sys.argv) not in (2, 3):
        print("usage: proof-report.py <run-dir> [ratio-threshold]", file=sys.stderr)
        return 2

    run_dir = pathlib.Path(sys.argv[1])
    if not run_dir.is_dir():
        print(f"error: not a directory: {run_dir}", file=sys.stderr)
        return 2

    threshold = float(sys.argv[2]) if len(sys.argv) > 2 else 0.05
    rows = {}
    units = {}
    runtimes = set()
    targets = set()
    benchmarks = set()

    for path in sorted(run_dir.glob("*.json")):
        match = re.match(r"(.+)-release(\d+)\.json$", path.name)
        if not match:
            continue
        runtime, target_s = match.groups()
        target = int(target_s)
        try:
            data = json.loads(path.read_text())
        except json.JSONDecodeError:
            continue
        runtimes.add(runtime)
        targets.add(target)
        for item in data:
            benchmark = item.get("benchmark", "").split(".")[-1]
            primary = item.get("primaryMetric", {})
            score = primary.get("score")
            error = primary.get("scoreError")
            unit = primary.get("scoreUnit", "")
            if score is None:
                continue
            rows[(runtime, target, benchmark)] = {
                "score": float(score),
                "error": None if error is None else float(error),
            }
            units[benchmark] = unit
            benchmarks.add(benchmark)

    env_path = run_dir / "environment.txt"
    print("# Lattice Java Release Target Proof Report")
    print()
    print(f"Run directory: `{run_dir}`")
    if env_path.exists():
        env = env_path.read_text(errors="replace").splitlines()
        for key in ("run_id=", "kernel=", "bench_regex=", "targets=", "runtimes=", "forks=", "jvm_args="):
            for line in env:
                if line.startswith(key):
                    print(f"- `{line}`")
                    break
    print()
    print("Interpretation rule: compare targets only within the same runtime and benchmark. "
          f"Verdicts use non-overlapping JMH error intervals and a {threshold * 100:.0f}% ratio threshold.")
    print()

    ordered_targets = sorted(targets)
    ordered_runtimes = sorted(runtimes)
    ordered_benchmarks = sorted(benchmarks)

    for benchmark in ordered_benchmarks:
        print(f"## {benchmark}")
        print()
        header = "| runtime | " + " | ".join(f"release {t}" for t in ordered_targets) + " |"
        sep = "|---|" + "|".join("---:" for _ in ordered_targets) + "|"
        print(header)
        print(sep)
        for runtime in ordered_runtimes:
            values = []
            for target in ordered_targets:
                row = rows.get((runtime, target, benchmark))
                values.append(fmt_score(row["score"]) if row else "")
            print(f"| {runtime} | " + " | ".join(values) + " |")
        print()

        print("| runtime | r21/r17 | r25/r17 | r21 verdict | r25 verdict | max error/score |")
        print("|---|---:|---:|---|---|---:|")
        for runtime in ordered_runtimes:
            base = rows.get((runtime, 17, benchmark))
            r21 = rows.get((runtime, 21, benchmark))
            r25 = rows.get((runtime, 25, benchmark))
            ratio21 = r21["score"] / base["score"] if base and r21 else None
            ratio25 = r25["score"] / base["score"] if base and r25 else None
            max_err = None
            candidates = [row for row in (base, r21, r25) if row and row.get("error") is not None and row["score"]]
            if candidates:
                max_err = max(row["error"] / row["score"] for row in candidates)
            print(
                f"| {runtime} | "
                f"{'' if ratio21 is None else f'{ratio21:.3f}x'} | "
                f"{'' if ratio25 is None else f'{ratio25:.3f}x'} | "
                f"{verdict(base, r21, threshold)} | "
                f"{verdict(base, r25, threshold)} | "
                f"{fmt_pct(max_err)} |"
            )
        print()

    print("## Notes")
    print()
    print("- `inconclusive-overlap` means the JMH error intervals overlap; do not treat the point-estimate ratio as proof.")
    print("- `target-higher` or `target-lower` means the intervals did not overlap and the point estimate moved by at least the threshold.")
    print("- For the Java target question, the strongest evidence is consistency across runtimes and across both machines.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
