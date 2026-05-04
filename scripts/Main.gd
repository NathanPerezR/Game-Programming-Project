extends Node

var map_grid: MapGrid
var tile_palette: TilePalette
var status_bar: StatusBar
var toolbar: VBoxContainer

var T = DungeonTile.TileType

var TILE_POINTS: Dictionary = {
	T.ROOM:             10,
	T.ENTRANCE:         20,
	T.CORRIDOR_H:        5,
	T.CORRIDOR_V:        5,
	T.CORRIDOR_CROSS:   10,
	T.CORRIDOR_T_UP:     8,
	T.CORRIDOR_T_DOWN:   8,
	T.CORRIDOR_T_LEFT:   8,
	T.CORRIDOR_T_RIGHT:  8,
	T.CORNER_TL:         6,
	T.CORNER_TR:         6,
	T.CORNER_BL:         6,
	T.CORNER_BR:         6,
	T.TREASURE:         25,
	T.MONSTER:          15,
	T.BOSS:             30,
}

const NEAR_MISS_RATIO:        float = 0.5
const CLUSTER_BONUS_PER_TILE: int   = 3
const MIN_CLUSTER_SIZE:       int   = 3
const DIRS: Array = [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]

var ANSWER_LAYOUT: Array = [
		[8, 2, T.ENTRANCE], [8, 3, T.ROOM], [8, 4, T.ROOM],
		[9, 2, T.ROOM],     [9, 3, T.ROOM], [9, 4, T.ROOM],
		[10, 2, T.ROOM],    [10, 3, T.ROOM],[10, 4, T.ROOM],

		[9, 6, T.CORRIDOR_H], [9, 7, T.CORRIDOR_H], [9, 8, T.CORRIDOR_H],
		[9, 9, T.CORRIDOR_H], [9, 10, T.CORRIDOR_H],

		[9, 11, T.CORRIDOR_T_UP],
		[6, 11, T.CORRIDOR_V], [7, 11, T.CORRIDOR_V], [8, 11, T.CORRIDOR_V],
		[5, 9, T.ROOM],  [5, 10, T.ROOM], [5, 11, T.ROOM],
		[5, 12, T.ROOM], [6, 9, T.ROOM],  [6, 10, T.ROOM],

		[9, 12, T.CORRIDOR_H], [9, 13, T.CORRIDOR_H],
		[9, 14, T.CORRIDOR_H], [9, 15, T.CORRIDOR_H],

		[9, 16, T.CORRIDOR_CROSS],

		[10, 16, T.CORRIDOR_V], [11, 16, T.CORRIDOR_V], [12, 16, T.CORRIDOR_V],
		[13, 14, T.ROOM], [13, 15, T.ROOM], [13, 16, T.ROOM],
		[13, 17, T.ROOM], [14, 15, T.TREASURE], [14, 16, T.ROOM],

		[9, 17, T.CORRIDOR_H], [9, 18, T.CORRIDOR_H], [9, 19, T.CORRIDOR_H],

		[7, 19, T.ROOM],  [7, 20, T.ROOM],  [7, 21, T.ROOM],
		[8, 19, T.ROOM],  [8, 20, T.ROOM],  [8, 21, T.ROOM],
		[9, 21, T.ROOM],  [10, 19, T.ROOM], [10, 20, T.ROOM], [10, 21, T.ROOM],
		[8, 20, T.BOSS],

		[9, 8, T.MONSTER], [9, 14, T.MONSTER],
]

# Built in _ready once T is valid
var _answer_map: Dictionary = {}
var _max_score:  int = 0

func _ready() -> void:
	_build_answer_map()
	_build_scene()

func _build_answer_map() -> void:
	for entry in ANSWER_LAYOUT:
		var pos  := Vector2i(entry[0], entry[1])
		var type : DungeonTile.TileType = (entry[2])
		_answer_map[pos] = type
		_max_score += TILE_POINTS.get(type, 0)

func _build_scene() -> void:
	var root_vbox = VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	toolbar = _build_toolbar()
	root_vbox.add_child(toolbar)

	var hbox = HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 0)
	root_vbox.add_child(hbox)

	tile_palette = TilePalette.new()
	tile_palette.custom_minimum_size = Vector2(190, 0)
	tile_palette.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(tile_palette)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var scroll_style = StyleBoxFlat.new()
	scroll_style.bg_color = Color(0.05, 0.04, 0.03)
	scroll.add_theme_stylebox_override("panel", scroll_style)
	hbox.add_child(scroll)

	map_grid = MapGrid.new()
	scroll.add_child(map_grid)

	status_bar = StatusBar.new()
	status_bar.custom_minimum_size = Vector2(0, 28)
	root_vbox.add_child(status_bar)

	tile_palette.tile_selected.connect(_on_tile_selected)
	map_grid.tile_placed.connect(_on_tile_placed)
	map_grid.tile_removed.connect(_on_tile_removed)

