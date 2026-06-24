from __future__ import annotations

import requests

PROVIDERS = {
    "weibo": [
        ("vvhan", "https://api.vvhan.com/api/hotlist", {"type": "weiboHot"}),
        ("tenapi", "https://tenapi.cn/v2/weibohot", None),
    ],
    "baidu": [
        ("vvhan", "https://api.vvhan.com/api/hotlist", {"type": "baiduHot"}),
        ("tenapi", "https://tenapi.cn/v2/baiduhot", None),
    ],
    "zhihu": [
        ("vvhan", "https://api.vvhan.com/api/hotlist", {"type": "zhihuHot"}),
        ("tenapi", "https://tenapi.cn/v2/zhihuhot", None),
    ],
}


def _parse_items(source: str, payload: dict) -> list[dict]:
    if payload.get("success") is False:
        return []

    # vvhan: { success, data: [{title, url, hot}] }
    if isinstance(payload.get("data"), list) and payload["data"]:
        first = payload["data"][0]
        if isinstance(first, dict) and "title" in first:
            return [
                {
                    "source": source,
                    "title": item.get("title", ""),
                    "url": item.get("url", item.get("mobilUrl", "")),
                    "hot": str(item.get("hot", item.get("index", ""))),
                }
                for item in payload["data"]
                if item.get("title")
            ]

    # tenapi: { code: 200, data: [{title, url, hot}] }
    data = payload.get("data")
    if isinstance(data, list):
        return [
            {
                "source": source,
                "title": item.get("title", item.get("name", "")),
                "url": item.get("url", item.get("link", "")),
                "hot": str(item.get("hot", item.get("heat", ""))),
            }
            for item in data
            if item.get("title") or item.get("name")
        ]

    return []


def fetch_hotlist(source: str, limit: int = 15) -> list[dict]:
    for _name, url, params in PROVIDERS.get(source, []):
        try:
            resp = requests.get(url, params=params, timeout=15)
            resp.raise_for_status()
            items = _parse_items(source, resp.json())
            if items:
                return items[:limit]
        except (requests.RequestException, ValueError, KeyError):
            continue
    return []


def fetch_all(sources: list[str], top_n: int = 15) -> list[dict]:
    results: list[dict] = []
    for source in sources:
        results.extend(fetch_hotlist(source, top_n))
    return results
