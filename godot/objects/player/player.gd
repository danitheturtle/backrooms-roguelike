extends CharacterBody3D
class_name Player

const StandBehaviorRes = preload("res://objects/player/behaviors/stand_behavior.gd")
const JumpBehaviorRes = preload("res://objects/player/behaviors/jump_behavior.gd")
const VaultBehaviorRes = preload("res://objects/player/behaviors/vault_behavior.gd")
const CrouchBehaviorRes = preload("res://objects/player/behaviors/crouch_behavior.gd")
const CrawlBehaviorRes = preload("res://objects/player/behaviors/crawl_behavior.gd")
const SqueezeBehaviorRes = preload("res://objects/player/behaviors/squeeze_behavior.gd")
const SprintBehaviorRes = preload("res://objects/player/behaviors/sprint_behavior.gd")
const ClimbBehaviorRes = preload("res://objects/player/behaviors/climb_behavior.gd")
const StairstepBehaviorRes = preload("res://objects/player/behaviors/stairstep_behavior.gd")
const DragBehaviorRes = preload("res://objects/player/behaviors/drag_behavior.gd")
const GrabBehaviorRes = preload("res://objects/player/behaviors/grab_behavior.gd")
const RotateBehaviorRes = preload("res://objects/player/behaviors/rotate_behavior.gd")
const ThrowBehaviorRes = preload("res://objects/player/behaviors/throw_behavior.gd")
const FilmCameraBehaviorRes = preload("res://objects/player/behaviors/film_camera_behavior.gd")
const FlashlightBehaviorRes = preload("res://objects/player/behaviors/flashlight_behavior.gd")
const ShoveBehaviorRes = preload("res://objects/player/behaviors/shove_behavior.gd")

var behaviors: BehaviorState = BehaviorState.new(self)
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
@onready var playerShape: CapsuleShape3D = $PlayerCollisionShape3D.shape
@onready var grabArm: SpringArm3D = $Camera/GrabArm
@onready var grabAnchor: Area3D = $Camera/GrabArm/Anchor
@onready var roomForStateChangeArea: Area3D = $RoomForStateChangeDetector
@onready var roomForStateChangeCollider: CollisionShape3D = $RoomForStateChangeDetector/StateChangeCollisionShape3D
@onready var roomForStateChangeShape: CapsuleShape3D = roomForStateChangeCollider.shape
@onready var adjacentArea: Area3D = $AdjacentDetector
@onready var adjacentCollider: CollisionShape3D = $AdjacentDetector/CollisionShape3D
@onready var adjacentShape: BoxShape3D = adjacentCollider.shape
@onready var actionTimer: Timer = $ActionTimer
@onready var interactTimer: Timer = $InteractTimer
@onready var stairSolver: Node3D = $StairSolver
@onready var stairRayCast: RayCast3D = $StairSolver/DontStepUpSlopesRayCast
@onready var vaultRayCast: RayCast3D = $VaultSolverRayCast

# local state
var moveDir: Vector2
var cameraMoveDir: Vector2
var movePriority: Dictionary[StringName, bool]
var mouseCaptured: bool
var onFloorLastFrame: bool
var actionTimerFinished: bool
var interactTimerFinished: bool
# holdable object targeted by spring arm (but not picked up)
var objectInReachRef: Holdable
# grabbed or dragged
var heldObjectRef: Holdable
var throwHeldOnNextFrame: bool
var draggedPoint: Vector3
# some objects change player controls contextually based on adjacency, eg ladders
var adjacentRef: Node3D
var slideVelocity: float

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
    onFloorLastFrame = false
    actionTimerFinished = false
    interactTimerFinished = false
    objectInReachRef = null
    heldObjectRef = null
    throwHeldOnNextFrame = false
    draggedPoint = Vector3.ZERO
    adjacentRef = null
    slideVelocity = 0.0
    global_position = Vector3(0,0,0)
    global_rotation = Vector3(0,0,0)
    playerShape.height = standingHeight
    playerShape.radius = standingRadius
    camera.position.y = standingHeight - cameraTopOffset
    grabArm.spring_length = grabArmLength
    grabArm.shape.radius = grabArmShapeRadius
    actionTimer.stop()
    interactTimer.stop()
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
    roomForStateChangeArea.body_exited.connect(on_room_for_state_change_body_exited)
    adjacentArea.body_entered.connect(on_adjacent_entered)
    adjacentArea.body_exited.connect(on_adjacent_exited)
    adjacentArea.area_entered.connect(on_adjacent_area_entered)
    adjacentArea.area_exited.connect(on_adjacent_area_exited)
    grabAnchor.body_entered.connect(on_grab_anchor_entered)
    grabAnchor.body_exited.connect(on_grab_anchor_exited)
    actionTimer.wait_time = HELD_INPUT_TIMEOUT
    interactTimer.wait_time = HELD_INPUT_TIMEOUT
    actionTimer.timeout.connect(on_action_timer_ended)
    interactTimer.timeout.connect(on_interact_timer_ended)
    for nextBehavior: PlayerBehavior in b.all(): nextBehavior.player_ready()
    reinit()

