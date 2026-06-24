from __future__ import annotations

import os
from io import BytesIO
from pathlib import Path

import requests
from PIL import Image, ImageDraw, ImageFont
from dotenv import load_dotenv

load_dotenv()


def _placeholder(path: Path, text: str, size: tuple[int, int]) -> Path:
    img = Image.new("RGB", size, color=(30, 41, 59))
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("arial.ttf", 28)
    except OSError:
        font = ImageFont.load_default()
    draw.text((40, size[1] // 2 - 20), text[:40], fill=(226, 232, 240), font=font)
    img.save(path)
    return path


def fetch_pexels(query: str, dest: Path, size: tuple[int, int] = (1280, 720)) -> Path | None:
    api_key = os.getenv("PEXELS_API_KEY", "")
    if not api_key:
        return None

    try:
        resp = requests.get(
            "https://api.pexels.com/v1/search",
            headers={"Authorization": api_key},
            params={"query": query, "per_page": 1, "orientation": "landscape"},
            timeout=20,
        )
        resp.raise_for_status()
        photos = resp.json().get("photos", [])
        if not photos:
            return None
        url = photos[0]["src"]["large2x"]
        img_resp = requests.get(url, timeout=30)
        img_resp.raise_for_status()
        img = Image.open(BytesIO(img_resp.content)).convert("RGB")
        img = img.resize(size, Image.Resampling.LANCZOS)
        img.save(dest)
        return dest
    except (requests.RequestException, OSError, KeyError):
        return None


def get_image(query: str, dest: Path, size: tuple[int, int] = (1280, 720)) -> Path:
    dest.parent.mkdir(parents=True, exist_ok=True)
    result = fetch_pexels(query, dest, size)
    if result:
        return result
    return _placeholder(dest, query, size)
