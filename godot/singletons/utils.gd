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
func equalsf(a: float, b: float, precision: float = 0.00001):
    return a + precision >= b && a - precision <= b

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

func get_materials_on_mesh(mesh: MeshInstance3D):
    var totalSurfaces = mesh.mesh.get_surface_count()
    var activeMaterials: Array[BaseMaterial3D] = []
    for surfaceIndex in range(0,totalSurfaces):
        var nextMaterial = mesh.get_active_material(surfaceIndex)
        if nextMaterial != null: activeMaterials.append(nextMaterial)
    return activeMaterials
    
