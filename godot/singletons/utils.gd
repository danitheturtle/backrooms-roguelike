extends Node
# in all functions, X represents a float between 0 and 1

func normf(value: float, rangeStart: float, rangeEnd: float) -> float:
    return (value - rangeStart) / (rangeEnd - rangeStart)

func easeInOutCubic(x: float) -> float:
    if (x < 0.5):
        return 4 * x * x * x
    else:
        return 1 - ((-2 * x + 2) ** 3) / 2

# compare two floats with a given precision
func equalsf(a: float, b: float, epsilon: float = 0.001):
    return a + epsilon >= b && a - epsilon <= b

# get 2d index in a 1d array given a width
func coordIndex(x: int, y: int, width: int):
    return x + (y * width)

# as opposed to default implementation only returns true with overlap greater than epsilon
func rect_intersectsf(rect1: Rect2, rect2: Rect2, epsilon: float = 0.001) -> bool:
    var test1 = rect1.position.x + epsilon < rect2.end.x
    var test2 = rect1.end.x - epsilon > rect2.position.x
    var test3 = rect1.position.y + epsilon < rect2.end.y
    var test4 = rect1.end.y - epsilon > rect2.position.y
    return test1 && test2 && test3 && test4

# gets self or first found child of given type
func get_self_or_child_of_type(selfNode: Node, type: Variant, recursive: bool = false):
    if is_instance_of(selfNode, type):
        return selfNode
    else:
        return get_child_of_type(selfNode, type, recursive)

# gets first found child of given type
func get_child_of_type(parentNode: Node, type: Variant, recursive: bool = false):
    var allChildren = parentNode.get_children(true) if !recursive else parentNode.find_children("*")
    if allChildren.size() == 0: return null
    for nextChild in allChildren:
        if is_instance_of(nextChild, type):
            return nextChild

# gets all children of node that are a given type
func get_children_of_type(parentNode: Node, type: Variant, recursive: bool = false):
    var foundChildren = []
    var allChildren = parentNode.get_children(true) if !recursive else parentNode.find_children("*")
    if allChildren.size() == 0: return foundChildren
    for nextChild in allChildren:
        if is_instance_of(nextChild, type):
            foundChildren.append(nextChild)
    return foundChildren

# gets all children of node in given group
func get_children_in_group(parentNode: Node, groupName: String, recursive: bool = false):
    var foundChildren = []
    var allChildren = parentNode.find_children("*", "", recursive)
    if allChildren.size() == 0: return foundChildren
    for nextChild in allChildren:
        if nextChild.is_in_group(groupName):
            foundChildren.append(nextChild)
    return foundChildren

func get_materials_on_mesh(mesh: MeshInstance3D) -> Array[BaseMaterial3D]:
    var totalSurfaces = mesh.mesh.get_surface_count()
    var activeMaterials: Array[BaseMaterial3D] = []
    for surfaceIndex in range(0,totalSurfaces):
        var nextMaterial = mesh.get_active_material(surfaceIndex)
        if nextMaterial != null: activeMaterials.append(nextMaterial)
    return activeMaterials
    
func load_or_create_config(file: ConfigFile, filepath: String) -> Error:
    var loadError = file.load(filepath)
    if loadError != OK:
        var saveError: Error = file.save(filepath)
        return saveError
    else:
        return loadError

func read_first_line_json(filepath: String) -> Dictionary:
    var openedFile := FileAccess.open(filepath, FileAccess.READ)
    var unparsedString = openedFile.get_line()
    openedFile.close()
    var jsonParser = JSON.new()
    var parseResult = jsonParser.parse(unparsedString)
    if parseResult != OK:
        print("JSON Parse Error: ", jsonParser.get_error_message(), " in ", unparsedString, " at line ", jsonParser.get_error_line())
        return {}
    return jsonParser.data
