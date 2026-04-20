extends Resource
class_name TileRegistry

@export var tiles: Array[DungeonTile] = []

func get_tiles_with_openings(mask: int) -> Array[DungeonTile]:
    var matches: Array[DungeonTile] = []
    for tile in tiles:
        if (tile.tile_openings & mask) == mask:
            matches.append(tile)
    return matches

func get_tiles_with_exact_openings(mask: int) -> Array[DungeonTile]:
    var matches: Array[DungeonTile] = []
    for tile in tiles:
        if tile.tile_openings == mask:
            matches.append(tile)
    return matches

