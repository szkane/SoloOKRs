<p align="center">
  <img src="../src/SoloOKRs/SoloOKRs/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" height="128" alt="SoloOKRs アイコン">
</p>

<h1 align="center">SoloOKRs</h1>

<p align="center">
  <strong>macOS 用のパーソナル OKR 管理アプリ — AI アシスタンスと MCP 統合を内蔵</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-blue?logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/swift-6.0-orange?logo=swift" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/UI-SwiftUI-purple" alt="SwiftUI">
  <img src="https://img.shields.io/badge/license-CC%20BY--NC--ND%204.0-lightgrey" alt="License">
</p>

---

## ✨ SoloOKRs とは？

SoloOKRs は、**OKR（Objectives and Key Results）フレームワーク**を用いてパーソナルゴールを管理するための**ネイティブ macOS アプリケーション**です。チーム向けの OKR ツールとは異なり、SoloOKRs は OPC（One Person Company）創設者や個人向けに設計されており、集中できて気晴らしのない環境で個人の目標を設定・追跡・振り返ることができます。このプロジェクトは Google Antigravity との vibe-coding ワークフローで構築されました。

AI の時代において、SoloOKRs は**人間と AI Agent の間の架け橋**でもあります — 目標を AI アシスタントと同期し、AI による目標設定、進捗追跡、キー結果の達成、振り返りを支援するためのツールです。

特別な機能：

- 🧠 **AI パワーアシスタンス** — 目標の精緻化、キー結果の分解、進捗の振り返りにおける AI 提案の活用
- 🔌 **MCP サーバー** — Model Context Protocol を通じて Claude Desktop などの AI アシスタントに OKR データを公開
- 📊 **レビューモード** — 定期的な OKR 振り返りための構造化されたワークフロー
- ☁️ **iCloud 同期** — Mac デバイス間でシームレスにデータを同期
- 🌍 **9 か国語** — リアルタイムでの言語切替に対応した完全な多言語サポート

---

## 🌐 翻訳

この README は世界中の開発者を支援するため、複数の言語で利用可能です：

| 言語           | リンク                                     |
| -------------- | ------------------------------------------ |
| 英語           | [README.md](README.md)                     |
| 简体中文       | [docs/README_zh.md](docs/README_zh.md)     |
| 日本語         | [docs/README_ja.md](docs/README_ja.md)     |
| 한국어         | [docs/README_ko.md](docs/README_ko.md)     |
| Deutsch        | [docs/README_de.md](docs/README_de.md)     |
| Français       | [docs/README_fr.md](docs/README_fr.md)     |
| Español        | [docs/README_es.md](docs/README_es.md)     |
| Português (BR) | [docs/README_ptBR.md](docs/README_ptBR.md) |

---

## 🎯 機能

### コア OKR 管理

| 機能                        | 説明                                                                       |
| --------------------------- | -------------------------------------------------------------------------- |
| **Objectives（目標）**      | 進捗追跡付きで目標の作成・編集・アーカイブ                                 |
| **Key Results（キー結果）** | 異なるタイプ（パーセント、数値、マイルストーン）で測定可能なキー結果を定義 |
| **Tasks（タスク）**         | Markdown 説明文で Key Results を実行可能なタスクに分解                     |
| **Archives（アーカイブ）**  | 完了した目標をトロフィーマーク付きのアーカイブセクションへ                 |
| **Drag & Drop**             | ドラッグ＆ドロップで目標と Key Results の順序を並び替え                    |

### 🧠 AI 統合

SoloOKRs には、OKR ライフサイクルのすべての段階で支援するビルトイン AI アシスタントが搭載されています：

**対応プロバイダー：**

| プロバイダー  | タイプ | 説明                                       |
| ------------- | ------ | ------------------------------------------ |
| **Gemini**    | Cloud  | Google の Gemini モデル                    |
| **OpenAI**    | Cloud  | GPT-4o およびその他の OpenAI モデル        |
| **Anthropic** | Cloud  | Claude モデル                              |
| **Ollama**    | Local  | ローカル LLM の実行（Llama、Mistral など） |
| **LM Studio** | Local  | ローカルモデル推論サーバー                 |

