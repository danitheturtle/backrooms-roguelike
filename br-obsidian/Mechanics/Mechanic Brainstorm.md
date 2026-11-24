##### Main Dump
* camera zoom?
* perspective puzzle
* progressive clue system like endfield but good. pick up parts of different stories on different runs. take pictures of environmental storytelling and it gets catalogued. etc.
* temporary basebuilding with found objects. saveable? new start location?
* If you end a run with a photo of a unique room or setpiece, you can spend the photo to increase / decrease the chances of it appearing again
* if you destroy a security camera, another one materializes behind you. Out of view but facing the player. Spooky!
* forklift thats holding a bin in two positions, up or down, and can be toggled like endfield. Maybe the player can move the forklift
* "Anchor points" you can attach to walls while rope climbing so its not just up and down traversal
* rope spike gun that can shoot into and anchor on drywall
* **static ladder inside a dynamic room with multiple definitions. dynamic height vertical traversal that is garunteed. probably need this**
* loadouts where more impactful items are bigger and you gotta fit everything into the backpack including loot like in dredge
* two tutorial paths, one for experienced users and one for genre noobs
* scan action that reveals all interactable objects color-coded by use
* meta-progression ARG where the user has to do real cryptography and put clues together across many runs. once solved, similar to animal well, unlocks a way to teleport and spawn specific parts of the map. basically a cheat code but you've gotta unlock it.
* Game is about finding unique "exits" and Finding one gives you a huge score boost

##### Lighting
Every light has a small chance to start flickering and/or go out. Some lights are permanently like this, others only start flickering once the player begins exploration.
- this combines with the weeping angel mechanic where a player might think they are safe but the light they are relying on goes out
* Shining a flashlight on an angel drains the battery much faster
* Lights within the vicinity of an angel have a much higher probability to flicker, so you'd only really be safe in a well-lit room which should be rare
##### Rope:
* grab rope section closest to camera / target cast rather than closest to harness for better gamefeel
- instead of picking up entire slack rope, insert new path control point close to player and shorten end of rope by amount player lengthens it at sub-section
- simulate the last vert while the player is not touching it. maybe even add a few extra rope segments with physics. Simplest implementation would be a constrained sphere collider attached to the end.
- pity rope. if the last rope you place has less than 5m, it can extend to 5m. it still only returns the limited ammo used to create it
- give player inertia while on pendulum to give swinging better gamefeel