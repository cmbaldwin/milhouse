#!/usr/bin/env python3
"""
Preview balanced weekly windows for Milhouse Codex dispatch automation.
"""

from __future__ import annotations

import argparse
import math

DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


def compute_windows(weekly_limit: int, window_hours: int) -> list[int]:
    total_windows = math.ceil(168 / window_hours)
    if weekly_limit <= 0 or weekly_limit >= total_windows:
        return list(range(total_windows))

    slots: list[int] = []
    last = None
    for i in range(weekly_limit):
        idx = (i * total_windows) // weekly_limit
        if idx != last:
            slots.append(idx)
            last = idx
    return slots


def window_to_day_hour(window_index: int, window_hours: int) -> tuple[str, int]:
    start_hour_of_week = window_index * window_hours
    day = DAYS[(start_hour_of_week // 24) % 7]
    hour = start_hour_of_week % 24
    return day, hour


def main() -> None:
    parser = argparse.ArgumentParser(description="Preview balanced weekly run windows.")
    parser.add_argument("--weekly-limit", type=int, required=True, help="Max runs per week.")
    parser.add_argument("--window-hours", type=int, default=5, help="Window size in hours.")
    args = parser.parse_args()

    if args.weekly_limit < 0:
        raise SystemExit("weekly-limit must be >= 0")
    if args.window_hours <= 0:
        raise SystemExit("window-hours must be > 0")

    total_windows = math.ceil(168 / args.window_hours)
    slots = compute_windows(args.weekly_limit, args.window_hours)

    print("Balanced Weekly Window Plan")
    print(f"  Weekly limit: {args.weekly_limit}")
    print(f"  Window size: {args.window_hours}h")
    print(f"  Total windows/week: {total_windows}")
    print(f"  Planned windows/week: {len(slots)}")
    print("")
    print("Recommended automation RRULE:")
    print(f"  FREQ=HOURLY;INTERVAL={args.window_hours}")
    print("")
    print("Allowed window starts:")
    for idx in slots:
        day, hour = window_to_day_hour(idx, args.window_hours)
        print(f"  - window {idx:02d}: {day} {hour:02d}:00")


if __name__ == "__main__":
    main()
