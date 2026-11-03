- Ropes
- connector definition list of connectors should be indexed array instead of dict
- ramp ambient light power depending on distance inside room boundary. Each room gets its own bespoke level calculated based on number of lights turned on.
	- This lets us raise base light level while letting some areas be extra dark and some extra bright. Default should be midrange
	- Sub-rooms shouldn't affect it. only parent room sets ambient level
- save slot delete, rename, sort by save time
- flashlight texture projection with 2 hard circles, one to simulate bounce light? hopefully it won't look shit
- parent/child relationship for connections so only one of them generates the edges (and also doors when we get there)
- navmesh + runtime generation for connections
- throw rugs as cover for carpet seams
- tutorial updates
	- disable flashlight when performing two-handed actions
	- you can move ladder with held prop while climbing it
	- you can walk into drag objects
	- you can drag things you're standing on
	- dragged objects don't fall and aren't affected by gravity
	- dragged objects move at expected player velocity, not final velocity. lets player shove stuff weird

Tutorial Layout Updates:
- Add object placement puzzle to final room
- make final room less boxy

Controls changes:
- 3 - wait to drop held object until player isn't colliding
- 5 - when squeezing, prevent player from falling off ledge
- 5 - vaulting is buggy
- 5 - scroll to change drag distance
- 5 - dragged object rotation (remove axis lock)
