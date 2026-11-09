class_name BehaviorState

## Mutually-exclusive behaviors that change player size, collider, and speed
var stand: StandBehavior
var crouch: CrouchBehavior
var crawl: CrawlBehavior
var squeeze: SqueezeBehavior

## velocity-modifying behaviors. vault and jump are call order dependant
var vault: VaultBehavior
var jump: JumpBehavior
var climb: ClimbBehavior
var sprint: SprintBehavior
var look: LookBehavior
var move: MoveBehavior
var stairstep: StairstepBehavior

## velocity-inheriting behaviors
var shove: ShoveBehavior
var target: TargetBehavior
var throw: ThrowBehavior
var grab: GrabBehavior # holdable
var rotate: RotateBehavior
var drag: DragBehavior # holdable
var unstuck: UnstuckBehavior

## Non-physics behaviors
var film_camera: FilmCameraBehavior
var flashlight: FlashlightBehavior

func _init(_player: Player) -> void:
    stand = StandBehavior.new(_player)
    crouch = CrouchBehavior.new(_player)
    crawl = CrawlBehavior.new(_player)
    squeeze = SqueezeBehavior.new(_player)
    vault = VaultBehavior.new(_player)
    jump = JumpBehavior.new(_player)
    climb = ClimbBehavior.new(_player)
    sprint = SprintBehavior.new(_player)
    look = LookBehavior.new(_player)
    move = MoveBehavior.new(_player)
    stairstep = StairstepBehavior.new(_player)
    shove = ShoveBehavior.new(_player)
    target = TargetBehavior.new(_player)
    throw = ThrowBehavior.new(_player)
    grab = GrabBehavior.new(_player)
    rotate = RotateBehavior.new(_player)
    drag = DragBehavior.new(_player)
    unstuck = UnstuckBehavior.new(_player)
    film_camera = FilmCameraBehavior.new(_player)
    flashlight = FlashlightBehavior.new(_player)

## all behaviors in update order
func all() -> Array[PlayerBehavior]:
    return [
        stand, crouch, crawl, squeeze, # mutually-exclusive player size and collision changers
        vault, jump, # call order dependant; vaulting prevents jump
        climb, sprint, look, move, stairstep, # velocity modifying behaviors
        shove, target, throw, grab, rotate, drag, unstuck, # velocity inheriting behaviors
        film_camera, flashlight # non-physics behaviors
    ]

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
