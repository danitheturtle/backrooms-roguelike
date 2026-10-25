- Connectors in the same room should never touch or meet at a right angle.
- Minimum gap between connectors is HALF_VOXEL
- One-sided wall meshes only
- Leave large space between bright rooms to avoid light bleed. Consider this when defining room bounds
- default level geometry size should be 1.0 (2 voxels) and collision shapes should overlap. Helps with physics glitches. Can still have thin walls, but use more sparsely
- All level geometry mesh origins are set to 0 in blender by default. Adjusting the mesh origin changes the uv coordinates of the shared texture
- do not make materials unique. use UV offset instead

Aesthetic considerations:
- as few co-planar pieces of level geometry as possible. things shouldn't line up like real architecture