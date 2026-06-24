#!/usr/bin/env python3
"""每日软文流水线入口。"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.workflows.daily_pipeline import run_daily  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description="GEO 软文每日流水线")
    parser.add_argument("--dry-run", action="store_true", help="不触发发布 API，仅生成文件")
    parser.add_argument("--mock", action="store_true", help="无 API 测试模式，使用模拟数据")
    args = parser.parse_args()

    try:
        out = run_daily(dry_run=args.dry_run, mock=args.mock)
        print(f"\n[OK] 完成，输出目录：{out}\n")
    except RuntimeError as exc:
        print(f"\n[FAIL] {exc}\n", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
