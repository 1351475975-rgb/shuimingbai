from __future__ import annotations

from pathlib import Path
from typing import Any

from src.config_loader import load_yaml
from src.services.image_fetcher import get_image


class ImageAgent:
    """配图：封面 + 正文插图 + 竖版（小红书）。"""

    def __init__(self) -> None:
        self.settings = load_yaml("settings.yaml").get("images", {})

    def generate_pack(
        self,
        article: dict[str, Any],
        output_dir: Path,
    ) -> dict[str, str]:
        queries: list[str] = article.get("image_queries") or []
        style = article.get("image_style", "")
        title = article.get("title", "cover")

        if not queries:
            queries = [title, title, title]

        images: dict[str, str] = {}
        img_dir = output_dir / "images"

        # 封面 16:9
        cover_16_9 = img_dir / "cover_16x9.jpg"
        get_image(f"{queries[0]} {style}", cover_16_9, (1280, 720))
        images["cover_16x9"] = str(cover_16_9)

        # 封面 1:1
        cover_1_1 = img_dir / "cover_1x1.jpg"
        get_image(f"{queries[0]} {style}", cover_1_1, (1080, 1080))
        images["cover_1x1"] = str(cover_1_1)

        # 正文配图
        inline_count = int(self.settings.get("inline_count", 3))
        for i in range(inline_count):
            q = queries[min(i + 1, len(queries) - 1)]
            path = img_dir / f"inline_{i + 1}.jpg"
            get_image(f"{q} {style}", path, (1200, 675))
            images[f"inline_{i + 1}"] = str(path)

        # 小红书竖图
        for i in range(3):
            q = queries[min(i, len(queries) - 1)]
            path = img_dir / f"xhs_{i + 1}.jpg"
            get_image(f"{q} {style}", path, (1080, 1440))
            images[f"xhs_{i + 1}"] = str(path)

        return images