func _build_toolbar() -> VBoxContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 42)

	var style = StyleBoxFlat.new()
	style.bg_color        = Color(0.09, 0.08, 0.07, 1.0)
	style.border_color    = Color(0.30, 0.26, 0.20)
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	var wrapper = VBoxContainer.new()
	wrapper.add_child(panel)

	var title = Label.new()
	title.text = "DUNGEON MAPPER"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.90, 0.78, 0.45))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(title)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var clear_btn = _make_toolbar_button("Clear Map", Color(0.55, 0.20, 0.20))
	clear_btn.pressed.connect(_on_clear_pressed)
	hbox.add_child(clear_btn)

	var score_btn = _make_toolbar_button("Score Map", Color(0.20, 0.35, 0.55))
	score_btn.pressed.connect(_on_score_pressed)
	hbox.add_child(score_btn)

	var demo_btn = _make_toolbar_button("Load Example", Color(0.20, 0.35, 0.55))
	demo_btn.pressed.connect(_on_demo_pressed)
	hbox.add_child(demo_btn)

	var padding = Control.new()
	padding.custom_minimum_size = Vector2(8, 0)
	hbox.add_child(padding)

	return wrapper

func _make_toolbar_button(label: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(140, 30)

	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.3)
	style.border_color = color
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = color.darkened(0.1)
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 12)
	return btn

func _on_tile_selected(tile: DungeonTile) -> void:
	map_grid.set_selected_tile(tile)
	status_bar.update_selected(tile)

func _on_tile_placed(_pos: Vector2i, _tile: DungeonTile) -> void:
	status_bar.update_count(map_grid.get_tile_count())

func _on_tile_removed(_pos: Vector2i) -> void:
	status_bar.update_count(map_grid.get_tile_count())

func _on_clear_pressed() -> void:
	map_grid.clear_map()
	status_bar.update_count(0)

func _on_score_pressed() -> void:
	var player_map := _build_player_map()
	var result     := score(player_map)
	result.print_summary()
	status_bar.show_score(result)

func _build_player_map() -> Dictionary:
	var player_map: Dictionary = {}
	var rows := map_grid.base_data.size()
	for r in rows:
		var cols := (map_grid.base_data[r] as Array).size()
		for c in cols:
			var pos   := Vector2i(r, c)
			var base  : DungeonTile = map_grid.base_data[r][c]
			var over  : DungeonTile = map_grid.overlay_data[r][c]
			if over != null and over.tile_type != T.EMPTY:
				player_map[pos] = over.tile_type
			elif base != null and base.tile_type != T.EMPTY:
				player_map[pos] = base.tile_type
	return player_map

func _on_demo_pressed() -> void:
	_load_example_map()

func _load_example_map() -> void:
	map_grid.clear_map()

	var palette_tiles: Dictionary = {}
	for t in tile_palette.tile_definitions:
		palette_tiles[t.tile_type] = t

	var layout = ANSWER_LAYOUT

	for entry in layout:
		var row = entry[0]
		var col = entry[1]
		var type = entry[2]
		if type in palette_tiles:
			var tile = palette_tiles[type]
			if tile.is_overlay:
				map_grid.overlay_data[row][col] = tile
			else:
				map_grid.base_data[row][col] = tile

	map_grid.queue_redraw()
	status_bar.update_count(map_grid.get_tile_count())

