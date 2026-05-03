
extends Node
class_name TileMapGenerator
## The class makes generators. Its pretty cool
##
## 

enum PatternId {
	CROSS,
	STRAIGHT_HORIZONTAL,
	STRAIGHT_VERTICAL,
	T_EAST,
	T_WEST,
	T_SOUTH,
	T_NORTH,
	L_NORTH_WEST,
	L_NORTH_EAST,
	L_SOUTH_WEST,
	L_SOUTH_EAST,
}

@export var door_sprite: Sprite2D
@export var boss_sprite: Sprite2D  
@export var treasure_sprite: Sprite2D



## TileMapLayer that receives the generated patterns.
@export var tileMap: TileMapLayer
## Maximum number of patterns that can be placed during generation.
@export var MAXTILES: int = 25

## Patterns widths and heights
@export_category("Pattern Sizes")
@export var pattern_width: int = 9
@export var pattern_height: int = 9

## Total width of the allowed generation area in tile cells.
## This is computed from num_w_cell * pattern_width.
var MAX_W_CELL: int

## Number of pattern "slots" allowed horizontally.
## Example: if this is 5 and pattern_width is 3, total width is 15 cells.
@export_range(1,10,1) var num_w_cell: int = 5

## Total height of the allowed generation area in tile cells.
## This is computed from num_h_cell * pattern_height.
var MAX_H_CELL: int

## Number of pattern "slots" allowed vertically.
@export_range(1,10,1) var num_h_cell: int = 5


var curr_pos:Vector2i
var visited: Array = []

func _for_debug_gen()->void:
	assert(tileMap.tile_set, "Tile set was not provided in the tilemap layer")
	gen_map(num_w_cell, num_h_cell, MAXTILES)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(tileMap.tile_set, "Tile set was not provided in the tilemap layer")
	gen_map(num_w_cell, num_h_cell, MAXTILES)
	
	var spawn   = _find_spawn()
	var boss    = _find_boss(spawn)
	var treasure = _find_treasure(spawn)




# Initializes the valid generation bounds in tile coordinates.
#
# width  = number of pattern slots horizontally
# height = number of pattern slots vertically
#
# Example:
#   width = 5, pattern_width = 3  => MAX_W_CELL = 15
#   height = 5, pattern_height = 3 => MAX_H_CELL = 15
func _init_grid(width: int, height: int) -> void:
	var x = tileMap.tile_set.tile_size.x
	var y = tileMap.tile_set.tile_size.y
	var w_cells : int = floor(width*x)
	var h_cells : int = floor(height*y)
	
	MAX_W_CELL = width * pattern_width
	MAX_H_CELL = height * pattern_height

# Adds items to an array only if they are not already present.
# Useful for preventing duplicate frontier or candidate entries and
# is esstential a set duplicate checker.
func _append_unique(items: Array[Variant], arr:Array) -> void:
	for i in items:
		if not arr.has(i):
			arr.append(i)

func _is_walkable_cell(pos: Vector2i) -> bool:
	var tile_data := tileMap.get_cell_tile_data(pos)
	if tile_data == null:
		return false
	return tile_data.get_custom_data("walkable") == true

