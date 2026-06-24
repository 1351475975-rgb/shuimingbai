# Windows Open Interpreter 智能体搭建

## 任务目标
在 Windows 16GB 机器上搭建 Ollama + Open Interpreter 本地智能体，支持控电脑 + 自媒体写稿。

## 环境
- 系统：Windows 10
- 内存：16GB
- Ollama：已安装 `C:\Users\13915\AppData\Local\Programs\Ollama\ollama.exe`
- Python：3.12

## 步骤
- [ ] 确认 Ollama 服务运行 + 选择合适模型
- [ ] 安装 Open Interpreter
- [ ] 创建启动脚本和配置
- [ ] 验证智能体可对话并执行命令

## 模型选择（16GB Windows）
- 推荐：`qwen3:8b`（~5GB，中文好，智能体够用）
- 备选：`qwen2.5:7b`（更轻）
- 不推荐：`qwen3.6:27b`（~17GB，16GB 系统会卡死）

## 关键路径
- 启动脚本：`scripts/start-agent.ps1`
- Ollama API：`http://localhost:11434/v1`

## 当前进度
正在检查环境和已装模型。
