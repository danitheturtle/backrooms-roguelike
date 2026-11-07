extends CharacterBody3D
class_name Player

const BehaviorStateRes = preload("res://objects/player/behavior_state.gd")

var behaviors: BehaviorState = BehaviorStateRes.new(self)
var b: BehaviorState:
    get: return behaviors

@export var PLAYER_SPEED: float = 4.0
@export var PLAYER_MASS: float = 40.0
@export var SPRINT_SPEED: float = 7.0
@export var SLOWED_SPEED: float = 1.5
@export var EXTRA_SLOW_SPEED: float = 0.5
@export var CLIMB_SPEED: float = 2.0
@export var GRAB_SPEED: float = 2.5
@export var SHOVING_FORCE: float = 2.0
@export var STRONGER_DOWNWARD_GRAVITY_THRESHOLD: float = 5.0
@export var STRONGER_GRAVITY_MULTIPLIER: float = 2.0
@export var JUMP_IMPULSE: float = 6.5
@export var CROUCH_HEIGHT: float = 0.95
@export var CRAWL_HEIGHT: float = 0.45
@export var SQUEEZE_RADIUS: float = 0.2
@export var SLOWED_CAMERA_DAMPING: float = 0.4
@export var SLIDE_IMPULSE: float = 7.5
@export var SLIDE_DECELERATION: float = 20.0
@export var CRAWL_STRAFE_DAMPING: float = 0.25
@export var MAX_STEP_HEIGHT: float = 0.3
@export var VAULT_DURATION: float = 0.4
@export var TARGETING_DISTANCE: float = 2.0
@export var MAX_GRAB_MASS: float = 15.0
@export var MAX_DRAG_MASS: float = 150.0

# child nodes
@onready var camera: Camera3D = $Camera
@onready var playerCollider: CollisionShape3D = $PlayerCollisionShape3D
@onready var playerShape: Shape3D = playerCollider.shape
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
var lookDir: Vector2
var movePriority: Dictionary[StringName, bool]
var mouseCaptured: bool
var actionTimerFinished: bool
var interactTimerFinished: bool
var crawlTimerFinished: bool
var sprintTimerFinished: bool
# tracked via roomForStateChangeArea
var nearbyBodies: Dictionary[Node3D, bool] = {}
# some objects change player controls contextually based on adjacency, eg ladders
var adjacentRef: Node3D

# defaults stored at runtime
var standingHeight: float
var standingRadius: float
var cameraTopOffset: float
var grabArmShapeRadius: float

func reinit() -> void:
    moveDir = Vector2.ZERO
    lookDir = Vector2.ZERO
    movePriority = { left = false, right = false, forward = false, backward = false }
    mouseCaptured = false
    actionTimerFinished = false
    interactTimerFinished = false
    crawlTimerFinished = false
    sprintTimerFinished = false
    adjacentRef = null
    global_position = Vector3.ZERO
    global_rotation = Vector3.ZERO
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
    # wire up signals
    roomForStateChangeArea.body_entered.connect(on_room_for_state_change_body_entered)
    roomForStateChangeArea.body_exited.connect(on_room_for_state_change_body_exited)
    adjacentDetectorArea.body_entered.connect(on_adjacent_entered)
    adjacentDetectorArea.body_exited.connect(on_adjacent_exited)
    adjacentDetectorArea.area_entered.connect(on_adjacent_area_entered)
    adjacentDetectorArea.area_exited.connect(on_adjacent_area_exited)
    set_long_press_delay(GameSettings.LongPressDelay)
    actionTimer.timeout.connect(on_action_timer_ended)
    interactTimer.timeout.connect(on_interact_timer_ended)
    crawlTimer.timeout.connect(on_crawl_timer_ended)
    sprintTimer.timeout.connect(on_sprint_timer_ended)
    for nextBehavior: PlayerBehavior in b.all(): nextBehavior.player_ready()
    reinit()

func _physics_process(_delta: float) -> void:
    for nextBehavior: PlayerBehavior in b.all():
        nextBehavior.process_action(_delta)
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

func set_long_press_delay(_newDelay: float) -> void:
    actionTimer.wait_time = _newDelay
    interactTimer.wait_time = _newDelay
    crawlTimer.wait_time = _newDelay
    sprintTimer.wait_time = _newDelay

