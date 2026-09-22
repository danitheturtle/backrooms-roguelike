extends Node

const savesRootPath = "user://saves"
func slot_name(slotIndex: int) -> String:
    return "slot" + str(slotIndex)
func slot_folder_path(slotIndex: int) -> String:
    return savesRootPath + "/" + slot_name(slotIndex)
func slot_savegame_path(slotIndex: int) -> String:
    return slot_folder_path(slotIndex) + "/savegame.json"
func slot_node_data_path(slotIndex: int) -> String:
    return slot_folder_path(slotIndex) + "/node_data.json"
    

var inMemoryMode: bool
var savesOnDisk: Dictionary[int, SaveSlotStats]
var activeSlot: int # -1 means no active slot

# global serialized data
var customName: String
var runs: Array[Run]
var exitsFound: Array = []
var playTime: float
var lastSavedTime: float

# properties
var totalScore: int:
    get:
        var scoreValue = 0
        for nextRun in runs:
            for nextEvent in nextRun.scoreEvents:
                scoreValue += nextEvent.value
        return scoreValue

var sortedSaves: Array[SaveSlotStats]:
    get:
        var sortedArray = savesOnDisk.values()
        sortedArray.sort_custom(func(a, b): return a.lastSavedTime > b.lastSavedTime)
        return sortedArray

func _init() -> void:
    inMemoryMode = true
    reinit()
    if inMemoryMode: return
    # ensure saves folder exists
    if not DirAccess.dir_exists_absolute(savesRootPath):
        var error = DirAccess.make_dir_absolute(savesRootPath)
        if error != OK:
            print("could not create save directory", error)
            inMemoryMode = true
    load_stats_for_saves_on_disk()

func reinit() -> void:
    activeSlot = 1
    customName = "slot1"
    runs = []
    savesOnDisk = {}
    if inMemoryMode: return
    activeSlot = -1

func load_stats_for_saves_on_disk():
    if inMemoryMode: return
    savesOnDisk = {}
    var saveDirectories: PackedStringArray = DirAccess.get_directories_at(savesRootPath)
    for nextSave: String in saveDirectories:
        # strip 'slot' from beginning of string; cast to int
        var nextSaveIndex = int(nextSave.right(-4))
        var nextData = Utils.read_first_line_json(slot_savegame_path(nextSaveIndex))
        savesOnDisk.set(nextSaveIndex, SaveSlotStats.new(nextData))

func first_empty_slot_index() -> int:
    if inMemoryMode: return 1
    var emptySlotIndex = 1
    if SaveSlot.savesOnDisk.size() < emptySlotIndex: return emptySlotIndex
    while SaveSlot.savesOnDisk.has(emptySlotIndex):
        emptySlotIndex += 1
    return emptySlotIndex

func new_slot(slotIndex: int) -> void:
    delete_slot(slotIndex)
    reinit()
    activeSlot = slotIndex
    save_game()
    SignalBus.new_run_started.emit()

func save_game() -> void:
    if inMemoryMode: return
    if not DirAccess.dir_exists_absolute(slot_folder_path(activeSlot)):
        var error = DirAccess.make_dir_absolute(slot_folder_path(activeSlot))
        if error != OK:
            print("could not create save slot directory", error)
            inMemoryMode = true
            return
    var savegameFile := FileAccess.open(slot_savegame_path(activeSlot), FileAccess.WRITE)
    if savegameFile == null:
        print("could not save game", FileAccess.get_open_error())
        inMemoryMode = true
    else:
        lastSavedTime = Time.get_unix_time_from_system()
        var textToStore = JSON.stringify(serialize())
        savegameFile.store_line(textToStore)
        savegameFile.close()
        # TODO save nodes in group save_to_disk

func load_slot(slotIndex: int) -> void:
    if inMemoryMode: return
    activeSlot = slotIndex
    var savegameFile := FileAccess.open(slot_savegame_path(activeSlot), FileAccess.READ)
    if savegameFile == null:
        print("could not load game", FileAccess.get_open_error())
        inMemoryMode = true
    else:
        var saveData = Utils.read_first_line_json(slot_savegame_path(activeSlot))
        if saveData.keys().size() > 0:
            deserialize(saveData)
        savegameFile.close()
        # TODO load nodes from group save_to_disk
    SignalBus.new_run_started.emit()

func delete_slot(slotIndex: int) -> void:
    if inMemoryMode: return
    var slotAbsolutePath = slot_folder_path(slotIndex)
    if DirAccess.dir_exists_absolute(slotAbsolutePath):
        var deleteResult = DirAccess.remove_absolute(slotAbsolutePath)
        if deleteResult != OK:
            print("could not clear save slot", deleteResult)
            inMemoryMode = true

# should serialize the full game state
func serialize() -> Dictionary:
    var dataDict = {
        "index": activeSlot,
        "customName": "slot" + str(activeSlot),
        "runs": [],
        "totalScore": totalScore,
        "exitsFound": exitsFound,
        "playTime": playTime,
        "lastSavedTime": lastSavedTime
    }
    for nextRun in runs:
        dataDict.runs.append(nextRun.serialize())
    return dataDict

func deserialize(dataDict: Dictionary) -> void:
    customName = dataDict.customName
    runs = []
    for nextRun in dataDict.runs:
        runs.append(Run.new().deserialize(nextRun))
    exitsFound = dataDict.exitsFound
    playTime = dataDict.playTime
    lastSavedTime = dataDict.lastSavedTime
