from __future__ import annotations

import json
from datetime import date
from pathlib import Path

from src.agents.image_agent import ImageAgent
from src.agents.pm import ProjectManager
from src.agents.publisher import PublisherAgent
from src.agents.writer import WriterAgent
from src.config_loader import day_output_dir, load_yaml
from src.services.hotspot import fetch_all

MOCK_HOTSPOTS = [
    {"source": "weibo", "title": "AI大模型应用落地加速", "url": "", "hot": "1"},
    {"source": "baidu", "title": "企业数字化转型趋势解读", "url": "", "hot": "2"},
    {"source": "zhihu", "title": "如何选择靠谱的API服务商", "url": "", "hot": "3"},
]

MOCK_ARTICLE = {
    "title": "AI大模型落地：企业如何选对API服务？[合作推广]",
    "summary": "从成本、稳定性、合规三维度解读企业选型要点。",
    "body": """## 是什么：企业为什么需要 API 聚合服务？

越来越多企业把大模型接入业务，但直连多家厂商成本高、维护难。

## 怎么做：选型看这三点

1. **价格透明** — 按 token 计费，有缓存折扣
2. **国内直连** — 低延迟、合规备案
3. **统一接口** — OpenAI 兼容，换模型不改代码

## 值不值：真实场景对比

| 维度 | 自建对接 | 聚合平台 |
|------|----------|----------|
| 上线周期 | 数周 | 数小时 |
| 运维成本 | 高 | 低 |

> 本文含合作推广内容，观点基于公开行业观察。

**数据来源**：各厂商公开定价页（2026年6月）""",
    "tags": ["AI", "API", "GEO"],
    "image_queries": ["AI technology", "cloud API", "business digital"],
}

MOCK_PLATFORM_TEXTS = {
    "xiaohongshu": "【AI选型笔记】企业接大模型别踩坑\n\n3个维度帮你省一半成本👇\n#AI #企业服务",
    "douyin": "第1页：企业接AI最难的不是技术\n第2页：是选哪家API\n第3页：看价格、稳定性、接口统一",
    "kuaishou": "老铁们，企业想用AI，API怎么选？三点说清楚…",
    "shipinhao": "口播提纲：开场热点→痛点→三点建议→引导关注",
    "zhihu": MOCK_ARTICLE["body"],
    "weibo": "AI落地选型三要点：价格、稳定性、接口统一。详见长文 [合作推广]",
    "csdn": MOCK_ARTICLE["body"],
    "juejin": MOCK_ARTICLE["body"],
    "toutiao": f"# {MOCK_ARTICLE['title']}\n\n{MOCK_ARTICLE['summary']}",
}


def run_daily(*, dry_run: bool = False, mock: bool = False) -> Path:
    """每日流水线：热点 → PM 选题 → 写文 → 配图 → PM 审 → 发布/生成。"""
    settings = load_yaml("settings.yaml")
    pm = ProjectManager()

    if not pm.is_ready and not mock:
        raise RuntimeError(
            "品牌档案未就绪。请先运行: python scripts/init_pm.py"
        )

    day = date.today().isoformat()
    suffix = "-mock" if mock else ""
    out = day_output_dir(f"{day}{suffix}")

    # 1. 热点
    sources = settings.get("hotspot", {}).get("sources", ["weibo", "baidu", "zhihu"])
    top_n = int(settings.get("hotspot", {}).get("top_n", 15))
    hotspots = fetch_all(sources, top_n) if not mock else []
    if not hotspots:
        hotspots = MOCK_HOTSPOTS if mock else hotspots
    (out / "hotspots.json").write_text(
        json.dumps(hotspots, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    writer = WriterAgent(pm)

    if mock:
        topic_decision = {
            "approved": True,
            "topic": hotspots[0]["title"],
            "angle": "从行业视角自然引出产品价值",
            "reason": "mock 测试选题",
        }
        article = dict(MOCK_ARTICLE)
        review_data = {"approved": True, "score": 92, "issues": [], "suggestions": []}
        platform_texts = dict(MOCK_PLATFORM_TEXTS)
    else:
        # 2. PM 选题
        topic_decision = pm.review_topic(hotspots)
        if not topic_decision.get("approved"):
            raise RuntimeError(f"PM 驳回选题：{topic_decision.get('reason', '无合适话题')}")

        # 3. 写文
        article = writer.write_main_article(
            topic_decision["topic"],
            topic_decision.get("angle", ""),
        )

        # 4. PM 合规审（可重试）
        max_retries = int(settings.get("pipeline", {}).get("pm_max_retries", 2))
        review_data = {}
        for attempt in range(max_retries + 1):
            review = pm.review_article(article)
            review_data = {
                "approved": review.approved,
                "score": review.score,
                "issues": review.issues,
                "suggestions": review.suggestions,
            }
            (out / f"pm_review_{attempt}.json").write_text(
                json.dumps(review_data, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
            if review.approved:
                break
            if attempt < max_retries:
                article = writer.revise(article, review.issues + review.suggestions)
            else:
                article["_pm_blocked"] = True
                article["_pm_issues"] = review.issues

        platform_texts = writer.adapt_platforms(article)

    (out / "pm_topic.json").write_text(
        json.dumps(topic_decision, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    if mock:
        (out / "pm_review_0.json").write_text(
            json.dumps(review_data, ensure_ascii=False, indent=2), encoding="utf-8"
        )

    (out / "article.json").write_text(
        json.dumps(article, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (out / "article.md").write_text(
        f"# {article.get('title', '')}\n\n{article.get('body', '')}",
        encoding="utf-8",
    )

    # 5. 配图
    image_agent = ImageAgent()
    images = image_agent.generate_pack(article, out)

    (out / "platform_texts.json").write_text(
        json.dumps(platform_texts, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    # 7. 发布 / 仅生成（mock 模式跳过真实 API 发布等待）
    publisher = PublisherAgent()
    if mock:
        results = publisher.publish_all(out, article, platform_texts, images, fast=True)
        for r in results:
            if r.get("status") not in ("generate_only", "saved_to_file", "skipped"):
                r["status"] = "mock_skipped"
        status = "mock_completed"
    elif not dry_run:
        results = publisher.publish_all(out, article, platform_texts, images)
        status = "completed"
    else:
        publisher.save_platform_files(out, article, platform_texts, images)
        results = []
        status = "dry_run"

    (out / "pipeline_status.json").write_text(
        json.dumps({"status": status, "publish": results}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    return out
