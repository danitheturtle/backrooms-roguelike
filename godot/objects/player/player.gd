extends CharacterBody3D
class_name Player

# global constants
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")
var GRAVITY_VECTOR = ProjectSettings.get_setting("physics/3d/default_gravity_vector")

@export var PLAYER_SPEED = 4.0
@export var MOUSE_SENSITIVITY = 0.1
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
@onready var flashlight: SpotLight3D = $Camera/Flashlight
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
var moveDir = Vector2(0.0,0.0)
var cameraMoveDir = Vector2(0.0,0.0)
var movePriority = { left = false, right = false, forward = false, backward = false }
var mouseCaptured = false
var onFloorLastFrame = false
var justJumped = false
var justVaulted = false
var actionTimerFinished = false
var interactTimerFinished = false
# holdable object targeted by spring arm (but not picked up)
var objectInReachRef: Holdable = null
# grabbed or dragged
var heldObjectRef: Holdable = null
var throwHeldOnNextFrame: bool = false
var draggedPoint = Vector3.ZERO
# some objects change player controls contextually based on adjacency, eg ladders
var adjacentRef: Node3D = null
# climbing uses path-following
var climbPath: Path3D = null
var climbCurve: Curve3D = null
var slideVelocity = 0.0

#state machine
var jumping = false
var crouching = false
var crawling = false
var running = false
var climbing = false
var vaulting = false
var squeezing = false
var photographing = false
var grabbing = false
var rotating = false
var dragging = false

#runtime calculated state
var standingHeight: float
var standingRadius: float
var cameraTopOffset: float
var flashlightOffset: Vector3
var grabArmLength: float
var grabArmShapeRadius: float

func _ready() -> void:
    State.player = self
    standingHeight = playerShape.height
    standingRadius = playerShape.radius
    cameraTopOffset = playerShape.height - camera.position.y
    flashlightOffset = flashlight.position
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
    call_deferred("capture_mouse")

func _physics_process(_delta: float) -> void:
    var onFloorThisFrame = is_on_floor()
    if (onFloorThisFrame && !onFloorLastFrame):
        handle_land_jump()
    onFloorLastFrame = onFloorThisFrame
    if (rotating && grabbing && heldObjectRef != null):
        # rotate held object
        heldObjectRef.angular_velocity = (-camera.global_basis.y*cameraMoveDir.x + camera.global_basis.x * cameraMoveDir.y) * MOUSE_SENSITIVITY * 100.0
    else:
        var cameraVelocity = -MOUSE_SENSITIVITY
        if (grabbing || dragging):
            cameraVelocity *= SLOWED_CAMERA_DAMPING
        if (cameraMoveDir.y < 0 && camera.rotation_degrees.x < 85) || (cameraMoveDir.y > 0 && camera.rotation_degrees.x > -85):
            camera.rotate_x(cameraMoveDir.y * cameraVelocity)
        rotate_y(cameraMoveDir.x * cameraVelocity)
        if (mouseCaptured):
            cameraMoveDir = Vector2.ZERO
    if !vaulting:
        if !climbing:
            #determine move speed based on state
            var movementSpeed = PLAYER_SPEED
            if (running):
                movementSpeed = SPRINT_SPEED
            elif (crouching || photographing || squeezing || dragging):
                movementSpeed = SLOWED_SPEED
            elif (grabbing):
                movementSpeed = GRAB_SPEED
            elif (crawling || dragging):
                movementSpeed = EXTRA_SLOW_SPEED
            #multiply basis vectors by input direction. preserve vertical velocity
            velocity = Vector3(0,velocity.y,0) + Vector3(basis.x * moveDir.x + basis.z * moveDir.y).limit_length() * (movementSpeed + slideVelocity)
            if slideVelocity > 0.0:
                slideVelocity -= SLIDE_DECELERATION * _delta
        else:
            # climbing behavior based velocity
            if climbCurve != null && climbPath != null:
                var playerPosInLocalCurveSpace = climbPath.to_local(global_position)
                var closestOffset = climbCurve.get_closest_offset(playerPosInLocalCurveSpace)
                # adjust offset based on direction clamped to up/down
                closestOffset -= moveDir.y * CLIMB_SPEED
                # I don't know why the z axis needs reversed and at this point I'm too afraid to ask
                var nearestPoint = climbPath.global_position + climbCurve.sample_baked(closestOffset) * Basis(climbPath.global_basis.x, climbPath.global_basis.y, -climbPath.global_basis.z)
                # get required velocity to keep player at new location
                velocity = nearestPoint - global_position
    #handle jump / vault
    if justJumped:
        justJumped = false
        var didVault = false
        vaultRayCast.force_raycast_update()
        if vaultRayCast.is_colliding():
            if vaultRayCast.get_collider() is not RigidBody3D:
                didVault = handle_vault(vaultRayCast.get_collision_point())
        if !didVault && onFloorLastFrame:
            handle_jump()
    # some behaviors only happen when not climbing, like gravity and shoving
    if !climbing && !vaulting:
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
    #handle held object
    if heldObjectRef != null:
        if grabbing:
            if throwHeldOnNextFrame:
                handle_throw()
            else:
                # account for objects not moved from their default origin
                var heldObjectOrigin = heldObjectRef.get_node_or_null("GrabOrigin")
                var fromPos = heldObjectRef.global_position if heldObjectOrigin == null else heldObjectOrigin.global_position
                var toPos = grabAnchor.global_position
                heldObjectRef.linear_velocity = (toPos - fromPos) / _delta + velocity
                heldObjectRef.angular_velocity *= 0.1
        elif dragging:
            if (global_position - (heldObjectRef.global_position + draggedPoint)).length_squared() > 4.0:
                handle_drop()
            else:
                heldObjectRef.linear_velocity = Vector3(velocity.x, 0.0, velocity.z)
    # climb stairs
    if !vaulting && !jumping && !crawling && !squeezing && velocity.y <= 0 && velocity.length_squared() > 0.05:
        stairSolver.rotation.y = atan2(-moveDir.x, -moveDir.y)
        var expectedPositionDelta = velocity * 0.4 * _delta
        var collisionCastVector = Vector3(0,MAX_STEP_HEIGHT*1.5, 0)
        var nextPosCollisionCastStart = global_transform.translated(expectedPositionDelta + collisionCastVector)
        var collisionResult = KinematicCollision3D.new()
        if test_move(nextPosCollisionCastStart, -collisionCastVector, collisionResult):
            var foundCollider = collisionResult.get_collider()
            if ((foundCollider is CollisionObject3D || foundCollider is CSGShape3D) \
                && (foundCollider.get_collision_layer_value(3) || foundCollider.get_collision_layer_value(4))):
                var castHeightTravelled = ((nextPosCollisionCastStart.origin + collisionResult.get_travel()) - global_position).y
                if (castHeightTravelled > 0.01 && castHeightTravelled <= MAX_STEP_HEIGHT && (collisionResult.get_position() - global_position).y <= MAX_STEP_HEIGHT):
                    if stairRayCast.get_collision_normal().dot(Vector3.UP) < 0.1:
                        global_position = nextPosCollisionCastStart.origin + collisionResult.get_travel() + Vector3(0,0.02,0)
    # finally, move and slide
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
    return !jumping && !vaulting && !crouching && !crawling && !squeezing && !photographing && (onFloorLastFrame || climbing)
