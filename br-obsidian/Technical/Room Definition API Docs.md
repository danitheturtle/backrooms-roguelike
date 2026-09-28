Spawn probability (room rarity)

Only spawn after n iterations (late game room)

Bounds (AABB ordered array in room-local space)
- special case for infinite 

Can Spawn Object Tags
*set (dictionary<string,bool>) of things level gen can force to spawn in the room.*
- objectPlacementPuzzle
- ladder
- ladderFreestanding
- ladderTall
- skeleton key
- etc.

Connections
* position in room-local space
* subtype
  *If subtype is NONE at gen-time, it can be changed by the level generator to force a specific subtype. If the subtype already exists, its an intentional part of the room design*
	* NONE is just a straight passthrough
	* DOOR is any kind of door
	* LOCKED_DOOR is a locked door that requires some action to open
	* NULL_ZONE is a hidden door. a wall you can noclip through
	* NULL_ZONE_ONE_WAY is a null zone that can only be clipped through in one direction
* normal
* size (vec2)
* corner1, corner2
* distFromFloor
  *Dist from bottom wall edge, 0 for floors, or ceiling height*
* depth
  *to calculate real height of vertical connections, you need the depth plus dist from floor. Climbup height of adjacent floor/ceiling connections is distFromFloor1+distFromFloor2+depth1+depth2*
* at ceiling? *true if ceiling or wall with edge at ceiling*
* biome
* connection layer (int)
	* some rooms generate with blocking walls that prevent traversal even if the player has access to puzzle objects
		* Useful for tiny sub-voxel gaps the player can only look through. unbreakable windows. bottomless pits. etc.
	* Each layer of connections should be treated as a sub-room
	* Connection layer is meaningless for inter-room connections. any layer can connect to any other layer for level gen purposes.
	* there to let you know the room has internal traversal constraints

Biome Type(s)
- all rooms have at least one
- if more than one, this is a transition room
	- biomes can only change using a transition room. Transition rooms should be rare enough that the generated biomes are pretty big.
	- Loopbacks ignore this rarity
- Only one or two biomes in first release

Dynamic Room Props (dict<string,Variant>. Probably not useful for level gen. Passed back to a scene that defines multiple rooms when instantiating it to tell it which room to place as)

When do locked doors get generated?