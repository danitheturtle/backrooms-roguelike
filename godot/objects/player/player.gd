extends CharacterBody3D
class_name Player

var HOVER_OVER_OBJECT_MATERIAL = preload("res://assets/materials/HoverOverObject/HoverOverObject.tres")

@export var PLAYER_SPEED = 4.0
@export var PLAYER_MASS = 80.0
@export var SPRINT_SPEED = 7.0
@export var SLOWED_SPEED = 1.5
@export var EXTRA_SLOW_SPEED = 0.5
@export var GRABBING_SPEED = 2.5
@export var CAMERA_ANGULAR_VELOCITY = 0.1
@export var SHOVING_FORCE = 2.0
@export var STRONGER_DOWNWARD_GRAVITY_THRESHOLD = 5.0
@export var STRONGER_GRAVITY_MULTIPLIER = 2.0
@export var JUMP_IMPULSE = 6.5
@export var CROUCH_HEIGHT = 0.95
@export var CRAWL_HEIGHT = 0.45
@export var SQUEEZE_RADIUS = 0.2
@export var HELD_OBJECT_DISTANCE = 2.25
@export var HELD_OBJECT_ROTATION_SPEED = 10.0
@export var SLOWED_CAMERA_DAMPING = 0.4
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")
var GRAVITY_VECTOR = ProjectSettings.get_setting("physics/3d/default_gravity_vector")

# child nodes
@onready var camera: Camera3D = $Camera
@onready var playerCollider: CollisionShape3D = $PlayerCollisionShape3D
@onready var playerShape: CapsuleShape3D = $PlayerCollisionShape3D.shape
@onready var roomForStateChangeArea: Area3D = $RoomForStateChangeDetector
@onready var flashlight: SpotLight3D = $Camera/Flashlight
@onready var grabArm: SpringArm3D = $Camera/GrabArm
@onready var grabAnchor: Area3D = $Camera/GrabArm/Anchor
@onready var roomForStateChangeCollider: CollisionShape3D = $RoomForStateChangeDetector/StateChangeCollisionShape3D
@onready var roomForStateChangeShape: CapsuleShape3D = roomForStateChangeCollider.shape
# local state
var moveDir = Vector2(0.0,0.0)
var cameraMoveDir = Vector2(0.0,0.0)
var movePriority = { left = false, right = false, forward = false, backward = false }
var mouseCaptured = false
var onFloorLastFrame = false
var justJumped = false
var objectInReachRef: RigidBody3D = null
var objectInReachMesh: MeshInstance3D = null
var heldObjectRef: RigidBody3D = null # grabbed or dragged

#state machine
var jumping = false
var crouching = false
var crawling = false
var running = false
var climbing = false
var squeezing = false
var photographing = false
var grabbing = false
var dragging = false

#runtime calculated state
var standingHeight: float
var standingRadius: float
var cameraTopOffset: float
var flashlightOffset: Vector3
var grabArmLength: float

func _ready() -> void:
    State.player = self
    standingHeight = playerShape.height
    standingRadius = playerShape.radius
    cameraTopOffset = playerShape.height - camera.position.y
    flashlightOffset = flashlight.position
    grabArmLength = grabArm.spring_length
    roomForStateChangeArea.body_exited.connect(on_room_for_state_change_body_exited)
    grabAnchor.body_entered.connect(on_grab_anchor_entered)
    grabAnchor.body_exited.connect(on_grab_anchor_exited)
    capture_mouse()

