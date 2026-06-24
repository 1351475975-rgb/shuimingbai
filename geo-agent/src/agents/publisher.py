from __future__ import annotations

import json
import os
import random
import time
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any

import requests
from dotenv import load_dotenv

from src.config_loader import load_yaml

load_dotenv()


class BasePublisher(ABC):
    @abstractmethod
    def publish(self, article: dict[str, Any], images: dict[str, str], platform_text: str) -> dict[str, Any]:
        ...


class FilePublisher(BasePublisher):
    """默认：写入 platforms/ 目录，供人工或 Wechatsync 使用。"""

    def __init__(self, platform_id: str, mode: str) -> None:
        self.platform_id = platform_id
        self.mode = mode

    def publish(self, article: dict[str, Any], images: dict[str, str], platform_text: str) -> dict[str, Any]:
        return {
            "platform": self.platform_id,
            "mode": self.mode,
            "status": "saved_to_file",
            "note": "已生成平台素材，见 platforms/ 目录",
        }


class WordPressPublisher(BasePublisher):
    def publish(self, article: dict[str, Any], images: dict[str, str], platform_text: str) -> dict[str, Any]:
        url = os.getenv("WORDPRESS_URL", "").rstrip("/")
        user = os.getenv("WORDPRESS_USER", "")
        password = os.getenv("WORDPRESS_APP_PASSWORD", "")
        if not all([url, user, password]):
            return {"platform": "wordpress", "status": "skipped", "reason": "未配置 WordPress"}

        body = article.get("body", platform_text)
        payload = {
            "title": article.get("title", ""),
            "content": body,
            "status": "draft",
            "excerpt": article.get("summary", ""),
        }
        try:
            resp = requests.post(
                f"{url}/wp-json/wp/v2/posts",
                json=payload,
                auth=(user, password),
                timeout=30,
            )
            resp.raise_for_status()
            data = resp.json()
            return {"platform": "wordpress", "status": "draft", "post_id": data.get("id")}
        except requests.RequestException as exc:
            return {"platform": "wordpress", "status": "error", "reason": str(exc)}


class PublisherAgent:
    """按 platforms.yaml 策略分发。"""

    def __init__(self) -> None:
        self.config = load_yaml("platforms.yaml")
        self.pipeline = load_yaml("settings.yaml").get("pipeline", {})

    def _get_publisher(self, platform_id: str, mode: str) -> BasePublisher:
        if platform_id == "wordpress" and mode == "auto_publish":
            return WordPressPublisher()
        return FilePublisher(platform_id, mode)

    def save_platform_files(
        self,
        output_dir: Path,
        article: dict[str, Any],
        platform_texts: dict[str, str],
        images: dict[str, str],
    ) -> None:
        plat_dir = output_dir / "platforms"
        manifest: dict[str, Any] = {
            "title": article.get("title"),
            "images": images,
            "platforms": {},
        }

        for pid, cfg in self.config.get("platforms", {}).items():
            if not cfg.get("enabled", True):
                continue
            text = platform_texts.get(pid, "")
            if not text and cfg.get("mode") != "generate_only":
                text = f"# {article.get('title')}\n\n{article.get('body', '')}"

            mode = cfg.get("mode", "auto_draft")
            entry = {
                "name": cfg.get("name", pid),
                "risk": cfg.get("risk"),
                "mode": mode,
                "text_preview": text[:200],
            }
            manifest["platforms"][pid] = entry

            out = plat_dir / f"{pid}.md"
            header = (
                f"<!-- platform: {pid} | mode: {mode} | risk: {cfg.get('risk')} -->\n\n"
            )
            out.write_text(header + text, encoding="utf-8")

        (output_dir / "manifest.json").write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    def publish_all(
        self,
        output_dir: Path,
        article: dict[str, Any],
        platform_texts: dict[str, str],
        images: dict[str, str],
        *,
        fast: bool = False,
    ) -> list[dict[str, Any]]:
        self.save_platform_files(output_dir, article, platform_texts, images)
        results: list[dict[str, Any]] = []
        min_sec = int(self.pipeline.get("publish_interval_min_sec", 300))
        max_sec = int(self.pipeline.get("publish_interval_max_sec", 1800))

        for pid, cfg in self.config.get("platforms", {}).items():
            if not cfg.get("enabled", True):
                continue
            mode = cfg.get("mode", "auto_draft")
            if mode == "generate_only":
                results.append({
                    "platform": pid,
                    "status": "generate_only",
                    "note": "仅生成素材，不自动发送",
                })
                continue

            publisher = self._get_publisher(pid, mode)
            text = platform_texts.get(pid, article.get("body", ""))
            result = publisher.publish(article, images, text)
            results.append(result)

            if not fast and mode in ("auto_publish", "auto_draft"):
                time.sleep(random.randint(min_sec, max_sec))

        log_path = output_dir / "publish_log.json"
        log_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
        return results