## Chooses a random pattern that fits the current position based on
## neighboring openings around curr_pos.
##
## The generator checks the tile just outside each side of the current
## pattern area:
## - if that neighboring cell is an opening/path tile (source id 0),
##   then the new pattern should include a matching connection on that side.
##
## If no required neighboring openings are found, any pattern may be chosen.
func choose_rand_pattern()-> TileMapPattern:
	# Neighbor check positions are based on the top-left corner of curr_pos.
	# These positions look just outside the possible pattern footprint.
	var dir:Dictionary[String,Vector2i] = {
		"north":  Vector2i(curr_pos.x + pattern_width/2, curr_pos.y - 1),
		"south":  Vector2i(curr_pos.x + pattern_width/2, (curr_pos.y + pattern_height)),
		"west" : Vector2i(curr_pos.x - 1, (curr_pos.y + pattern_height/2)),
		"east" : Vector2i((curr_pos.x + pattern_width), (curr_pos.y + pattern_height/2)),		
		}
		
	# Tracks which sides require an opening based on surrounding tiles.
	var d: Dictionary = {
		"north": false,
		 "south":false,
		 "east":false,
		 "west":false
		}
	for key in dir:
		print("Current ID of Tile: ", tileMap.get_cell_source_id(dir[key]))
		if _is_walkable_cell(dir[key]):
			d[key] = true	
		
	# If there are no required openings, pick any pattern at random.
	if not d.values().has(true):
		var index = randi_range(0, tileMap.tile_set.get_patterns_count() - 1)
		return tileMap.tile_set.get_pattern(index)
	
	# Collect all patterns that satisfy at least one required opening.
	# Note: this is currently a union of allowed patterns by side and
	# should probably be updated to using an intersection? But it seems to
	# work so I will just leave it.
	var openings: Array = []
	if d["north"] == true:
		_append_unique([
			tileMap.tile_set.get_pattern(PatternId.CROSS),
			tileMap.tile_set.get_pattern(PatternId.STRAIGHT_VERTICAL),
			tileMap.tile_set.get_pattern(PatternId.T_NORTH),
			tileMap.tile_set.get_pattern(PatternId.T_WEST),
			tileMap.tile_set.get_pattern(PatternId.T_EAST),
			tileMap.tile_set.get_pattern(PatternId.L_NORTH_WEST),
			tileMap.tile_set.get_pattern(PatternId.L_NORTH_EAST),
			], openings)
	if d["south"] == true:
		_append_unique([
			tileMap.tile_set.get_pattern(PatternId.CROSS),
			tileMap.tile_set.get_pattern(PatternId.STRAIGHT_VERTICAL),
			tileMap.tile_set.get_pattern(PatternId.T_WEST),
			tileMap.tile_set.get_pattern(PatternId.T_EAST),
			tileMap.tile_set.get_pattern(PatternId.T_SOUTH),
			tileMap.tile_set.get_pattern(PatternId.L_SOUTH_EAST),
			tileMap.tile_set.get_pattern(PatternId.L_SOUTH_WEST),
			], openings)
	if d["east"] == true:
		_append_unique([
			tileMap.tile_set.get_pattern(PatternId.CROSS),
			tileMap.tile_set.get_pattern(PatternId.STRAIGHT_HORIZONTAL),
			tileMap.tile_set.get_pattern(PatternId.T_SOUTH),
			tileMap.tile_set.get_pattern(PatternId.T_NORTH),
			tileMap.tile_set.get_pattern(PatternId.T_EAST),
			tileMap.tile_set.get_pattern(PatternId.L_NORTH_EAST),
			tileMap.tile_set.get_pattern(PatternId.L_SOUTH_EAST),
			], openings)
	if d["west"] == true:
		_append_unique([
			tileMap.tile_set.get_pattern(PatternId.CROSS),
			tileMap.tile_set.get_pattern(PatternId.STRAIGHT_HORIZONTAL),
			tileMap.tile_set.get_pattern(PatternId.T_WEST),
			tileMap.tile_set.get_pattern(PatternId.T_SOUTH),
			tileMap.tile_set.get_pattern(PatternId.T_NORTH),
			tileMap.tile_set.get_pattern(PatternId.L_NORTH_WEST),
			tileMap.tile_set.get_pattern(PatternId.L_SOUTH_WEST),
			], openings)
	return openings.pick_random()
	
# Returns true if a pattern placed with its top-left corner at loc
# would fit entirely inside the allowed generation area.
#
# This checks the full pattern footprint, not just the top-left cell.	
func _in_range(loc: Vector2i) -> bool:
	return (
		loc.x >= 0
		and loc.y >= 0
		and loc.x + pattern_width - 1 < MAX_W_CELL
		and loc.y + pattern_height - 1 < MAX_H_CELL
	) 

# Finds which sides of the pattern currently at curr_pos are open.
#
# It checks the center edge tile on each side of the placed pattern.
# If that edge tile is an opening/path tile and within range, that
# direction is considered a valid expansion direction.
#
# Returns a dictionary mapping direction name -> tile position of the opening.
func _find_openings(_pattern: TileMapPattern) -> Dictionary[String,Vector2i]:
	# takes currpos we are at and the tile pattern there and finds the openings
	# to return 
	var dir: Dictionary[String, Vector2i] = {
		"north": Vector2i(curr_pos.x + ((pattern_width/2)), curr_pos.y),
		"south": Vector2i(curr_pos.x + ((pattern_width/2)), (curr_pos.y + pattern_height - 1 )),
		"west": Vector2i(curr_pos.x, (curr_pos.y + pattern_height /2)),
		"east": Vector2i((curr_pos.x + pattern_width - 1), (curr_pos.y + pattern_height/2)),
	}
 
	var openings: Dictionary[String, Vector2i] = {}
	for key in dir:
		if _is_walkable_cell(dir[key]) and _in_range(dir[key]):
			openings[key] = dir[key]
	return openings			
	



