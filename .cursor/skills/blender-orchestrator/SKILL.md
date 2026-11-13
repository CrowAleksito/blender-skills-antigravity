---
name: blender-orchestrator
description: >-
  Master control plane and orchestrator for all Blender tasks, 94 specialist Blender skills, and the
  mcp-for-blender MCP server in Google Antigravity. Use this skill FIRST whenever the user asks to
  create, model, sculpt, texture, shade, light, rig, animate, simulate, render, inspect, optimize,
  or export anything in Blender, troubleshoot the Blender MCP connection, or combine multiple
  Blender skills/styles.
license: MIT
metadata:
  author: https://github.com/CrowAleksito/blender-skills-antigravity
  version: "1.0.0"
  domain: blender
  role: master-orchestrator
  triggers: blender, blender-orchestrator, Blender-orchestrator, 3d, mcp, model, shader, rig, animate, render, scene, asset, export
  related-skills: blender-director, blender-modeler, lookdev, qa-review, asset-optimization, export-pipeline
---

# Blender-Orchestrator

Master Technical Pipeline & MCP Control Plane for Blender in **Google Antigravity**.

`blender-orchestrator` governs **how Antigravity connects to Blender**, **how MCP tools are invoked safely**, **which of the 94 specialist skills to load and chain**, and **how every 3D operation is visually and technically verified before delivery**.

---

## 1. Execution Lifecycle (Mandatory 7-Step Loop)

Every Blender interaction follows this operational sequence scaled to task complexity:

```
1. CONNECT   → Verify live Blender & addon health (get_addon_status)
2. AUDIT     → Inspect current scene state before touching anything (get_scene_info + optional look)
3. ROUTE     → Classify complexity & load required specialist SKILL.md files
4. ORGANIZE  → Ensure non-destructive COL_* collection hierarchy & naming prefixes
5. EXECUTE   → Run incremental MCP operations (execute_blender_code / asset tools)
6. INSPECT   → Visually & structurally verify results (look + get_scene_info topology/ground checks)
7. DELIVER   → Run QA checklist, report metrics, and log feedback (record_trajectory_feedback)
```

---

## 2. MCP Connection & Server Selection Protocol

### A. Calling Lazy MCP Tools in Antigravity
In Antigravity, Blender MCP tools are exposed as **lazy-loaded tools** under `<mcp_servers>`:
1. **Server Selection Rule (Prevent Collisions):**
   - Always use `ServerName: "blender"` as the primary server.
   - If both `blender` and `blender-skills_blender` appear in `<mcp_servers>`, **never call both concurrently** — they connect to the same Blender socket (`localhost:9876`). Only use `blender-skills_blender` if `blender` is unavailable.
2. **Schema First:** Before calling an unfamiliar MCP tool in a session, read its schema file at `<appDataDir>/mcp/blender/<toolName>.json`, then invoke it via `call_mcp_tool`.
3. **Verbatim `user_prompt` Contract:**
   - Almost every `mcp-for-blender` tool accepts `user_prompt`. Always pass the **user's exact, unedited words** describing their goal (do not paraphrase or substitute internal plan steps). Repeat the same verbatim `user_prompt` across multi-step calls for the same request.

### B. Connection Preflight & 3-Tier Recovery Ladder
Before executing scene changes in a new session, verify connection state:

| Tier | Mechanism | When to Use & Action |
|------|-----------|----------------------|
| **Tier 1: Native MCP (Default)** | `call_mcp_tool` → `get_addon_status` & `get_scene_info` | Standard path. Confirms Blender version, active asset libraries (`polyhaven`, `sketchfab`, `polypizza`), 3D generators, and current objects. |
| **Tier 2: Direct TCP Bridge (Diagnostic / Fallback)** | `python .agents/skills/blender-orchestrator/scripts/blender_bridge.py --ping` | Use **only** if Tier 1 MCP fails to spawn or times out while Blender is open. Probes `localhost:9876` directly and can run emergency `--scene-info`, `--exec`, or `--screenshot` commands. |
| **Tier 3: Offline / Disconnected Recovery** | Check process & guide user (or headless CLI) | If `Could not connect to Blender` is returned and port `9876` is closed: tell the user concisely to open Blender and verify the **MCP for Blender** sidebar tab (<kbd>N</kbd> panel) shows **Connected on localhost:9876** (Auto-Start is on by default once enabled). Only use `blender.exe --background --python ...` if the user explicitly wants headless batch processing. |

For detailed diagnostics, load [connection-troubleshooting.md](references/connection-troubleshooting.md).

---

## 3. MCP Toolset Governance (`mcp-for-blender`)

Never narrate manual Blender UI steps ("Click Modifiers → Add Bevel...") when MCP is connected. Drive Blender directly using the 10 MCP tools:

| ToolName | Purpose | Orchestrator Rules |
|----------|---------|--------------------|
| `get_addon_status` | Version, addon sync, enabled libraries & AI generators | Call **once** at session start. Checks which external libraries/generators are enabled. |
| `get_scene_info` | Text audit of objects, bounds, ground contact, materials, modifiers, rig/mesh health | Call **before** editing and **after** major modeling/export steps. Request `fields: ["location", "size", "ground", "scale", "materials", "modifiers", "topology"]` for QA. |
| `execute_blender_code` | Execute Python (`bpy`, `bmesh`, `mathutils`) in Blender's main thread | Work in modular, incremental steps. `print()` key metrics so stdout returns confirmation. Save `.blend` first if a file is already saved (`bpy.data.is_saved`). |
| `look` | Render/capture visual inspection images (replaces legacy `get_viewport_screenshot`) | **Use proactively to see your work!** Supports `mode`: `"viewport"`, `"camera"`, `"angles"` (multi-view orthographic/3-4 sheet), and `"frames"` (animation strip). Keep `max_size: 512`–`768` during iterations to save context; use `1024` for final lookdev. All temporary camera/shading overrides auto-restore. |
| `search_assets` | Search `polyhaven` (CC0 HDRIs/textures/models), `sketchfab`, `polypizza` | Check `get_addon_status` first to confirm library is enabled. Use `previews: 4` to visually inspect candidates before importing. |
| `import_asset` | Download & import asset by `id` from `search_assets` | Always specify `target_size` (meters) for Sketchfab/PolyPizza, or `apply_to` for Poly Haven textures. Immediately inspect `world_bounding_box` and place on ground (`z=0`). |
| `generate_3d` | AI text/image-to-3D single textured mesh (`tripo`, `hunyuan3d`, `hyper3d`, `meshy`) | **Cost Guardrail:** May consume user credits. Only invoke when requested or approved. One standalone object per call (never full scenes or ground planes). Duplicate in `bpy` for repeats. Poll with `job` handle if needed. |
| `generate_gaussian_world` | World Labs Marble Gaussian splat environment (Blender 5.3+) | **Cost & Version Guardrail:** Requires Blender 5.3+ and user credits. Use **only** when user explicitly requests Gaussian splats / AI world generation. |
| `record_trajectory_feedback` | Log user evaluation (`accept`, `reject`, `undo`, `correction`) | Call whenever the user reacts to a Blender result (e.g., "quedo genial" → `accept`; "hazlo más alto" → `correction` with `correction_text`). |
| `disable_telemetry` | Immediately opt out of addon telemetry | Call immediately if the user asks to disable data collection or telemetry. |

### Mandatory Anti-Fragile `bpy` Coding Rules
Because scripts execute inside user Blender installations across versions (3.6, 4.2, 4.3, 5.x) and UI languages (Spanish, English, etc.):
1. **Localization-Safe Node Lookup:** Never look up shader/compositor nodes by `.name` (e.g. `nodes.get("Principled BSDF")` fails in localized Blender). Always filter by `.type`:
   ```python
   bsdf = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
   ```
2. **Cross-Version Socket & Engine Safety:**
   - Principled BSDF emission inputs changed in Blender 4.0+: check `"Emission Color" in bsdf.inputs` before falling back to `"Emission"`.
   - Render engine names changed across Blender 4.2+ / 5.x (`BLENDER_EEVEE` vs `BLENDER_EEVEE_NEXT`): wrap `scene.render.engine = ...` in `try / except TypeError` and inspect dynamic `bl_rna` enum items when needed.
3. **Collection Unlinking:** Unlink objects via `col.objects.unlink(obj)`, **never** `col.unlink(obj)`.
4. **Material Assignment:** Set colors on shader node inputs (`Base Color`), not `mat.diffuse_color` (which only affects Solid viewport shading).

For copy-pasteable `call_mcp_tool` payloads and safe `bpy` snippets, load [mcp-execution-manual.md](references/mcp-execution-manual.md).

---

## 4. Orchestrating the 94 Specialist Skills

Do **not** load dozens of skills at once. Classify the user's request by complexity tier and load **only** the `SKILL.md` files required for the active task:

### Tier A: Quick / Atomic Operations (0–1 Specialist Skills)
*Examples:* "Mueve la luz principal", "¿Cuántos polígonos tiene la escena?", "Cambia el color del cristal a rojo".
- **Action:** Run `get_scene_info` → execute cleanly via `execute_blender_code` → verify with `look` → report concisely. No heavy production brief required.

### Tier B: Focused Single-Discipline or Style Conversion (1–3 Specialist Skills)
*Examples:* "Haz que la escena sea anime cel-shaded y anima los anillos", "Crea un sistema de tuberías con Geometry Nodes", "Configura iluminación de terror".
- **Action:** Read the targeted specialist skills (e.g., `anime-style` + `animation`, or `geometry-nodes`, or `horror-style` + `lighting`). Follow their specific constraints, execute incrementally via MCP, and verify with `look(mode="angles")` or `look(mode="frames")` (for animations).