func can_shape_change():
    var detectedCollisions: Array[Node3D] = nearbyBodies.keys()
    return detectedCollisions.size() == 0

func on_room_for_state_change_body_entered(_body: Node3D):
    nearbyBodies[_body] = true

func on_room_for_state_change_body_exited(_body: Node3D):
    nearbyBodies.erase(_body)
    if (b.squeeze.active && !Input.is_action_pressed("squeeze")):
        if (b.stand.can_act()):
            b.stand.start_action()
            if (Input.is_action_pressed("sprint")):
                b.sprint.start_action()

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

func on_action_timer_ended():
    actionTimerFinished = true

func on_interact_timer_ended():
    interactTimerFinished = true

func on_crawl_timer_ended():
    crawlTimerFinished = true
    # on long keypress, crawl immediately
    if b.crawl.can_act():
        b.crawl.start_action()

func on_sprint_timer_ended():
    sprintTimerFinished = true

func handle_mouse_input(event: InputEventMouseMotion) -> void:
    if mouseCaptured:
        lookDir = event.screen_relative / 100.0
        get_tree().root.set_input_as_handled()

## This is where the gamefeel secret sauce is cooked
## one action trickles to one function call, where various side effects can happen
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
        if (b.squeeze.can_act()):
            b.squeeze.start_action()
        eventHandled = true
    elif (event.is_action_released("squeeze")):
        if (b.squeeze.active && b.stand.can_act()):
            b.stand.start_action()
        eventHandled = true
    elif (event.is_action_pressed("action")):
        actionTimerFinished = false
        actionTimer.start()
        if b.grab.active:
            b.grab.grabbedRef.activate()
        elif b.drag.active:
            b.drag.draggedRef.activate()
        eventHandled = true
    elif (event.is_action_released("action")):
        actionTimer.stop()
        if b.grab.active:
            b.throw.unhandledInput = !b.grab.grabbedRef.deactivate(actionTimerFinished)
        elif b.drag.active:
            b.drag.draggedRef.deactivate(actionTimerFinished)
        elif (!actionTimerFinished):
            if b.flashlight.can_act():
                b.flashlight.start_action()
            else:
                b.flashlight.stop_action()
        ## TODO action wheel
        eventHandled = true
    elif (event.is_action_pressed("interact")):
        interactTimerFinished = false
        interactTimer.start()
        if b.target.active:
            if b.grab.can_act():
                b.grab.start_action()
            elif b.drag.can_act():
                b.drag.start_action()
        elif b.grab.active:
            b.rotate.start_action()
        eventHandled = true
    elif (event.is_action_released("interact")):
        interactTimer.stop()
        b.rotate.stop_action()
        if b.drag.justDragged:
            b.drag.justDragged = false
        elif b.grab.justGrabbed:
            b.grab.justGrabbed = false
        elif b.drag.active && !interactTimerFinished:
            b.drag.stop_action()
        elif (b.grab.active && !interactTimerFinished && b.rotate.rotationDelta < 100.0):
            b.grab.stop_action()
        eventHandled = true
    elif (event.is_action_pressed("zoom_in")):
        if b.grab.active:
            b.grab.increase_held_distance()
        eventHandled = true
    elif (event.is_action_pressed("zoom_out")):
        if b.grab.active:
            b.grab.decrease_held_distance()
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
        lookDir = Vector2(lookDir.x, event.axis_value)
        eventHandled = true
    if (event.is_action("camera_left") || event.is_action("camera_right")):
        lookDir = Vector2(event.axis_value, lookDir.y)
        eventHandled = true
    #If vectors are tiny, set to zero
    if (moveDir.length_squared() < 0.01):
        moveDir = Vector2(0.0,0.0)
    if (lookDir.length_squared() < 0.01):
        lookDir = Vector2(0.0,0.0)
    # tell game event was handled and stop propagating
    if (eventHandled):
        get_tree().root.set_input_as_handled()

func release_mouse() -> void:
    Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_VISIBLE)
    mouseCaptured = false

func capture_mouse() -> void:
    Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_CAPTURED)
    mouseCaptured = true
