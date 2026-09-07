extends CharacterBody3D
class_name Player

@export var PLAYER_SPEED = 4.5
@export var SPRINT_SPEED = 7.0
@export var SLOWED_SPEED = 2.0
@export var CAMERA_ANGULAR_VELOCITY = 0.1
@export var STRONGER_DOWNWARD_GRAVITY_THRESHOLD = 5.0
@export var STRONGER_GRAVITY_MULTIPLIER = 2.0
@export var JUMP_IMPULSE = 6.5
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")
var GRAVITY_VECTOR = ProjectSettings.get_setting("physics/3d/default_gravity_vector")

# child nodes
@onready var camera = $PlayerCamera
@onready var collider = $PlayerCollisionShape3D

# local state
var moveDir = Vector2(0.0,0.0)
var cameraMoveDir = Vector2(0.0,0.0)
var movePriority = { left = false, right = false, forward = false, backward = false }
var mouseCaptured = false
var jumping = false

func _ready() -> void:
    State.player = self
    capture_mouse()

func _physics_process(_delta: float) -> void:
    if (cameraMoveDir.y < 0 && camera.rotation_degrees.x < 85) || (cameraMoveDir.y > 0 && camera.rotation_degrees.x > -85):
        camera.rotate_x(cameraMoveDir.y * -CAMERA_ANGULAR_VELOCITY)
    rotate_y(cameraMoveDir.x * -CAMERA_ANGULAR_VELOCITY)
    if (mouseCaptured):
        cameraMoveDir = Vector2.ZERO
    #multiply basis vectors by input direction. preserve vertical velocity
    velocity = Vector3(0,velocity.y,0) + Vector3(basis.x * moveDir.x + basis.z * moveDir.y).limit_length() * PLAYER_SPEED
    #apply then jerk the jump acceleration
    if jumping:
        velocity += Vector3(0,JUMP_IMPULSE,0)
        jumping = false
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

func handle_mouse_input(event: InputEventMouseMotion) -> void:
    if mouseCaptured:
        cameraMoveDir = event.screen_relative / 100.0
        get_tree().root.set_input_as_handled()

func handle_key_input(event: InputEvent ) -> void:
    var eventHandled: bool = false
    if (event.is_action_pressed("jump") && !jumping):
        if is_on_floor():
            jumping = true
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
        moveDir = Vector2(-1, moveDir.y)
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
