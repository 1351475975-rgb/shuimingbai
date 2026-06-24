# GEO 软文智能体框架

多智能体流水线：**项目经理（PM）建档与合规审查** → 热点选题 → 写文 → 配图 → 分级发布。

实际行业/产品内容**由 PM 建档后确定**；框架可先搭好，后续再填品牌档案。

## 架构

```
你 ←→ 项目经理（PM）
         ├ init_pm.py 建档
         ├ 每日选题审核
         └ 发稿合规审查（不合规打回重写）
              ↓
         热点 → 写手 → 配图 → 发布
```

## 平台策略

| 档位 | 行为 |
|------|------|
| ★★★★★ 小红书/抖音/快手/视频号 | **仅生成**图文素材，不自动发 |
| ★★★★ 知乎/微博等 | 生成 + 草稿，不自动点发布 |
| ★★–★★★ 技术社区/资讯号 | 生成草稿素材（文件输出） |
| WordPress | 配置了 API 则自动发草稿 |

配置见 `config/platforms.yaml`。

## 快速开始

```powershell
cd geo-agent
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
# 编辑 .env 填入 LLM_API_KEY（DeepSeek 等）
```

### 1. PM 建档（首次必做）

```powershell
python scripts/init_pm.py
```

填写行业、产品、红线等 → `config/brand_profile.json` 状态变为 `ready`。

### 2. 每日跑一篇

```powershell
python scripts/run_daily.py
```

输出目录 `output/YYYY-MM-DD/`：

```
output/2026-06-10/
├── hotspots.json       # 今日热榜
├── pm_topic.json       # PM 选题决定
├── pm_review_0.json    # PM 合规审查
├── article.md          # 主文 Markdown
├── article.json
├── images/             # 封面+配图+小红书竖图
├── platforms/          # 各平台适配文案
├── manifest.json       # 图文清单
└── publish_log.json    # 发布结果
```

### 3. 查看 PM 状态

```powershell
python scripts/pm_status.py
```

## 环境变量

| 变量 | 说明 |
|------|------|
| `LLM_API_KEY` | 必填，DeepSeek / 通义等 OpenAI 兼容 API |
| `LLM_BASE_URL` | 默认 `https://api.deepseek.com` |
| `LLM_MODEL` | 默认 `deepseek-chat` |
| `PEXELS_API_KEY` | 可选，不配则生成文字占位图 |
| `WORDPRESS_*` | 可选，WordPress 自动草稿 |

## 后续扩展

- [ ] 微信公众号 API 草稿上传
- [ ] 通义万相 AI 生图
- [ ] Windows 任务计划程序每日 8:00 触发
- [ ] PM 对话式更新品牌档案（Web/CLI）

## 成本参考

日产 1 篇：DeepSeek V4-Flash 约 ¥0.01/篇 + Pexels 免费图。
