# MCP Execution Manual (`mcp-for-blender` + Safe `bpy` Recipes)

Authoritative reference for invoking `mcp-for-blender` tools in **Google Antigravity** via `call_mcp_tool` and writing version-safe, localization-proof Python (`bpy`) code.

---

## 1. Calling Lazy MCP Tools in Antigravity

All Blender MCP tools are invoked through `call_mcp_tool` targeting `ServerName: "blender"`.

> **Critical Rule (`user_prompt`):** Always pass the user's **exact, verbatim request text** in `user_prompt` on every call in a task sequence. Never paraphrase or replace it with your own internal sub-step description.

### 1.1 Session Preflight (`get_addon_status` + `get_scene_info`)

```json
{
  "ServerName": "blender",
  "ToolName": "get_addon_status",
  "Arguments": {
    "user_prompt": "<exact user request>"
  }
}
```

```json
{
  "ServerName": "blender",
  "ToolName": "get_scene_info",
  "Arguments": {
    "fields": ["location", "size", "ground", "rotation", "scale", "materials", "modifiers", "details", "settings"],
    "limit": 50,
    "user_prompt": "<exact user request>"
  }
}
```

**Available `get_scene_info` field groups:**
- **Placement:** `location`, `size` (world bounding box), `ground` (on ground / floating / below), `rotation` (degrees), `scale`, `parent`
- **Contents:** `children`, `hidden`, `details` (face count, bone count, or light power), `materials`, `modifiers`, `animation`
- **Health (QA Gate):** `topology` (quads, tris, ngons, non-manifold edges, boundary edges, loose verts, poles), `weights` (unweighted verts, unused deform bones)
- **Scene Header:** `settings` (blend file path, render engine, frame range, resolution, active camera, HDRI, unit scale)

---

### 1.2 Visual Inspection (`look`)

`look` is the native visual inspection tool (superseding legacy `get_viewport_screenshot` calls). Any temporary view/shading adjustments made by `look` are **automatically restored** after capture.

#### Standard Viewport / Camera Check
```json
{
  "ServerName": "blender",
  "ToolName": "look",
  "Arguments": {
    "mode": "viewport",
    "shading": "material",
    "max_size": 768,
    "user_prompt": "<exact user request>"
  }
}
```

#### Multi-Angle Silhouette & QA Sheet (`mode: "angles"`)
Captures front, right, top, and 3/4 views in a single composite image — ideal after blockout, modeling, and before delivery:
```json
{
  "ServerName": "blender",
  "ToolName": "look",
  "Arguments": {
    "mode": "angles",
    "target": ["SM_Prop_Crate_01"],
    "views": ["front", "right", "top", "three_quarter"],
    "shading": "rendered",
    "max_size": 768,
    "user_prompt": "<exact user request>"
  }
}
```

#### Animation Strip Verification (`mode: "frames"`)
Samples multiple frames across the timeline into one strip to verify motion arcs and seamless loops:
```json
{
  "ServerName": "blender",
  "ToolName": "look",
  "Arguments": {
    "mode": "frames",
    "frame_count": 6,
    "view": "camera",
    "shading": "rendered",
    "max_size": 768,
    "user_prompt": "<exact user request>"
  }
}
```

---

### 1.3 Executing Python (`execute_blender_code`)

```json
{
  "ServerName": "blender",
  "ToolName": "execute_blender_code",
  "Arguments": {
    "code": "import bpy\nprint('Objects:', len(bpy.data.objects))",
    "user_prompt": "<exact user request>"
  }
}
```
- Always `print(...)` concise confirmation metrics (object names, triangle counts, world bounds) because `stdout` is returned directly to you.
- Break complex builds into logical phases (1. Collections & Blockout → `look` → 2. Detail & Modifiers → `look` → 3. Materials & Lighting → `look`).

---

### 1.4 Asset Libraries (`search_assets` & `import_asset`)

Only call when `get_addon_status` shows the target source (`polyhaven`, `sketchfab`, or `polypizza`) is enabled.

```json
{
  "ServerName": "blender",
  "ToolName": "search_assets",
  "Arguments": {
    "source": "polyhaven",
    "asset_type": "hdris",
    "query": "studio softbox",
    "previews": 4,
    "limit": 8,
    "user_prompt": "<exact user request>"
  }
}
```

