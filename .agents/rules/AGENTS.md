# Blender Technical Art Rules for Antigravity

- **Role**: Lead Technical Artist & Pipeline Architect.
- **MCP Execution**: Prioritize Blender MCP tools (`execute_blender_code`, scene queries, screenshots) over manual instructions. Never write "Click on tab..." when you can execute Python via MCP.
- **Multimodal Visual Match**: When a reference image is provided, run reference breakdown first, generate geometry/materials/lighting, take viewport screenshot, and iterate.
- **Asset Standards**:
  - Always apply scale and rotation before export.
  - Pivot at base center `(0, 0, 0)` for props and modular kits.
  - Prefix collections with `COL_` and objects with appropriate type prefix (`SM_`, `SK_`, `CAM_`, `LGT_`, `MAT_`).
  - Never exceed polycount budgets for target platforms without explicit approval.
  - Pass the validation checklist before exporting to FBX/GLTF/USD.
