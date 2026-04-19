<p align="center">
  <img src="../src/SoloOKRs/SoloOKRs/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" height="128" alt="SoloOKRs Icon">
</p>

<h1 align="center">SoloOKRs</h1>

<p align="center">
  <strong>Um app de gerenciamento de OKRs pessoais para macOS — com assistência de IA integrada e integração MCP</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-blue?logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/swift-6.0-orange?logo=swift" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/UI-SwiftUI-purple" alt="SwiftUI">
  <img src="https://img.shields.io/badge/license-CC%20BY--NC--ND%204.0-lightgrey" alt="License">
</p>

---

## ✨ O que é o SoloOKRs?

SoloOKRs é um **aplicativo nativo para macOS** para gerenciamento de metas pessoais usando a estrutura **OKR (Objectives and Key Results)**. Diferente das ferramentas de OKR voltadas para equipes, o SoloOKRs foi projetado para fundadores de OPC (One Person Company) e indivíduos que desejam um ambiente focado e sem distrações para definir, acompanhar e refletir sobre suas metas pessoais. Este projeto foi construído em um fluxo de vibe-coding com o Google Antigravity.

Na era da IA, o SoloOKRs é também uma **ponte entre humanos e agentes de IA** — uma ferramenta que ajuda a alinhar suas metas com assistentes de IA para que eles possam ajudá-lo a definir metas, acompanhar o progresso, completar resultados-chave e realizar retrospectivas.

O que o torna especial:

- 🧠 **Assistência com IA** — Receba sugestões da IA para refinar objetivos, dividir resultados-chave e revisar o progresso
- 🔌 **Servidor MCP** — Expuse seus dados de OKR para assistentes de IA como o Claude Desktop via Model Context Protocol
- 📊 **Modo de Revisão** — Fluxo de trabalho de retrospectiva integrado para revisões periódicas de OKR
- ☁️ **Sincronização com iCloud** — Sincronização perfeita de dados entre seus dispositivos Mac
- 🌍 **9 Idiomas** — Suporte completo a multilíngues com troca de idioma em tempo real

---

## 🌐 Traduções

Este README está disponível em vários idiomas para ajudar desenvolvedores ao redor do mundo:

| Idioma         | Link                                       |
| -------------- | ------------------------------------------ |
| Inglês         | [README.md](README.md)                     |
| 简体中文       | [docs/README_zh.md](docs/README_zh.md)     |
| 日本語         | [docs/README_ja.md](docs/README_ja.md)     |
| 한국어         | [docs/README_ko.md](docs/README_ko.md)     |
| Deutsch        | [docs/README_de.md](docs/README_de.md)     |
| Français       | [docs/README_fr.md](docs/README_fr.md)     |
| Español        | [docs/README_es.md](docs/README_es.md)     |
| Português (BR) | [docs/README_ptBR.md](docs/README_ptBR.md) |

---

## 🎯 Funcionalidades

### Gerenciamento Central de OKRs

| Funcionalidade        | Descrição                                                                             |
| --------------------- | ------------------------------------------------------------------------------------- |
| **Objetivos**         | Criar, editar e arquivar objetivos com acompanhamento de progresso                    |
| **Resultados-Chave**  | Definir resultados-chave mensuráveis com tipos diferentes (percentual, número, marco) |
| **Tarefas**           | Dividir resultados-chave em tarefas acionáveis com descrições em Markdown             |
| **Arquivos**          | Arquivar objetivos concluídos com uma seção de arquivos marcada com troféu            |
| **Arrastar e Soltar** | Reordenar objetivos e resultados-chave com arrastar e soltar                          |

### 🧠 Integração com IA

O SoloOKRs inclui um assistente de IA integrado que pode ajudá-lo em todas as etapas do ciclo de vida do OKR:

**Provedores Suportados:**

| Provedor      | Tipo  | Descrição                                   |
| ------------- | ----- | ------------------------------------------- |
| **Gemini**    | Nuvem | Modelos Gemini do Google                    |
| **OpenAI**    | Nuvem | GPT-4o e outros modelos da OpenAI           |
| **Anthropic** | Nuvem | Modelos Claude                              |
| **Ollama**    | Local | Executar LLMs locais (Llama, Mistral, etc.) |
| **LM Studio** | Local | Servidor local de inferência de modelos     |

