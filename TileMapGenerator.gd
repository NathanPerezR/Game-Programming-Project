extends Node

@export var tileMap: TileMapLayer
@export var MAXTILES: int = 25

@export_category("Pattern Sizes")
@export var pattern_width: int = 9
@export var pattern_height: int = 9

var MAX_W_CELL: int
@export_range(1,10,1) var num_w_cell: int = 5
var MAX_H_CELL: int
@export_range(1,10,1) var num_h_cell: int = 5
var curr_pos:Vector2i
var visited: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(tileMap.tile_set, "Tile set was not provided in the tilemap layer")
	gen_map(num_w_cell, num_h_cell, MAXTILES)

# Sets up the meta map to all false
# meta map used to detrmine if a tile can go there.
func _init_grid(width: int, height: int) -> void:
	var x = tileMap.tile_set.tile_size.x
	var y = tileMap.tile_set.tile_size.y
	var w_cells : int = floor(width*x)
	var h_cells : int = floor(height*y)
	
	MAX_W_CELL = w_cells
	MAX_H_CELL = h_cells

func _my_add_to_array(items: Array[Variant], arr:Array) -> void:
	for i in items:
		if not arr.has(i):
			arr.append(i)
		
func choose_rand_pattern()-> TileMapPattern:
	## Looks around the curr position to find if there
	## are any openings around it and uses it to for a 
	## list of available patterns to choose randomly from
	
	
	# all positions are referenced by their top left corner
	# just in case patterns in the future arent 9X9
	# i should check the borders of the pattern for the brown
	# tiles
	var dir:Dictionary[String,Vector2i] = {
		"north":  Vector2i(curr_pos.x + pattern_width/2, curr_pos.y - 1),
		"south":  Vector2i(curr_pos.x + pattern_width/2, (curr_pos.y + pattern_height + 1)),
		"west" : Vector2i(curr_pos.x - 1, (curr_pos.y + pattern_height/2)),
		"east" : Vector2i((curr_pos.x + pattern_width + 1), (curr_pos.y + pattern_height/2)),		
		}
	
	var d: Dictionary = {"north": false, "south":false, "east":false, "west":false}
	for key in dir:
		print("Current ID of Tile: ", tileMap.get_cell_source_id(dir[key]))
		if tileMap.get_cell_source_id(dir[key]) == 0:
			d[key] = true	
	if not d.values().has(true):
		var index = randi_range(0, tileMap.tile_set.get_patterns_count() - 1)
		return tileMap.tile_set.get_pattern(index)
	# now that i know the openings
	var openings: Array = []
	if d["north"] == true:
		_my_add_to_array([
			tileMap.tile_set.get_pattern(0),
			tileMap.tile_set.get_pattern(1),
			tileMap.tile_set.get_pattern(2),
			tileMap.tile_set.get_pattern(4),
			tileMap.tile_set.get_pattern(5),
			tileMap.tile_set.get_pattern(9),
			tileMap.tile_set.get_pattern(10),
			], openings)
	if d["south"] == true:
		_my_add_to_array([
			tileMap.tile_set.get_pattern(0),
			tileMap.tile_set.get_pattern(2),
			tileMap.tile_set.get_pattern(6),
			tileMap.tile_set.get_pattern(7),
			tileMap.tile_set.get_pattern(8),
			tileMap.tile_set.get_pattern(9),
			tileMap.tile_set.get_pattern(10),
			], openings)
	if d["east"] == true:
		_my_add_to_array([
			tileMap.tile_set.get_pattern(0),
			tileMap.tile_set.get_pattern(1),
			tileMap.tile_set.get_pattern(3),
			tileMap.tile_set.get_pattern(5),
			tileMap.tile_set.get_pattern(6),
			tileMap.tile_set.get_pattern(8),
			tileMap.tile_set.get_pattern(10),
			], openings)
	if d["west"] == true:
		_my_add_to_array([
			tileMap.tile_set.get_pattern(0),
			tileMap.tile_set.get_pattern(1),
			tileMap.tile_set.get_pattern(3),
			tileMap.tile_set.get_pattern(4),
			tileMap.tile_set.get_pattern(7),
			tileMap.tile_set.get_pattern(8),
			tileMap.tile_set.get_pattern(9),
			], openings)
	return openings.pick_random()
	
func _in_range(loc: Vector2i) -> bool:
	if loc.x >= 0 and loc.x <= MAX_W_CELL and loc.y >= 0 and loc.y <= MAX_H_CELL:
		return true
	return true 

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
		if tileMap.get_cell_source_id(dir[key]) == 0 and _in_range(dir[key]):
			openings[key] = dir[key]
	return openings			
	

func gen_map(width, height, max_tiles) -> void:

	# starts at origin with any tile, find the openings the tile
	# has, from those openings you would know where you can go
	# in the next possible places to go, place random patterns that
	# fit there, keep repeating until either there is no place to go
	# that fits the pattern, or fills the screen or you have hit 
	# max tiles 

	_init_grid(width, height)
	# we know we are going to start at the arrays 00
	# pick a random tile to go there
	# find that tiles opening
	# use those openings to determine directions to go
	# whenever tile is to be place, check around itself to 
	# see any other placed tiles and use that to determine 
	# what tiles can be placed at that section
	var curr_amt_tiles = 0
	var frontier: Array[Vector2i] = []
	frontier.append(Vector2i(0,0))
	
	while not frontier.is_empty() and curr_amt_tiles <= max_tiles:
		curr_pos = frontier.pop_back()	
		_my_add_to_array([curr_pos], visited)
		
		var pattern: TileMapPattern = choose_rand_pattern()
		tileMap.set_pattern(curr_pos, pattern)
		tileMap.update_internals()
		# find openings the pattern has and add those potential
		# positions to the frontier and make sure its not already
		# in the frontier and that the meta map doesnt already
		# have that spot checked
		
		curr_amt_tiles+=1
		
		var openings:Dictionary = _find_openings(pattern)
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
		
		for pos in open_with_off:
			if not visited.has(pos) and not frontier.has(pos):
				frontier.append(pos)
		
	
	


 
