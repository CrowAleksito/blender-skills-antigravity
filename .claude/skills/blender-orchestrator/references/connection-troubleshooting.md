# Blender MCP Connection & Troubleshooting Runbook

Diagnostic and recovery procedures when connecting **Google Antigravity** to **Blender** via `mcp-for-blender`.

---

## 1. Architecture Overview

```
Antigravity Agent
   │
   ├── Tier 1 (Primary): call_mcp_tool(ServerName="blender", ...)
   │      └── Stdio MCP Server: cmd /c uvx mcp-for-blender
   │             └── TCP Socket: localhost:9876
   │                    └── Blender (3.0 – 5.x) running blender_mcp_addon.py ("MCP for Blender")
   │
   └── Tier 2 (Emergency Diagnostic / Fallback):
          └── python .agents/skills/blender-orchestrator/scripts/blender_bridge.py --ping
                 └── Direct TCP Socket: localhost:9876
```

---

## 2. Common Errors & Exact Fixes

### Error A: `Could not connect to Blender. Make sure the Blender addon is running.`
**Cause:** No listener is active on `localhost:9876` (either Blender is closed, the addon checkbox is unchecked, or the server was manually disconnected).

**Diagnostic Steps:**
1. Run quick socket & process check via `run_command`:
   ```powershell
   Get-Process blender -ErrorAction SilentlyContinue | Select-Object Id, ProcessName, MainWindowTitle
   python ".agents\skills\blender-orchestrator\scripts\blender_bridge.py" --ping
   ```
2. **If `blender` process is NOT running:**
   - Inform the user concisely: *"Blender no está abierto actualmente. Ábrelo (el addon MCP for Blender tiene Auto-Start activado y se conectará automáticamente en `localhost:9876`) y avísame para continuar."*
3. **If `blender` IS running, but `--ping` fails (`Connection refused`):**
   - Tell the user:
     1. In Blender's **3D Viewport**, press <kbd>N</kbd> → open the **MCP for Blender** tab.
     2. Click **Connect to MCP server** (or **Connect to Claude**).
     3. *(If the tab isn't visible)* Go to **Edit → Preferences → Add-ons**, search **MCP for Blender**, and check the `[✓]` box.

---

### Error B: Duplicate MCP Servers (`blender` vs `blender-skills_blender`)
**Cause:** Both `~/.gemini/config/mcp_config.json` (global) and `~/.gemini/config/plugins/blender-skills/mcp_config.json` (plugin) register the MCP server.

**Orchestrator Rule:**
- **Always call `ServerName: "blender"`**.
- Never dispatch parallel calls to `blender` and `blender-skills_blender` at the same time — Blender executes bpy commands sequentially on its main thread timer queue (`_drain_command_queue`).

---

### Error C: Addon Outdated Warning in `get_addon_status`
**Cause:** `uvx mcp-for-blender` updated to a newer release than the `blender_mcp_addon.py` file inside `%APPDATA%\Blender Foundation\Blender\<ver>\scripts\addons\`.

**Fix:**
1. Run in PowerShell:
   ```powershell
   uvx mcp-for-blender install-addon
   ```
2. Ask the user to restart Blender (or toggle the **MCP for Blender** addon off and on in Preferences).

---

### Error D: `uvx` Not Found (`ENOENT`) on a New Machine
**Cause:** `uv` is not installed yet or `%USERPROFILE%\.local\bin` is missing from `PATH`.

**Fix:**
Run the workspace's automated installer:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup_antigravity.ps1
```
Or on macOS / Linux:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
uvx mcp-for-blender install-addon
```

---

## 3. Tier 2 Direct Socket Fallback (`blender_bridge.py`)

Use `scripts/blender_bridge.py` **only** when `call_mcp_tool` is temporarily unavailable in the current session (for instance, right after editing `mcp_config.json` before an IDE restart) AND Blender's addon is already listening on `localhost:9876`:

```powershell
# 1. Verify socket liveness
python ".agents\skills\blender-orchestrator\scripts\blender_bridge.py" --ping

# 2. Query raw scene summary
python ".agents\skills\blender-orchestrator\scripts\blender_bridge.py" --scene-info

# 3. Execute inline Python or a .py script file in Blender
python ".agents\skills\blender-orchestrator\scripts\blender_bridge.py" --exec "import bpy; print([o.name for o in bpy.data.objects])"
python ".agents\skills\blender-orchestrator\scripts\blender_bridge.py" --script "scratch_task.py"

# 4. Capture offscreen viewport image
python ".agents\skills\blender-orchestrator\scripts\blender_bridge.py" --screenshot "C:\path\to\artifact_dir\viewport.png" --max-size 800
```