func handle_jump():
    try_clear_hover_state()
    velocity += Vector3(0,JUMP_IMPULSE,0)
    jumping = true
    if dragging: handle_drop()
    if climbing: stop_climbing()
func handle_land_jump():
    jumping = false
    vaulting = false

###
### VAULTING
###
func can_vault():
    return !vaulting && !crouching && !crawling && !climbing && !squeezing && !photographing && !grabbing && !dragging
func handle_vault(ledgePoint: Vector3):
    var spaceState = get_world_3d().direct_space_state
    var standingQuery = PhysicsRayQueryParameters3D.create(
        ledgePoint,
        ledgePoint + Vector3(0.0, standingHeight + 0.025, 0.0),
        collision_mask
    )
    standingQuery.exclude = [self]
    var canStandAtDestination = spaceState.intersect_ray(standingQuery)
    
    var canCrouchAtDestination = false
    if !canStandAtDestination.is_empty():
        var crouchingQuery = PhysicsRayQueryParameters3D.create(
            ledgePoint,
            ledgePoint + Vector3(0.0, CROUCH_HEIGHT + 0.025, 0.0),
            collision_mask
        )
        crouchingQuery.exclude = [self]
        canCrouchAtDestination = spaceState.intersect_ray(crouchingQuery)
        if !canCrouchAtDestination.is_empty():
            return false
        else:
            handle_crouch()
    running = false
    vaulting = true
    velocity = Vector3.ZERO
    var destination = ledgePoint - global_transform.basis.z * 0.1
    var start = global_position
    var mid = start.lerp(destination, 0.5) + Vector3(0.0, 0.5, 0.0)
    var tween = create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    tween.tween_method(bezier_move.bind(start, mid, destination + Vector3(0.0, 0.05, 0.0)), 0.0, 1.0, VAULT_DURATION)
    tween.tween_callback(handle_land_vault)
    return true
    
func handle_land_vault():
    vaulting = false
    jumping = false

func can_shape_change():
    var detectedCollisions: Array[Node3D] = roomForStateChangeArea.get_overlapping_bodies()
    return detectedCollisions.size() == 0
###
### CROUCHING
###
func can_crouch():
    if (!crawling):
        return !squeezing
    else:
        return can_shape_change()
func handle_crouch():
    if (grabbing || dragging || photographing):
        # stop photographing
        handle_drop()
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
        slideVelocity = SLIDE_IMPULSE
        running = false
    crawling = false
    crouching = true
    try_clear_hover_state()

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
    if (!crawling && !vaulting && !crouching && !climbing && !dragging && !grabbing):
        return onFloorLastFrame
    elif (crouching):
        return can_stand()
    else:
        return false
