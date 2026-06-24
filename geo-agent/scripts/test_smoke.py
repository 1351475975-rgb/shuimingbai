#!/usr/bin/env python3
"""冒烟测试：不依赖 LLM API。"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from dotenv import load_dotenv

load_dotenv(ROOT / ".env")

from src.agents.pm import ProjectManager  # noqa: E402
from src.config_loader import load_yaml  # noqa: E402
from src.services.hotspot import fetch_all  # noqa: E402
from src.workflows.daily_pipeline import run_daily  # noqa: E402


def main() -> None:
    print("=== GEO Agent 冒烟测试 ===\n")
    ok = True

    # 1. 配置加载
    platforms = load_yaml("platforms.yaml")
    count = len(platforms.get("platforms", {}))
    print(f"[1/4] 配置加载 OK — {count} 个平台")
    gen_only = [k for k, v in platforms["platforms"].items() if v.get("mode") == "generate_only"]
    print(f"      仅生成（五星）: {', '.join(gen_only)}")

    # 2. 热榜
    hotspots = fetch_all(["weibo", "baidu", "zhihu"], 5)
    if hotspots:
        print(f"[2/4] 热榜抓取 OK — 获取 {len(hotspots)} 条，示例: {hotspots[0]['title'][:30]}")
    else:
        print("[2/4] 热榜抓取 WARN — 外网 API 暂不可用，mock 模式会用内置数据")

    # 3. API Key
    has_key = bool(os.getenv("LLM_API_KEY"))
    print(f"[3/4] LLM_API_KEY — {'已配置' if has_key else '未配置（需填入 .env）'}")

    # 4. Mock 全流程
    print("[4/4] 运行 mock 全流程...")
    out = run_daily(mock=True)
    files = list(out.rglob("*"))
    img_count = len(list((out / "images").glob("*.jpg")))
    plat_count = len(list((out / "platforms").glob("*.md")))
    print(f"      输出: {out}")
    print(f"      图片: {img_count} 张 | 平台文案: {plat_count} 份")

    status = json.loads((out / "pipeline_status.json").read_text(encoding="utf-8"))
    print(f"      状态: {status['status']}")

    pm = ProjectManager()
    if not pm.is_ready:
        print("\n提示: 品牌档案仍为 pending，正式跑通前请执行 python scripts/init_pm.py")
    if not has_key:
        print("提示: 配置 .env 后执行 python scripts/run_daily.py 跑真实 AI 流水线")

    print("\n=== 测试完成 ===\n")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
