Action Items:
- new setting for grabbed item rotation speed. separate from camera speed
- much lower and much higher range for mouse sensitivity
- tell player they can scroll to change position of grabbed item
- Make squeeze tutorial bigger to cover the ledge section
- interact can sometimes break a prop and put it on wrong collision layer if picking up and dropping repeatedly while moving the camera rapidly
	- props glitched onto the wrong collision layer can be shoved when they are not supposed to be shoved
- you can ledge grab up into a ceiling. something to do with room connectors. definitely need shapecasting
- Illuminate the jump vault area so its an obvious progression route
- make strafe crawl slightly faster
- Specify which mouse button is keybound
- Add dedicated vault tutorial before combining mechanics with the ladder
- Vault tutorial text is unclear that second jump input is needed
* add another chair to the rocking chair puzzle and narrow the target area depression to make it more obvious
- drag distance needs calculated from nearest point on object collider, probably with a static raycast from player to dragged object
	* use drag distance raycast for line of sight break 
- kill floor that teleports the player to a random position in the generated level. can reuse the player spawn object 
- loading screen, especially important for slower PCs and mobile
- cancel linear and angular velocity when dropping a prop due to sprinting
- cap linear and angular velocity for held props (and maybe non-held props) to a reasonable value
- z to lay down as alternate keybind
- Keyboard shouldn't have long press actions; reserve that input style for controller and touch. Give keyboard alternate keybinds, with an option to enable the controller-style long press defaults.
	-  z for crawl/prone
- spamming space on climbup can break can_stand
- sprinting while crouching can clip into ceiling occasionally
- remove chairs in hallway to ladder. they look cool but make tutorial harder than it needs to be
* add bhopping and adjust how sprint/jump speeds work
- increase number of collisions before freezing a prop by 1
* add position tweening, and don't make it linear or ease_in_out. currently the lack of animation between states plus lack of inertia makes the game feel like a prototype
* give the player a better way to yeet props very hard. maybe make throwing a charge-up so there's precision skill to it?
* players should not impart velocity on dragged objects when crawling or crouching, even if dragged object is on top of them
* players should be able to stand up from underneath a grabbable prop
- instead of preventing sprint while grabbing, slow down default walking speed while grabbing and let player sprint at normal walk speed
- F11 fullsceen doesn't work for some reason 
- if player is in the air and not moving for a while, force all nearby rigidbodies that aren't level geometry out of collision with player.
* allow player to drag grabbable objects while crouched. when dipping into a crouch while grabbing an item, switch behavior modes

Ladder updates:
- only climb ladder if its oriented correctly. fall off ladder if the ladder tips too far
- put ladder hinge on a toggle. hinge timer still exists, enforcing the state the ladder was dropped in. maybe even wait until the velocity is zero
- make ladder targetable from back as well. its very jank not being able to pick it up from the back
- hotkey to self-right the held prop so its y axis is up. helpful when you can't quite rotate the thing accurate

Object Placement puzzles:
- snap held prop into puzzle solution while still grabbing it if its close and within 30 deg
* freeze a solved object placement puzzle. make puzzle piece non-interactable
- Object placement puzzle too precise. Make detection area larger and target smaller
- Tell the player they almost have the solution and hint about orientation if they place the tutorial object placement prop in the right spot but wrong orientation

Squeeze / Shimmy updates:
* Hold key until in the state, then keep player suqeezing until  there's enough space for them to stand. Even up on ledges
- When squeezing, constrain player camera 160 degrees along the axis of squeezing. For gaps where both sides are geometry, rotate towards player camera normal
* if the player has room to unsqueeze but is against a wall they will stay squeezed, preventing other actions



