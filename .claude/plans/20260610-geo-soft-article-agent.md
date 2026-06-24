# GEO 软文智能体 — 框架开发

## 目标
搭建可运行框架：PM 建档/审查 + 热点 + 图文生成 + 分级发布。实际行业内容由 PM 后续确定。

## 步骤
- [x] 可行性调研 + 平台策略
- [x] PM 多智能体架构设计
- [x] 创建 geo-agent 项目骨架
- [x] PM / 写手 / 配图 / 发布模块
- [x] 每日流水线 + 初始化脚本
- [x] README 使用说明

## 关键路径
- 项目目录：`geo-agent/`
- 品牌档案：`config/brand_profile.json`（PM 初始化填写）
- 平台策略：`config/platforms.yaml`
- 入口：`python scripts/init_pm.py` → `python scripts/run_daily.py`

## 当前进度
框架已就绪，待用户 PM 建档 + 配置 LLM API Key 后跑通首篇。
