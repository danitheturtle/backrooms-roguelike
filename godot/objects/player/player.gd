extends CharacterBody3D
class_name Player

const BehaviorStateRes = preload("res://objects/player/behavior_state.gd")

var behaviors: BehaviorState = BehaviorStateRes.new(self)
var b: BehaviorState:
    get: return behaviors

# global constants
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")
var GRAVITY_VECTOR = ProjectSettings.get_setting("physics/3d/default_gravity_vector")

@export var PLAYER_SPEED = 4.0
@export var PLAYER_MASS = 40.0
@export var SPRINT_SPEED = 7.0
@export var SLOWED_SPEED = 1.5
@export var EXTRA_SLOW_SPEED = 0.5
@export var CLIMB_SPEED = 2.0
@export var GRAB_SPEED = 2.5
@export var SHOVING_FORCE = 2.0
@export var STRONGER_DOWNWARD_GRAVITY_THRESHOLD = 5.0
@export var STRONGER_GRAVITY_MULTIPLIER = 2.0
@export var JUMP_IMPULSE = 6.5
@export var CROUCH_HEIGHT = 0.95
@export var CRAWL_HEIGHT = 0.45
@export var SQUEEZE_RADIUS = 0.2
@export var SLOWED_CAMERA_DAMPING = 0.4
@export var HELD_INPUT_TIMEOUT = 0.5
@export var SLIDE_IMPULSE = 7.5
@export var SLIDE_DECELERATION = 20.0
@export var MAX_STEP_HEIGHT = 0.3
@export var VAULT_DURATION = 0.4

# child nodes
@onready var camera: Camera3D = $Camera
@onready var playerCollider: CollisionShape3D = $PlayerCollisionShape3D
@onready var playerShape: Shape3D = playerCollider.shape
@onready var grabArm: SpringArm3D = $Camera/GrabArm
@onready var grabAnchor: Area3D = $Camera/GrabArm/Anchor
@onready var roomForStateChangeArea: Area3D = $RoomForStateChangeDetector
@onready var roomForStateChangeCollider: CollisionShape3D = $RoomForStateChangeDetector/StateChangeCollisionShape3D
@onready var roomForStateChangeShape: CapsuleShape3D = roomForStateChangeCollider.shape
@onready var adjacentDetectorArea: Area3D = $AdjacentDetector
@onready var actionTimer: Timer = $ActionTimer
@onready var interactTimer: Timer = $InteractTimer
@onready var crawlTimer: Timer = $CrawlTimer
@onready var sprintTimer: Timer = $SprintTimer

# local state
var moveDir: Vector2
var cameraMoveDir: Vector2
var movePriority: Dictionary[StringName, bool]
var mouseCaptured: bool
var actionTimerFinished: bool
var interactTimerFinished: bool
var crawlTimerFinished: bool
var sprintTimerFinished: bool
# tracked via roomForStateChangeArea
var nearbyBodies: Dictionary[Node3D, bool] = {}
# holdable object targeted by spring arm (but not picked up)
var objectInReachRef: Holdable
# grabbed or dragged
var heldObjectRef: Holdable
var throwHeldOnNextFrame: bool
var draggedPoint: Vector3
# some objects change player controls contextually based on adjacency, eg ladders
var adjacentRef: Node3D

# defaults stored at runtime
var standingHeight: float
var standingRadius: float
var cameraTopOffset: float
var grabArmLength: float
var grabArmShapeRadius: float

func reinit() -> void:
    moveDir = Vector2(0.0,0.0)
    cameraMoveDir = Vector2(0.0,0.0)
    movePriority = { left = false, right = false, forward = false, backward = false }
    mouseCaptured = false
    actionTimerFinished = false
    interactTimerFinished = false
    crawlTimerFinished = false
    sprintTimerFinished = false
    objectInReachRef = null
    heldObjectRef = null
    throwHeldOnNextFrame = false
    draggedPoint = Vector3.ZERO
    adjacentRef = null
    global_position = Vector3(0,0,0)
    global_rotation = Vector3(0,0,0)
    grabArm.spring_length = grabArmLength
    grabArm.shape.radius = grabArmShapeRadius
    actionTimer.stop()
    interactTimer.stop()
    crawlTimer.stop()
    sprintTimer.stop()
    set_default_positions()
    for nextBehavior: PlayerBehavior in b.all(): nextBehavior.reinit()
    # disable until level_ready
    process_mode = Node.PROCESS_MODE_DISABLED

