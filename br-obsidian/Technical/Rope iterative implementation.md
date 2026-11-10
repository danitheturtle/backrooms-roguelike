see [[Rope]] for design

Build iteratively and test manually at each stage

Unique rope keybind for all rope interactions. Will become an action wheel action later.

1- Static anchor point swinging with fixed distance. anchor manually placed in the world

2- Player-placed anchor point

3 - make rope its own game object with a path and a series of verts. Single anchor point and a point at the player that updates its position to the player while the player is holding the rope

4 - render the rope and only let the player attach while next to it

5 - let the player untie the rope and attach it again. Add a targetable knot object for pick up and placement. No collision yet, just straight line logic. The rope should constrain player movement to its length even under gravity. Player should be able to swing back and forth