func _physics_process(_delta: float) -> void:
    var onFloorThisFrame = is_on_floor()
    if (onFloorThisFrame && !onFloorLastFrame):
        handle_land_jump()
    onFloorLastFrame = onFloorThisFrame
    if (Input.is_action_pressed("rotate") && grabbing && heldObjectRef != null):
        # rotate held object
        heldObjectRef.angular_velocity = (Vector3(0,-1,0)*cameraMoveDir.x + camera.global_basis.x * cameraMoveDir.y) * HELD_OBJECT_ROTATION_SPEED
    else:
        var cameraVelocity = -CAMERA_ANGULAR_VELOCITY
        if (grabbing || dragging):
            cameraVelocity *= SLOWED_CAMERA_DAMPING
        if (cameraMoveDir.y < 0 && camera.rotation_degrees.x < 85) || (cameraMoveDir.y > 0 && camera.rotation_degrees.x > -85):
            camera.rotate_x(cameraMoveDir.y * cameraVelocity)
        rotate_y(cameraMoveDir.x * cameraVelocity)
        if (mouseCaptured):
            cameraMoveDir = Vector2.ZERO
    #determine move speed based on state
    var movementSpeed = PLAYER_SPEED
    if (running):
        movementSpeed = SPRINT_SPEED
    elif (crouching || photographing || squeezing || dragging):
        movementSpeed = SLOWED_SPEED
    elif (grabbing):
        movementSpeed = GRABBING_SPEED
    elif (crawling || dragging):
        movementSpeed = EXTRA_SLOW_SPEED
    #multiply basis vectors by input direction. preserve vertical velocity
    velocity = Vector3(0,velocity.y,0) + Vector3(basis.x * moveDir.x + basis.z * moveDir.y).limit_length() * movementSpeed
    #handle held object
    if heldObjectRef != null:
        if grabbing:
            # account for objects not moved from their default origin
            var heldObjectOrigin = heldObjectRef.get_node_or_null("GrabOrigin")
            var fromPos = heldObjectRef.global_position if heldObjectOrigin == null else heldObjectOrigin.global_position
            var toPos = grabAnchor.global_position
            heldObjectRef.linear_velocity = (toPos - fromPos) / _delta + velocity
            heldObjectRef.angular_velocity *= 0.1
        elif dragging:
            pass
    #handle 
    #handle jump
    if justJumped: handle_jump()
    #apply gravity acceleration. apply more strongly if falling
    if (velocity.y >= STRONGER_DOWNWARD_GRAVITY_THRESHOLD):
        velocity += GRAVITY*_delta * GRAVITY_VECTOR
    else:
        velocity += GRAVITY*STRONGER_GRAVITY_MULTIPLIER*_delta * GRAVITY_VECTOR
    # shove any rigidbodies
    for i in get_slide_collision_count():
        var collision = get_slide_collision(i)
        var collider = collision.get_collider()
        if collider is RigidBody3D:
            var oppositeCollisionDir = -collision.get_normal()
            oppositeCollisionDir.y = 0
            var velocityInShoveDir = max(
                velocity.dot(oppositeCollisionDir) - collider.linear_velocity.dot(oppositeCollisionDir),
                0.0
            )
            var massRatio = min(1.0, PLAYER_MASS / collider.mass)
            var shoveForce = SHOVING_FORCE * massRatio
            collider.apply_impulse(oppositeCollisionDir * velocityInShoveDir * shoveForce, collision.get_position() - collider.global_position)
            
    move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        handle_mouse_input(event)
    elif event is InputEventJoypadMotion:
        handle_axis_input(event)
    else:
        handle_key_input(event)

###
### JUMPING
###
func can_jump():
    return !jumping && !crouching && !crawling && !squeezing && !photographing && onFloorLastFrame
func handle_jump():
    clear_hover_material()
    velocity += Vector3(0,JUMP_IMPULSE,0)
    justJumped = false
    jumping = true
func handle_land_jump():
    handle_stand()
    jumping = false

func can_shape_change():
    var detectedCollisions: Array[Node3D] = roomForStateChangeArea.get_overlapping_bodies()
    return detectedCollisions.size() == 0
###
### CROUCHING
###
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
    flashlight.position.y = flashlightOffset.y
    if (running):
        # apply slide impulse in direction of run
        running = false
    crawling = false
    crouching = true
    clear_hover_material()

###
### CRAWLING
###
func can_crawl():
    return crouching && onFloorLastFrame
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
    flashlight.position.y = flashlightOffset.y / 3.0
    crouching = false
    photographing = false
    crawling = true

