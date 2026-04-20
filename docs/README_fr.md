<p align="center">
  <img src="../src/SoloOKRs/SoloOKRs/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" height="128" alt="Icône SoloOKRs">
</p>

<h1 align="center">SoloOKRs</h1>

<p align="center">
  <strong>Une application de gestion d'OKR personnelle pour macOS — avec assistance IA intégrée et intégration MCP</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-blue?logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/swift-6.0-orange?logo=swift" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/UI-SwiftUI-purple" alt="SwiftUI">
  <img src="https://img.shields.io/badge/license-CC%20BY--NC--ND%204.0-lightgrey" alt="License">
</p>

---

[English](README.md) | [简体中文](docs/README_zh.md) | [日本語](docs/README_ja.md) | [한국어](docs/README_ko.md) | [Deutsch](docs/README_de.md) | [Français](docs/README_fr.md) | [Español](docs/README_es.md) | [Português (BR)](docs/README_ptBR.md)

---

## ✨ Qu'est-ce que SoloOKRs ?

SoloOKRs est une **application macOS native** de gestion d'objectifs personnels utilisant le framework **OKR (Objectives and Key Results)**. Contrairement aux outils OKR orientés équipes, SoloOKRs est conçu pour les fondateurs d'OPC (One Person Company) et les individus qui souhaitent un environnement concentré et sans distraction pour définir, suivre et réfléchir à leurs objectifs personnels. Ce projet a été développé dans un workflow de vibe-coding avec Google Antigravity.

À l'ère de l'IA, SoloOKRs est aussi un **pont entre les humains et les agents IA** — un outil qui aide à aligner vos objectifs avec des assistants IA afin qu'ils puissent vous aider à définir des objectifs, suivre les progrès, accomplir les résultats clés et mener des rétrospectives.

Ce qui la rend spéciale :

- 🧠 **Assistance alimentée par l'IA** — Bénéficiez de suggestions IA pour affiner vos objectifs, décomposer les résultats clés et suivre les progrès
- 🔌 **Serveur MCP** — Exposez vos données OKR aux assistants IA comme Claude Desktop via le Model Context Protocol
- 📊 **Mode Révision** — Flux de travail rétrospectif intégré pour des révisions périodiques d'OKR
- ☁️ **Synchronisation iCloud** — Synchronisation transparente des données entre vos appareils Mac
- 🌍 **9 langues** — Support multilingue complet avec changement de langue en temps réel

---

## 🎯 Fonctionnalités

### Gestion d'OKR fondamentale

| Fonctionnalité      | Description                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------- |
| **Objectifs**       | Créez, modifiez et archivez des objectifs avec suivi de progression                         |
| **Résultats clés**  | Définissez des résultats clés mesurables avec différents types (pourcentage, nombre, jalon) |
| **Tâches**          | Décomposez les résultats clés en tâches actionnables avec des descriptions Markdown         |
| **Archives**        | Archivez les objectifs terminés avec une section archive marquée d'un trophée               |
| **Glisser-déposer** | Réorganisez les objectifs et résultats clés par glisser-déposer                             |

### 🧠 Intégration IA

SoloOKRs inclut un assistant IA intégré qui peut vous aider à chaque étape du cycle de vie des OKR :

**Fournisseurs supportés :**

| Fournisseur   | Type  | Description                                     |
| ------------- | ----- | ----------------------------------------------- |
| **Gemini**    | Cloud | Modèles Gemini de Google                        |
| **OpenAI**    | Cloud | GPT-4o et autres modèles OpenAI                 |
| **Anthropic** | Cloud | Modèles Claude                                  |
| **Ollama**    | Local | Exécutez des LLMs locaux (Llama, Mistral, etc.) |
| **LM Studio** | Local | Serveur d'inférence de modèles locaux           |

**Comment utiliser :**

