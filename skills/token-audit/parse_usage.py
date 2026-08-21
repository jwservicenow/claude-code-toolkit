#!/usr/bin/env python3
"""
Sum cache/token usage from Claude Code session .jsonl transcripts for one
config dir's most recently active day, converted to US Mountain time.

Usage: parse_usage.py <config_dir> [YYYY-MM-DD]
  <config_dir>  e.g. ~/.claude-personal or ~/.claude-work
  [YYYY-MM-DD]  optional — force a specific Mountain-time date instead of
                auto-detecting the most recent day with activity.

Prints one JSON object to stdout:
  {"date": "...", "files": N, "input": N, "output": N,
   "cache_read": N, "cache_creation": N, "total": N, "cache_read_pct": N.N}
Or {"date": null, "files": 0, ...all zero} if no usage data exists at all
under <config_dir>/projects (e.g. claudec, which stores no usage locally).
"""
import json
import sys
import glob
import os
from datetime import datetime, timedelta, timezone

MDT = timezone(timedelta(hours=-6))  # Mountain time, no DST handling needed for this use


def local_date(ts_iso):
    try:
        return datetime.fromisoformat(ts_iso.replace("Z", "+00:00")).astimezone(MDT)
    except Exception:
        return None


def main():
    if len(sys.argv) < 2:
        print("usage: parse_usage.py <config_dir> [YYYY-MM-DD]", file=sys.stderr)
        sys.exit(2)

    config_dir = os.path.expanduser(sys.argv[1])
    forced_date = sys.argv[2] if len(sys.argv) > 2 else None

    files = glob.glob(os.path.join(config_dir, "projects", "**", "*.jsonl"), recursive=True)

    # Pass 1: find the most recent Mountain-time date with any usage record,
    # unless a date was forced.
    target_date = forced_date
    if not target_date:
        latest = None
        for f in files:
            try:
                with open(f, errors="ignore") as fh:
                    for line in fh:
                        if '"usage"' not in line:
                            continue
                        try:
                            obj = json.loads(line)
                        except Exception:
                            continue
                        dt = local_date(obj.get("timestamp", ""))
                        if dt and (latest is None or dt > latest):
                            latest = dt
            except Exception:
                continue
        if latest is None:
            print(json.dumps({
                "date": None, "files": 0, "input": 0, "output": 0,
                "cache_read": 0, "cache_creation": 0, "total": 0,
                "cache_read_pct": 0.0,
            }))
            return
        target_date = latest.strftime("%Y-%m-%d")

    # Pass 2: sum usage for that date.
    totals = {"input": 0, "output": 0, "cache_read": 0, "cache_creation": 0}
    file_set = set()
    for f in files:
        try:
            with open(f, errors="ignore") as fh:
                for line in fh:
                    if '"usage"' not in line:
                        continue
                    try:
                        obj = json.loads(line)
                    except Exception:
                        continue
                    dt = local_date(obj.get("timestamp", ""))
                    if not dt or dt.strftime("%Y-%m-%d") != target_date:
                        continue
                    msg = obj.get("message")
                    usage = msg.get("usage") if isinstance(msg, dict) else None
                    if not usage:
                        continue
                    file_set.add(f)
                    totals["input"] += usage.get("input_tokens", 0) or 0
                    totals["output"] += usage.get("output_tokens", 0) or 0
                    totals["cache_read"] += usage.get("cache_read_input_tokens", 0) or 0
                    totals["cache_creation"] += usage.get("cache_creation_input_tokens", 0) or 0
        except Exception:
            continue

    grand = sum(totals.values())
    result = {
        "date": target_date,
        "files": len(file_set),
        **totals,
        "total": grand,
        "cache_read_pct": round(totals["cache_read"] / grand * 100, 1) if grand else 0.0,
    }
    print(json.dumps(result))


if __name__ == "__main__":
    main()