```json
{
  "ServerName": "blender",
  "ToolName": "import_asset",
  "Arguments": {
    "source": "polyhaven",
    "id": "studio_small_09",
    "asset_type": "hdris",
    "resolution": "2k",
    "user_prompt": "<exact user request>"
  }
}
```
- **Models (`sketchfab` / `polypizza`):** Always pass `target_size` in meters (e.g., `1.0` for a chair, `4.5` for a car). Afterwards check `get_scene_info(fields=["location", "size", "ground"])`, place on `z=0`, and rename/move into `COL_Props`.
- **Textures (`polyhaven`):** Always pass `apply_to: ["SM_TargetObject"]` so the generated PBR material isn't left orphaned.

---

### 1.5 Generative 3D & Feedback Tools

- **`generate_3d`:** Generates **one** standalone object (never a whole room, ground plane, or multi-part kit). May consume paid user credits — confirm intent first. If a job handle is returned after `wait_seconds`, resume with `{"job": "<handle>", "name": "...", "user_prompt": "..."}`.
- **`generate_gaussian_world`:** Requires **Blender 5.3+** and World Labs Marble credits. Only invoke when Gaussian splats / AI world capture is explicitly requested.
- **`record_trajectory_feedback`:** Call with `feedback: "accept" | "reject" | "undo" | "correction"` (plus `correction_text` on `"correction"`) when the user evaluates your output.
- **`disable_telemetry`:** Call immediately if the user asks to opt out of telemetry.

---

## 2. Anti-Fragile, Cross-Version `bpy` Recipes

### 2.1 Safe Backup Before Destructive Operations
```python
import bpy

if bpy.data.is_saved:
    bpy.ops.wm.save_mainfile()
    print("Saved .blend before operation:", bpy.data.filepath)
```

### 2.2 Standard `COL_*` Collection Setup & Safe Object Linking
Never call `col.unlink(obj)` (raises `AttributeError`). Always use `col.objects.unlink(obj)`:

```python
import bpy

def ensure_collection(name, parent=None):
    col = bpy.data.collections.get(name)
    if not col:
        col = bpy.data.collections.new(name)
        target_parent = parent if parent else bpy.context.scene.collection
        target_parent.children.link(col)
    return col

def move_to_collection(obj, target_col):
    for col in list(obj.users_collection):
        col.objects.unlink(obj)
    if obj.name not in target_col.objects:
        target_col.objects.link(obj)

col_props = ensure_collection("COL_Props")
col_lights = ensure_collection("COL_Lights")
col_cams = ensure_collection("COL_Cameras")
```

### 2.3 Cross-Version Render Engine Selection (Blender 3.x / 4.2+ / 5.x)
`BLENDER_EEVEE` became `BLENDER_EEVEE_NEXT` in Blender 4.2 and reverted/changed across 5.x. Never hardcode without fallback:

```python
import bpy

def set_eevee_engine(scene=None):
    scene = scene or bpy.context.scene
    for candidate in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try:
            scene.render.engine = candidate
            return scene.render.engine
        except TypeError:
            continue
    return scene.render.engine
```

### 2.4 Localization-Safe PBR Material Builder
Node names like `"Principled BSDF"` or `"Material Output"` fail on non-English Blender installations. **Always match `node.type`**:

```python
import bpy

def create_pbr_material(name, base_color=(0.5, 0.5, 0.5, 1.0), metallic=0.0, roughness=0.5, emission_color=None, emission_strength=0.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    bsdf = next((n for n in nodes if n.type == 'BSDF_PRINCIPLED'), None)
    out = next((n for n in nodes if n.type == 'OUTPUT_MATERIAL'), None)
    if not bsdf:
        nodes.clear()
        out = nodes.new("ShaderNodeOutputMaterial")
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        links.new(bsdf.outputs[0], out.inputs["Surface"])

    bsdf.inputs["Base Color"].default_value = base_color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness

    if emission_strength > 0.0:
        e_col = emission_color or base_color
        if "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = e_col
        elif "Emission" in bsdf.inputs:
            bsdf.inputs["Emission"].default_value = e_col
        if "Emission Strength" in bsdf.inputs:
            bsdf.inputs["Emission Strength"].default_value = emission_strength

    return mat
```

### 2.5 Base-Center Pivot & Grounding (`z = 0`)
Places an object cleanly on the floor with its origin at the bottom-center of its world bounding box and scale/rotation applied:

```python
import bpy
from mathutils import Vector

def ground_and_set_base_pivot(obj):
    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    bbox_world = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    min_z = min(v.z for v in bbox_world)
    center_x = sum(v.x for v in bbox_world) / 8.0
    center_y = sum(v.y for v in bbox_world) / 8.0

    saved_cursor = bpy.context.scene.cursor.location.copy()
    bpy.context.scene.cursor.location = Vector((center_x, center_y, min_z))
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.context.scene.cursor.location = saved_cursor

    obj.location.z = 0.0
    if obj.data:
        obj.data.name = obj.name
```
