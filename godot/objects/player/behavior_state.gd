class_name BehaviorState

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

var stand: StandBehavior
var crouch: CrouchBehavior
var crawl: CrawlBehavior
var squeeze: SqueezeBehavior
var jump: JumpBehavior
var vault: VaultBehavior
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
    crouch = CrouchBehaviorRes.new(_player)
    crawl = CrawlBehaviorRes.new(_player)
    squeeze = SqueezeBehaviorRes.new(_player)
    jump = JumpBehaviorRes.new(_player)
    vault = VaultBehaviorRes.new(_player)
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
    return [stand, crouch, crawl, squeeze, jump, vault, sprint, climb, stairstep, drag, rotate, throw, shove, film_camera, flashlight]
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
