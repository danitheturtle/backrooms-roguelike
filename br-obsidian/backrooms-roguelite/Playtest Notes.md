Controls changes:
- Put Crouch/Stand is on toggle, hold to dip into crawl
- Use raycast for target instead of the shapecast. ensure pickup is responsive by updating mouse inupts
- pick up on mousedown. if held, rotate immediately. stop rotate on mouseup
- if rotation delta > n, don't drop even if timer expired

- vaulting is buggy
- spring arm collider to big on some objects, makes precision placement odd. Maybe add full collision for the held object?
- make highlight distance shorter than drag distance
- ladder closes too quickly after releasing f
- ladder path needs adjusted
- throw rugs as cover for carpet seams