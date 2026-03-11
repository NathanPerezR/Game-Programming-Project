## Main controller that wires together the map grid, palette, toolbar, and status bar.

extends Node

var map_grid: MapGrid
var tile_palette: TilePalette
var status_bar: StatusBar
var toolbar: VBoxContainer

func _ready() -> void:
	_build_scene()

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
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	style.bg_color = Color(0.09, 0.08, 0.07, 1.0)
	style.border_color = Color(0.30, 0.26, 0.20)
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
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(title)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var clear_btn = _make_toolbar_button("Clear Map", Color(0.55, 0.20, 0.20))
	clear_btn.pressed.connect(_on_clear_pressed)
	hbox.add_child(clear_btn)

	#TODO: Delete this and the other demo logic lol
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

#TODO: Delete this and the other demo logic lol
func _on_demo_pressed() -> void:
	_load_example_map()

#TODO: Delete this and the other demo logic lol
func _load_example_map() -> void:
	map_grid.clear_map()

	var palette_tiles: Dictionary = {}
	for t in tile_palette.tile_definitions:
		palette_tiles[t.tile_type] = t

	var T = DungeonTile.TileType
	var layout = [
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