###
### SQUEEZING
###
func can_squeeze():
    if (!crawling && !crouching && !climbing && !dragging && !grabbing):
        return onFloorLastFrame
    elif (crouching):
        return can_stand()
    else:
        return false
func handle_squeeze():
    handle_stand()
    clear_hover_material()
    playerShape.radius = SQUEEZE_RADIUS
    flashlight.position.x = 0
    running = false
    squeezing = true

###
### RUNNING
###
func can_run():
    if (squeezing || crawling || climbing):
        return false
    elif (crouching):
        return can_stand()
    else:
        return onFloorLastFrame
func handle_run():
    running = true
    clear_hover_material()
    if (grabbing || dragging || photographing):
        # drop out of alternate states
        pass

###
### STANDING
###
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
        flashlight.position.x = flashlightOffset.x
        squeezing = false
    running = false
    # find first rigidbody touching anchor, if it exists, and apply hover material
    for nextBody in grabAnchor.get_overlapping_bodies():
        if nextBody is RigidBody3D:
            on_grab_anchor_entered(nextBody)
            break

###
### GRABBING
###
func can_grab():
    if (!dragging && !jumping && !crouching && !crawling && !squeezing && !running && !climbing && !photographing && onFloorLastFrame):
        if (objectInReachRef != null && objectInReachRef.mass > 20.0):
            return false
        else:
            return true
    else:
        return false
func handle_grab():
    grabArm.collision_mask = 0b00000000000000001110
    grabArm.spring_length = HELD_OBJECT_DISTANCE
    # causes visual bug as arm rapidly shifts if we don't defer
    call_deferred("_handle_grab_deferred")
func _handle_grab_deferred():
    grabbing = true
    heldObjectRef = objectInReachRef

###
### DRAGGING
###
func can_drag():
    if (!grabbing && !jumping && !crouching && !crawling && !squeezing && !running && !climbing && !photographing && onFloorLastFrame):
        if (objectInReachRef != null && objectInReachRef.mass > 150.0):
            return false
        else:
            return true
    else:
        return false
func handle_drag():
    pass

func handle_drop():
    heldObjectRef = null
    grabbing = false
    dragging = false
    grabArm.collision_mask = 0b00000000000000001111
    grabArm.spring_length = grabArmLength
    handle_stand()

func on_room_for_state_change_body_exited(_body: Node3D):
    if (squeezing && !Input.is_action_pressed("squeeze")):
        if (can_stand()):
            handle_stand()
            if (Input.is_action_pressed("run")):
                handle_run()

func on_grab_anchor_entered(body: Node3D):
    if (body is RigidBody3D && objectInReachRef != body && (can_grab() || can_drag())):
        objectInReachRef = body
        objectInReachMesh = Utils.get_child_of_type(body, MeshInstance3D)
        apply_hover_material()

func on_grab_anchor_exited(body: Node3D):
    if (body == objectInReachRef):
        clear_hover_material()

func apply_hover_material():
    for nextMaterial in Utils.get_materials_on_mesh(objectInReachMesh):
        HOVER_OVER_OBJECT_MATERIAL.next_pass = nextMaterial
        objectInReachMesh.set_surface_override_material(0, HOVER_OVER_OBJECT_MATERIAL)

func clear_hover_material():
    if objectInReachMesh == null: return
    for surfaceIndex in objectInReachMesh.mesh.get_surface_count():
        var surfaceMaterial = objectInReachMesh.get_surface_override_material(surfaceIndex)
        if surfaceMaterial == HOVER_OVER_OBJECT_MATERIAL:
            objectInReachMesh.set_surface_override_material(surfaceIndex, null)
    objectInReachRef = null
    objectInReachMesh = null

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
            justJumped = true
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
    elif (event.is_action_released("flashlight")):
        flashlight.visible = !flashlight.visible
    elif (event.is_action_released("hold")):
        if (grabbing || dragging):
            handle_drop()
        elif (!grabbing && can_grab() && objectInReachRef != null):
            handle_grab()
        elif (!dragging && can_drag() && objectInReachRef != null):
            handle_drag()
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
