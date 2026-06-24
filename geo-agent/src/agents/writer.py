from __future__ import annotations

import json
from typing import Any

from src.agents.pm import ProjectManager
from src.services.llm import chat


class WriterAgent:
    """写手：GEO 结构化长文 + 各平台适配文案。"""

    def __init__(self, pm: ProjectManager) -> None:
        self.pm = pm

    def write_main_article(self, topic: str, angle: str) -> dict[str, Any]:
        system = """你是 GEO 软文写手。要求：
1. 总分总结构，含问答小标题（是什么/怎么做/值不值）
2. 嵌入 1-2 处可核查数据或行业事实
3. 自然植入产品，不生硬推销
4. 标注 [广告] 或 [合作推广] 若涉及商业内容
5. 输出 JSON：
{
  "title": "主标题",
  "summary": "摘要80字内",
  "body": "Markdown 正文",
  "tags": ["标签1","标签2"],
  "image_queries": ["封面关键词","配图1","配图2","配图3"]
}"""
        user = (
            f"{self.pm.brand_context()}\n\n"
            f"热点话题：{topic}\n植入角度：{angle}\n"
            "请写一篇 1200-1800 字的 GEO 软文。"
        )
        raw = chat(system, user, json_mode=True)
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return {
                "title": topic,
                "summary": "",
                "body": raw,
                "tags": [],
                "image_queries": [topic, topic, topic],
            }

    def adapt_platforms(self, article: dict[str, Any]) -> dict[str, str]:
        """生成各平台适配版（含五星仅生成平台）。"""
        system = """根据主文生成多平台适配文案。输出 JSON，key 为平台 id：
xiaohongshu: 短文案+9条配图说明（竖图3:4场景）
douyin: 图文轮播脚本（每页1-2句+配图说明）
kuaishou: 类似抖音，偏接地气
shipinhao: 视频号图文/口播提纲
zhihu: 长文版（可略删减营销感）
weibo: 140字引流+链接提示
其余平台 id 给标题+摘要+正文精简版
平台 id 列表：xiaohongshu,douyin,kuaishou,shipinhao,zhihu,weibo,csdn,juejin,toutiao,baijiahao"""
        user = (
            f"标题：{article.get('title')}\n\n"
            f"正文：\n{article.get('body', '')[:5000]}"
        )
        raw = chat(system, user, json_mode=True)
        try:
            data = json.loads(raw)
            return {k: str(v) for k, v in data.items()}
        except json.JSONDecodeError:
            return {"raw": raw}

    def revise(self, article: dict[str, Any], feedback: list[str]) -> dict[str, Any]:
        system = "根据 PM 审查意见修改软文，保持 JSON 格式同 write_main_article。"
        user = (
            f"原稿：{json.dumps(article, ensure_ascii=False)}\n\n"
            f"修改意见：{'；'.join(feedback)}"
        )
        raw = chat(system, user, json_mode=True)
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            article["body"] = raw
            return article
