## Represents a single placeable dungeon element with its metadata.
class_name DungeonTile
extends Resource

enum TileType {
	EMPTY,
	ROOM,
	CORRIDOR_H,
	CORRIDOR_V,
	CORRIDOR_CROSS,
	CORRIDOR_T_UP,
	CORRIDOR_T_DOWN,
	CORRIDOR_T_LEFT,
	CORRIDOR_T_RIGHT,
	CORNER_TL,
	CORNER_TR,
	CORNER_BL,
	CORNER_BR,
	TREASURE,
	MONSTER,
	BOSS,
	ENTRANCE,
}

@export var tile_type: TileType = TileType.EMPTY
@export var display_name: String = ""
@export var color: Color = Color.WHITE
@export var symbol: String = ""
@export var category: String = ""
@export var is_overlay: bool = false  # If true, this tile is drawn on top of a base tile (rather than replacing it)

static func create(type: TileType, name: String, col: Color, sym: String, cat: String, overlay: bool = false) -> DungeonTile:
	var tile = DungeonTile.new()
	tile.tile_type = type
	tile.display_name = name
	tile.color = col
	tile.symbol = sym
	tile.category = cat
	tile.is_overlay = overlay
	return tile
