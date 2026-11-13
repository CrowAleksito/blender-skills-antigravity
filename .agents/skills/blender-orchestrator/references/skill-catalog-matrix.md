# 95-Skill Catalog, Routing Matrix & Conflict Rules

Complete map of the Blender Skills ecosystem managed by `blender-orchestrator`. Load **only** the `SKILL.md` files required for the active workflow.

---

## 1. Complete Skill Taxonomy (by Layer)

### Layer 1: Orchestration & Planning (2)
| Skill Folder | Role | Load When |
|--------------|------|-----------|
| `blender-orchestrator` | Master MCP & multi-skill control plane | **First on any Blender / MCP request** |
| `blender-director` | AAA Production Brief & Reference-Match planner | Tier C multi-discipline assets, full scenes, or reference image matching |

### Layer 2: Worlds, Moods, Genres & Eras (24)
*Provides environmental context, shape vocabulary, gameplay readability, and era constraints.*

- **Worlds (5):** `fantasy-worlds`, `sci-fi-punk-worlds`, `historical-worlds`, `apocalypse-worlds`, `biome-worlds`
- **Moods (5):** `cozy-wholesome-mood`, `dark-gritty-mood`, `dream-surreal-mood`, `neon-retrofuturism`, `brutalist-mood`
- **Gameplay Genres (13):** `genre-action-combat`, `genre-shooter`, `genre-rpg`, `genre-survival`, `genre-stealth`, `genre-puzzle-platformer`, `genre-metroidvania-roguelike`, `genre-soulslike`, `genre-strategy-sim`, `genre-racing-sports`, `genre-narrative-vn`, `genre-card-party-idle`, `genre-open-world-sandbox`
- **Console / Media Eras (1):** `visual-console-eras`

### Layer 3: Art Styles & Horror Packs (31)
*Locks shading rules, color palette discipline, silhouette proportions, and rendering look. **Pick ONE primary visual style** unless an intentional hybrid (like `hd-2d-style`) is requested.*

- **Core Styles (8):** `realistic-style`, `stylized-style`, `lowpoly-style`, `anime-style`, `voxel-style`, `isometric-style`, `horror-style`, `psx-horror-style`
- **Extended Styles (15):** `cartoon-style`, `comic-book-style`, `manga-style`, `pixel-art-style`, `hand-painted-style`, `painterly-style`, `stop-motion-craft-style`, `chibi-style`, `noir-style`, `minimalist-style`, `vector-style`, `retro-8bit-style`, `retro-16bit-style`, `hd-2d-style`, `frutiger-aero-style`
- **Horror Subgenres (8):** `cosmic-eldritch-horror`, `body-horror-style`, `analog-found-footage-horror`, `liminal-space-style`, `folk-horror-style`, `mascot-puppet-horror`, `dream-weirdcore-style`, `indie-horror-aesthetics`

### Layer 4A: Modeling & Asset Creation (9)
| Skill Folder | Primary Domain |
|--------------|----------------|
| `blender-modeler` | Core Edit Mode, modifiers, blockouts, general precision modeling |
| `hard-surface` | Sci-fi, weapons, industrial machinery, booleans, bevels, panel lines |
| `prop-artist` | Grounded everyday/hero props, furniture, tools, kitbash |
| `vehicle-artist` | Cars, aircraft, ships, mechs, wheel/panel splits |
| `environment-artist` | Modular kits, architecture, terrain, level blockouts |
| `vegetation-artist` | Trees, foliage, grass cards, canopy LODs, wind vertex colors |
| `character-artist` | Human/stylized character anatomy, clothing base, facial loops |
| `creature-artist` | Monsters, quadrupeds, aliens, winged anatomy |
| `character-archetypes` | Race/role silhouette kits (knight, mecha, chibi, horror creatures) |

### Layer 4B: Production & Surface (8)
| Skill Folder | Primary Domain |
|--------------|----------------|
| `sculpting` | High-poly organic/damage detail, multires, Dyntopo |
| `retopology` | Clean animation-ready quad flow & edge loops |
| `uv-workflow` | Seams, texel density, packing, trim sheets, UDIM, lightmap UVs |
| `materials` | Procedural & PBR node graphs (metal, wood, concrete, toon, glass) |
| `texture-workflow` | Baking AO/normal/curvature/ORM atlases & decals |
| `hair-groom` | Curve hair, particle fur, real-time hair cards |
| `cloth-sim` | Garments, capes, pin groups, shape-key/cache bakes |
| `lookdev` | Iterative material + light + `look` screenshot evaluation loop |

