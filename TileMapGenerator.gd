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
@export var monster_count: int = 1
@export var nav_region: NavigationRegion2D

## Emitted when the map has finished generating.
## spawn_world_pos is the world-space position the player should start at.
signal map_generated(spawn_world_pos: Vector2i)

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

var curr_pos: Vector2i
var visited: Array = []

func _for_debug_gen() -> void:
	assert(tileMap.tile_set, "Tile set was not provided in the tilemap layer")
	gen_map(num_w_cell, num_h_cell, MAXTILES)

func _ready() -> void:
	assert(tileMap.tile_set, "Tile set was not provided in the tilemap layer")
	gen_map(num_w_cell, num_h_cell, MAXTILES)

func _init_grid(width: int, height: int) -> void:
	var x = tileMap.tile_set.tile_size.x
	var y = tileMap.tile_set.tile_size.y
	var _w_cells: int = floor(width * x)
	var _h_cells: int = floor(height * y)
	MAX_W_CELL = width * pattern_width
	MAX_H_CELL = height * pattern_height

func _append_unique(items: Array[Variant], arr: Array) -> void:
	for i in items:
		if not arr.has(i):
			arr.append(i)

func _is_walkable_cell(pos: Vector2i) -> bool:
	var tile_data := tileMap.get_cell_tile_data(pos)
	if tile_data == null:
		return false
	return tile_data.get_custom_data("walkable") == true

func choose_rand_pattern() -> TileMapPattern:
	var dir: Dictionary[String, Vector2i] = {
		"north": Vector2i(curr_pos.x + pattern_width / 2, curr_pos.y - 1),
		"south": Vector2i(curr_pos.x + pattern_width / 2, (curr_pos.y + pattern_height)),
		"west":  Vector2i(curr_pos.x - 1, (curr_pos.y + pattern_height / 2)),
		"east":  Vector2i((curr_pos.x + pattern_width), (curr_pos.y + pattern_height / 2)),
	}
	var d: Dictionary = {
		"north": false,
		"south": false,
		"east":  false,
		"west":  false,
	}
	for key in dir:
		print("Current ID of Tile: ", tileMap.get_cell_source_id(dir[key]))
		if _is_walkable_cell(dir[key]):
			d[key] = true

	if not d.values().has(true):
		var index = randi_range(0, tileMap.tile_set.get_patterns_count() - 1)
		return tileMap.tile_set.get_pattern(index)

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

func _in_range(loc: Vector2i) -> bool:
	return (
		loc.x >= 0
		and loc.y >= 0
		and loc.x + pattern_width - 1 < MAX_W_CELL
		and loc.y + pattern_height - 1 < MAX_H_CELL
	)

func _find_openings(_pattern: TileMapPattern) -> Dictionary[String, Vector2i]:
	var dir: Dictionary[String, Vector2i] = {
		"north": Vector2i(curr_pos.x + (pattern_width / 2), curr_pos.y),
		"south": Vector2i(curr_pos.x + (pattern_width / 2), (curr_pos.y + pattern_height - 1)),
		"west":  Vector2i(curr_pos.x, (curr_pos.y + pattern_height / 2)),
		"east":  Vector2i((curr_pos.x + pattern_width - 1), (curr_pos.y + pattern_height / 2)),
	}
	var openings: Dictionary[String, Vector2i] = {}
	for key in dir:
		if _is_walkable_cell(dir[key]) and _in_range(dir[key]):
			openings[key] = dir[key]
	return openings

func _place_objects(spawn: Vector2i, boss: Vector2i, treasure: Vector2i) -> void:
	door_sprite.global_position = tileMap.to_global(tileMap.map_to_local(spawn))
	boss_sprite.global_position = tileMap.to_global(tileMap.map_to_local(boss))
	treasure_sprite.global_position = tileMap.to_global(tileMap.map_to_local(treasure))

	var spawn_world: Vector2 = tileMap.to_global(tileMap.map_to_local(spawn))
	map_generated.emit(spawn_world)

	_bake_and_spawn.call_deferred(spawn, boss, treasure)

