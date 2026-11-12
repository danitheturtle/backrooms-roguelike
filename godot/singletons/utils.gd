@tool
extends Node

## Get percentage of a range in float form 0.0-1.0
func normf(_value: float, _rangeStart: float, _rangeEnd: float) -> float:
    return (_value - _rangeStart) / (_rangeEnd - _rangeStart)

## cubic ease in out. _x is 0.0 to 1.0
func easeInOutCubic(_x: float) -> float:
    if (_x < 0.5):
        return 4 * _x * _x * _x
    else:
        return 1 - ((-2 * _x + 2) ** 3) / 2

## compare two floats with a given precision
func equalsf(_a: float, _b: float, _epsilon: float = 0.001):
    return _a + _epsilon >= _b && _a - _epsilon <= _b

## get 2d index in a 1d array given a width
func coordIndex(_x: int, _y: int, _width: int):
    return _x + (_y * _width)

## as opposed to default implementation only returns true with overlap greater than epsilon
## as opposed to default implementation only returns true with overlap greater than epsilon
func rect_intersectsf(_rect1: Rect2, _rect2: Rect2, _epsilon: float = 0.001) -> bool:
    var _test1 = _rect1.position.x + _epsilon < _rect2.end.x
    var _test2 = _rect1.end.x - _epsilon > _rect2.position.x
    var _test3 = _rect1.position.y + _epsilon < _rect2.end.y
    var _test4 = _rect1.end.y - _epsilon > _rect2.position.y
    return _test1 && _test2 && _test3 && _test4

## calls a callback after _timeout seconds with self-cleanup. returns timer ref. works like javascript
func set_timeout(_callback: Callable, _timeout: float) -> Timer:
    var timeoutTimer = Timer.new()
    timeoutTimer.wait_time = _timeout
    timeoutTimer.one_shot = true
    timeoutTimer.autostart = true
    var callbackWithCleanup := func callback_with_cleanup() -> void:
        _callback.call()
        timeoutTimer.queue_free()
    timeoutTimer.timeout.connect(callbackWithCleanup)
    get_tree().root.add_child(timeoutTimer)
    return timeoutTimer

## Checks if version is newer than an oldest compatible version
func is_version_valid(_oldestCompatibleVersion: Array[int], _version: String) -> bool:
    var versionSplit := _version.split(".", false)
    if versionSplit.size() == 0: return false
    var versionNumbers: Array[int] = []
    for nextNum: String in versionSplit:
        versionNumbers.append(int(nextNum))
    if versionNumbers[0] > _oldestCompatibleVersion[0]:
        return true
    elif versionNumbers[0] == _oldestCompatibleVersion[0]:
        if versionNumbers[1] > _oldestCompatibleVersion[1]:
            return true
        elif versionNumbers[1] == _oldestCompatibleVersion[1]:
            if versionNumbers[2] >= _oldestCompatibleVersion[2]:
                return true
    return false

## checks if node is in any of the groups listed
func is_in_any_group(_node: Node, _groupList: Array[String]) -> bool:
    if _node == null: return false
    for nextGroup in _groupList:
        if _node.is_in_group(nextGroup):
            return true
    return false

#region Typesafe Tree-Traversing Getters
## gets self or first found child of given type
func get_self_or_child_of_type(_selfNode: Node, _type: Variant, _recursive: bool = false):
    if is_instance_of(_selfNode, _type):
        return _selfNode
    else:
        return get_child_of_type(_selfNode, _type, _recursive)

## gets first found child of given type
func get_child_of_type(_parentNode: Node, _type: Variant, _recursive: bool = false):
    var allChildren = _parentNode.get_children(true) if !_recursive else _parentNode.find_children("*")
    if allChildren.size() == 0: return null
    for nextChild in allChildren:
        if is_instance_of(nextChild, _type):
            return nextChild

## gets all children of node that are a given type
func get_children_of_type(_parentNode: Node, _type: Variant, _recursive: bool = false):
    var foundChildren = []
    var allChildren = _parentNode.get_children(true) if !_recursive else _parentNode.find_children("*")
    if allChildren.size() == 0: return foundChildren
    for nextChild in allChildren:
        if is_instance_of(nextChild, _type):
            foundChildren.append(nextChild)
    return foundChildren

## gets first parent of given type, or null
func get_parent_of_type(_childNode: Node, _type: Variant):
    if _childNode == null: return null
    var parentNode = _childNode.get_parent()
    if !is_instance_of(parentNode, _type):
        if parentNode == null: return null
        return get_parent_of_type(parentNode, _type)
    else:
        return parentNode

## gets all children of node in given group
func get_children_in_group(_parentNode: Node, _groupName: String, _recursive: bool = false):
    var foundChildren = []
    var allChildren = _parentNode.find_children("*", "", _recursive)
    if allChildren.size() == 0: return foundChildren
    for nextChild in allChildren:
        if nextChild.is_in_group(_groupName):
            foundChildren.append(nextChild)
    return foundChildren
#endregion

#region Materials and Surfaces
func get_materials_on_mesh(_mesh: MeshInstance3D) -> Array[Material]:
    var totalSurfaces = _mesh.mesh.get_surface_count()
    var activeMaterials: Array[Material] = []
    for surfaceIndex in totalSurfaces:
        var nextMaterial: Material = _mesh.get_active_material(surfaceIndex)
        activeMaterials.append(nextMaterial)
    return activeMaterials

