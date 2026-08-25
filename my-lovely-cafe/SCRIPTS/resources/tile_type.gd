extends Marker3D
class_name CafeTile
# Attach this directly to each Marker3D in your customer path. Your
# LevelManager/Customer code already treats path entries as the markers
# themselves (t.tile_type, t.global_position), so CafeTile IS the marker
# rather than wrapping one.

enum TileType { SPAWN, ORDER, SEAT, WALKWAY }

@export var tile_type: TileType = TileType.WALKWAY