1. Ouvrez **Réglages → IA** et sélectionnez votre fournisseur préféré
2. Saisissez votre clé API (stockée en toute sécurité dans le Trésor macOS)
3. Pour les fournisseurs locaux (Ollama/LM Studio), assurez-vous que le serveur est en cours d'exécution sur votre machine
4. Utilisez le bouton étincelle IA (✦) dans les vues d'objectifs et de résultats clés pour obtenir des suggestions
5. Les réponses IA incluent une visualisation du **bloc de réflexion** — des blocs pliables qui montrent le processus de raisonnement de l'IA

### 🔌 Serveur MCP (Model Context Protocol)

SoloOKRs inclut un **serveur MCP** intégré qui expose vos données OKR aux assistants IA externes. Cela permet à des outils comme **Claude Desktop** de lire et manipuler vos objectifs directement.

**Options de transport :**

| Transport                   | Protocole                 | Cas d'utilisation                               |
| --------------------------- | ------------------------- | ----------------------------------------------- |
| **HTTP**                    | `http://localhost:<port>` | Accès universel, outils basés sur le web        |
| **Sockets de domaine Unix** | `/tmp/solookrs.sock`      | Claude Desktop, outils locaux (latence réduite) |

**Outils MCP disponibles (12 outils) :**

| Catégorie          | Outils                                                                                         |
| ------------------ | ---------------------------------------------------------------------------------------------- |
| **Objectifs**      | `list_objectives`, `get_objective`, `create_objective`, `update_objective`, `delete_objective` |
| **Résultats clés** | `list_key_results`, `update_key_result`                                                        |
| **Tâches**         | `list_tasks`, `create_task`, `update_task`                                                     |
| **Révisions**      | `list_reviews`, `get_review`, `create_review`                                                  |

**Intégration Claude Desktop :**

Pour connecter SoloOKRs à Claude Desktop, ajoutez ce qui suit à votre configuration Claude Desktop (`~/Library/Application Support/Claude/claude_desktop_config.json`) :

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

Ou pour le transport HTTP :

```json
{
  "mcpServers": {
    "solookrs": {
      "url": "http://localhost:8716"
    }
  }
}
```

**Comment activer :**

1. Ouvrez **Réglages → MCP**
2. Activez le serveur MCP
3. Choisissez votre transport (HTTP ou Socket Unix)
4. Configurez Claude Desktop avec les informations de connexion ci-dessus
5. L'indicateur de statut dans la barre latérale affiche l'état de la connexion

### 📊 Mode Révision

SoloOKRs inclut un flux de travail de **révision/rétrospective** structuré :

1. **Créer une révision** — Sélectionnez un objectif et générez une entrée de révision
2. **Évaluation des RC** — Évaluez la progression de chaque résultat clé avec des notes
3. **Résumé IA** — Générez optionnellement un résumé de révision alimenté par l'IA
4. **Historique des révisions** — Parcourez et revisitez les révisions passées au fil du temps
5. **Notes Markdown** — Rédigez des notes de révision enrichies avec Markdown complet + coloration syntaxique du code

### 🎨 Invitations IA personnalisables

Personnalisez le comportement de l'IA via **Réglages → Invitations** :

- Personnalisez les invitations système pour les suggestions d'objectifs
- Ajustez les invitations de génération des résultats clés
- Modifiez les modèles d'invitation de résumé de révision
- Toutes les invitations supportent le formatage Markdown

---

## 🏗 Architecture

```
SoloOKRs/
├── Models/           # Définitions du modèle SwiftData
│   ├── Objective     # Objectifs de haut niveau
│   ├── KeyResult     # Résultats mesurables
│   ├── OKRTask       # Tâches actionnables
│   ├── OKRReview     # Sessions de révision
│   └── KRReviewEntry # Entrées de révision par RC
├── Views/
│   ├── Objectives/   # Barre latérale — Liste et gestion des objectifs
│   ├── KeyResults/   # Colonne centrale — Cartes et création de RC
│   ├── Tasks/        # Colonne de détail — Liste et éditeurs de tâches
│   ├── Reviews/      # Création et historique des révisions
│   ├── Settings/     # Onglets des réglages (Général, IA, Invitations, MCP, Sync)
│   └── Components/   # Composants partagés (AIResponseView, MarkdownEditor)
├── Services/
│   ├── AIProvider/   # AIService, PromptManager, abstractions des fournisseurs
│   └── MCPServer/    # Serveur MCP basé sur SwiftNIO (HTTP + UDS)
└── Utilities/        # Trésor, analyse Markdown, coloration syntaxique
```

