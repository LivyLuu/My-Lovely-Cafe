extends Resource
class_name CafeTile
# One of these = one labeled entry in an Array[CafeTile] in the Inspector.
# Each shows both a Tile Type dropdown AND a Marker3D drag-and-drop slot.
 
enum TileType { SPAWN, ORDER, SEAT, WALKWAY }
 
@export var tile_type: TileType = TileType.WALKWAY