**使用方法：**

1. **設定 → AI** を開き、希望のプロバイダーを選択
2. API キーを入力（macOS Keychain に安全に保存）
3. ローカルプロバイダー（Ollama/LM Studio）の場合、マシン上でサーバーが実行中であることを確認
4. 目標および Key Results 画面上の AI スパークルボタン（✦）を使用して提案を取得
5. AI のレスポンスには**思考ブロック**の可視化が含まれます — AI の推論プロセスを表示する折りたたみ式ブロック

### 🔌 MCP サーバー（Model Context Protocol）

SoloOKRs にはビルトインの **MCP サーバー**が搭載されており、外部の AI アシスタントに OKR データを公開します。これにより、**Claude Desktop** などのツールが直接目標の読み書きを行えるようになります。

**トランスポートオプション：**

| トランスポート          | プロトコル                | ユースケース                                   |
| ----------------------- | ------------------------- | ---------------------------------------------- |
| **HTTP**                | `http://localhost:<port>` | ユニバーサルアクセス、ウェブベースのツール     |
| **Unix Domain Sockets** | `/tmp/solookrs.sock`      | Claude Desktop、ローカルツール（低レイテンシ） |

**利用可能な MCP ツール（12 種類）：**

| カテゴリ        | ツール                                                                                         |
| --------------- | ---------------------------------------------------------------------------------------------- |
| **Objectives**  | `list_objectives`, `get_objective`, `create_objective`, `update_objective`, `delete_objective` |
| **Key Results** | `list_key_results`, `update_key_result`                                                        |
| **Tasks**       | `list_tasks`, `create_task`, `update_task`                                                     |
| **Reviews**     | `list_reviews`, `get_review`, `create_review`                                                  |

**Claude Desktop 統合：**

SoloOKRs を Claude Desktop と接続するには、Claude Desktop の設定ファイル（`~/Library/Application Support/Claude/claude_desktop_config.json`）に以下を追加します：

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

または HTTP トランスポートの場合：

```json
{
  "mcpServers": {
    "solookrs": {
      "url": "http://localhost:8716"
    }
  }
}
```

**有効化方法：**

1. **設定 → MCP** を開く
2. MCP サーバーをオンに切り替え
3. トランスポートを選択（HTTP または Unix Socket）
4. 上記の接続詳細で Claude Desktop を設定
5. サイドバーのステータスインジケーターで接続状態を確認

### 📊 レビューモード

SoloOKRs には構造化された**振り返り（レビュー）**ワークフローが搭載されています：

1. **レビューの作成** — 目標を選択しレビューエントリを生成
2. **KR アセスメント** — 各 Key Result の進捗をノート付きで評価
3. **AI サマリー** — オプションで AI によるレビューサマリーを生成
4. **レビュー履歴** — 過去のレビューを閲覧し、時系列で振り返り
5. **Markdown ノート** — 完全な Markdown + コード構文強調付きのリッチなレビューノートを作成

### 🎨 カスタマイズ可能な AI プロンプト

**設定 → プロンプト** で AI の動作をカスタマイズ：

- 目標提案用のシステムプロンプトをカスタマイズ
- Key Result 生成プロンプトを調整
- レビューサマリープロンプトテンプレートを変更
- 全プロンプトで Markdown フォーマットに対応

---

## 🏗 アーキテクチャ

