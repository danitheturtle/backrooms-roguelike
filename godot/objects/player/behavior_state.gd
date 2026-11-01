class_name BehaviorState

## Mutually-exclusive behaviors that change player size, collider, and speed
var stand: StandBehavior
var crouch: CrouchBehavior
var crawl: CrawlBehavior
var squeeze: SqueezeBehavior

## Behaviors that modify velocity
var vault: VaultBehavior
var jump: JumpBehavior
var sprint: SprintBehavior
var climb: ClimbBehavior
var stairstep: StairstepBehavior

## Prop interaction behaviors
var drag: DragBehavior
var grab: GrabBehavior
var rotate: RotateBehavior
var throw: ThrowBehavior
## TODO activate behavior
var shove: ShoveBehavior

## Non-physical gameplay behaviors
var film_camera: FilmCameraBehavior
var flashlight: FlashlightBehavior

func _init(_player: Player) -> void:
    stand = StandBehavior.new(_player)
    crouch = CrouchBehavior.new(_player)
    crawl = CrawlBehavior.new(_player)
    squeeze = SqueezeBehavior.new(_player)
    vault = VaultBehavior.new(_player)
    jump = JumpBehavior.new(_player)
    sprint = SprintBehavior.new(_player)
    climb = ClimbBehavior.new(_player)
    stairstep = StairstepBehavior.new(_player)
    drag = DragBehavior.new(_player)
    grab = GrabBehavior.new(_player)
    rotate = RotateBehavior.new(_player)
    throw = ThrowBehavior.new(_player)
    shove = ShoveBehavior.new(_player)
    film_camera = FilmCameraBehavior.new(_player)
    flashlight = FlashlightBehavior.new(_player)

func all() -> Array[PlayerBehavior]:
    return [stand, crouch, crawl, squeeze, vault, jump, sprint, climb, stairstep, drag, rotate, throw, shove, film_camera, flashlight]

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
