# Displays current selected tile, tile count, and other info.

class_name StatusBar
extends PanelContainer

var selected_label: Label
var count_label: Label
var hint_label: Label

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:

	_set_panel_style()

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	add_child(hbox)

	hbox.add_child(_create_divider())
	selected_label = _create_label("Selected: None", 12, Color(0.75, 0.72, 0.60))
	hbox.add_child(selected_label)
	hbox.add_child(_create_divider())

	count_label = _create_label("Tiles placed: 0", 12, Color(0.60, 0.75, 0.60))
	hbox.add_child(count_label)
	hbox.add_child(_create_divider())

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	hint_label = _create_label("LMB: Place  |  RMB: Erase  |  Drag: Paint  ", 11, Color(0.45, 0.45, 0.45))
	hbox.add_child(hint_label)

func _set_panel_style() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.06, 0.95)
	style.border_color = Color(0.25, 0.22, 0.18)
	style.border_width_top = 2
	add_theme_stylebox_override("panel", style)


func _create_label(text: String, font_size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _create_divider() -> Label:
	var divider = Label.new()
	divider.text = "│"
	divider.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	return divider


func update_selected(tile: DungeonTile) -> void:
	if tile == null or tile.tile_type == DungeonTile.TileType.EMPTY:
		selected_label.text = "Selected: Eraser"
		selected_label.add_theme_color_override("font_color", Color(0.75, 0.45, 0.35))
	else:
		selected_label.text = "Selected: %s %s" % [tile.symbol, tile.display_name]
		selected_label.add_theme_color_override("font_color", tile.color.lightened(0.3))


func update_count(count: int) -> void:
	count_label.text = "Tiles placed: %d" % count