func _physics_process(_delta: float) -> void:
    var onFloorThisFrame = is_on_floor()
    if (onFloorThisFrame && !onFloorLastFrame):
        b.jump.stop_action()
    onFloorLastFrame = onFloorThisFrame
    if (b.rotate.active && b.grab.active && heldObjectRef != null):
        b.rotate.process_action(_delta)
    else:
        var cameraVelocity = -GameSettings.CameraSensitivity
        if (b.grab.active || b.drag.active):
            cameraVelocity *= SLOWED_CAMERA_DAMPING
        if (cameraMoveDir.y < 0 && camera.rotation_degrees.x < 85) || (cameraMoveDir.y > 0 && camera.rotation_degrees.x > -85):
            camera.rotate_x(cameraMoveDir.y * cameraVelocity)
        rotate_y(cameraMoveDir.x * cameraVelocity)
        if (mouseCaptured):
            cameraMoveDir = Vector2.ZERO
    if !b.vault.active:
        if !b.climb.active:
            #determine move speed based on state
            var movementSpeed = PLAYER_SPEED
            if (b.sprint.active):
                movementSpeed = SPRINT_SPEED
            elif (b.crouch.active || b.film_camera.active || b.squeeze.active || b.drag.active):
                movementSpeed = SLOWED_SPEED
            elif (b.grab.active):
                movementSpeed = GRAB_SPEED
            elif (b.crawl.active || b.drag.active):
                movementSpeed = EXTRA_SLOW_SPEED
            #multiply basis vectors by input direction. preserve vertical velocity
            velocity = Vector3(0,velocity.y,0) + Vector3(basis.x * moveDir.x + basis.z * moveDir.y).limit_length() * (movementSpeed + slideVelocity)
            if slideVelocity > 0.0:
                slideVelocity -= SLIDE_DECELERATION * _delta
        else:
            b.climb.process_action(_delta)
    #handle jump / vault
    if behaviors.jump.justJumped:
        behaviors.jump.justJumped = false
        vaultRayCast.force_raycast_update()
        if vaultRayCast.is_colliding():
            if vaultRayCast.get_collider() is not RigidBody3D:
                b.vault.ledgePoint = vaultRayCast.get_collision_point()
                b.vault.start_action()
        if !b.vault.active && (onFloorLastFrame || b.climb.active):
            if b.climb.active:
                b.climb.stop_action()
            b.jump.start_action()
    # some behaviors only happen when not climbing, like gravity and shoving
    if !b.climb.active && !b.vault.active:
        #apply gravity acceleration. apply more strongly if falling
        if (velocity.y >= STRONGER_DOWNWARD_GRAVITY_THRESHOLD):
            velocity += GRAVITY*_delta * GRAVITY_VECTOR
        else:
            velocity += GRAVITY*STRONGER_GRAVITY_MULTIPLIER*_delta * GRAVITY_VECTOR
        b.shove.process_action(_delta)
    #handle held object
    if heldObjectRef != null:
        if b.grab.active:
            if throwHeldOnNextFrame:
                b.throw.start_action()
            else:
                # account for objects not moved from their default origin
                var heldObjectOrigin = heldObjectRef.get_node_or_null("GrabOrigin")
                var fromPos = heldObjectRef.global_position if heldObjectOrigin == null else heldObjectOrigin.global_position
                var toPos = grabAnchor.global_position
                heldObjectRef.linear_velocity = (toPos - fromPos) / _delta + velocity
                heldObjectRef.angular_velocity *= 0.1
        elif b.drag.active:
            if (global_position - (heldObjectRef.global_position + draggedPoint)).length_squared() > 12.0:
                b.drag.stop_action()
            else:
                heldObjectRef.linear_velocity = Vector3(velocity.x, 0.0, velocity.z)
    # climb stairs
    b.stairstep.process_action(_delta)
    # finally, move and slide
    move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        handle_mouse_input(event)
    elif event is InputEventJoypadMotion:
        handle_axis_input(event)
    else:
        handle_key_input(event)

func can_shape_change():
    var detectedCollisions: Array[Node3D] = roomForStateChangeArea.get_overlapping_bodies()
    return detectedCollisions.size() == 0

func try_clear_hover_state():
    if objectInReachRef != null:
        objectInReachRef.clear_hover_material()
        objectInReachRef = null

func on_room_for_state_change_body_exited(_body: Node3D):
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

func handle_mouse_input(event: InputEventMouseMotion) -> void:
    if mouseCaptured:
        cameraMoveDir = event.screen_relative / 100.0
        get_tree().root.set_input_as_handled()

