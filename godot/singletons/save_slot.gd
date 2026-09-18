extends Node

const saveRootPath = "user://saves"
var inMemoryMode: bool
var savesOnDisk: Array[int]
var activeSlot: int # -1 means no active slot

# global serialized data
var runs: Array[Run]
var exitsFound: Array[int] = []

# properties
var totalScore: int:
    get:
        var scoreValue = 0
        for nextRun in runs:
            for nextEvent in nextRun.scoreEvents:
                scoreValue += nextEvent.value
        return scoreValue
var slotName: String:
    get: return "slot" + str(activeSlot)
var slotFolderPath: String:
    get: return saveRootPath + "/" + slotName
var slotSavegamePath: String:
    get: return slotFolderPath + "/savegame.json"
var slotNodeDataPath: String:
    get: return slotFolderPath + "/node_data.json"

func _init() -> void:
    inMemoryMode = false
    # ensure saves folder exists
    if not DirAccess.dir_exists_absolute(saveRootPath):
        var error = DirAccess.make_dir_absolute(saveRootPath)
        if error != OK:
            print("could not create save directory", error)
            inMemoryMode = true
    reinit()

func reinit() -> void:
    activeSlot = 1
    runs = []
    savesOnDisk = []
    if !inMemoryMode:
        activeSlot = -1
        var saveDirectories: PackedStringArray = DirAccess.get_directories_at(saveRootPath)
        for nextSave: String in saveDirectories:
            # strip 'slot' from beginning of string; cast to int
            var saveNumber = int(nextSave.right(-4))
            savesOnDisk.append(saveNumber)

func new_slot(slotNumber: int) -> void:
    delete_slot(slotNumber)
    reinit()
    activeSlot = slotNumber
    save_game()

func save_game() -> void:
    if inMemoryMode: return
    var saveFile := FileAccess.open(slotFolderPath + "/savegame.json", FileAccess.WRITE)
    if saveFile == null:
        print("could not save game", FileAccess.get_open_error())
        inMemoryMode = true
    saveFile.store_line(JSON.stringify(serialize()))
    # TODO save nodes in group save_to_disk

func load_slot(slotNumber: int) -> void:
    if inMemoryMode: return
    activeSlot = slotNumber
    var saveFile := FileAccess.open(slotSavegamePath, FileAccess.READ)
    if saveFile == null:
        print("could not load game", FileAccess.get_open_error())
        inMemoryMode = true
    else:
        var jsonParser = JSON.new()
        var jsonString = saveFile.get_line()
        var parseResult = jsonParser.parse(jsonString)
        if parseResult != OK:
            print("JSON Parse Error: ", jsonParser.get_error_message(), " in ", jsonString, " at line ", jsonParser.get_error_line())
            return
        deserialize(jsonParser.data)
        # TODO load nodes from group save_to_disk

func delete_slot(slotNumber: int) -> void:
    if inMemoryMode: return
    var slotAbsolutePath = saveRootPath + "/" + "slot" + str(slotNumber)
    if DirAccess.dir_exists_absolute(slotAbsolutePath):
        var deleteResult = DirAccess.remove_absolute(slotAbsolutePath)
        if deleteResult != OK:
            print("could not clear save slot", deleteResult)
            inMemoryMode = true

# should serialize the full game state
func serialize() -> Dictionary[String,Variant]:
    var dataDict = {
        "runs": [],
        "exitsFound": exitsFound
    }
    for nextRun in runs:
        dataDict.runs.append(nextRun.serialize())
    return dataDict

func deserialize(dataDict: Dictionary[String,Variant]) -> void:
    runs = []
    for nextRun in dataDict.runs:
        runs.append(Run.new().deserialize(nextRun))
    exitsFound = dataDict.exitsFound
