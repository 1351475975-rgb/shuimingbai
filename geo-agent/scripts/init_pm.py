#!/usr/bin/env python3
"""项目经理建档入口。"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.agents.pm import ProjectManager  # noqa: E402


def main() -> None:
    pm = ProjectManager()
    pm.init_profile_interactive()


if __name__ == "__main__":
    main()
