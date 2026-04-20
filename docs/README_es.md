<p align="center">
  <img src="../src/SoloOKRs/SoloOKRs/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" height="128" alt="SoloOKRs Icon">
</p>

<h1 align="center">SoloOKRs</h1>

<p align="center">
  <strong>Una aplicación de gestión de OKRs personales para macOS — con asistencia de IA integrada e integración con MCP</strong>
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

## ✨ ¿Qué es SoloOKRs?

SoloOKRs es una **aplicación nativa de macOS** para la gestión de objetivos personales utilizando el framework **OKR (Objectives and Key Results)**. A diferencia de las herramientas OKR orientadas a equipos, SoloOKRs está diseñado para fundadores de OPC (One Person Company) e individuos que desean un entorno enfocado y libre de distracciones para definir, rastrear y reflexionar sobre sus objetivos personales. Este proyecto fue construido en un flujo de vibe-coding con Google Antigravity.

En la era de la IA, SoloOKRs es también un **puente entre humanos y agentes de IA** — una herramienta que ayuda a alinear tus objetivos con asistentes de IA para que puedan ayudarte a establecer objetivos, rastrear el progreso, completar resultados clave y realizar retrospectivas.

Lo que la hace especial:

- 🧠 **Asistencia con IA** — Obtén sugerencias de la IA para refinar objetivos, desglosar resultados clave y revisar el progreso
- 🔌 **Servidor MCP** — Expone tus datos de OKR a asistentes de IA como Claude Desktop a través del Model Context Protocol
- 📊 **Modo de revisión** — Flujo de trabajo retrospectivo integrado para revisiones periódicas de OKR
- ☁️ **Sincronización con iCloud** — Sincronización de datos perfecta entre tus dispositivos Mac
- 🌍 **9 idiomas** — Soporte multilingüe completo con cambio de idioma en tiempo real

---

## 🎯 Funcionalidades

### Gestión central de OKR

| Funcionalidad          | Descripción                                                                       |
| ---------------------- | --------------------------------------------------------------------------------- |
| **Objetivos**          | Crea, edita y archiva objetivos con seguimiento de progreso                       |
| **Resultados clave**   | Define resultados clave medibles con diferentes tipos (porcentaje, número, hito)  |
| **Tareas**             | Desglosa los resultados clave en tareas accionables con descripciones en Markdown |
| **Archivos**           | Archiva objetivos completados con una sección de archivos marcada con trofeo      |
| **Arrastrar y soltar** | Reordena objetivos y resultados clave con arrastrar y soltar                      |

### 🧠 Integración con IA

SoloOKRs incluye un asistente de IA integrado que puede ayudarte en cada etapa del ciclo de vida de los OKR:

**Proveedores compatibles:**

| Proveedor     | Tipo  | Descripción                                 |
| ------------- | ----- | ------------------------------------------- |
| **Gemini**    | Nube  | Modelos Gemini de Google                    |
| **OpenAI**    | Nube  | Modelos GPT-4o y otros modelos de OpenAI    |
| **Anthropic** | Nube  | Modelos Claude                              |
| **Ollama**    | Local | Ejecuta LLMs locales (Llama, Mistral, etc.) |
| **LM Studio** | Local | Servidor de inferencia de modelos locales   |

**Cómo usar:**

1. Abre **Ajustes → IA** y selecciona tu proveedor preferido
2. Ingresa tu clave de API (almacenada de forma segura en el Llavero de macOS)
3. Para proveedores locales (Ollama/LM Studio), asegúrate de que el servidor esté ejecutándose en tu máquina
4. Usa el botón de brillo de IA (✦) en las vistas de objetivos y resultados clave para obtener sugerencias
5. Las respuestas de la IA incluyen visualización del **bloque de reflexión** — bloques expandibles que muestran el proceso de razonamiento de la IA

### 🔌 Servidor MCP (Model Context Protocol)

SoloOKRs incluye un **servidor MCP** integrado que expone tus datos de OKR a asistentes de IA externos. Esto habilita herramientas como **Claude Desktop** para leer y manipular tus objetivos directamente.

**Opciones de transporte:**

| Transporte                  | Protocolo                 | Caso de uso                                           |
| --------------------------- | ------------------------- | ----------------------------------------------------- |
| **HTTP**                    | `http://localhost:<port>` | Acceso universal, herramientas basadas en web         |
| **Sockets de dominio Unix** | `/tmp/solookrs.sock`      | Claude Desktop, herramientas locales (menor latencia) |

**Herramientas MCP disponibles (12 herramientas):**

| Categoría            | Herramientas                                                                                   |
| -------------------- | ---------------------------------------------------------------------------------------------- |
| **Objetivos**        | `list_objectives`, `get_objective`, `create_objective`, `update_objective`, `delete_objective` |
| **Resultados clave** | `list_key_results`, `update_key_result`                                                        |
| **Tareas**           | `list_tasks`, `create_task`, `update_task`                                                     |
| **Revisiones**       | `list_reviews`, `get_review`, `create_review`                                                  |

**Integración con Claude Desktop:**

Para conectar SoloOKRs con Claude Desktop, agrega lo siguiente a tu configuración de Claude Desktop (`~/Library/Application Support/Claude/claude_desktop_config.json`):

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

O para transporte HTTP:

```json
{
  "mcpServers": {
    "solookrs": {
      "url": "http://localhost:8716"
    }
  }
}
```

**Cómo habilitar:**

1. Abre **Ajustes → MCP**
2. Activa el servidor MCP
3. Elige tu transporte (HTTP o Socket Unix)
4. Configura Claude Desktop con los datos de conexión anteriores
5. El indicador de estado en la barra lateral muestra el estado de la conexión

