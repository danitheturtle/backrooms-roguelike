See [[Player Movement]] for exact player movement constraints

When generating a "lock", decide where the key goes at the same time. This goes for all puzzles. A lock can be any lockable connector

When generating a path **blocked** by a [[Heavy Obstacle]], always garuntee at least 1 blue almond water appears somewhere nearby.
##### Climb-ups
* The player can [[Player Movement|Vault]] up a vertical wall of 5 or fewer voxels given there's enough space at the top for them to stand/crouch
* Expect the player can improvise 1 voxel of extra height with some exploration effort and no ladder. Prop density should accomodate this.
- **Assume climb-ups taller than 6 voxels won't be reached by players without a [[Ladder]]**
- When generating a climb-up at a leaf node, either:
	- Ensure player has access to at least 1 ladder
	- Generate a second, fully accessible path as well
##### One-way Drops:
* Any vertically traversable height taller than 6 voxels is a one-way drop
- **Assume player has no [[Rope]] at generation-time**
- Generator should garuntee that players can continue their run after taking a one-way drop by:
	- Placing a ladder tall enough to climb back up after the drop
	- continuing generation post-drop
- One-way drops, even done with rope, reward extra points.