func _bake_and_spawn(spawn: Vector2i, boss: Vector2i, treasure: Vector2i) -> void:
	if nav_region:
		nav_region.bake_navigation_polygon()
	else:
		push_warning("nav_region not assigned!")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_spawn_monsters(spawn, boss, treasure)

func _spawn_monsters(spawn: Vector2i, boss: Vector2i, treasure: Vector2i) -> void:
	var used_cells = tileMap.get_used_cells()
	var forbidden = [spawn, boss, treasure]
	var candidates: Array[Vector2i] = []

	# First try to find walkable tiles within 15 tiles of spawn
	for pos in used_cells:
		if not _is_walkable_cell(pos):
			continue
		if pos.distance_to(spawn) > 15.0:
			continue
		var too_close := false
		for f in forbidden:
			if pos.distance_to(f) < 5.0:
				too_close = true
				break
		if not too_close:
			candidates.append(pos)

	# If nothing found nearby, fall back to anywhere on the map
	if candidates.is_empty():
		for pos in used_cells:
			if not _is_walkable_cell(pos):
				continue
			var too_close := false
			for f in forbidden:
				if pos.distance_to(f) < 5.0:
					too_close = true
					break
			if not too_close:
				candidates.append(pos)

	if candidates.is_empty():
		push_warning("No valid monster spawn positions found!")
		return

	candidates.shuffle()
	var to_spawn = min(monster_count, candidates.size())

	for i in range(to_spawn):
		var monster := CharacterBody2D.new()
		monster.collision_layer = 4
		monster.collision_mask = 1
		monster.z_index = 1
		
		# Set script first before adding any children
		monster.set_script(load("res://Monster.gd"))

		var nav := NavigationAgent2D.new()
		nav.name = "NavigationAgent2D"
		nav.avoidance_enabled = false
		monster.add_child(nav)

		var shape := CapsuleShape2D.new()
		shape.radius = 12.0
		shape.height = 28.0
		var col := CollisionShape2D.new()
		col.shape = shape
		monster.add_child(col)

		var sprite := Sprite2D.new()
		sprite.texture = load("res://sprites/Monster_Static.png")
		sprite.scale = Vector2(0.35, 0.35)
		monster.add_child(sprite)

		# Add to scene last
		get_parent().add_child(monster)
		monster.global_position = tileMap.to_global(tileMap.map_to_local(candidates[i]))
		monster.add_to_group("enemies")
		
		
func gen_map(width, height, max_tiles) -> void:
	tileMap.clear()
	visited.clear()

	_init_grid(width, height)

	for i in range(tileMap.tile_set.get_patterns_count()):
		print("Pattern ", i, ": ", tileMap.tile_set.get_pattern(i))

	var curr_amt_tiles = 0
	var frontier: Array[Vector2i] = []
	frontier.append(Vector2i(0, 0))

	while not frontier.is_empty() and curr_amt_tiles <= max_tiles:
		curr_pos = frontier.pop_at(randi_range(0, frontier.size() - 1))
		_append_unique([curr_pos], visited)

		var pattern: TileMapPattern = choose_rand_pattern()
		tileMap.set_pattern(curr_pos, pattern)
		tileMap.update_internals()
		curr_amt_tiles += 1

		var openings: Dictionary = _find_openings(pattern)
		var open_with_off: Array[Vector2i] = []

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
			if not visited.has(pos) and not frontier.has(pos) and _in_range(pos):
				frontier.append(pos)

	var spawn: Vector2i = _find_spawn()
	var boss: Vector2i = _find_boss(spawn)
	var treasure: Vector2i = _find_treasure(spawn)
	call_deferred("_place_objects", spawn, boss, treasure)

func _find_spawn() -> Vector2i:
	var candidates: Array[Vector2i] = []
	for x in range(0, MAX_W_CELL):
		var pos = Vector2i(x, 0)
		if _is_walkable_cell(pos):
			candidates.append(pos)
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
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not bfs_queue.is_empty():
		var current = bfs_queue.pop_front()
		last = current
		for d in directions:
			var neighbor = current + d
			if not bfs_visited.has(neighbor) and _is_walkable_cell(neighbor):
				bfs_visited[neighbor] = true
				bfs_queue.append(neighbor)
	return last