# Scoring
func score(player_map: Dictionary) -> ScoreResult:
	var result          := ScoreResult.new()
	result.max_score     = _max_score

	var correct_tiles:   Array[Vector2i] = []
	var near_miss_tiles: Array[Vector2i] = []

	for pos: Vector2i in _answer_map:
		var expected: int = _answer_map[pos]
		var placed:   int = player_map.get(pos, T.EMPTY)

		if placed == expected:
			correct_tiles.append(pos)
			result.base_points  += TILE_POINTS.get(expected, 0)
			result.correct_count += 1
		else:
			var found_near := false
			for d: Vector2i in DIRS:
				var neighbour := pos + d
				if player_map.get(neighbour, T.EMPTY) == expected \
				   and not _answer_map.has(neighbour):
					found_near = true
					break
			if found_near:
				near_miss_tiles.append(pos)
				result.near_miss_points += int(TILE_POINTS.get(expected, 0) * NEAR_MISS_RATIO)
				result.near_miss_count  += 1
			else:
				result.missing_count += 1

	for pos: Vector2i in player_map:
		var placed: int = player_map[pos]
		if placed == T.EMPTY:
			continue
		if player_map.get(pos, T.EMPTY) != _answer_map.get(pos, T.EMPTY):
			var is_near_offset := false
			for d: Vector2i in DIRS:
				var neighbour := pos + d
				if _answer_map.get(neighbour, T.EMPTY) == placed \
				   and near_miss_tiles.has(neighbour):
					is_near_offset = true
					break
			if not is_near_offset:
				result.wrong_count += 1

	# union-find cluster bonus
	var uf := _UnionFind.new()
	for pos: Vector2i in correct_tiles:
		uf.make(pos)
	for pos: Vector2i in correct_tiles:
		for d: Vector2i in DIRS:
			if correct_tiles.has(pos + d):
				uf.union(pos, pos + d)

	var cluster_sizes: Dictionary = {}
	for pos: Vector2i in correct_tiles:
		var root := uf.find(pos)
		cluster_sizes[root] = cluster_sizes.get(root, 0) + 1

	for root in cluster_sizes:
		var sz: int = cluster_sizes[root]
		if sz >= MIN_CLUSTER_SIZE:
			result.cluster_bonus    += sz * CLUSTER_BONUS_PER_TILE
			result.cluster_count    += 1
			result.largest_cluster   = max(result.largest_cluster, sz)

	result.total_score = mini(
    result.base_points + result.near_miss_points + result.cluster_bonus,
    _max_score
	) # i am just clamping the value - jank
	result.accuracy    = float(result.total_score) / float(_max_score) if _max_score > 0 else 0.0
	return result

func get_perfect_map() -> Dictionary:
	return _answer_map.duplicate()

func get_answer(pos: Vector2i) -> DungeonTile.TileType:
	return _answer_map.get(pos, T.EMPTY)

func get_max_base_score() -> int:
	return _max_score

class ScoreResult:
	var total_score:      int   = 0
	var max_score:        int   = 0
	var accuracy:         float = 0.0

	var base_points:      int   = 0
	var near_miss_points: int   = 0
	var cluster_bonus:    int   = 0

	var correct_count:    int   = 0
	var near_miss_count:  int   = 0
	var wrong_count:      int   = 0
	var missing_count:    int   = 0
	var cluster_count:    int   = 0
	var largest_cluster:  int   = 0

	func get_grade() -> String:
		if   accuracy >= 0.95: return "S"
		elif accuracy >= 0.80: return "A"
		elif accuracy >= 0.65: return "B"
		elif accuracy >= 0.50: return "C"
		elif accuracy >= 0.30: return "D"
		else:                  return "F"

	func to_dict() -> Dictionary:
		return {
			"total_score":      total_score,
			"max_score":        max_score,
			"accuracy":         accuracy,
			"grade":            get_grade(),
			"base_points":      base_points,
			"near_miss_points": near_miss_points,
			"cluster_bonus":    cluster_bonus,
			"correct_count":    correct_count,
			"near_miss_count":  near_miss_count,
			"wrong_count":      wrong_count,
			"missing_count":    missing_count,
			"cluster_count":    cluster_count,
			"largest_cluster":  largest_cluster,
		}

	# debug printing
	func print_summary() -> void:
		print("=== Score Summary ===")
		print("  Total  : %d / %d  (%.0f%%)  Grade: %s" % [total_score, max_score, accuracy * 100.0, get_grade()])
		print("  Exact  : %d tiles  → +%d pts" % [correct_count,   base_points])
		print("  Near   : %d tiles  → +%d pts" % [near_miss_count, near_miss_points])
		print("  Cluster: %d regions → +%d pts  (largest: %d tiles)" % [cluster_count, cluster_bonus, largest_cluster])
		print("  Wrong  : %d tiles"  % wrong_count)
		print("  Missing: %d tiles"  % missing_count)
		print("====================")

# union find
class _UnionFind:
	var _parent: Dictionary = {}
	var _rank:   Dictionary = {}

	func make(x: Vector2i) -> void:
		if not _parent.has(x):
			_parent[x] = x
			_rank[x]   = 0

	func find(x: Vector2i) -> Vector2i:
		if not _parent.has(x):
			make(x)
		if _parent[x] != x:
			_parent[x] = find(_parent[x])
		return _parent[x]

	func union(a: Vector2i, b: Vector2i) -> void:
		var ra := find(a)
		var rb := find(b)
		if ra == rb:
			return
		if _rank.get(ra, 0) < _rank.get(rb, 0):
			var tmp := ra; ra = rb; rb = tmp
		_parent[rb] = ra
		if _rank.get(ra, 0) == _rank.get(rb, 0):
			_rank[ra] = _rank.get(ra, 0) + 1
