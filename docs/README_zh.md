<p align="center">
  <img src="../src/SoloOKRs/SoloOKRs/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" height="128" alt="SoloOKRs Icon">
</p>

<h1 align="center">SoloOKRs</h1>

<p align="center">
  <strong>一款面向 macOS 的个人 OKR 管理应用 —— 内置 AI 辅助与 MCP 集成</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-blue?logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/swift-6.0-orange?logo=swift" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/UI-SwiftUI-purple" alt="SwiftUI">
  <img src="https://img.shields.io/badge/license-CC%20BY--NC--ND%204.0-lightgrey" alt="License">
</p>

---

## ✨ SoloOKRs 是什么？

SoloOKRs 是一款**原生 macOS 应用程序**，使用**OKR（目标与关键结果）**框架来管理个人目标。与面向团队的 OKR 工具不同，SoloOKRs 专为 OPC（一人公司）创始人和个人用户设计，提供一个专注、无干扰的环境来设定、追踪和回顾个人目标。本项目采用与 Google Antigravity 合作 vibe-coding 方式构建。

在 AI 时代，SoloOKRs 也是**人类与 AI Agent 之间的桥梁** —— 一个帮助你将目标与 AI 助手对齐的工具，让 AI 协助你制定目标、跟踪进度、完成关键结果和进行复盘。

它的独特之处：

- 🧠 **AI 智能辅助** — 获取 AI 建议，用于优化目标、拆解关键结果和回顾进展
- 🔌 **MCP 服务器** — 通过模型上下文协议（Model Context Protocol）将你的 OKR 数据暴露给 Claude Desktop 等 AI 助手
- 📊 **回顾模式** — 内置周期性 OKR 回顾的工作流
- ☁️ **iCloud 同步** — 在你的 Mac 设备间无缝同步数据
- 🌍 **9 种语言** — 完整的多语言支持，可实时切换语言

---

## 🌐 多语言版本

为了帮助全球的开发者，本 README 提供多种语言版本：

| 语言             | 链接                                       |
| ---------------- | ------------------------------------------ |
| 英语             | [README.md](README.md)                     |
| 简体中文         | [docs/README_zh.md](docs/README_zh.md)     |
| 日本語           | [docs/README_ja.md](docs/README_ja.md)     |
| 한국어           | [docs/README_ko.md](docs/README_ko.md)     |
| Deutsch          | [docs/README_de.md](docs/README_de.md)     |
| Français         | [docs/README_fr.md](docs/README_fr.md)     |
| Español          | [docs/README_es.md](docs/README_es.md)     |
| 葡萄牙语（巴西） | [docs/README_ptBR.md](docs/README_ptBR.md) |

---

## 🎯 功能特性

### 核心 OKR 管理

| 功能                        | 说明                                                       |
| --------------------------- | ---------------------------------------------------------- |
| **目标（Objectives）**      | 创建、编辑和归档目标，支持进度追踪                         |
| **关键结果（Key Results）** | 定义可衡量的关键结果，支持多种类型（百分比、数值、里程碑） |
| **任务（Tasks）**           | 将关键结果拆解为可执行的任务，支持 Markdown 描述           |
| **归档（Archives）**        | 将已完成的目标归档，归档区域带有奖杯标记                   |
| **拖放（Drag & Drop）**     | 支持拖放调整目标和关键结果的顺序                           |

### 🧠 AI 集成

SoloOKRs 内置 AI 助手，可以在 OKR 生命周期的每个阶段为你提供协助：

**支持的提供商：**

| 提供商        | 类型 | 说明                              |
| ------------- | ---- | --------------------------------- |
| **Gemini**    | 云端 | Google 的 Gemini 模型             |
| **OpenAI**    | 云端 | GPT-4o 等 OpenAI 模型             |
| **Anthropic** | 云端 | Claude 模型                       |
| **Ollama**    | 本地 | 运行本地 LLM（Llama、Mistral 等） |
| **LM Studio** | 本地 | 本地模型推理服务器                |

**使用方法：**

1. 打开 **设置 → AI**，选择你偏好的提供商
2. 输入 API 密钥（安全存储在 macOS 钥匙串中）
3. 对于本地提供商（Ollama/LM Studio），请确保服务器在本地运行
4. 在目标和关键结果视图中使用 AI 闪光灯按钮（✦）获取建议
5. AI 回复支持**思考块**可视化 —— 可折叠的区块展示 AI 的推理过程

### 🔌 MCP 服务器（模型上下文协议）

SoloOKRs 内置了 **MCP 服务器**，可将你的 OKR 数据暴露给外部 AI 助手。这使得 **Claude Desktop** 等工具可以直接读取和操作你的目标。

**传输选项：**

| 传输方式          | 协议                      | 使用场景                             |
| ----------------- | ------------------------- | ------------------------------------ |
| **HTTP**          | `http://localhost:<port>` | 通用访问，基于 Web 的工具            |
| **Unix 域套接字** | `/tmp/solookrs.sock`      | Claude Desktop、本地工具（延迟更低） |

**可用的 MCP 工具（共 12 个）：**

| 分类         | 工具                                                                                           |
| ------------ | ---------------------------------------------------------------------------------------------- |
| **目标**     | `list_objectives`、`get_objective`、`create_objective`、`update_objective`、`delete_objective` |
| **关键结果** | `list_key_results`、`update_key_result`                                                        |
| **任务**     | `list_tasks`、`create_task`、`update_task`                                                     |
| **回顾**     | `list_reviews`、`get_review`、`create_review`                                                  |

**Claude Desktop 集成：**