### Layer 4C: Technical, Motion, FX & Shot (9)
| Skill Folder | Primary Domain |
|--------------|----------------|
| `geometry-nodes` | Procedural scatter, cables, pipes, parametric node groups (`GN_`) |
| `rigging` | Armatures (`ARM_`), IK/FK, constraints, mechanical rigs, weights |
| `animation` | Walk/run/idle/combat cycles, seamless loops, Graph Editor / NLA |
| `physics-sim` | Rigid/soft bodies, fracture destruction, baked caches |
| `vfx-fx` | Smoke, fire, particle trails, stylized/game FX |
| `lighting` | Three-point, HDRI, volumetric, horror/noir mood lighting (`LGT_`) |
| `camera-cinematography` | Lenses, DOF, framing rules, animated camera rigs (`CAM_`) |
| `rendering` | Cycles & EEVEE sampling, denoising, passes, AgX color management |
| `compositing` | Glare, color grading, VHS/CRT post-FX, beauty pass stacks |

### Layer 5: Scene Assembly, Optimization, Engine Export & QA (12)
| Skill Folder | Primary Domain |
|--------------|----------------|
| `procedural-modeling` | Parametric rocks, roads, buildings, sci-fi panels |
| `scene-assembly` | Large scene collection layout, linking, library overrides |
| `set-dressing` | Narrative prop clusters, clutter density, visual storytelling |
| `archviz` | Real-world architectural interiors/exteriors |
| `asset-optimization` | Polycount audit, draw-call/material reduction, mesh cleanup |
| `lod-pipeline` | `LOD0`–`LOD3` decimation chains & screen-size thresholds |
| `collision-proxy` | `UCX_`, `UBX_`, convex hull & simple game colliders (`COL_Collision`) |
| `export-pipeline` | Generic FBX, GLTF/GLB, OBJ, USD, Alembic export verification |
| `unreal-export` | Unreal Engine cm scale, FBX, `UCX_` collision, sockets |
| `unity-export` | Unity FBX/GLB axis, Humanoid/Generic rig, ORM/mask maps |
| `godot-export` | Godot GLTF/GLB workflows, `-col` suffixes, animation tracks |
| `qa-review` | Final ship/no-ship visual (`look`) + technical audit gate |

---

## 2. Canonical Multi-Skill Pipelines

1. **Game-Ready Hard Surface Prop (Unreal / Unity / Godot):**
   `blender-orchestrator` → `blender-director` → `hard-surface` → `uv-workflow` → `materials` → `asset-optimization` → `collision-proxy` → (`unreal-export` | `unity-export` | `godot-export`) → `qa-review`
2. **Stylized / Anime Animated Scene:**
   `blender-orchestrator` → `anime-style` → `prop-artist` (or `character-artist`) → `materials` → `lighting` → `animation` → `lookdev`
3. **Production Game Character:**
   `blender-orchestrator` → `blender-director` → `character-archetypes` → `character-artist` → `sculpting` → `retopology` → `uv-workflow` → `materials` → `rigging` → `animation` → `export-pipeline`
4. **Atmospheric Horror Environment:**
   `blender-orchestrator` → `blender-director` → (`horror-style` | `psx-horror-style` | `liminal-space-style`) → `environment-artist` → `set-dressing` → `lighting` → `compositing`
5. **Reference Photo / Concept Match:**
   `blender-orchestrator` → `blender-director` (+ `../references/reference-image-match.md`) → `camera-cinematography` → `[discipline skill]` → `materials` → `lighting` → `lookdev` → `qa-review`

---

## 3. Conflict & Sequencing Guardrails

### Style Conflicts (Do Not Mix Unless Explicitly Requested)
- **`anime-style` / `vector-style` vs `realistic-style`:** Never inject noisy PBR roughness maps into constant cel-shaded toon ramps; cel shading requires clean, flat tonal breaks.
- **`psx-horror-style` / `retro-8bit-style` vs High-Subdivision Smooth Shading:** PSX/retro styles rely on low-poly silhouettes, quantized textures, and crisp facets — avoid heavy Catmull-Clark subsurf modifiers.
- **`voxel-style` vs Freeform Sculpting:** Voxel assets must adhere strictly to a uniform block grid.

### Strict Phase Ordering (Never Invert)
1. **Blockout & Scale BEFORE Micro-Detail:** Never add panel greebles or sculpt pores until primary silhouette and real-world dimensions (`get_scene_info`) are locked.
2. **Retopology BEFORE UVs & Rigging:** Never unwrap or weight-paint a raw Dyntopo/high-poly sculpt mesh.
3. **Validation BEFORE Export:** Never run `export-pipeline` / engine export until `get_scene_info(fields=["scale", "ground", "topology"])` and `look(mode="angles")` confirm zero non-manifold errors, applied scale `(1,1,1)`, and proper `COL_` / `SM_` naming.
