& = targeting next update

- 3 -&- fix connections
	- temporarily disable uv offset at runtime, then add it back in once things are actually connecting
	- ensure room definitions are accurate. potentially write tests and early-exit the bake if the room is invalid. Don't fail to save room, just set a default def with exclude from gen true
- 8 -&- action wheel
- 5 -&- you can ledge grab up into a ceiling, especially by spamming space and positioning the raycast at an edge. definitely need shapecasting
- 5 -&- add a greybox exit room
- 5 -&- add another greybox exit room
- 5 -&- add a greybox start room
- 3 -&- add a vertical extendable room
- 8 - film photography player behavior
- 8 - ramp ambient light power depending on distance inside room boundary. Each room gets its own bespoke level calculated based on number of lights turned on.
	- This lets us raise base light level while letting some areas be extra dark and some extra bright. Default should be midrange
- 3 - flashlight texture projection with 2 hard circles, one to simulate bounce light? hopefully it won't look shit
- 5 - dragged object rotation (remove axis lock)
- 5 - parent/child relationship for connections so only one of them generates the edges (and also doors when we get there)
- 8 - add position tweening, and don't make it linear or ease_in_out. currently the lack of animation between states plus lack of inertia makes the game feel like a prototype
- 8 - loading screen, especially important for slower PCs and mobile
- 8 - add bhopping and adjust how sprint/jump speeds work https://adrianb.io/2015/02/14/bunnyhop.html
* 8 - tutorial log from pause menu that shows you all tutorials you've seen
- 13 - sound systems
- 13 - navmesh + runtime generation for connections
- 13 - localization
- 5 - save slot rename, sort by save time
- 13 - final ui

Squeeze / Shimmy updates:
- 5 -&- Hold key until in the state, then keep player squeezing until  there's enough space for them to stand. Even up on ledges
- 5 - When squeezing, constrain player camera 160 degrees along the axis of squeezing. For gaps where both sides are geometry, rotate towards player camera normal
- 5 - if the player has room to unsqueeze but is against a wall they will stay squeezed, preventing other actions

Object Placement puzzles:
- 1 -&- snap held prop into puzzle solution while still grabbing it if its close and within 30 deg
- 1 -&- freeze a solved object placement puzzle. make puzzle piece non-interactable
- 3 -&- Tell the player they almost have the solution and hint about orientation if they place the tutorial object placement prop in the right spot but wrong orientation'
- 3 -&- Make the code reusable

Tutorial Layout Updates:
- 5 -&- Add dedicated vault tutorial before combining mechanics with the ladder
- 5 -&- add rope climb, pickup, attach, descend section to final part of tutorial