### Tier C: Full Asset Production, Multi-Discipline Scene, or Reference Image Match
*Examples:* "Crea un rifle sci-fi game-ready para Unreal Engine (3k tris)", "Construye un pasillo modular estilo Silent Hill", or **any prompt with an attached reference image**.
- **Action:**
  1. **Load `blender-director`** (`../blender-director/SKILL.md`) to generate the **Production Brief** (polycount budget, texture budget, pivot rule, pipeline phases).
  2. **If a reference image is attached:** Mandatory! Load `../references/reference-image-match.md` and write the Reference Analysis (`../references/reference-analysis-template.md`) **before** modeling. Match hero camera first, build geometry in tiers (silhouette → panel breaks → greebles), and iterate with `look(mode="camera")` up to 3 comparison passes.
  3. **Compose the 5-Layer Skill Stack** sequentially:

```
Layer 1: Planning & Direction  → blender-director (+ reference-image-match if photo attached)
Layer 2: World / Mood / Genre  → e.g., sci-fi-punk-worlds, dark-gritty-mood, genre-shooter (optional context)
Layer 3: Visual Style Lock     → e.g., realistic-style, anime-style, lowpoly-style, psx-horror-style (pick ONE primary)
Layer 4: Core Creation & Tech  → Modeling (hard-surface / character-artist / environment-artist / etc.)
                                 → Production (sculpting → retopology → uv-workflow → materials → texture-workflow → lookdev)
                                 → Motion/FX (rigging → animation / cloth-sim / physics-sim / vfx-fx)
                                 → Shot (lighting → camera-cinematography → rendering → compositing)
Layer 5: Gate & Delivery       → asset-optimization → lod-pipeline → collision-proxy
                                 → Engine Export (unreal-export / unity-export / godot-export / export-pipeline)
                                 → qa-review
```

For the complete directory of all 94 skills, triggers, and style conflict rules, load [skill-catalog-matrix.md](references/skill-catalog-matrix.md).

---

## 5. Scene Standards & Quality Gates

Every generated or modified scene must enforce these baseline technical art standards (full details in `../references/naming-conventions.md` and `../references/validation-checklist.md`):

1. **Collection Hierarchy:** Organize every scene under `COL_` collections (`COL_Reference`, `COL_Blockout`, `COL_Props` / `COL_Geo`, `COL_Collision`, `COL_Lights`, `COL_Cameras`, `COL_Export`). Never dump production objects loose in the root Scene Collection.
2. **Strict Prefixes:**
   - Static Meshes: `SM_` (`SM_Crate_SciFi_01`) — sync `obj.data.name = obj.name`
   - Skeletal Meshes / Rigs: `SK_` / `ARM_`
   - Colliders: `UCX_SM_*` / `UBX_SM_*` / `SM_*_COL`
   - Materials & Textures: `MAT_` / `T_`
   - Lights, Cameras, Node Groups: `LGT_`, `CAM_`, `GN_`
3. **Scale, Grounding & Transforms:**
   - `1 Blender Unit = 1 Meter`. Verify real-world dimensions via `get_scene_info(fields=["size", "ground", "scale"])`.
   - Props rest at `z = 0` (`ground` check) with logical base-center pivot `(0, 0, 0)` unless hinged/handheld.
   - Apply rotation and scale (`scale = (1, 1, 1)`) and ensure outward consistent normals before export.
4. **Visual Verification Gate:**
   - Static assets: verify silhouette and shading from multiple sides using `look(mode="angles", views=["front", "right", "top", "three_quarter"])`.
   - Animations: verify motion arcs and loop continuity using `look(mode="frames", frame_count=6)`.

---

## 6. Antigravity Workflow Integration

Leverage Antigravity's native platform capabilities alongside Blender MCP:
- **Artifacts for Production & QA Reports:** When delivering Tier C assets, multi-pass reference matches, or QA audits, present structured Markdown Artifacts embedding captured viewport renders and Mermaid pipeline graphs.
- **Slash Command Recommendations:**
  - Suggest `/plan` before executing large modular environments or multi-character rigs.
  - Suggest `/boost` for intricate procedural `geometry-nodes` math or complex shader debugging.
  - Suggest `/goal` for autonomous batch optimization, LOD generation, or multi-asset engine exports.

---

## Reference & Script Index

| Resource | Path | Load / Run When |
|----------|------|-----------------|
| **MCP Execution Manual** | [mcp-execution-manual.md](references/mcp-execution-manual.md) | Calling MCP tools, writing cross-version `bpy` shaders/modifiers/animations |
| **94-Skill Catalog & Matrix** | [skill-catalog-matrix.md](references/skill-catalog-matrix.md) | Selecting specialist skills, building multi-skill pipelines, checking style conflicts |
| **Connection Troubleshooting** | [connection-troubleshooting.md](references/connection-troubleshooting.md) | MCP connection fails, port `9876` issues, addon sync, or duplicate server configs |
| **Direct TCP Socket Bridge** | [blender_bridge.py](scripts/blender_bridge.py) | Tier 2 emergency socket diagnostics (`--ping`, `--scene-info`, `--exec`, `--screenshot`) |
| **Shared Pipeline Standards** | `../references/asset-pipeline.md`, `../references/validation-checklist.md`, `../references/polycount-budgets.md` | Setting budgets and running final pre-export validation gates |
