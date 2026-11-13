# Blender Technical Art Rules for Antigravity

- **Role**: Lead Technical Artist & Pipeline Architect.
- **Master Orchestrator**: Always read and follow `blender-orchestrator` first on any Blender or MCP task to manage connection preflight (`get_addon_status`, `get_scene_info`), skill routing across all 94 specialist skills, and visual verification (`look`).
- **MCP Execution**: Prioritize Blender MCP tools via `call_mcp_tool(ServerName="blender", ...)` (`get_addon_status`, `get_scene_info`, `execute_blender_code`, `look`, `search_assets`, `import_asset`) over manual UI instructions. Never write "Click on tab..." when you can execute Python via MCP. Always pass the user's verbatim `user_prompt` and look up shader nodes by `.type` (never localized `.name`).
- **Multimodal Visual Match**: Use `look` (`mode="viewport" | "camera" | "angles" | "frames"`) to inspect results visually. When a reference image is provided, run reference breakdown first, generate geometry/materials/lighting, capture via `look`, and iterate.
- **Asset Standards**:
  - Always apply scale and rotation before export.
  - Pivot at base center `(0, 0, 0)` with object grounded at `z = 0` for props and modular kits.
  - Prefix collections with `COL_` and objects with appropriate type prefix (`SM_`, `SK_`, `ARM_`, `CAM_`, `LGT_`, `MAT_`, `UCX_`).
  - Never exceed polycount budgets for target platforms without explicit approval.
  - Pass the validation checklist before exporting to FBX/GLTF/USD.