**Disposition UI :** `NavigationSplitView` à 3 colonnes

- **Colonne 1 (Barre latérale) :** Liste des objectifs avec barre de statut (indicateurs IA/MCP/Sync)
- **Colonne 2 (Contenu) :** Résultats clés pour l'objectif sélectionné
- **Colonne 3 (Détail) :** Tâches pour le résultat clé sélectionné

**Persistance :** SwiftData avec synchronisation automatique CloudKit

---

## 🌍 Localisation

SoloOKRs supporte **9 langues** avec changement en temps réel (aucun redémarrage requis) :

| Langue                          | Code      |
| ------------------------------- | --------- |
| Anglais                         | `en`      |
| Chinois simplifié (简体中文)    | `zh-Hans` |
| Chinois traditionnel (繁體中文) | `zh-Hant` |
| Japonais (日本語)               | `ja`      |
| Coréen (한국어)                 | `ko`      |
| Allemand (Deutsch)              | `de`      |
| Français (Français)             | `fr`      |
| Espagnol (Español)              | `es`      |
| Portugais - Brésil (Português)  | `pt-BR`   |

Changez de langue via **Réglages → Général → Langue de l'app**.

---

## 🚀 Pour commencer

### Prérequis

- macOS 14.0 (Sonoma) ou ultérieur
- Xcode 16.0 ou ultérieur
- Compte développeur Apple (pour la synchronisation CloudKit)

### Construction et exécution

```bash
# Cloner le dépôt
git clone https://github.com/your-username/SoloOKRs.git
cd SoloOKRs

# Construire
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build -destination 'platform=macOS,arch=arm64'

# Ou ouvrir dans Xcode
open src/SoloOKRs/SoloOKRs.xcodeproj
```

### Exécuter les tests

```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs test -destination 'platform=macOS,arch=arm64'
```

---

## 🛡 Sécurité

- **Les clés API** sont stockées dans le **Trésor** macOS en utilisant `kSecUseDataProtectionKeychain`
- **Aucun télémétrie** — toutes les données restent sur votre appareil et iCloud
- **IA locale** — Le support Ollama et LM Studio signifie que vos données OKR ne quittent jamais votre machine

---

## 🙏 Remerciements

Construit avec ces excellentes bibliothèques open-source :

- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) — Rendu Markdown dans SwiftUI
- [Splash](https://github.com/JohnSundell/Splash) — Coloration syntaxique du code
- [SwiftNIO](https://github.com/apple/swift-nio) — Framework de réseau orienté événements

---

## 📄 Licence

Ce projet est sous licence **Creative Commons Attribution-Pas d'Utilisation Commerciale-Pas de Travail Dérivé 4.0 International (CC BY-NC-ND 4.0)**.

### Vous êtes libre de :

- **Partager** — copier et redistribuer le matériel sur tout support ou format

### Aux conditions suivantes :

- **Attribution** — Vous devez citer le créateur, fournir un lien vers la licence et indiquer si des modifications ont été effectuées
- **Pas d'Utilisation Commerciale** — Vous ne pouvez **pas** utiliser le matériel à des fins commerciales
- **Pas de Travail Dérivé** — Si vous modifiez, transformez ou adaptez le matériel, vous ne pouvez **pas** distribuer le matériel modifié

### ⚠️ L'utilisation commerciale est strictement interdite

Cela inclut, mais n'est pas limité à :

- La vente ou la distribution de l'application à des fins lucratives
- L'utilisation de la base de code dans des produits ou services commerciaux
- L'offre de services payants basés sur ce logiciel

Pour le texte complet de la licence, voir : https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode

---

<p align="center">
  Réalisé avec ❤️ pour la productivité personnelle
</p>
