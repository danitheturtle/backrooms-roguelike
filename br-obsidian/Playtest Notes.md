Action Items:
* players should not impart velocity on dragged objects when crawling or crouching, even if dragged object is on top of them
- use forces instead of directly setting linear and angular velocity for grabbed props
- z to lay down as alternate keybind
- Keyboard shouldn't have long press actions; reserve that input style for controller and touch. Give keyboard alternate keybinds, with an option to enable the controller-style long press defaults.
	-  z for crawl/prone
* add bhopping and adjust how sprint/jump speeds work
* add position tweening, and don't make it linear or ease_in_out. currently the lack of animation between states plus lack of inertia makes the game feel like a prototype
* give the player a better way to yeet props very hard. maybe make throwing a charge-up so there's precision skill to it?
* players should be able to stand up from underneath a grabbable prop
- instead of preventing sprint while grabbing, slow down default walking speed while grabbing and let player sprint at normal walk speed
- F11 fullsceen doesn't work for some reason 
- if player is in the air and not moving for a while, force all nearby rigidbodies that aren't level geometry out of collision with player.
* allow player to drag grabbable objects while crouched. when dipping into a crouch while grabbing an item, switch behavior modes
* add another chair to the rocking chair puzzle and narrow the target area depression to make it more obvious
- drag distance needs calculated from nearest point on object collider, probably with a static raycast from player to dragged object
	* use drag distance raycast for line of sight break 
- Add dedicated vault tutorial before combining mechanics with the ladder
- loading screen, especially important for slower PCs and mobile
- you can ledge grab up into a ceiling, especially by spamming space and positioning the raycast at an edge. definitely need shapecasting
- interact can sometimes break a prop and put it on wrong collision layer if picking up and dropping repeatedly while moving the camera rapidly
	- props glitched onto the wrong collision layer can be shoved when they are not supposed to be shoved

Ladder updates:
- jumping repeatedly lets you climb rapidly
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



