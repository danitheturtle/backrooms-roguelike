Voxel sizes given in terms of (width, depth, height)

Player movement restrictions:
- If crawling, can fit in (2,2,1) voxel space
- If crouching, can fit in (2,2,2) voxel space
- if standing, fits in (2,2,4) voxel space
- If squeezing, fits in (1,1,4) voxel space
- Can walk / crouch over 0.5 voxel obstacles without jumping, but can't crawl over
- Max jump is 3 voxels
- Max ledge climbup is 5 voxels
- Max slope angle 40 deg
- Cannot carry props while running, crouched, crawling, or squeezing

When generating a "lock", decide where the key goes at the same time. This goes for all puzzles

Object Placement Puzzles:
- Objects in a room will be in a sequence or pattern, with one or two out of place. Player must look around and find the missing object, then place it in the correct position/orientation.
- **Object placement puzzles open otherwise un-openable doors** automatically with an audible hinge creak to let the player know something in the level changed
- Taking a photo of a solved object placement puzzle rewards extra points, enough that waiting until you notice a puzzle is worth it over taking pictures of individual props.

Null Zones
* Sometimes walls aren't walls and floors aren't floors. They let you clip through what looks like a wall
* By default, no visual indication. Occasionally they will start showing visual artifacts or there will be blue painters tape outlining them
* Null zones do not appear on camera. Instead you can see what's behind them without comitting
* Solving a puzzle can cause a nearby null zone to become obvious

Cameras
* Some things can only be seen on film or through a digital sensor
* After getting a digital camera upgrade, player can use the camera's digital viewfinder held up in front of them to visualize camera-only things in real time
* Taking a photo with a digital camera attracts the ravenous hunger of The Creator. The photo never makes it off the device as the second its stored to memory a black blobby entity comes out of the walls and eats the data and destroys the camera, requiring the player to get a new one
* Some puzzle solutions and wall writing are only visible through a camera
* all cameras can zoom

Rope
- The player starts the game with a certain length of consumable rope, and can find more.
- Rope can be attached to a static or heavy prop anchor point. This starts the length counter as the player moves away.
- The rope does not pull on its anchor - treats it as static
- The player can drop off the rope at any point and the rope will stop its extension there
- If the player runs out of rope, the only option is to climb back up or drop.
- Rope only gets extended if player has enough rope and climbs past the end.
- Rope only gets recoiled when interacting with its anchor point, which picks the whole line up
- Rope uses an ammo system and is not a prop. Rope pickups get consumed to increase rope ammo.
- Props can be held while climbing

Ladders
- Various sized ladders spawn in the world with fixed climb heights.
- The player can stand on top of a properly placed ladder
- Some ladders are free-standing, others need to be leaned against a wall.
- Ladders can be improvised with enough physics props in a given area, but stacking more than one physics object gets tedious.
	- **Expect the player can improvise 1 voxel of extra height with some exploration effort and no ladder.** Prop density should accomodate this.
- Props can be held while climbing, even other ladders

One-way Drops:
- Floor holes are almost always one-way without rope.
- **Assume player has no rope at generation-time**
- Generator should garuntee that players can continue their run after taking a one-way drop
- Player can take fall damage if they fall too far. Playtest for good height
- One-way drops, even done with rope, reward extra points.

Climb-ups at 6 or more voxels:
- **Assume climb-ups taller than 6 voxels won't be reached by players without a ladder**
- When generating a climb-up at a leaf node, either:
	- Ensure player has access to at least 1 ladder
	- Generate a second, fully accessible path as well

Almond Water
- 3 types: Energy (Blue), Sanity (White), Health (Red)
- Blue is very common. White is uncommon. Red is extremely rare
- Only unopened almond water is safe. Drinking an almond water thermos with its cap off is risky and has a 50% chance to have an opposite deleterious effect
- The player can carry 3 unconsumed almond water at any given time (there are 3 types)
- Drinking takes a few seconds and must be done while standing with flashlight turned off (default player state)

Energy Pips
- The player has 3 energy pips that form their energy bar
- Running or climbing drains the energy bar at a constant rate
- Heavy exertion (dragging large objects or performing a climb-up) consumes an energy pip
- Blue Almond Water pickups restore a single pip

Heavy Obstacles
- Some paths will generate with large blocking obstacles that require stamina pips to move.
- Without stamina pips, progression is impossible in this direction.
- **When generating a path blocked by a heavy obstacle, always garuntee at least 1 blue almond water appears somewhere nearby.**

The Creator's Fungus & Oxygen Masks
- Fungal Spores permeate the entire atmosphere of the backrooms and are the way The Creator gets into the bloodstream to read and influence thought.
- Breathing in the backrooms isn't exactly safe. Your sanity will constantly drain and once empty, you take health damage.
- The effect starts slow but gets worse as you go deeper
- Some areas visibly overtaken by fungus increase this rate significantly, but are also worth extra points for photographing
- Fungus spreads rapidly, even into areas of the map already explored. (hard, stretch goal)
- Traditional masks do not work. You must bring your own atmosphere to negate this effect, which the player will not have on their first or even fifth run.
- After unlocking the mask, oxygen tanks work on an ammo system
- **Player cannot progress through rooms entirely overtaken by fungus without a gas mask and available oxygen**
	- Generate them to the side of the critical path before mask is unlocked to build curiosity
	- Once mask is unlocked, they can be part of the late-game critical path if enough oxygen is placed in the level

Locked Doors
* Smallest lockable door size is 2x2 voxels
- Connections can sometimes be locked doors. Skeleton Keys found in the level open them. Probably not 1-1, any key can open any locked door. Mayyyybe add a tier or color system.
- Definitely no lockpicking minigame
- **Give player fewer skeleton keys than there are locked doors**, forcing them to choose one to unlock.
- **If a player unlocks a door, garuntee that there is (1) level progression, or if that's not possible (2) something interesting on the other side worth photo points.**