<p align="center">
  <img src="../src/SoloOKRs/SoloOKRs/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" height="128" alt="SoloOKRs Icon">
</p>

<h1 align="center">SoloOKRs</h1>

<p align="center">
  <strong>Eine persönliche OKR-Management-App für macOS — mit integrierter KI-Assistenz & MCP-Integration</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-blue?logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/swift-6.0-orange?logo=swift" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/UI-SwiftUI-purple" alt="SwiftUI">
  <img src="https://img.shields.io/badge/license-CC%20BY--NC--ND%204.0-lightgrey" alt="License">
</p>

---

## ✨ Was ist SoloOKRs?

SoloOKRs ist eine **native macOS-Anwendung** zur Verwaltung persönlicher Ziele mithilfe des **OKR (Objectives and Key Results)**-Frameworks. Im Gegensatz zu teamorientierten OKR-Tools ist SoloOKRs für OPC (One Person Company) Gründer und Einzelpersonen konzipiert, die eine fokussierte, ablenkungsfreie Umgebung wünschen, um persönliche Ziele zu setzen, zu verfolgen und zu reflektieren. Dieses Projekt wurde in einem Vibe-Coding-Workflow mit Google Antigravity entwickelt.

Im Zeitalter der KI ist SoloOKRs auch eine **Brücke zwischen Menschen und KI-Agenten** — ein Tool, das hilft, Ihre Ziele mit KI-Assistenten in Einklang zu bringen, damit diese Ihnen dabei helfen können, Ziele zu setzen, Fortschritt zu verfolgen, Schlüsselergebnisse zu erreichen und Reflexionen durchzuführen.

Was es besonders macht:

- 🧠 **KI-gestützte Assistenz** — Erhalten Sie KI-Vorschläge zur Verfeinerung von Zielen, zur Aufschlüsselung von Schlüsselergebnissen und zur Fortschrittsüberprüfung
- 🔌 **MCP-Server** — Stellen Sie Ihre OKR-Daten KI-Assistenten wie Claude Desktop über das Model Context Protocol zur Verfügung
- 📊 **Review-Modus** — Eingebauter Retrospektive-Workflow für regelmäßige OKR-Überprüfungen
- ☁️ **iCloud-Sync** — Nahtlose Datensynchronisation über alle Ihre Mac-Geräte hinweg
- 🌍 **9 Sprachen** — Vollständige mehrsprachige Unterstützung mit Echtzeit-Sprachwechsel

---

## 🌐 Übersetzungen

Dieses README ist in mehreren Sprachen verfügbar, um Entwicklern weltweit zu helfen:

| Sprache            | Link                                       |
| ------------------ | ------------------------------------------ |
| Englisch           | [README.md](README.md)                     |
| 简体中文           | [docs/README_zh.md](docs/README_zh.md)     |
| 日本語             | [docs/README_ja.md](docs/README_ja.md)     |
| 한국어             | [docs/README_ko.md](docs/README_ko.md)     |
| Deutsch            | [docs/README_de.md](docs/README_de.md)     |
| Französisch        | [docs/README_fr.md](docs/README_fr.md)     |
| Spanisch           | [docs/README_es.md](docs/README_es.md)     |
| Portugiesisch (BR) | [docs/README_ptBR.md](docs/README_ptBR.md) |

---

## 🎯 Funktionen

### Kern-OKR-Verwaltung

| Funktion                              | Beschreibung                                                                                         |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **Ziele (Objectives)**                | Erstellen, bearbeiten und archivieren Sie Ziele mit Fortschrittsverfolgung                           |
| **Schlüsselergebnisse (Key Results)** | Definieren Sie messbare Schlüsselergebnisse mit verschiedenen Typen (Prozentsatz, Zahl, Meilenstein) |
| **Aufgaben**                          | Schließen Sie Schlüsselergebnisse in umsetzbare Aufgaben mit Markdown-Beschreibungen auf             |
| **Archiv**                            | Archiveren Sie abgeschlossene Ziele mit einem mit Trophäen markierten Archivbereich                  |
| **Drag & Drop**                       | Sortieren Sie Ziele und Schlüsselergebnisse per Drag-and-Drop                                        |

### 🧠 KI-Integration

SoloOKRs enthält einen integrierten KI-Assistenten, der Sie bei jedem Schritt des OKR-Lebenszyklus unterstützen kann:

**Unterstützte Anbieter:**

| Anbieter      | Typ   | Beschreibung                                 |
| ------------- | ----- | -------------------------------------------- |
| **Gemini**    | Cloud | Googles Gemini-Modelle                       |
| **OpenAI**    | Cloud | GPT-4o und andere OpenAI-Modelle             |
| **Anthropic** | Cloud | Claude-Modelle                               |
| **Ollama**    | Lokal | Lokale LLMs ausführen (Llama, Mistral, usw.) |
| **LM Studio** | Lokal | Lokaler Modell-Inferenz-Server               |