func _ready() -> void:
    State.player = self
    standingHeight = playerShape.height
    standingRadius = playerShape.radius
    cameraTopOffset = playerShape.height - camera.position.y
    grabArmLength = grabArm.spring_length
    grabArmShapeRadius = grabArm.shape.radius
    # wire up signals
    roomForStateChangeArea.body_entered.connect(on_room_for_state_change_body_entered)
    roomForStateChangeArea.body_exited.connect(on_room_for_state_change_body_exited)
    adjacentDetectorArea.body_entered.connect(on_adjacent_entered)
    adjacentDetectorArea.body_exited.connect(on_adjacent_exited)
    adjacentDetectorArea.area_entered.connect(on_adjacent_area_entered)
    adjacentDetectorArea.area_exited.connect(on_adjacent_area_exited)
    grabAnchor.body_entered.connect(on_grab_anchor_entered)
    grabAnchor.body_exited.connect(on_grab_anchor_exited)
    actionTimer.wait_time = HELD_INPUT_TIMEOUT
    interactTimer.wait_time = HELD_INPUT_TIMEOUT
    crawlTimer.wait_time = HELD_INPUT_TIMEOUT
    sprintTimer.wait_time = HELD_INPUT_TIMEOUT
    actionTimer.timeout.connect(on_action_timer_ended)
    interactTimer.timeout.connect(on_interact_timer_ended)
    crawlTimer.timeout.connect(on_crawl_timer_ended)
    sprintTimer.timeout.connect(on_sprint_timer_ended)
    for nextBehavior: PlayerBehavior in b.all(): nextBehavior.player_ready()
    reinit()

func _physics_process(_delta: float) -> void:
    # vault -> jump process is call order dependant since successful vault prevents jump
    b.vault.process_action(_delta)
    b.jump.process_action(_delta)
    b.rotate.process_action(_delta)
    b.climb.process_action(_delta)
    b.crouch.process_action(_delta)
    b.sprint.process_action(_delta)
    # handle camera rotation. skip if input is being used for object rotation
    if (!b.rotate.active):
        var cameraVelocity = -GameSettings.CameraSensitivity
        if (b.grab.active || b.drag.active):
            cameraVelocity *= SLOWED_CAMERA_DAMPING
        if (cameraMoveDir.y < 0 && camera.rotation_degrees.x < 85) || (cameraMoveDir.y > 0 && camera.rotation_degrees.x > -85):
            camera.rotate_x(cameraMoveDir.y * cameraVelocity)
        rotate_y(cameraMoveDir.x * cameraVelocity)
        if (mouseCaptured):
            cameraMoveDir = Vector2.ZERO
    # apply gravity and movement, skipping for behaviors that directly manipulate position
    if b.none([&"climb", &"vault"]):
        var movementSpeed: float = get_current_move_speed() + b.crouch.slideVelocity
        # dampen side-to-side movement when crawling
        var moveDirXComponent  = moveDir.x if !b.crawl.active else moveDir.x * 0.1
        #multiply basis vectors by input direction. preserve vertical velocity
        velocity = Vector3(0,velocity.y,0) + Vector3(basis.x * moveDirXComponent + basis.z * moveDir.y).limit_length() * movementSpeed
        #apply gravity acceleration. apply more strongly if falling
        if (velocity.y >= STRONGER_DOWNWARD_GRAVITY_THRESHOLD):
            velocity += GRAVITY*_delta * GRAVITY_VECTOR
        else:
            velocity += GRAVITY*STRONGER_GRAVITY_MULTIPLIER*_delta * GRAVITY_VECTOR
    # process behaviors that inherit player movement
    b.shove.process_action(_delta)
    b.stairstep.process_action(_delta)
    if heldObjectRef != null:
        if b.grab.active:
            if throwHeldOnNextFrame:
                b.throw.start_action()
            else:
                b.grab.process_action(_delta)
        elif b.drag.active:
            b.drag.process_action(_delta)
    # finally, move and slide
    move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        handle_mouse_input(event)
    elif event is InputEventJoypadMotion:
        handle_axis_input(event)
    else:
        handle_key_input(event)

func set_default_positions() -> void:
    playerShape.height = standingHeight
    playerShape.radius = standingRadius
    playerCollider.position.y = standingHeight / 2.0
    playerCollider.rotation.z = 0.0
    roomForStateChangeShape.height = standingHeight
    roomForStateChangeShape.radius = standingRadius
    roomForStateChangeCollider.position.y = standingHeight / 2.0
    camera.position.y = standingHeight - cameraTopOffset
    b.flashlight.light.position.x = b.flashlight.offset.x
    b.flashlight.light.position.y = b.flashlight.offset.y

func can_shape_change():
    var detectedCollisions: Array[Node3D] = nearbyBodies.keys()
    return detectedCollisions.size() == 0

func try_clear_hover_state():
    if objectInReachRef != null:
        objectInReachRef.clear_hover_material()
        objectInReachRef = null

func get_current_move_speed() -> float:
    if b.sprint.active:
        return SPRINT_SPEED
    elif b.some([&"crouch", &"squeeze", &"drag", &"film_camera"]):
        return SLOWED_SPEED
    elif b.grab.active:
        return GRAB_SPEED
    elif b.crawl.active:
        return EXTRA_SLOW_SPEED
    else:
        return PLAYER_SPEED