```
SoloOKRs/
├── Models/           # SwiftData モデル定義
│   ├── Objective     # トップレベルの目標
│   ├── KeyResult     # 測定可能な成果
│   ├── OKRTask       # 実行可能なアイテム
│   ├── OKRReview     # レビューセッション
│   └── KRReviewEntry # 各 KR ごとのレビューエントリ
├── Views/
│   ├── Objectives/   # サイドバー — 目標リスト＆管理
│   ├── KeyResults/   # 中央カラム — KR カード＆作成
│   ├── Tasks/        # 詳細カラム — タスクリスト＆エディタ
│   ├── Reviews/      # レビュー作成＆履歴
│   ├── Settings/     # 設定タブ（General, AI, Prompts, MCP, Sync）
│   └── Components/   # 共有コンポーネント（AIResponseView, MarkdownEditor）
├── Services/
│   ├── AIProvider/   # AIService, PromptManager, provider 抽象化
│   └── MCPServer/    # SwiftNIO ベースの MCP サーバー（HTTP + UDS）
└── Utilities/        # Keychain, Markdown パース構文強調
```

**UI レイアウト：** 3 カラムの `NavigationSplitView`

- **カラム 1（サイドバー）：** ステータスバー付きの目標リスト（AI/MCP/同期インジケーター）
- **カラム 2（コンテンツ）：** 選択された目標の Key Results
- **カラム 3（詳細）：** 選択された Key Result のタスク

**永続化：** CloudKit 自動同期付き SwiftData

---

## 🌍 ローカライゼーション

SoloOKRs はリアルタイム切替に対応した**9 か国語**をサポートしています（再起動不要）：

| 言語                    | コード    |
| ----------------------- | --------- |
| 英語                    | `en`      |
| 中国語（簡体字）        | `zh-Hans` |
| 中国語（繁体字）        | `zh-Hant` |
| 日本語                  | `ja`      |
| 韓国語                  | `ko`      |
| ドイツ語                | `de`      |
| フランス語              | `fr`      |
| スペイン語              | `es`      |
| ポルトガル語 - ブラジル | `pt-BR`   |

**設定 → 一般 → アプリの言語** で言語を変更できます。

---

## 🚀 始め方

### 要件

- macOS 14.0 (Sonoma) 以降
- Xcode 16.0 以降
- Apple Developer アカウント（CloudKit 同期用）

### ビルド＆実行

```bash
# リポジトリをクローン
git clone https://github.com/your-username/SoloOKRs.git
cd SoloOKRs

# ビルド
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build -destination 'platform=macOS,arch=arm64'

# または Xcode で開く
open src/SoloOKRs/SoloOKRs.xcodeproj
```

### テストの実行

```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs test -destination 'platform=macOS,arch=arm64'
```

---

## 🛡 セキュリティ

- **API キー** は `kSecUseDataProtectionKeychain` を使用して macOS **Keychain** に保存
- **テレメトリなし** — すべてのデータはデバイスと iCloud のみに留まる
- **ローカル AI** — Ollama と LM Studio のサポートにより、OKR データはマシンの外に出ない

---

## 🙏 謝辞

以下の優れたオープンソースライブラリを使用して構築されています：

- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) — SwiftUI での Markdown レンダリング
- [Splash](https://github.com/JohnSundell/Splash) — コードのシンタックスハイライト
- [SwiftNIO](https://github.com/apple/swift-nio) — イベント駆動型ネットワーキングフレームワーク

---

## 📄 ライセンス

本プロジェクトは、**Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License (CC BY-NC-ND 4.0)** の下にライセンスされています。

### 許諾される行為：

- **共有** — あらゆるメディアまたはフォーマットで素材をコピーし、再配布する

### 以下の条件に従う必要があります：

- **表示** — 適切なクレジットを付与し、ライセンスへのリンクを記載し、変更した場合はその旨を示す
- **非商業利用** — 素材を商業目的で**使用できません**
- **改変禁止** — 素材の翻案、変形、または再利用をした場合でも、変更された素材を**再配布できません**

### ⚠️ 商業利用は厳しく禁止されています

これらに限定されません：

- 利益を目的としてアプリケーションを販売または配布すること
- 商用製品やサービスでコードベースを使用すること
- 本ソフトウェアに基づいた有料サービスの提供

完全なライセンステキストはこちら：https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode

---

<p align="center">
  Made with ❤️ for personal productivity
</p>