**Como usar:**

1. Abra **Settings → AI** e selecione seu provedor preferido
2. Insira sua chave de API (armazenada com segurança no macOS Keychain)
3. Para provedores locais (Ollama/LM Studio), certifique-se de que o servidor está em execução na sua máquina
4. Use o botão de IA (✦) nas visualizações de objetivo e resultado-chave para obter sugestões
5. As respostas da IA incluem visualização de **bloco de raciocínio** — blocos expansíveis que mostram o processo de raciocínio da IA

### 🔌 Servidor MCP (Model Context Protocol)

O SoloOKRs inclui um **servidor MCP** integrado que expose seus dados de OKR para assistentes de IA externos. Isso permite que ferramentas como o **Claude Desktop** leiam e manipulem suas metas diretamente.

**Opções de Transporte:**

| Transporte              | Protocolo                 | Caso de Uso                                         |
| ----------------------- | ------------------------- | --------------------------------------------------- |
| **HTTP**                | `http://localhost:<port>` | Acesso universal, ferramentas baseadas na web       |
| **Unix Domain Sockets** | `/tmp/solookrs.sock`      | Claude Desktop, ferramentas locais (menor latência) |

**Ferramentas MCP Disponíveis (12 ferramentas):**

| Categoria            | Ferramentas                                                                                    |
| -------------------- | ---------------------------------------------------------------------------------------------- |
| **Objetivos**        | `list_objectives`, `get_objective`, `create_objective`, `update_objective`, `delete_objective` |
| **Resultados-Chave** | `list_key_results`, `update_key_result`                                                        |
| **Tarefas**          | `list_tasks`, `create_task`, `update_task`                                                     |
| **Revisões**         | `list_reviews`, `get_review`, `create_review`                                                  |

**Integração com Claude Desktop:**

Para conectar o SoloOKRs ao Claude Desktop, adicione o seguinte à configuração do Claude Desktop (`~/Library/Application Support/Claude/claude_desktop_config.json`):

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

Ou para transporte HTTP:

```json
{
  "mcpServers": {
    "solookrs": {
      "url": "http://localhost:8716"
    }
  }
}
```

**Como habilitar:**

1. Abra **Settings → MCP**
2. Ative o servidor MCP
3. Escolha seu transporte (HTTP ou Unix Socket)
4. Configure o Claude Desktop com os detalhes de conexão acima
5. O indicador de status na barra lateral mostra o estado da conexão

### 📊 Modo de Revisão

O SoloOKRs inclui um fluxo de trabalho de **revisão/retrospectiva** estruturado:

1. **Criar uma Revisão** — Selecione um objetivo e gere uma entrada de revisão
2. **Avaliação de KRs** — Classifique o progresso de cada resultado-chave com notas
3. **Resumo da IA** — Opcionalmente, gere um resumo de revisão com assistência da IA
4. **Histórico de Revisões** — Navegue e reveja revisões passadas ao longo do tempo
5. **Notas em Markdown** — Escreva notas de revisão ricas com Markdown completo + realce de sintaxe de código

### 🎨 Prompts de IA Personalizáveis

Personalize o comportamento da IA em **Settings → Prompts**:

- Personalize prompts do sistema para sugestões de objetivos
- Ajuste prompts de geração de resultados-chave
- Modifique modelos de prompt de resumo de revisão
- Todos os prompts suportam formatação Markdown

---

## 🏗 Arquitetura

