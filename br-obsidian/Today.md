refactor player behaviors into own scripts

Controls changes:
- 1 - sprint toggle. stopping movement toggles off
- 1 - if rotation delta > n, don't drop even if timer expired
- 1 - spring arm collider to big on some objects, makes precision placement odd. Maybe add full collision for the held object?
- 1 - make highlight distance shorter than drag distance
- 1 - ladder path needs adjusted
- 1 - dial in climbup min/max height
- 1 - pick up on mousedown. if held, rotate immediately. stop rotate on mouseup
- 3- Put Crouch/Stand on toggle, hold to dip into crawl
- 3 - scroll to change held distance
- 3 - ladder closes too quickly after releasing f
- 3 - stairstepping up small ramps
- 3 - when squeezing, prevent player from falling off ledge
- 3 - Use raycast for target instead of the shapecast. ensure pickup is responsive by updating mouse inupts
- 5 - vaulting is buggy