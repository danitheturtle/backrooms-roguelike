extends CharacterBody3D
class_name Player

@export var PLAYER_SPEED = 4.5
@export var SPRINT_SPEED = 7.0
@export var SLOWED_SPEED = 2.0
@export var CRAWL_SPEED = 0.75
@export var CAMERA_ANGULAR_VELOCITY = 0.1
@export var STRONGER_DOWNWARD_GRAVITY_THRESHOLD = 5.0
@export var STRONGER_GRAVITY_MULTIPLIER = 2.0
@export var JUMP_IMPULSE = 6.5
@export var CROUCH_HEIGHT = 0.95
@export var CRAWL_HEIGHT = 0.45
@export var SQUEEZE_RADIUS = 0.2
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")
var GRAVITY_VECTOR = ProjectSettings.get_setting("physics/3d/default_gravity_vector")

# child nodes
@onready var camera: Camera3D = $PlayerCamera
@onready var playerCollider: CollisionShape3D = $PlayerCollisionShape3D
@onready var playerShape: CapsuleShape3D = $PlayerCollisionShape3D.shape
@onready var roomForStateChangeArea: Area3D = $RoomForStateChangeDetector
@onready var roomForStateChangeCollider: CollisionShape3D = $RoomForStateChangeDetector/StateChangeCollisionShape3D
@onready var roomForStateChangeShape: CapsuleShape3D = roomForStateChangeCollider.shape

# local state
var moveDir = Vector2(0.0,0.0)
var cameraMoveDir = Vector2(0.0,0.0)
var movePriority = { left = false, right = false, forward = false, backward = false }
var mouseCaptured = false

#state machine
var jumping = false
var crouching = false
var crawling = false
var running = false
var climbing = false
var squeezing = false
var photographing = false

#runtime calculated state
var standingHeight
var standingRadius
var cameraTopOffset

func _ready() -> void:
    State.player = self
    standingHeight = playerShape.height
    standingRadius = playerShape.radius
    cameraTopOffset = playerShape.height - camera.position.y
    roomForStateChangeArea.body_exited.connect(on_room_for_state_change_body_exited)
    capture_mouse()

func _physics_process(_delta: float) -> void:
    if (cameraMoveDir.y < 0 && camera.rotation_degrees.x < 85) || (cameraMoveDir.y > 0 && camera.rotation_degrees.x > -85):
        camera.rotate_x(cameraMoveDir.y * -CAMERA_ANGULAR_VELOCITY)
    rotate_y(cameraMoveDir.x * -CAMERA_ANGULAR_VELOCITY)
    if (mouseCaptured):
        cameraMoveDir = Vector2.ZERO
    #determine move speed based on state
    var movementSpeed = PLAYER_SPEED
    if (running):
        movementSpeed = SPRINT_SPEED
    elif (crouching || photographing || squeezing):
        movementSpeed = SLOWED_SPEED
    elif (crawling):
        movementSpeed = CRAWL_SPEED
    #multiply basis vectors by input direction. preserve vertical velocity
    velocity = Vector3(0,velocity.y,0) + Vector3(basis.x * moveDir.x + basis.z * moveDir.y).limit_length() * movementSpeed
    #handle jump
    if jumping: handle_jump()
    #apply gravity acceleration. apply more strongly if falling
    if (velocity.y >= STRONGER_DOWNWARD_GRAVITY_THRESHOLD):
        velocity += GRAVITY*_delta * GRAVITY_VECTOR
    else:
        velocity += GRAVITY*STRONGER_GRAVITY_MULTIPLIER*_delta * GRAVITY_VECTOR
    move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        handle_mouse_input(event)
    elif event is InputEventJoypadMotion:
        handle_axis_input(event)
    else:
        handle_key_input(event)

func can_jump():
    if (!jumping && !crouching && !crawling && !squeezing && !photographing):
        return is_on_floor()
    else:
        return false
func handle_jump():
    velocity += Vector3(0,JUMP_IMPULSE,0)
    jumping = false

func can_shape_change():
    var detectedCollisions: Array[Node3D] = roomForStateChangeArea.get_overlapping_bodies()
    return detectedCollisions.size() == 0

func can_crouch():
    if (!crawling):
        return !squeezing && !climbing
    else:
        return can_shape_change()
