# Blender Skills para Google Antigravity (Guía Completa de Configuración)

Esta guía explica cómo utilizar el paquete de **94 Skills especializadas de Blender** y la integración directa vía **Blender MCP (Model Context Protocol)** en **Google Antigravity**.

---

## 1. Arquitectura y Funcionamiento

En Antigravity, la interacción con Blender no consiste en dar instrucciones manuales de interfaz ("haz clic aquí"), sino en **ejecución técnica directa**:

```
+-------------------------------------------------------------+
|                     GOOGLE ANTIGRAVITY                      |
|                                                             |
|  [blender-director]  -->  [94 Skills en .agents/skills/]    |
|  (Orquestador TD)         (Modelado, Shaders, Rigging, etc)|
|         |                                                   |
|         v                                                   |
|  [mcp_config.json]                                          |
+---------+---------------------------------------------------+
          | Protocolo MCP (Stdio)
          v
+------------------------+
|   uvx blender-mcp      | (Servidor puente MCP en Python 3.11)
+---------+--------------+
          | Socket TCP (localhost:9876)
          v
+-------------------------------------------------------------+
|                     BLENDER (3.0 a 5.x)                     |
|                                                             |
|  [Addon Blender MCP] (En ejecución / Conectado)             |
|         |                                                   |
|         +--> execute_blender_code (Python bpy)              |
|         +--> get_viewport_screenshot (Captura de pantalla)  |
|         +--> get_scene_info (Jerarquía y estadísticas)      |
+-------------------------------------------------------------+
```

---

## 2. Instalación Rápida Automatizada (Windows)

Hemos preparado el script `setup_antigravity.ps1` en la raíz de este proyecto.

Ejecútalo en PowerShell:

```powershell
.\setup_antigravity.ps1
```

Este script automáticamente:
1. Verifica e instala el gestor `uv` si no está presente.
2. Añade `uv` a tu variable `PATH`.
3. Detecta tus versiones instaladas de Blender (ej. Blender 4.2, 4.3, 5.1).
4. Copia el addon `blender_mcp_addon.py` directamente en la carpeta de extensiones de tu Blender.
5. Configura `mcp_config.json` tanto a nivel de proyecto como global (`~/.gemini/config/mcp_config.json`).
6. Pre-descarga las dependencias de `blender-mcp`.

---

## 3. Configuración Manual Paso a Paso

Si prefieres realizar la configuración manualmente:

### Paso 1: Instalar `uv`
Abre PowerShell y ejecuta:
```powershell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Asegúrate de que `$env:USERPROFILE\.local\bin` esté en tu PATH:
```powershell
$localBin = "$env:USERPROFILE\.local\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$localBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$localBin", "User")
}
```

### Paso 2: Activar el Addon en Blender
1. El archivo `addons/blender_mcp_addon.py` ya ha sido colocado en las carpetas de scripts de tus versiones de Blender.
2. Abre Blender.
3. Dirígete a **Edit > Preferences > Add-ons**.
4. Busca **Blender MCP** (o haz clic en *Install...* y selecciona `addons/blender_mcp_addon.py` si no lo ves).
5. Marca la casilla para habilitarlo.

### Paso 3: Iniciar el Servidor de Escucha en Blender
1. En la vista 3D de Blender (**3D Viewport**), presiona la tecla **N** para abrir la barra lateral derecha.
2. Haz clic en la pestaña **BlenderMCP**.
3. Haz clic en **Connect to Claude** (inicia el listener en `localhost:9876`).
   *(Nota: Se llama "Connect to Claude" por compatibilidad con el addon base, pero funciona universalmente con cualquier cliente MCP, incluido Antigravity).*

### Paso 4: Configuración de Antigravity (`mcp_config.json`)
El archivo `mcp_config.json` en la raíz del proyecto y en `~/.gemini/config/mcp_config.json` contiene:

```json
{
  "mcpServers": {
    "blender": {
      "command": "cmd",
      "args": [
        "/c",
        "uvx",
        "mcp-for-blender"
      ],
      "env": {
        "BLENDER_HOST": "localhost",
        "BLENDER_PORT": "9876",
        "DISABLE_TELEMETRY": "true"
      }
    }
  }
}
```

---

## 4. Uso y Flujos de Trabajo en Antigravity

### A. Creación de Assets y Modelado Directo
Pide a Antigravity lo que necesitas:
> *"Construye un prop de ciencia ficción game-ready: una terminal médica futurista con pantalla holográfica, optimizada a menos de 4,000 triángulos para Unreal Engine 5."*

Antigravity automáticamente:
1. Activa `blender-director`.
2. Encadena: `hard-surface` -> `materials` -> `asset-optimization` -> `unreal-export`.
3. Ejecuta los comandos Python y modifiers directamente en Blender.
4. Consulta las estadísticas de polígonos y valida la escala y normales.

### B. Loop Visual de Coincidencia de Referencias (Multimodal)
Adjunta una fotografía o arte conceptual y escribe:
> *"Replica este modelo en Blender coincidiendo con la imagen de referencia."*

Antigravity:
1. Lee `references/reference-image-match.md`.
2. Realiza el análisis visual multimodal de proporciones y formas primarias.
3. Genera el blockout en Blender.
4. Invoca `get_viewport_screenshot` para obtener una captura del viewport de Blender.
5. Compara visualmente la captura con la referencia original y realiza ajustes automáticos.

### C. Comandos Slash Recomendados en Antigravity
- **/plan**: Para proyectos complejos (entornos modulares, personajes completos) donde desees revisar y aprobar la arquitectura antes de que el agente comience a crear objetos en Blender.
- **/boost**: Para tareas de alta complejidad técnica como sistemas de Geometry Nodes intrincados o simulaciones físicas.
- **/goal**: Para tareas batch de larga duración (por ejemplo, optimizar y exportar 20 modelos secuencialmente).

---

## 5. Estructura de Archivos del Proyecto

```
.
├── .agents/
│   ├── rules/
│   │   └── AGENTS.md          # Reglas maestras de Technical Art para Antigravity
│   └── skills/                # 94 Skills completas adaptadas para Antigravity
│       ├── blender-director/  # Orquestador principal
│       ├── hard-surface/
│       ├── environment-artist/
│       ├── character-artist/
│       ├── geometry-nodes/
│       ├── ... (90 skills más)
│       └── references/        # Pipelines, presupuestos, checklists y convenciones
├── addons/
│   └── blender_mcp_addon.py   # Addon de Blender listo para usar
├── docs/
│   ├── ANTIGRAVITY_SETUP.md   # Esta guía
│   └── BLENDER_MCP_SETUP.md   # Guía general de Blender MCP
├── GEMINI.md                  # Contexto y directrices de alto nivel para el agente
├── mcp_config.json            # Configuración MCP nativa de Antigravity
├── plugin.json                # Manifiesto de Plugin de Antigravity
├── setup_antigravity.ps1      # Script de automatización para Windows
└── README.md                  # Documentación principal actualizada
```