func on_room_for_state_change_body_entered(_body: Node3D):
    nearbyBodies[_body] = true

func on_room_for_state_change_body_exited(_body: Node3D):
    nearbyBodies.erase(_body)
    if (b.squeeze.active && !Input.is_action_pressed("squeeze")):
        if (b.stand.can_act()):
            b.stand.start_action()
            if (Input.is_action_pressed("sprint")):
                b.sprint.start_action()

func on_grab_anchor_entered(body: Node3D):
    if (body is Holdable && objectInReachRef != body && (b.grab.can_act() || b.drag.can_act())):
        objectInReachRef = body
        objectInReachRef.apply_hover_material()

func on_grab_anchor_exited(body: Node3D):
    if (body == objectInReachRef): try_clear_hover_state()

func on_adjacent_entered(body: Node3D):
    # only used for climbing right now
    # some climbable objects don't need an activation area
    if (body.is_in_group("climbable") && body.get_node_or_null("ActivationArea") == null):
        adjacentRef = body

func on_adjacent_exited(body: Node3D):
    if (adjacentRef == body && body.get_node_or_null("ActivationArea") == null):
        adjacentRef = null

func on_adjacent_area_entered(area: Node3D):
    var areaParent = area.get_parent()
    if (areaParent.is_in_group("climbable")):
        adjacentRef = areaParent

func on_adjacent_area_exited(area: Node3D):
    var areaParent = area.get_parent()
    if (areaParent == adjacentRef):
        adjacentRef = null

func on_action_timer_ended(): actionTimerFinished = true

func on_interact_timer_ended(): interactTimerFinished = true

func on_crawl_timer_ended():
    crawlTimerFinished = true
    # on long keypress, crawl immediately
    if b.crawl.can_act():
        b.crawl.start_action()

func on_sprint_timer_ended():
    sprintTimerFinished = true

func handle_mouse_input(event: InputEventMouseMotion) -> void:
    if mouseCaptured:
        cameraMoveDir = event.screen_relative / 100.0
        get_tree().root.set_input_as_handled()