func handle_key_input(event: InputEvent ) -> void:
    var eventHandled: bool = false
    if (event.is_action_pressed("jump")):
        if (b.crawl.active && b.crouch.can_act()):
            b.crouch.tryStandAfterCrouching = true
            b.crouch.start_action()
        elif (b.crouch.active && b.stand.can_act()):
            b.stand.start_action()
        elif (!b.climb.active && b.climb.can_act() && !Input.is_action_pressed("sprint")):
            b.climb.start_action()
        elif (b.jump.can_act() || b.vault.can_act()):
            b.jump.justJumped = true
        eventHandled = true
    elif (event.is_action_pressed("crouch")):
        if (!b.crouch.active && b.crouch.can_act()):
            b.crouch.tryStandAfterCrouching = false
            b.crouch.start_action()
        elif (b.crouch.active && b.crawl.can_act()):
            b.crawl.start_action()
        eventHandled = true
    elif (event.is_action_pressed("squeeze")):
        if (!b.squeeze.active && b.squeeze.can_act()):
            b.squeeze.start_action()
    elif (event.is_action_released("squeeze")):
        if (b.squeeze.active): b.stand.try_action()
    elif (event.is_action_pressed("action")):
        actionTimer.start()
        if ((b.grab.active || b.drag.active) && heldObjectRef != null):
            heldObjectRef.start_action()
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
        actionTimerFinished = false
    elif (event.is_action_pressed("interact")):
        interactTimer.start()
        if b.rotate.can_act():
            b.rotate.start_action()
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
        interactTimerFinished = false
    elif (event.is_action_pressed("sprint")):
        if (b.climb.active):
            b.climb.stop_action()
        if (!b.sprint.active && b.sprint.can_act()):
            b.stand.start_action()
            b.sprint.start_action()
    elif (event.is_action_released("sprint")):
        if (b.sprint.active):
            b.stand.start_action()
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
    if b.crawl.active: moveDir.x = moveDir.x * 0.1
    # cursor capture. lets player get mouse back to interact with UI
    if (event.is_action_pressed("capture_cursor") && !mouseCaptured):
        capture_mouse()
        eventHandled = true
    if (event.is_action_pressed("toggle_cursor")):
        if (mouseCaptured):
            release_mouse()
        else:
            capture_mouse()
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

class BehaviorState:
    var stand: StandBehavior
    var jump: JumpBehavior
    var vault: VaultBehavior
    var crouch: CrouchBehavior
    var crawl: CrawlBehavior
    var squeeze: SqueezeBehavior
    var sprint: SprintBehavior
    var climb: ClimbBehavior
    var stairstep: StairstepBehavior
    var drag: DragBehavior
    var grab: GrabBehavior
    var rotate: RotateBehavior
    var throw: ThrowBehavior
    var shove: ShoveBehavior
    var film_camera: FilmCameraBehavior
    var flashlight: FlashlightBehavior
    func _init(_player: Player) -> void:
        stand = StandBehaviorRes.new(_player)
        jump = JumpBehaviorRes.new(_player)
        vault = VaultBehaviorRes.new(_player)
        crouch = CrouchBehaviorRes.new(_player)
        crawl = CrawlBehaviorRes.new(_player)
        squeeze = SqueezeBehaviorRes.new(_player)
        sprint = SprintBehaviorRes.new(_player)
        climb = ClimbBehaviorRes.new(_player)
        stairstep = StairstepBehaviorRes.new(_player)
        drag = DragBehaviorRes.new(_player)
        grab = GrabBehaviorRes.new(_player)
        rotate = RotateBehaviorRes.new(_player)
        throw = ThrowBehaviorRes.new(_player)
        shove = ShoveBehaviorRes.new(_player)
        film_camera = FilmCameraBehaviorRes.new(_player)
        flashlight = FlashlightBehaviorRes.new(_player)
    func all() -> Array[PlayerBehavior]:
        return [stand, jump, vault, crouch, crawl, squeeze, sprint, climb, stairstep, drag, rotate, throw, shove, film_camera, flashlight]
    func subset(_subset: Array[StringName]) -> Array[PlayerBehavior]:
        if _subset.size() == 0: return all()
        var resultArray: Array[PlayerBehavior] = []
        for nextBehaviorKey: StringName in _subset: resultArray.append(self[nextBehaviorKey])
        return resultArray
    func some(_subset: Array[StringName] = []) -> bool:
        for nextBehavior: PlayerBehavior in subset(_subset):
            if nextBehavior.active: return true
        return false
    func none(_subset: Array[StringName] = []) -> bool:
        for nextBehavior: PlayerBehavior in subset(_subset):
            if nextBehavior.active: return false
        return true
    func every(_subset: Array[StringName] = []) -> bool:
        var everyActive = true
        for nextBehavior: PlayerBehavior in subset(_subset):
            everyActive = everyActive && nextBehavior.active
        return everyActive
    func stop(_subset: Array[StringName] = []) -> void:
        for nextBehavior: PlayerBehavior in subset(_subset):
            nextBehavior.stop_action()
        if _subset.size() == 0: self.stand.start_action()
    func start(_subset: Array[StringName] = []) -> void:
        if _subset.size() == 0: return
        for nextBehavior: PlayerBehavior in subset(_subset):
            nextBehavior.start_action()