func handle_crouch():
    # move camera down and set player height to crouched
    playerShape.height = CROUCH_HEIGHT
    playerShape.radius = standingRadius
    playerCollider.position.y = CROUCH_HEIGHT / 2.0
    playerCollider.rotation.z = 0.0
    roomForStateChangeShape.height = standingHeight
    roomForStateChangeShape.radius = standingRadius
    roomForStateChangeCollider.position.y = standingHeight / 2.0
    camera.position.y = CROUCH_HEIGHT - cameraTopOffset
    if (running):
        # apply slide impulse in direction of run
        running = false
    crawling = false
    crouching = true

func can_crawl():
    if (crouching):
        return is_on_floor()
    else:
        return false
func handle_crawl():
    # capsule collider can't be shorter than it is wide; rotate on camera axis so its sideways, 
    # thus maintaining player "width"
    playerShape.height = standingRadius * 2.0
    playerShape.radius = CRAWL_HEIGHT / 2.0
    playerCollider.position.y = CRAWL_HEIGHT / 2.0
    playerCollider.rotation.z = deg_to_rad(90.0)
    roomForStateChangeShape.height = CROUCH_HEIGHT
    roomForStateChangeShape.radius = CRAWL_HEIGHT / 2.0
    roomForStateChangeCollider.position.y = CROUCH_HEIGHT / 2.0
    camera.position.y = CRAWL_HEIGHT - cameraTopOffset
    crouching = false
    photographing = false
    crawling = true

func can_squeeze():
    if (!crawling && !crouching && !climbing):
        return is_on_floor()
    elif (crouching):
        return can_stand()
    else:
        return false
func handle_squeeze():
    handle_stand()
    playerShape.radius = SQUEEZE_RADIUS
    running = false
    squeezing = true

func can_run():
    if (squeezing || crawling || climbing):
        return false
    elif (crawling):
        return can_stand()
    else:
        return is_on_floor()

func handle_run():
    running = true

func can_stand():
    return can_shape_change()
# reset to base collision state
func handle_stand():
    if (playerShape.height != standingHeight):
        playerShape.height = standingHeight
        playerCollider.position.y = standingHeight / 2.0
        camera.position.y = standingHeight - cameraTopOffset
        crouching = false
    if (playerShape.radius != standingRadius):
        playerShape.radius = standingRadius
        squeezing = false
    running = false

func on_room_for_state_change_body_exited(_body: Node3D):
    if (squeezing && !Input.is_action_pressed("squeeze")):
        if (can_stand()):
            handle_stand()
            if (Input.is_action_pressed("run")):
                handle_run()

func handle_mouse_input(event: InputEventMouseMotion) -> void:
    if mouseCaptured:
        cameraMoveDir = event.screen_relative / 100.0
        get_tree().root.set_input_as_handled()

func handle_key_input(event: InputEvent ) -> void:
    var eventHandled: bool = false
    if (event.is_action_pressed("jump")):
        if (crawling && can_crouch()):
            handle_crouch()
        elif (crouching && can_stand()):
            handle_stand()
        elif (can_jump()):
            jumping = true
        eventHandled = true
    elif (event.is_action_pressed("crouch")):
        if (!crouching && can_crouch()):
            handle_crouch()
        elif (crouching && can_crawl()):
            handle_crawl()
        eventHandled = true
    elif (event.is_action_pressed("squeeze")):
        if (!squeezing && can_squeeze()):
            handle_squeeze()
    elif (event.is_action_released("squeeze")):
        if (squeezing && can_stand()):
            handle_stand()
    elif (event.is_action_pressed("run")):
        if (!running && can_run()):
            handle_stand()
            handle_run()
    elif (event.is_action_released("run")):
        if (running):
            handle_stand()
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
    elif (event.is_action_pressed("left") && !crawling):
        moveDir = Vector2(-1, moveDir.y)
        eventHandled = true
    elif (event.is_action_released("left") && !crawling):
        moveDir = Vector2(1.0 if Input.is_action_pressed("right") else 0.0, moveDir.y)
        eventHandled = true
    elif (event.is_action_pressed("right") && !crawling):
        moveDir = Vector2(1.0, moveDir.y)
        eventHandled = true
    elif (event.is_action_released("right") && !crawling):
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
    # handle pause game
    if (event.is_action_pressed("pause_game")):
        if (mouseCaptured):
            release_mouse()
        eventHandled = true
        SignalBus.game_paused.emit()
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
