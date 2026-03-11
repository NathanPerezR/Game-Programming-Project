# The side-panel UI where players select dungeon elements to place.
# Organizes tiles by category with visual buttons.

class_name TilePalette
extends PanelContainer

const BUTTON_SIZE = Vector2(56, 56)
const TILE_FONT_SIZE: int = 18

var tile_definitions: Array[DungeonTile] = []
var selected_button: Button = null
var selected_tile: DungeonTile = null

signal tile_selected(tile: DungeonTile)

func _ready() -> void:
	_build_tile_definitions()
	_build_ui()

func _build_tile_definitions() -> void:
	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.ROOM,       "Room",         Color(0.35, 0.30, 0.22), "Room", "Rooms"))
	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.ENTRANCE,   "Entrance",     Color(0.20, 0.55, 0.30), "Enter", "Rooms"))

	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.CORRIDOR_H,     "Corridor H",   Color(0.28, 0.25, 0.20), "━",  "Corridors"))
	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.CORRIDOR_V,     "Corridor V",   Color(0.28, 0.25, 0.20), "┃",  "Corridors"))
	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.CORRIDOR_CROSS, "Cross",        Color(0.28, 0.25, 0.20), "╋",  "Corridors"))
	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.CORRIDOR_T_UP,    "T-Up",       Color(0.28, 0.25, 0.20), "┻",  "Corridors"))
	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.CORRIDOR_T_DOWN,  "T-Down",     Color(0.28, 0.25, 0.20), "┳",  "Corridors"))
	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.CORRIDOR_T_LEFT,  "T-Left",     Color(0.28, 0.25, 0.20), "┫",  "Corridors"))
	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.CORRIDOR_T_RIGHT, "T-Right",    Color(0.28, 0.25, 0.20), "┣",  "Corridors"))
	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.CORNER_TL,  "Corner TL",    Color(0.28, 0.25, 0.20), "┛",  "Corridors"))
	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.CORNER_TR,  "Corner TR",    Color(0.28, 0.25, 0.20), "┗",  "Corridors"))
	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.CORNER_BL,  "Corner BL",    Color(0.28, 0.25, 0.20), "┓",  "Corridors"))
	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.CORNER_BR,  "Corner BR",    Color(0.28, 0.25, 0.20), "┏",  "Corridors"))

	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.MONSTER,    "Monster",      Color(0.65, 0.28, 0.10), "M",  "Encounters", true))
	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.BOSS,       "Boss",         Color(0.75, 0.10, 0.10), "Boss", "Encounters", true))
	tile_definitions.append(DungeonTile.create(DungeonTile.TileType.TREASURE,   "Treasure",     Color(0.75, 0.65, 0.10), "★",  "Encounters", true))

func _build_ui() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.09, 0.08, 0.97)
	style.border_color = Color(0.35, 0.30, 0.22, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	var categories: Dictionary = {}
	for tile in tile_definitions:
		if tile.category not in categories:
			categories[tile.category] = []
		categories[tile.category].append(tile)

	for category_name in categories:
		var cat_label = Label.new()
		cat_label.text = category_name
		cat_label.add_theme_font_size_override("font_size", 11)
		cat_label.add_theme_color_override("font_color", Color(0.65, 0.60, 0.45))
		vbox.add_child(cat_label)

		var grid = GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		vbox.add_child(grid)

		for tile in categories[category_name]:
			var btn = _make_tile_button(tile)
			grid.add_child(btn)

		var cat_sep = HSeparator.new()
		vbox.add_child(cat_sep)

func _make_tile_button(tile: DungeonTile) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = BUTTON_SIZE
	btn.toggle_mode = true
	btn.tooltip_text = tile.display_name

	var vb = VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	btn.add_child(vb)

	var sym_label = Label.new()
	sym_label.text = tile.symbol
	sym_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sym_label.add_theme_font_size_override("font_size", TILE_FONT_SIZE)
	sym_label.add_theme_color_override("font_color", Color.WHITE)
	sym_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(sym_label)

	var name_label = Label.new()
	name_label.text = tile.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.add_theme_color_override("font_color", Color(0.85, 0.80, 0.65))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.clip_text = true
	vb.add_child(name_label)

	var normal_style = _make_button_style(tile.color.darkened(0.5))
	var hover_style = _make_button_style(tile.color.darkened(0.2))
	var pressed_style = _make_button_style(tile.color.lightened(0.1))
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("focus", normal_style)

	btn.pressed.connect(_on_tile_button_pressed.bind(btn, tile))
	return btn

func _make_button_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

func _on_tile_button_pressed(btn: Button, tile: DungeonTile) -> void:
	if selected_button != null and selected_button != btn:
		selected_button.button_pressed = false

	if btn.button_pressed:
		selected_button = btn
		selected_tile = tile
	else:
		selected_button = null
		selected_tile = null

	tile_selected.emit(selected_tile)
