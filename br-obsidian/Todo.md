- 3 - charge up throw over hold_time to let player determine how hard to throw object
- 3 - connector definition list of connectors should be indexed array instead of dict (will need updated when merging monica's code)
- 3 - scroll to impulse dragged object on camera z axis
- 3 - flashlight texture projection with 2 hard circles, one to simulate bounce light? hopefully it won't look shit
- 13 - Ropes
- 5 - dragged object rotation (remove axis lock)
- 5 - instead of preventing sprint while grabbing, slow down default walking speed while grabbing and let player sprint at normal walk speed
* 5 - allow player to drag grabbable objects while crouched. when dipping into a crouch while grabbing an item, switch behavior modes
- 5 - you can ledge grab up into a ceiling, especially by spamming space and positioning the raycast at an edge. definitely need shapecasting
- 5 - save slot rename, sort by save time
- 8 - ramp ambient light power depending on distance inside room boundary. Each room gets its own bespoke level calculated based on number of lights turned on.
	- This lets us raise base light level while letting some areas be extra dark and some extra bright. Default should be midrange
- 5 - parent/child relationship for connections so only one of them generates the edges (and also doors when we get there)
* 8 - add position tweening, and don't make it linear or ease_in_out. currently the lack of animation between states plus lack of inertia makes the game feel like a prototype
- 8 - loading screen, especially important for slower PCs and mobile
* 8 - add bhopping and adjust how sprint/jump speeds work https://adrianb.io/2015/02/14/bunnyhop.html
- 13 - navmesh + runtime generation for connections

Squeeze / Shimmy updates:
* 5 - Hold key until in the state, then keep player squeezing until  there's enough space for them to stand. Even up on ledges
- 5 - When squeezing, constrain player camera 160 degrees along the axis of squeezing. For gaps where both sides are geometry, rotate towards player camera normal
* 5 - if the player has room to unsqueeze but is against a wall they will stay squeezed, preventing other actions

Object Placement puzzles:
* 1 - snap held prop into puzzle solution while still grabbing it if its close and within 30 deg
* 1 - freeze a solved object placement puzzle. make puzzle piece non-interactable
* 3 - Tell the player they almost have the solution and hint about orientation if they place the tutorial object placement prop in the right spot but wrong orientation

Tutorial Layout Updates:
- 5 - Add dedicated vault tutorial before combining mechanics with the ladder
- 5 - add rope climb, pickup, attach, descend section to final part of tutorial
