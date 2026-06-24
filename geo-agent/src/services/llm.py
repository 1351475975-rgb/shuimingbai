from __future__ import annotations

import os
from typing import Any

from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()


def get_client() -> OpenAI:
    api_key = os.getenv("LLM_API_KEY", "")
    base_url = os.getenv("LLM_BASE_URL", "https://api.deepseek.com")
    if not api_key:
        raise RuntimeError("未配置 LLM_API_KEY，请复制 .env.example 为 .env 并填写")
    return OpenAI(api_key=api_key, base_url=base_url)


def chat(
    system: str,
    user: str,
    *,
    temperature: float = 0.7,
    max_tokens: int = 4096,
    json_mode: bool = False,
) -> str:
    model = os.getenv("LLM_MODEL", "deepseek-chat")
    kwargs: dict[str, Any] = {
        "model": model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
        "temperature": temperature,
        "max_tokens": max_tokens,
    }
    if json_mode:
        kwargs["response_format"] = {"type": "json_object"}

    client = get_client()
    resp = client.chat.completions.create(**kwargs)
    return resp.choices[0].message.content or ""
