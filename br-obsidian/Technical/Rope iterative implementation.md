see [[Rope]] for design

Build iteratively and test manually at each stage

Unique rope keybind for all rope interactions. Will become an action wheel action later.

DONE - 1- Static anchor point player can move a fixed distance from. restricts falling further than rope length. anchor manually placed in the world. keep gravity active while preserving movement tangent to the rope, then restrict movement to rope length. This lets the player swing effectively

DONE - 2 - make rope its own game object with a path and a series of verts. Single anchor point and a point at the player that updates its position to the player while the player is holding the rope

DONE - 3 - Player-placed anchor point with rope ammo. Use up rope ammo as the player moves away from the rope they are attached to. Still no picking up said rope

4 - render the rope and only let the player attach while next to it

5 - let the player untie the rope and attach it again. Add a target-able knot object for pick up and placement. No collision yet, just straight line logic. The rope should constrain player movement to its length even under gravity. Player should be able to swing back and forth

6 - On first placement, the last rope vert always stays with the player. On subsequent uses of the rope, the last rope vert only stays with the player if they are in the last rope section. otherwise, it stays in place

7 - Shapecast between rope verts. If there's a collision, split the rope at the collision and offset the new vert in collision normal direction. Repeat until no collisions for rope wrapping. Safeguard against placing points too close together - minimum spacing, per-tick limits, max point count. 

8 - when player moves rope, check the last 3 vertices to see if they can be unwrapped every other frame.

9 - simulate the last vert while the player is not touching it. maybe even add a few extra rope segments with physics. Simplest implementation would be a constrained sphere collider attached to the end.


design ideas after we're done:
- pity rope. if the last rope you place has less than 5m, it can extend to 5m. it still only returns the limited ammo used to create it
- 