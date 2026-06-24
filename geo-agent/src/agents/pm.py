from __future__ import annotations

import json
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

from src.config_loader import load_json, load_yaml, save_json
from src.services.llm import chat


@dataclass
class ReviewResult:
    approved: bool
    score: int
    issues: list[str] = field(default_factory=list)
    suggestions: list[str] = field(default_factory=list)


class ProjectManager:
    """项目经理：建档、选题审核、合规终审。"""

    def __init__(self) -> None:
        self.profile = load_json("brand_profile.json")
        self.rules = load_yaml("compliance_rules.yaml")

    @property
    def is_ready(self) -> bool:
        return self.profile.get("status") == "ready" and bool(self.profile.get("industry"))

    def brand_context(self) -> str:
        p = self.profile
        return (
            f"行业：{p.get('industry', '未设定')}\n"
            f"产品：{p.get('product', '未设定')}\n"
            f"受众：{p.get('target_audience', '未设定')}\n"
            f"口吻：{p.get('brand_voice', '')}\n"
            f"卖点：{', '.join(p.get('selling_points', []))}\n"
            f"软文角度：{p.get('soft_article_angle', '')}\n"
            f"红线：{'; '.join(p.get('compliance_redlines', []))}"
        )

    def init_profile_interactive(self) -> dict[str, Any]:
        """CLI 建档：与用户沟通后写入 brand_profile.json。"""
        print("\n=== 项目经理 · 品牌建档 ===\n")
        fields = [
            ("industry", "行业（如：双碳、AI API）"),
            ("product", "产品/服务（一句话）"),
            ("target_audience", "目标读者"),
            ("brand_voice", "品牌口吻"),
            ("soft_article_angle", "软文植入角度（如何自然带出产品）"),
            ("image_style", "配图风格"),
        ]
        for key, label in fields:
            current = self.profile.get(key, "")
            hint = f" [{current}]" if current else ""
            value = input(f"{label}{hint}: ").strip()
            if value:
                self.profile[key] = value

        sp = input("卖点（逗号分隔）: ").strip()
        if sp:
            self.profile["selling_points"] = [s.strip() for s in sp.split(",") if s.strip()]

        red = input("额外红线（逗号分隔，回车跳过）: ").strip()
        if red:
            extra = [s.strip() for s in red.split(",") if s.strip()]
            base = self.profile.get("compliance_redlines", [])
            self.profile["compliance_redlines"] = list(dict.fromkeys(base + extra))

        geo = input("GEO 关键词（逗号分隔，回车跳过）: ").strip()
        if geo:
            self.profile["geo_keywords"] = [s.strip() for s in geo.split(",") if s.strip()]

        self.profile["status"] = "ready"
        self.profile["updated_at"] = datetime.now(timezone.utc).isoformat()
        save_json("brand_profile.json", self.profile)
        print("\n✓ 品牌档案已保存，PM 状态：ready\n")
        return self.profile

    def review_topic(self, hotspots: list[dict]) -> dict[str, Any]:
        """从热榜中选题并定角度。"""
        if not self.is_ready:
            return {
                "approved": False,
                "topic": "",
                "angle": "",
                "reason": "品牌档案未就绪，请先运行 python scripts/init_pm.py",
            }

        hot_text = "\n".join(
            f"- [{h['source']}] {h['title']}" for h in hotspots[:20]
        )
        system = (
            "你是内容项目经理。根据品牌档案从热榜中选 1 个可写话题，"
            "并给出软文植入角度。输出 JSON："
            '{"approved":bool,"topic":str,"angle":str,"reason":str}'
        )
        user = f"{self.brand_context()}\n\n今日热榜：\n{hot_text}"
        raw = chat(system, user, temperature=0.3, json_mode=True)
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return {
                "approved": False,
                "topic": "",
                "angle": "",
                "reason": "PM 选题解析失败",
            }

    def review_article(self, article: dict[str, Any]) -> ReviewResult:
        """规则 + LLM 双重合规审查。"""
        issues: list[str] = []
        body = article.get("body", "")
        title = article.get("title", "")

        for rule in self.rules.get("required_checks", []):
            if rule["id"] == "false_claims":
                for pat in rule.get("forbidden_patterns", []):
                    if pat in body or pat in title:
                        issues.append(f"命中禁用表述：{pat}")

        for red in self.profile.get("compliance_redlines", []):
            if len(red) > 4 and red[:4] in ("禁止", "不得"):
                keyword = red.replace("禁止", "").replace("不得", "").strip()
                if keyword and keyword in body:
                    issues.append(f"可能触犯红线：{red}")

        system = (
            "你是内容合规项目经理。审查软文是否可发布。"
            "输出 JSON："
            '{"approved":bool,"score":0-100,"issues":[],"suggestions":[]}'
        )
        user = (
            f"{self.brand_context()}\n\n"
            f"标题：{title}\n\n正文：\n{body[:6000]}"
        )
        raw = chat(system, user, temperature=0.2, json_mode=True)
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            data = {"approved": False, "score": 0, "issues": ["PM 审查解析失败"], "suggestions": []}

        all_issues = issues + data.get("issues", [])
        approved = bool(data.get("approved", False)) and not issues

        return ReviewResult(
            approved=approved,
            score=int(data.get("score", 0)),
            issues=all_issues,
            suggestions=data.get("suggestions", []),
        )

    def apply_profile_from_dict(self, data: dict[str, Any]) -> dict[str, Any]:
        """供后续对话/API 更新档案。"""
        self.profile.update(data)
        self.profile["updated_at"] = datetime.now(timezone.utc).isoformat()
        if self.profile.get("industry") and self.profile.get("product"):
            self.profile["status"] = "ready"
        save_json("brand_profile.json", self.profile)
        return self.profile