func get_surface_overrides_on_mesh(_mesh: MeshInstance3D) -> Array[Material]:
    var totalSurfaces = _mesh.mesh.get_surface_count()
    var surfaceOverrides: Array[Material] = []
    for surfaceIndex in totalSurfaces:
        var nextMaterial: Material = _mesh.get_surface_override_material(surfaceIndex)
        surfaceOverrides.append(nextMaterial)
    return surfaceOverrides

func apply_surface_overrides(_mesh: MeshInstance3D, _materials: Array[Material]) -> void:
    if _mesh == null: return
    for surfaceIndex in _mesh.mesh.get_surface_count():
        var activeSurfaceOverride = _mesh.get_surface_override_material(surfaceIndex)
        if activeSurfaceOverride != _materials[surfaceIndex]:
            _mesh.set_surface_override_material(surfaceIndex, _materials[surfaceIndex])
#endregion

#region File I/O
func load_or_create_config(_file: ConfigFile, _filepath: String) -> Error:
    var loadError = _file.load(_filepath)
    if loadError != OK:
        var saveError: Error = _file.save(_filepath)
        return saveError
    else:
        return loadError

func read_first_line_json(_filepath: String) -> Dictionary:
    var openedFile := FileAccess.open(_filepath, FileAccess.READ)
    var unparsedString = openedFile.get_line()
    openedFile.close()
    var jsonParser = JSON.new()
    var parseResult = jsonParser.parse(unparsedString)
    if parseResult != OK:
        push_error("JSON Parse Error: ", jsonParser.get_error_message(), " in ", unparsedString, " at line ", jsonParser.get_error_line())
        return {}
    return jsonParser.data

func remove_dir_recursive(_dirPath: String) -> Error:
    var filesInDir := DirAccess.get_files_at(_dirPath)
    var dirsInDir := DirAccess.get_directories_at(_dirPath)
    for nextDirName in dirsInDir:
        var nextDirPath = _dirPath + "/" + nextDirName
        var recursiveCallResult = remove_dir_recursive(nextDirPath)
        if recursiveCallResult != Error.OK:
            push_warning("Error recursively deleting directory ", nextDirPath, " ", recursiveCallResult)
            return recursiveCallResult
    for nextFileName in filesInDir:
        var nextFilePath = _dirPath + "/" + nextFileName
        var removeFileResult = DirAccess.remove_absolute(nextFilePath)
        if removeFileResult != Error.OK:
            push_warning("Error recursively deleting directory ", nextFilePath, " ", removeFileResult)
            return removeFileResult
    var dirRemoveResult = DirAccess.remove_absolute(_dirPath)
    if dirRemoveResult != Error.OK:
        push_warning("Error recursively deleting directory ", _dirPath, " ", dirRemoveResult)
    return dirRemoveResult
#endregion

#region Debug Drawing
var drawnLines: Dictionary[StringName, MeshInstance3D] = {}
func draw_line(_id: StringName, _start: Vector3, _end: Vector3, _color: Color) -> void:
    if !OS.is_debug_build(): return
    var startToEnd: Vector3 = _end - _start
    var length: float = startToEnd.length()
    if equalsf(length, 0.0):return
    var dir = startToEnd / length
    var middle = _start + startToEnd/2.0
    if !drawnLines.has(_id):
        var newLine = MeshInstance3D.new()
        newLine.transform.origin = middle
        newLine.transform.basis.y = dir
        newLine.mesh = CapsuleMesh.new()
        newLine.mesh.radial_segments = 8
        newLine.mesh.radius = 0.01
        newLine.mesh.height = length
        newLine.material_override = StandardMaterial3D.new()
        newLine.material_override.albedo_color = _color
        drawnLines.set(_id, newLine)
        get_tree().root.add_child(newLine)
    else:
        var modifiedLine: MeshInstance3D = drawnLines.get(_id)
        if modifiedLine.transform.origin != middle:
            modifiedLine.transform.origin = middle
        if modifiedLine.mesh.height != length:
            modifiedLine.mesh.height = length
        if modifiedLine.transform.basis.y != dir:
            modifiedLine.transform.basis.y = dir
        if modifiedLine.material_override.albedo_color != _color:
            modifiedLine.material_override.albedo_color = _color

func draw_vector(_id: StringName, _pos: Vector3, _vector: Vector3, _color: Color) -> void:
    if !OS.is_debug_build(): return
    draw_line(_id, _pos, _pos + _vector, _color)

var drawnPoints: Dictionary[StringName, MeshInstance3D] = {}
func draw_point(_id: StringName, _pos: Vector3, _color: Color = Color.AQUA, _radius: float = 0.05) -> void:
    if !OS.is_debug_build(): return
    if !drawnPoints.has(_id):
        var newPoint = MeshInstance3D.new()
        newPoint.transform.origin = _pos
        newPoint.mesh = SphereMesh.new()
        newPoint.mesh.radius = _radius
        newPoint.mesh.height = _radius * 2.0
        newPoint.material_override = StandardMaterial3D.new()
        newPoint.material_override.albedo_color = _color
        drawnPoints.set(_id, newPoint)
        get_tree().root.add_child(newPoint)
    else:
        var modifiedPoint: MeshInstance3D = drawnPoints.get(_id)
        if modifiedPoint.transform.origin != _pos:
            modifiedPoint.transform.origin = _pos
        if modifiedPoint.mesh.radius != _radius:
            modifiedPoint.mesh.radius = _radius
            modifiedPoint.mesh.height = _radius * 2.0
        if modifiedPoint.material_override.albedo_color != _color:
            modifiedPoint.material_override.albedo_color = _color
#endregion
