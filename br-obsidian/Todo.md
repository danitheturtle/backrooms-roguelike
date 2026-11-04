- Ropes
- connector definition list of connectors should be indexed array instead of dict
- ramp ambient light power depending on distance inside room boundary. Each room gets its own bespoke level calculated based on number of lights turned on.
	- This lets us raise base light level while letting some areas be extra dark and some extra bright. Default should be midrange
	- Sub-rooms shouldn't affect it. only parent room sets ambient level
- save slot delete, rename, sort by save time
- flashlight texture projection with 2 hard circles, one to simulate bounce light? hopefully it won't look shit
- parent/child relationship for connections so only one of them generates the edges (and also doors when we get there)
- navmesh + runtime generation for connections
- move mouse capture out of player state and into global keybinds with fullscreen / screenshot
- throw rugs as cover for carpet seams

Tutorial Layout Updates:
- Add object placement puzzle to final room that unlocks door
- make final room less boxy
- add rope climb, pickup, attach, descend section to final part of tutorial

 tutorial updates:
- 5 - when squeezing, prevent player from falling off ledge
- 5 - vaulting is buggy
- 5 - scroll to impulse dragged object on camera z axis
- 8 - dragged object rotation (remove axis lock)