func _place_objects(spawn: Vector2i, boss: Vector2i, treasure: Vector2i) -> void:
	# map_to_local gives you the CENTER of the tile in local space
	# to_global converts it to world space
	door_sprite.global_position = tileMap.to_global(tileMap.map_to_local(spawn))
	boss_sprite.global_position = tileMap.to_global(tileMap.map_to_local(boss))
	treasure_sprite.global_position = tileMap.to_global(tileMap.map_to_local(treasure))
	

	

## Generates a map by expanding outward from the starting position.
##
## Process:
## 1. Start at (0, 0)
## 2. Place a pattern
## 3. Find openings on that pattern
## 4. Convert openings into neighboring top-left pattern positions
## 5. Add valid neighbors to the frontier
## 6. Repeat until the frontier is empty or max_tiles is reached
##
## width and height are measured in pattern slots, not raw tile cells.
func gen_map(width, height, max_tiles) -> void:
	tileMap.clear()
	visited.clear()
	
	_init_grid(width, height)
	
	for i in range(tileMap.tile_set.get_patterns_count()):
		print("Pattern ", i, ": ", tileMap.tile_set.get_pattern(i))
	
	# Number of patterns placed so far.
	var curr_amt_tiles = 0
	
	# Frontier holds top-left positions where a future pattern may be placed.
	var frontier: Array[Vector2i] = []
	frontier.append(Vector2i(0,0))
	
	while not frontier.is_empty() and curr_amt_tiles <= max_tiles:
		# Randomly choose the next frontier position.
		# Using pop_back() instead would make this more DFS-like.
		curr_pos = frontier.pop_at(randi_range(0, frontier.size()-1))
		# curr_pos = frontier.pop_back()
		
		_append_unique([curr_pos], visited)
		
		# Choose and place a pattern that fits the current surroundings.
		var pattern: TileMapPattern = choose_rand_pattern()
		tileMap.set_pattern(curr_pos, pattern)
		tileMap.update_internals()
		
		curr_amt_tiles+=1
		
		# Find all openings on the newly placed pattern.
		var openings:Dictionary = _find_openings(pattern)
		
		# Convert each opening direction into the top-left coordinate
		# of the neighboring pattern that could be placed there.
		var open_with_off: Array[Vector2i] =[]
		
		for key in openings: 
			if key == "north":
				open_with_off.append(curr_pos - Vector2i(0, pattern_height))
			if key == "south":
				open_with_off.append(curr_pos + Vector2i(0, pattern_height))
			if key == "east":
				open_with_off.append(curr_pos + Vector2i(pattern_width, 0))
			if key == "west":
				open_with_off.append(curr_pos - Vector2i(pattern_width, 0))
		
		# Add valid, unvisited, non-duplicate positions to the frontier.
		for pos in open_with_off:
			if not visited.has(pos) and not frontier.has(pos) and _in_range(pos):
				frontier.append(pos)
	
	var spawn: Vector2i = _find_spawn()
	var boss: Vector2i = _find_boss(spawn)
	var treasure: Vector2i = _find_treasure(spawn)
	# At the end of gen_map instead of calling directly
	call_deferred("_place_objects", spawn, boss, treasure)


func _find_spawn() -> Vector2i:
	var candidates: Array[Vector2i] = []
	
	# Check top edge (y == 0)
	for x in range(0, MAX_W_CELL):
		var pos = Vector2i(x, 0)
		if _is_walkable_cell(pos):
			candidates.append(pos)
	
	# Check left edge (x == 0)
	for y in range(0, MAX_H_CELL):
		var pos = Vector2i(0, y)
		if _is_walkable_cell(pos):
			candidates.append(pos)
	
	return candidates.pick_random()

func _find_treasure(spawn: Vector2i) -> Vector2i:
	var candidates: Array[Vector2i] = []
	var used_cells = tileMap.get_used_cells()

	for pos in used_cells:
		if _is_walkable_cell(pos) and pos != spawn:
			candidates.append(pos)

	return candidates.pick_random()

func _find_boss(spawn: Vector2i) -> Vector2i:
	var bfs_queue: Array[Vector2i] = [spawn]
	var bfs_visited: Dictionary = {}
	bfs_visited[spawn] = true
	var last: Vector2i = spawn

	var directions = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]

	while not bfs_queue.is_empty():
		var current = bfs_queue.pop_front()
		last = current
		for d in directions:
			var neighbor = current + d
			if not bfs_visited.has(neighbor) and _is_walkable_cell(neighbor):
				bfs_visited[neighbor] = true
				bfs_queue.append(neighbor)

	return last
 