```
SoloOKRs/
├── Models/           # Definições de modelos SwiftData
│   ├── Objective     # Metas de nível superior
│   ├── KeyResult     # Resultados mensuráveis
│   ├── OKRTask       # Itens acionáveis
│   ├── OKRReview     # Sessões de revisão
│   └── KRReviewEntry # Entradas de revisão por KR
├── Views/
│   ├── Objectives/   # Sidebar — Lista e gerenciamento de objetivos
│   ├── KeyResults/   # Coluna central — Cards de KR e criação
│   ├── Tasks/        # Coluna de detalhes — Lista de tarefas e editores
│   ├── Reviews/      # Criação e histórico de revisões
│   ├── Settings/     # Abas de configurações (General, AI, Prompts, MCP, Sync)
│   └── Components/   # Componentes compartilhados (AIResponseView, MarkdownEditor)
├── Services/
│   ├── AIProvider/   # AIService, PromptManager, abstrações de provedores
│   └── MCPServer/    # Servidor MCP baseado em SwiftNIO (HTTP + UDS)
└── Utilities/        # Keychain, parse de Markdown, realce de sintaxe
```

**Layout da UI:** `NavigationSplitView` de 3 colunas

- **Coluna 1 (Sidebar):** Lista de objetivos com barra de status (indicadores de IA/MCP/Sync)
- **Coluna 2 (Conteúdo):** Resultados-chave para o objetivo selecionado
- **Coluna 3 (Detalhe):** Tarefas para o resultado-chave selecionado

**Persistência:** SwiftData com sincronização automática via CloudKit

---

## 🌍 Localização

O SoloOKRs suporta **9 idiomas** com troca em tempo real (sem necessidade de reiniciar):

| Idioma                          | Código    |
| ------------------------------- | --------- |
| English                         | `en`      |
| Simplified Chinese (简体中文)   | `zh-Hans` |
| Traditional Chinese (繁體中文)  | `zh-Hant` |
| Japanese (日本語)               | `ja`      |
| Korean (한국어)                 | `ko`      |
| German (Deutsch)                | `de`      |
| French (Français)               | `fr`      |
| Spanish (Español)               | `es`      |
| Portuguese - Brazil (Português) | `pt-BR`   |

Altere o idioma em **Settings → General → App Language**.

---

## 🚀 Iniciando

### Pré-requisitos

- macOS 14.0 (Sonoma) ou posterior
- Xcode 16.0 ou posterior
- Conta de desenvolvedor Apple (para sincronização com iCloud)

### Compilar e Executar

```bash
# Clone o repositório
git clone https://github.com/your-username/SoloOKRs.git
cd SoloOKRs

# Compilar
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build -destination 'platform=macOS,arch=arm64'

# Ou abrir no Xcode
open src/SoloOKRs/SoloOKRs.xcodeproj
```

### Executar Testes

```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs test -destination 'platform=macOS,arch=arm64'
```

---

## 🛡 Segurança

- **Chaves de API** são armazenadas no **Keychain** do macOS usando `kSecUseDataProtectionKeychain`
- **Sem telemetria** — todos os dados permanecem no seu dispositivo e iCloud
- **IA Local** — O suporte a Ollama e LM Studio significa que seus dados de OKR nunca saem da sua máquina

---

## 🙏 Agradecimentos

Construído com estas excelentes bibliotecas de código aberto:

- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) — Renderização de Markdown em SwiftUI
- [Splash](https://github.com/JohnSundell/Splash) — Realce de sintaxe de código
- [SwiftNIO](https://github.com/apple/swift-nio) — Framework de rede orientado a eventos

---

## 📄 Licença

Este projeto está licenciado sob a **Licença Internacional Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 (CC BY-NC-ND 4.0)**.

### Você é livre para:

- **Compartilhar** — copiar e redistribuir o material em qualquer meio ou formato

### Sob os seguintes termos:

- **Atribuição** — Você deve dar crédito adequado, fornecer um link para a licença e indicar se foram feitas alterações
- **NãoComercial** — Você **não** pode usar o material para fins comerciais
- **SemDerivativos** — Se você remixar, transformar ou criar a partir do material, você **não** pode distribuir o material modificado

### ⚠️ Uso Comercial é Estritamente Proibido

Isso inclui, mas não se limita a:

- Vender ou distribuir o aplicativo para lucro
- Usar a base de código em produtos ou serviços comerciais
- Oferecer serviços pagos baseados neste software

Para o texto completo da licença, consulte: https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode

---

<p align="center">
  Feito com ❤️ para produtividade pessoal
</p>