func handle_squeeze():
    handle_stand()
    try_clear_hover_state()
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
    elif (!vaulting):
        return onFloorLastFrame
    return false
func handle_run():
    running = true
    try_clear_hover_state()
    if (grabbing || dragging || photographing):
        # stop photographing
        handle_drop()

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
### Grabbing / Dragging
###
func can_hold(maxMass: float = 20.0):
    if (!dragging && !grabbing && !jumping && !vaulting && !crouching && !crawling && !squeezing && !running && !climbing && !photographing && onFloorLastFrame):
        if (objectInReachRef != null && objectInReachRef.mass > maxMass):
            return false
        else:
            return true
    else:
        return false
func handle_grab():
    objectInReachRef.on_hold()
    grabArm.spring_length = objectInReachRef.heldDistance
    grabArm.shape.radius = objectInReachRef.heldCollisionRadius
    # causes visual bug as arm rapidly shifts if we don't defer
    call_deferred("_handle_grab_deferred")
func _handle_grab_deferred():
    grabbing = true
    heldObjectRef = objectInReachRef
    heldObjectRef.clear_hover_material()

func handle_drag():
    objectInReachRef.on_hold()
    draggedPoint = objectInReachRef.to_local(grabAnchor.global_position)
    heldObjectRef = objectInReachRef
    heldObjectRef.clear_hover_material()
    dragging = true

func handle_drop():
    heldObjectRef.on_drop()
    heldObjectRef = null
    grabbing = false
    dragging = false
    grabArm.spring_length = grabArmLength
    grabArm.shape.radius = grabArmShapeRadius
    handle_stand()

func try_clear_hover_state():
    if objectInReachRef != null:
        objectInReachRef.clear_hover_material()
        objectInReachRef = null
###
### CLIMBING
###
func can_climb():
    if (adjacentRef != null && !climbing && !photographing && !dragging && !squeezing && !vaulting):
        if crouching: return can_shape_change()
        return true
    return false
func handle_climb():
    climbPath = adjacentRef.get_node_or_null("ClimbPath")
    if climbPath != null:
        climbCurve = climbPath.curve
        climbing = true
func stop_climbing():
    climbing = false
    climbPath = null
    climbCurve = null

###
### THROWING
###
func handle_throw():
    heldObjectRef.linear_velocity = (-camera.global_basis.z * heldObjectRef.throwImpulse) + Vector3(0.0, heldObjectRef.throwLobFactor, 0.0)
    heldObjectRef.on_throw()
    throwHeldOnNextFrame = false
    handle_drop()

func bezier_move(t: float, start: Vector3, mid: Vector3, end: Vector3):
    var a = start.lerp(mid, t)
    var b = mid.lerp(end, t)
    global_position = a.lerp(b, t)

func on_room_for_state_change_body_exited(_body: Node3D):
    if (squeezing && !Input.is_action_pressed("squeeze")):
        if (can_stand()):
            handle_stand()
            if (Input.is_action_pressed("run")):
                handle_run()

func on_grab_anchor_entered(body: Node3D):
    if (body is Holdable && objectInReachRef != body && can_hold(150.0)):
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
        if (crawling && can_crouch()):
            handle_crouch()
        elif (crouching && can_stand()):
            handle_stand()
        elif (can_climb() && !Input.is_action_pressed("run")):
            handle_climb()
        elif (can_jump() || can_vault()):
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
    elif (event.is_action_pressed("action")):
        actionTimer.start()
        if ((grabbing || dragging) && heldObjectRef != null):
            heldObjectRef.start_action()
    elif (event.is_action_released("action")):
        actionTimer.stop()
        if ((grabbing || dragging) && heldObjectRef != null):
            var playerActionResult = heldObjectRef.finish_action(actionTimerFinished)
            if !playerActionResult && grabbing:
                throwHeldOnNextFrame = true
        elif (!actionTimerFinished):
            flashlight.visible = !flashlight.visible
        actionTimerFinished = false
    elif (event.is_action_pressed("interact")):
        interactTimer.start()
        if grabbing && heldObjectRef != null:
            rotating = true
            heldObjectRef.on_rotate_start()
    elif (event.is_action_released("interact")):
        interactTimer.stop()
        if ((grabbing || dragging) && !interactTimerFinished):
            handle_drop()
        elif (can_hold(15.0) && objectInReachRef != null):
            handle_grab()
        elif (can_hold(150.0) && objectInReachRef != null):
            handle_drag()
        rotating = false
        if heldObjectRef != null:
            heldObjectRef.on_rotate_stop()
        interactTimerFinished = false
    elif (event.is_action_pressed("run")):
        if (climbing):
            stop_climbing()
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
    if crawling: moveDir.x = moveDir.x * 0.1
    
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