# one action trickles to one function call, where various side effects happen
func handle_key_input(event: InputEvent ) -> void:
    var eventHandled: bool = false
    if (event.is_action_pressed("jump")):
        # try standing from crawling
        if (b.crawl.active && b.crouch.can_act()):
            b.crouch.tryStandAfterCrouching = true
            b.crouch.start_action()
        # stand from crouching
        elif (b.crouch.active && b.stand.can_act()):
            b.stand.start_action()
        # climb if possible
        elif (b.climb.can_act() && !Input.is_action_pressed("sprint")):
            b.climb.start_action()
        # vault/jump if possible. one of these actions will happen next; synced to physics
        else:
            # seperate unhandledInputs because can_act() conditions diverge
            if b.vault.can_act(): b.vault.unhandledInput = true
            if b.jump.can_act(): b.jump.unhandledInput = true
        eventHandled = true
    elif (event.is_action_pressed("crouch")):
        crawlTimerFinished = false
        crawlTimer.start()
        # always crouch immediately on key press; track previous behavior
        if b.crouch.can_act():
            b.crouch.tryStandAfterCrouching = false
            if b.crawl.active:
                b.crouch.previousBehavior = &"crawl"
            else:
                b.crouch.previousBehavior = &"stand"
            b.crouch.start_action()
        eventHandled = true
    elif (event.is_action_released("crouch")):
        crawlTimer.stop()
        # do nothing if action was captured on pressed
        if !b.crouch.previousBehavior.is_empty():
            b.crouch.previousBehavior = &""
        # stand from crouch if crawl timer did not finish
        elif !crawlTimerFinished && b.crouch.active && b.stand.can_act():
            b.stand.start_action()
        eventHandled = true
    elif (event.is_action_pressed("squeeze")):
        if (b.squeeze.can_act()): b.squeeze.start_action()
        eventHandled = true
    elif (event.is_action_released("squeeze")):
        if (b.squeeze.active && b.stand.can_act()): b.stand.start_action()
        eventHandled = true
    elif (event.is_action_pressed("action")):
        actionTimerFinished = false
        actionTimer.start()
        if ((b.grab.active || b.drag.active) && heldObjectRef != null):
            heldObjectRef.start_action()
        eventHandled = true
    elif (event.is_action_released("action")):
        actionTimer.stop()
        if ((b.grab.active || b.drag.active) && heldObjectRef != null):
            var playerActionResult = heldObjectRef.finish_action(actionTimerFinished)
            if !playerActionResult && b.grab.active:
                throwHeldOnNextFrame = true
        elif (!actionTimerFinished):
            if !b.flashlight.active:
                b.flashlight.start_action()
            else:
                b.flashlight.stop_action()
        eventHandled = true
    elif (event.is_action_pressed("interact")):
        interactTimerFinished = false
        interactTimer.start()
        if b.rotate.can_act():
            b.rotate.start_action()
        eventHandled = true
    elif (event.is_action_released("interact")):
        interactTimer.stop()
        if ((b.grab.active || b.drag.active) && !interactTimerFinished):
            b.drag.stop_action()
            b.grab.stop_action()
        elif (b.grab.can_act() && objectInReachRef != null):
            b.grab.start_action()
        elif (b.drag.can_act() && objectInReachRef != null):
            b.drag.start_action()
        b.rotate.stop_action()
        if heldObjectRef != null:
            heldObjectRef.on_rotate_stop()
        eventHandled = true
    elif (event.is_action_pressed("sprint")):
        sprintTimerFinished = false
        sprintTimer.start()
        if (b.climb.active):
            b.climb.stop_action()
        # TODO standing up this quickly is jarring. fix with tweens 
        if b.crawl.active && b.crouch.can_act():
            b.crouch.start_action()
        if (b.sprint.can_act()):
            b.sprint.start_action()
        elif b.sprint.active:
            b.sprint.stop_action()
        eventHandled = true
    elif (event.is_action_released("sprint")):
        sprintTimer.stop()
        if sprintTimerFinished:
            b.sprint.stop_action()
        eventHandled = true
    elif (event.is_action_pressed("forward")):
        moveDir = Vector2(moveDir.x, -1)
        eventHandled = true
    elif (event.is_action_released("forward")):
        moveDir = Vector2(moveDir.x, 1.0 if Input.is_action_pressed("backward") else 0.0)
        eventHandled = true
    elif (event.is_action_pressed("backward")):
        moveDir = Vector2(moveDir.x, 1)
        eventHandled = true
    elif (event.is_action_released("backward")):
        moveDir = Vector2(moveDir.x, -1.0 if Input.is_action_pressed("forward") else 0.0)
        eventHandled = true
    elif (event.is_action_pressed("left")):
        moveDir = Vector2(-1.0, moveDir.y)
        eventHandled = true
    elif (event.is_action_released("left")):
        moveDir = Vector2(1.0 if Input.is_action_pressed("right") else 0.0, moveDir.y)
        eventHandled = true
    elif (event.is_action_pressed("right")):
        moveDir = Vector2(1.0, moveDir.y)
        eventHandled = true
    elif (event.is_action_released("right")):
        moveDir = Vector2(-1.0 if Input.is_action_pressed("left") else 0.0, moveDir.y)
        eventHandled = true
    moveDir = moveDir.normalized()
    # cursor capture. lets player get mouse back to interact with UI
    if (event.is_action_pressed("capture_cursor") && !mouseCaptured):
        capture_mouse()
        eventHandled = true
    if (event.is_action_pressed("toggle_cursor")):
        if (mouseCaptured):
            release_mouse()
        else:
            capture_mouse()
        eventHandled = true
    # handle pause game
    if (event.is_action_pressed("pause_game")):
        if (mouseCaptured):
            release_mouse()
        eventHandled = true
        SignalBus.game_paused.emit()
        SignalBus.goto_pause_menu.emit()
    # tell game event was handled and stop propagating
    if (eventHandled):
        get_tree().root.set_input_as_handled()

func handle_axis_input(event: InputEventJoypadMotion) -> void:
    var eventHandled: bool = false
    #Vertical joystick movement
    if (event.is_action("forward") || event.is_action("backward")):
        moveDir = Vector2(moveDir.x, event.axis_value)
        eventHandled = true
    #Horizontal joystick movement
    if (event.is_action("left") || event.is_action("right")):
        moveDir = Vector2(event.axis_value, moveDir.y)
        eventHandled = true
    #camera
    if (event.is_action("camera_down") || event.is_action("camera_up")):
        cameraMoveDir = Vector2(cameraMoveDir.x, event.axis_value)
        eventHandled = true
    if (event.is_action("camera_left") || event.is_action("camera_right")):
        cameraMoveDir = Vector2(event.axis_value, cameraMoveDir.y)
        eventHandled = true
    #If vectors are tiny, set to zero
    if (moveDir.length_squared() < 0.01):
        moveDir = Vector2(0.0,0.0)
    if (cameraMoveDir.length_squared() < 0.01):
        cameraMoveDir = Vector2(0.0,0.0)
    # tell game event was handled and stop propagating
    if (eventHandled):
        get_tree().root.set_input_as_handled()

func release_mouse() -> void:
    Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_VISIBLE)
    mouseCaptured = false

func capture_mouse() -> void:
    Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_CAPTURED)
    mouseCaptured = true
