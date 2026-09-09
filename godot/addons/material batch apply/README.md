# Material Batch Apply

A free Godot 4 editor plugin that lets you apply or clear a `Material` on multiple `MeshInstance3D` nodes at once — no more clicking through each mesh one by one.

Made by **Raykit Studio**.

# Features

- Auto-detects every `MeshInstance3D` in the currently edited scene
- Checklist UI with a real-time, case-insensitive search filter (with a built-in clear button)
- Apply a material to all checked nodes in one click
- Clear only removes materials that were applied through this tool — it never touches a mesh's original material
- Full Undo/Redo support (Ctrl+Z / Ctrl+Y) via Godot's built-in `EditorUndoRedoManager`
- Clear popup notifications for every action (success, no material selected, no node checked, etc.)

# Requirements

- Godot 4.x

# Installation

1. Download or clone this repository
2. Copy the `material batch apply` folder into your project's `res://addons/` directory
3. In Godot, go to **Project → Project Settings → Plugins**
4. Enable **Material Batch Apply**
5. A new **"Material Batch"** tab will appear in the bottom panel

# Usage

1. Open the **Material Batch** tab in the bottom panel
2. Select a `Material` resource in the **Material** slot
   - Note: this slot only accepts `Material` resources (e.g. `.tres`), not image files (`.png`, `.jpg`, etc.). If your color/texture is a plain image, create a `StandardMaterial3D` first and assign the image to its **Albedo → Texture** slot.
3. Use the **Search node...** field to quickly find a mesh if your scene has many
4. Check the boxes next to the meshes you want to affect
5. Click **Apply** to apply the material, or **Clear** to remove any material previously applied through this tool
6. Every action can be undone with Ctrl+Z

# How it works

This plugin uses `material_override` on `MeshInstance3D`, which sits *on top of* a mesh's original material without changing it. That means:

- **Apply** temporarily covers the original material
- **Clear** removes that override and reveals the original material again
- If a mesh never had an override applied, **Clear** will simply report that there was nothing to clear

# License

Released under the MIT License — see [LICENSE](LICENSE) for details.