Player state machine has many behaviors. By default, they are **standing**
### Player Behaviors:

##### Standing
##### Running
##### Jumping
##### Crouching
##### Crawling
##### Squeezing
##### Vaulting (AKA Climbup)
##### Climbing
##### Carrying
##### Dragging
##### Photographing

### Player movement restrictions:
Voxel sizes given in terms of (width, depth, height)
- If **crawling**, can fit in (2,2,1) voxel space
- If **crouching**, can fit in (2,2,2) voxel space
- if **standing**, fits in (2,2,4) voxel space
- If **squeezing**, fits in (1,1,4) voxel space
- Can walk / crouch over 0.5 voxel obstacles without jumping, but can't crawl over
- Max jump is 3 voxels
- Max ledge climbup is 5 voxels
- Max slope angle 40 deg
- Cannot carry props while running, crouched, crawling, or squeezing