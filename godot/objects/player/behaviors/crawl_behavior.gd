class_name CrawlBehavior
extends PlayerBehavior

func can_act() -> bool:
    return p.b.crouch.active && p.onFloorLastFrame
func start_action() -> void:
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
    p.flashlight.position.y = p.flashlightOffset.y / 3.0
    p.b.crouch.active = false
    p.photographing = false
    active = true
func process_action(_delta: float) -> void: pass
func end_action() -> void: pass