要将 SoloOKRs 与 Claude Desktop 连接，请将以下内容添加到你的 Claude Desktop 配置（`~/Library/Application Support/Claude/claude_desktop_config.json`）：

```json
{
  "mcpServers": {
    "solookrs": {
      "command": "nc",
      "args": ["-U", "/tmp/solookrs.sock"]
    }
  }
}
```

或使用 HTTP 传输：

```json
{
  "mcpServers": {
    "solookrs": {
      "url": "http://localhost:8716"
    }
  }
}
```

**启用方法：**

1. 打开 **设置 → MCP**
2. 开启 MCP 服务器开关
3. 选择传输方式（HTTP 或 Unix 域套接字）
4. 根据上述连接信息配置 Claude Desktop
5. 侧边栏的状态指示器显示连接状态

### 📊 回顾模式

SoloOKRs 内置了结构化的**回顾/复盘**工作流：

1. **创建回顾** — 选择目标并生成回顾条目
2. **KR 评估** — 对每个关键结果的进度进行评分并添加备注
3. **AI 摘要** — 可选择生成 AI 驱动的回顾摘要
4. **回顾历史** — 浏览和回顾过往的回顾记录
5. **Markdown 笔记** — 使用完整的 Markdown + 代码语法高亮编写丰富的回顾笔记

### 🎨 自定义 AI 提示词

通过 **设置 → 提示词** 定制 AI 的行为：

- 自定义目标建议的系统提示词
- 调整关键结果生成提示词
- 修改回顾摘要提示词模板
- 所有提示词支持 Markdown 格式

---

## 🏗 项目架构

```
SoloOKRs/
├── Models/           # SwiftData 模型定义
│   ├── Objective     # 顶层目标
│   ├── KeyResult     # 可衡量的结果
│   ├── OKRTask       # 可执行的任务项
│   ├── OKRReview     # 回顾会话
│   └── KRReviewEntry # 每个 KR 的回顾条目
├── Views/
│   ├── Objectives/   # 侧边栏 — 目标列表与管理
│   ├── KeyResults/   # 中间栏 — KR 卡片与创建
│   ├── Tasks/        # 详情栏 — 任务列表与编辑器
│   ├── Reviews/      # 回顾创建与历史
│   ├── Settings/     # 设置标签页（通用、AI、提示词、MCP、同步）
│   └── Components/   # 共享组件（AIResponseView、MarkdownEditor）
├── Services/
│   ├── AIProvider/   # AIService、PromptManager、提供商抽象
│   └── MCPServer/    # 基于 SwiftNIO 的 MCP 服务器（HTTP + UDS）
└── Utilities/        # 钥匙串、Markdown 解析、语法高亮
```

**UI 布局：** 3 列 `NavigationSplitView`

- **第 1 列（侧边栏）：** 目标列表，带状态栏（AI/MCP/同步指示器）
- **第 2 列（内容）：** 选中目标的关键结果
- **第 3 列（详情）：** 选中关键结果的任务

**数据存储：** SwiftData 配合 CloudKit 自动同步

---

## 🌍 本地化

SoloOKRs 支持**9 种语言**，可实时切换（无需重启应用）：

| 语言             | 代码      |
| ---------------- | --------- |
| 英语             | `en`      |
| 简体中文         | `zh-Hans` |
| 繁体中文         | `zh-Hant` |
| 日语             | `ja`      |
| 韩语             | `ko`      |
| 德语             | `de`      |
| 法语             | `fr`      |
| 西班牙语         | `es`      |
| 葡萄牙语（巴西） | `pt-BR`   |

通过 **设置 → 通用 → 应用语言** 切换语言。

---

## 🚀 快速开始

### 前置要求

- macOS 14.0 (Sonoma) 或更高版本
- Xcode 16.0 或更高版本
- Apple Developer 账号（用于 CloudKit 同步）

### 构建与运行

```bash
# 克隆仓库
git clone https://github.com/your-username/SoloOKRs.git
cd SoloOKRs

# 构建
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build -destination 'platform=macOS,arch=arm64'

# 或在 Xcode 中打开
open src/SoloOKRs/SoloOKRs.xcodeproj
```

### 运行测试

```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs test -destination 'platform=macOS,arch=arm64'
```

---

## 🛡 安全

- **API 密钥** 存储在 macOS **钥匙串**中，使用 `kSecUseDataProtectionKeychain`
- **无遥测** — 所有数据仅保留在你的设备和 iCloud 上
- **本地 AI** — 支持 Ollama 和 LM Studio 意味着你的 OKR 数据永远不会离开你的机器

---

## 🙏 致谢

本项目使用了以下优秀的开源库：

- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) — SwiftUI 中的 Markdown 渲染
- [Splash](https://github.com/JohnSundell/Splash) — 代码语法高亮
- [SwiftNIO](https://github.com/apple/swift-nio) — 事件驱动的网络框架

---

## 📄 许可证

本项目采用 **Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License (CC BY-NC-ND 4.0)** 许可证。

### 你可以自由：

- **分享** — 以任何媒介或格式复制和分发材料

### 需遵循以下条件：

- **署名** — 你必须给出适当的署名，提供许可证链接，并标明是否作了修改
- **非商业性使用** — 你**不得**将材料用于商业目的
- **禁止演绎** — 如果你重新混合、转换或基于该材料创作，你**不得**分发修改后的材料

### ⚠️ 严格禁止商业使用

包括但不限于：

- 出售或以营利为目的分发该应用
- 在商业产品或服务中使用本代码库
- 基于本软件提供付费服务

完整许可证文本请参阅：https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode

---

<p align="center">
  为个人生产力而 ❤️ 打造
</p>
