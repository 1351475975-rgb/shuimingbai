#!/usr/bin/env python3
"""查看项目经理 / 品牌档案状态。"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.agents.pm import ProjectManager  # noqa: E402


def main() -> None:
    pm = ProjectManager()
    print(json.dumps(pm.profile, ensure_ascii=False, indent=2))
    print(f"\nPM 就绪: {pm.is_ready}")


if __name__ == "__main__":
    main()