**So verwenden Sie es:**

1. Öffnen Sie **Einstellungen → KI** und wählen Sie Ihren bevorzugten Anbieter
2. Geben Sie Ihren API-Schlüssel ein (sicher im macOS Schlüsselbund gespeichert)
3. Stellen Sie bei lokalen Anbietern (Ollama/LM Studio) sicher, dass der Server auf Ihrem Rechner läuft
4. Verwenden Sie den KI-Funkensymbol-Button (✦) in den Objective- und Key-Result-Ansichten, um Vorschläge zu erhalten
5. KI-Antworten enthalten eine **Thinking-Block**-Visualisierung — aufklappbare Blöcke, die den Denkprozess der KI zeigen

### 🔌 MCP-Server (Model Context Protocol)

SoloOKRs enthält einen integrierten **MCP-Server**, der Ihre OKR-Daten für externe KI-Assistenten verfügbar macht. Dies ermöglicht Tools wie **Claude Desktop**, Ihre Ziele direkt zu lesen und zu manipulieren.

**Transport-Optionen:**

| Transport               | Protokoll                 | Anwendungsfall                                  |
| ----------------------- | ------------------------- | ----------------------------------------------- |
| **HTTP**                | `http://localhost:<port>` | Universeller Zugriff, webbasierte Tools         |
| **Unix Domain Sockets** | `/tmp/solookrs.sock`      | Claude Desktop, lokale Tools (geringere Latenz) |

**Verfügbare MCP-Tools (12 Tools):**

| Kategorie                             | Tools                                                                                          |
| ------------------------------------- | ---------------------------------------------------------------------------------------------- |
| **Ziele (Objectives)**                | `list_objectives`, `get_objective`, `create_objective`, `update_objective`, `delete_objective` |
| **Schlüsselergebnisse (Key Results)** | `list_key_results`, `update_key_result`                                                        |
| **Aufgaben (Tasks)**                  | `list_tasks`, `create_task`, `update_task`                                                     |
| **Überprüfungen (Reviews)**           | `list_reviews`, `get_review`, `create_review`                                                  |

**Claude Desktop-Integration:**

Um SoloOKRs mit Claude Desktop zu verbinden, fügen Sie folgendes in Ihre Claude Desktop-Konfiguration (`~/Library/Application Support/Claude/claude_desktop_config.json`) ein:

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

Oder für HTTP-Transport:

```json
{
  "mcpServers": {
    "solookrs": {
      "url": "http://localhost:8716"
    }
  }
}
```

**So aktivieren Sie es:**

1. Öffnen Sie **Einstellungen → MCP**
2. Schalten Sie den MCP-Server ein
3. Wählen Sie Ihren Transport (HTTP oder Unix Socket)
4. Konfigurieren Sie Claude Desktop mit den obigen Verbindungsdetails
5. Die Statusanzeige in der Seitenleiste zeigt den Verbindungsstatus an

### 📊 Review-Modus

SoloOKRs enthält einen strukturierten **Review-/Retrospektive**-Workflow:

1. **Review erstellen** — Wählen Sie ein Ziel und generieren Sie einen Review-Eintrag
2. **KR-Bewertung** — Bewerten Sie den Fortschritt jedes Schlüsselergebnisses mit Notizen
3. **KI-Zusammenfassung** — Generieren Sie optional eine KI-gestützte Review-Zusammenfassung
4. **Review-Verlauf** — Durchsuchen und besuchen Sie vergangene Reviews im Laufe der Zeit
5. **Markdown-Notizen** — Schreiben Sie umfangreiche Review-Notizen mit voller Markdown- und Code-Syntax-Hervorhebung

### 🎨 Anpassbare KI-Prompts

Passen Sie das Verhalten der KI über **Einstellungen → Prompts** an:

- Passen Sie System-Prompts für Zielvorschläge an
- Passen Sie Prompts zur Generierung von Schlüsselergebnissen an
- Passen Sie Review-Zusammenfassungs-Prompt-Vorlagen an
- Alle Prompts unterstützen Markdown-Formatierung

---

## 🏗 Architektur

