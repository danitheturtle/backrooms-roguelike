- 1 - move mouse capture out of player state and into global keybinds with fullscreen / screenshot
- 1 - F11 fullsceen doesn't work for some reason
* 3 - add another chair to the rocking chair puzzle and narrow the target area depression to make it more obvious
- 3 - if player is in the air and not moving for a while, force all nearby rigidbodies that aren't level geometry out of collision with player.
- 3 - drag distance needs calculated from nearest point on object collider, probably with a static raycast from player to dragged object
	* 1 - use drag distance raycast for line of sight break 
- 3 - charge up throw over hold_time to let player determine how hard to throw object
- 3 - connector definition list of connectors should be indexed array instead of dict (will need updated when merging monica's code)
- 3 - scroll to impulse dragged object on camera z axis
- 3 - flashlight texture projection with 2 hard circles, one to simulate bounce light? hopefully it won't look shit
- 3 - use forces instead of directly setting linear and angular velocity for grabbed props
- 3 - Keyboard shouldn't have long press actions; reserve that input style for controller and touch. Give keyboard alternate keybinds, with an option to enable the controller-style long press defaults.
	-  z for crawl/prone
- 3 - hotkey to self-right the held prop so its y axis is up. Playtest also correcting its rotation around y axis. Helpful when you can't quite rotate the thing accurate
- 8 - Ropes
- 5 - dragged object rotation (remove axis lock)
- 5 - save slot rename, sort by save time
- 5 - instead of preventing sprint while grabbing, slow down default walking speed while grabbing and let player sprint at normal walk speed
- 8 - ramp ambient light power depending on distance inside room boundary. Each room gets its own bespoke level calculated based on number of lights turned on.
	- This lets us raise base light level while letting some areas be extra dark and some extra bright. Default should be midrange
- 5 - parent/child relationship for connections so only one of them generates the edges (and also doors when we get there)
* 8 - add position tweening, and don't make it linear or ease_in_out. currently the lack of animation between states plus lack of inertia makes the game feel like a prototype
* 5 - allow player to drag grabbable objects while crouched. when dipping into a crouch while grabbing an item, switch behavior modes
- 8 - loading screen, especially important for slower PCs and mobile
- you can ledge grab up into a ceiling, especially by spamming space and positioning the raycast at an edge. definitely need shapecasting
* 8 - add bhopping and adjust how sprint/jump speeds work https://adrianb.io/2015/02/14/bunnyhop.html
- 13 - navmesh + runtime generation for connections

Squeeze / Shimmy updates:
* Hold key until in the state, then keep player suqeezing until  there's enough space for them to stand. Even up on ledges
- When squeezing, constrain player camera 160 degrees along the axis of squeezing. For gaps where both sides are geometry, rotate towards player camera normal
* if the player has room to unsqueeze but is against a wall they will stay squeezed, preventing other actions

Object Placement puzzles:
- snap held prop into puzzle solution while still grabbing it if its close and within 30 deg
* freeze a solved object placement puzzle. make puzzle piece non-interactable
- Object placement puzzle too precise. Make detection area larger and target smaller
- Tell the player they almost have the solution and hint about orientation if they place the tutorial object placement prop in the right spot but wrong orientation

Tutorial Layout Updates:
- Add dedicated vault tutorial before combining mechanics with the ladder
- add rope climb, pickup, attach, descend section to final part of tutorial
