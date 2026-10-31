class_name CrawlBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"jump", &"vault", &"squeeze", &"sprint", &"climb"]
const mutuallyExclusiveWith: Array[StringName] = [&"stand", &"grab", &"drag", &"crouch", &"film_camera"]

func can_act() -> bool:
    return !active && pb.none(cannotTransitionFrom) && pb.jump.onFloorLastFrame

func start_action() -> void:
    if active: return
    active = true
    pb.stop(mutuallyExclusiveWith)
    set_positions()

func set_positions() -> void:
    p.set_default_positions()
    # capsule collider can't be shorter than it is wide; rotate on camera axis so its sideways, 
    # thus maintaining player "width"
    p.playerShape.height = p.standingRadius * 2.0
    p.playerShape.radius = p.CRAWL_HEIGHT / 2.0
    p.playerCollider.position.y = p.CRAWL_HEIGHT / 2.0
    p.playerCollider.rotation.z = deg_to_rad(90.0)
    p.roomForStateChangeShape.height = p.CROUCH_HEIGHT
    p.roomForStateChangeShape.radius = p.CRAWL_HEIGHT / 2.0
    p.roomForStateChangeCollider.position.y = p.CROUCH_HEIGHT / 2.0
    p.camera.position.y = p.CRAWL_HEIGHT - p.cameraTopOffset
    pb.flashlight.light.position.y = pb.flashlight.offset.y / 3.0