```
SoloOKRs/
├── Models/           # SwiftModel-Definitionen
│   ├── Objective     # Ziele auf oberster Ebene
│   ├── KeyResult     # Messbare Ergebnisse
│   ├── OKRTask       # Umsetzbare Aufgaben
│   ├── OKRReview     # Review-Sessions
│   └── KRReviewEntry # Pro-KR Review-Einträge
├── Views/
│   ├── Objectives/   # Seitenleiste — Objektive auflisten & verwalten
│   ├── KeyResults/   # Mittlere Spalte — KR-Karten & Erstellung
│   ├── Tasks/        # Detailspalte — Aufgabenliste & Editoren
│   ├── Reviews/      # Review-Erstellung & Verlauf
│   ├── Settings/     # Einstellungstabs (Allgemein, KI, Prompts, MCP, Sync)
│   └── Components/   # Shared Components (AIResponseView, MarkdownEditor)
├── Services/
│   ├── AIProvider/   # AIService, PromptManager, Provider-Abstraktionen
│   └── MCPServer/    # SwiftNIO-basierter MCP-Server (HTTP + UDS)
└── Utilities/        # Schlüsselbund, Markdown-Parsing, Syntax-Hervorhebung
```

**UI-Layout:** 3-spaltiger `NavigationSplitView`

- **Spalte 1 (Seitenleiste):** Objektive-Liste mit Statusleiste (KI/MCP/Sync-Anzeigen)
- **Spalte 2 (Inhalt):** Schlüsselergebnisse für das ausgewählte Ziel
- **Spalte 3 (Detail):** Aufgaben für das ausgewählte Schlüsselergebnis

**Datenspeicherung:** SwiftData mit CloudKit-Automatisch-Sync

---

## 🌍 Lokalisierung

SoloOKRs unterstützt **9 Sprachen** mit Echtzeit-Wechsel (kein Neustart erforderlich):

| Sprache                               | Code      |
| ------------------------------------- | --------- |
| Englisch                              | `en`      |
| Chinesisch (Vereinfacht) (简体中文)   | `zh-Hans` |
| Chinesisch (Traditionell) (繁體中文)  | `zh-Hant` |
| Japanisch (日本語)                    | `ja`      |
| Koreanisch (한국어)                   | `ko`      |
| Deutsch                               | `de`      |
| Französisch (Français)                | `fr`      |
| Spanisch (Español)                    | `es`      |
| Portugiesisch – Brasilien (Português) | `pt-BR`   |

Sprache ändern über **Einstellungen → Allgemein → App-Sprache**.

---

## 🚀 Erste Schritte

### Voraussetzungen

- macOS 14.0 (Sonoma) oder später
- Xcode 16.0 oder später
- Apple Developer-Konto (für CloudKit-Sync)

### Erstellen & Ausführen

```bash
# Repository klonen
git clone https://github.com/your-username/SoloOKRs.git
cd SoloOKRs

# Erstellen
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build -destination 'platform=macOS,arch=arm64'

# Oder in Xcode öffnen
open src/SoloOKRs/SoloOKRs.xcodeproj
```

### Tests ausführen

```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs test -destination 'platform=macOS,arch=arm64'
```

---

## 🛡 Sicherheit

- **API-Schlüssel** werden im macOS **Schlüsselbund** mit `kSecUseDataProtectionKeychain` gespeichert
- **Kein Telemetry** — alle Daten verbleiben auf Ihrem Gerät und in iCloud
- **Lokale KI** — Ollama- und LM-Studio-Unterstützung bedeutet, dass Ihre OKR-Daten Ihren Rechner nie verlassen

---

## 🙏 Danksagungen

Erstellt mit diesen ausgezeichneten Open-Source-Bibliotheken:

- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) — Markdown-Rendering in SwiftUI
- [Splash](https://github.com/JohnSundell/Splash) — Code-Syntax-Hervorhebung
- [SwiftNIO](https://github.com/apple/swift-nio) — Event-getriebenes Netzwerkframework

---

## 📄 Lizenz

Dieses Projekt steht unter der **Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License (CC BY-NC-ND 4.0)**.

### Sie dürfen:

- **Teilen** — das Material in jedem Medium oder Format kopieren und weiterverbreiten

### Folgendermaßen Sie zustimmen:

- **Namensnennung** — Sie müssen eine angemessene Credit geben, einen Link zur Lizenz hinzufügen und angeben, ob Änderungen vorgenommen wurden
- **Nicht-kommerziell** — Sie dürfen das Material **nicht** für kommerzielle Zwecke verwenden
- **Keine Bearbeitung** — Wenn Sie das Material abwandeln, transformieren oder darauf aufbauen, dürfen Sie das **veränderte Material nicht verteilen**

### ⚠️ Kommerzielle Nutzung ist streng verboten

Dies umfasst unter anderem:

- Verkauf oder Verbreitung der Anwendung zum Gewinn
- Verwendung der Codebasis in kommerziellen Produkten oder Diensten
- Angebot bezahlter Dienstleistungen auf Basis dieser Software

Für den vollständigen Lizenztext, siehe: https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode

---

<p align="center">
  Erstellt mit ❤️ für persönliche Produktivität
</p>