### 📊 Modo de revisión

SoloOKRs incluye un flujo de trabajo de **revisión/retrospectiva** estructurado:

1. **Crear una revisión** — Selecciona un objetivo y genera una entrada de revisión
2. **Evaluación de KRs** — Califica el progreso de cada resultado clave con notas
3. **Resumen de IA** — Opcionalmente genera un resumen de revisión con asistencia de IA
4. **Historial de revisiones** — Explora y revisa revisiones pasadas a lo largo del tiempo
5. **Notas en Markdown** — Escribe notas de revisión enriquecidas con resaltado de sintaxis completo de Markdown + código

### 🎨 Prompts de IA personalizables

Adapta el comportamiento de la IA a través de **Ajustes → Prompts**:

- Personaliza prompts del sistema para sugerencias de objetivos
- Ajusta prompts de generación de resultados clave
- Modifica plantillas de prompt para resúmenes de revisión
- Todos los prompts soportan formato Markdown

---

## 🏗 Arquitectura

```
SoloOKRs/
├── Models/           # Definiciones de modelos SwiftData
│   ├── Objective     # Objetivos de nivel superior
│   ├── KeyResult     # Resultados medibles
│   ├── OKRTask       # Tareas accionables
│   ├── OKRReview     # Sesiones de revisión
│   └── KRReviewEntry # Entradas de revisión por KR
├── Views/
│   ├── Objectives/   # Barra lateral — Lista de objetivos y gestión
│   ├── KeyResults/   # Columna central — Tarjetas de KR y creación
│   ├── Tasks/        # Columna de detalle — Lista de tareas y editores
│   ├── Reviews/      # Creación e historial de revisiones
│   ├── Settings/     # Pestañas de ajustes (General, IA, Prompts, MCP, Sync)
│   └── Components/   # Componentes compartidos (AIResponseView, MarkdownEditor)
├── Services/
│   ├── AIProvider/   # AIService, PromptManager, abstracciones de proveedores
│   └── MCPServer/    # Servidor MCP basado en SwiftNIO (HTTP + UDS)
└── Utilities/        # Llavero, análisis de Markdown, resaltado de sintaxis
```

**Diseño de UI:** `NavigationSplitView` de 3 columnas

- **Columna 1 (Barra lateral):** Lista de objetivos con barra de estado (indicadores de IA/MCP/Sync)
- **Columna 2 (Contenido):** Resultados clave para el objetivo seleccionado
- **Columna 3 (Detalle):** Tareas para el resultado clave seleccionado

**Persistencia:** SwiftData con sincronización automática mediante CloudKit

---

## 🌍 Localización

SoloOKRs admite **9 idiomas** con cambio en tiempo real (no requiere reiniciar):

| Idioma                         | Código    |
| ------------------------------ | --------- |
| Inglés                         | `en`      |
| Chino simplificado (简体中文)  | `zh-Hans` |
| Chino tradicional (繁體中文)   | `zh-Hant` |
| Japonés (日本語)               | `ja`      |
| Coreano (한국어)               | `ko`      |
| Alemán (Deutsch)               | `de`      |
| Francés (Français)             | `fr`      |
| Español (Español)              | `es`      |
| Portugués - Brasil (Português) | `pt-BR`   |

Cambia el idioma a través de **Ajustes → General → Idioma de la app**.

---

## 🚀 Primeros pasos

### Requisitos previos

- macOS 14.0 (Sonoma) o posterior
- Xcode 16.0 o posterior
- Cuenta de desarrollador de Apple (para sincronización con CloudKit)

### Compilar y ejecutar

```bash
# Clonar el repositorio
git clone https://github.com/your-username/SoloOKRs.git
cd SoloOKRs

# Compilar
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build -destination 'platform=macOS,arch=arm64'

# O abrir en Xcode
open src/SoloOKRs/SoloOKRs.xcodeproj
```

### Ejecutar pruebas

```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs test -destination 'platform=macOS,arch=arm64'
```

---

## 🛡 Seguridad

- **Claves de API** se almacenan en el **Llavero** de macOS usando `kSecUseDataProtectionKeychain`
- **Sin telemetría** — todos los datos permanecen en tu dispositivo y iCloud
- **IA local** — El soporte de Ollama y LM Studio significa que tus datos de OKR nunca salen de tu máquina

---

## 🙏 Agradecimientos

Construido con estas excelentes bibliotecas de código abierto:

- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) — Renderizado de Markdown en SwiftUI
- [Splash](https://github.com/JohnSundell/Splash) — Resaltado de sintaxis de código
- [SwiftNIO](https://github.com/apple/swift-nio) — Framework de networking orientado a eventos

---

## 📄 Licencia

Este proyecto está licenciado bajo la **Licencia Internacional Creative Commons Atribución-NoComercial-SinObrasDerivadas 4.0 (CC BY-NC-ND 4.0)**.

### Eres libre de:

- **Compartir** — copiar y redistribuir el material en cualquier medio o formato

### Bajo los siguientes términos:

- **Atribución** — Debes dar crédito apropiado, proporcionar un enlace a la licencia e indicar si se realizaron cambios
- **NoComercial** — No puedes usar el material con fines comerciales
- **SinObrasDerivadas** — Si remezclas, transformas o creas a partir del material, **no** puedes distribuir el material modificado

### ⚠️ El uso comercial está estrictamente prohibido

Esto incluye, entre otros:

- Vender o distribuir la aplicación con fines de lucro
- Utilizar la base de código en productos o servicios comerciales
- Ofrecer servicios de pago basados en este software

Para el texto completo de la licencia, visita: https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode

---

<p align="center">
  Hecho con ❤️ para la productividad personal
</p>
