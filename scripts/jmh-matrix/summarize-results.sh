#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

RUN_DIR="${1:-}"
if [[ -z "$RUN_DIR" ]]; then
    RUN_DIR="$(find "$RESULTS_DIR" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)"
fi
[[ -d "$RUN_DIR" ]] || die "result directory not found: $RUN_DIR"

python3 - "$RUN_DIR" <<'PY'
import json
import pathlib
import re
import sys

run_dir = pathlib.Path(sys.argv[1])
rows = []
for path in sorted(run_dir.glob("*.json")):
    match = re.match(r"(.+)-release(\d+)\.json$", path.name)
    if not match:
        continue
    runtime, target = match.groups()
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError:
        continue
    for item in data:
        bench = item.get("benchmark", "").split(".")[-1]
        primary = item.get("primaryMetric", {})
        rows.append((
            runtime,
            int(target),
            bench,
            primary.get("score"),
            primary.get("scoreError"),
            primary.get("scoreUnit"),
        ))

print("| runtime | target | benchmark | score | error | unit |")
print("|---|---:|---|---:|---:|---|")
for runtime, target, bench, score, error, unit in rows:
    score_s = "" if score is None else f"{score:.3f}"
    error_s = "" if error is None else f"{error:.3f}"
    print(f"| {runtime} | {target} | {bench} | {score_s} | {error_s} | {unit or ''} |")
PY
