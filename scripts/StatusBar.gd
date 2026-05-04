# Displays current selected tile, tile count, and other info.

class_name StatusBar
extends PanelContainer

var selected_label: Label
var count_label: Label
var hint_label: Label
var score_label: Label

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
	score_label = _create_label("", 12, Color(0.75, 0.72, 0.60))
	score_label.visible = false
	hbox.add_child(score_label)

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


func show_score(result: Object) -> void: # yea object is actually a score result but im not fixing types rn, sorry
	var grade        := result.get_grade() as String # awful 
	var grade_color  := _grade_color(grade)
	score_label.text = "Score: %d / %d  |  Grade: %s  |  Clusters: %d" % [
		result.total_score, result.max_score, grade, result.cluster_count
	]
	score_label.add_theme_color_override("font_color", grade_color)
	score_label.visible = true

func _grade_color(grade: String) -> Color:
	match grade:
		"S":  return Color(1.00, 0.85, 0.20)   # gold
		"A":  return Color(0.40, 0.90, 0.45)   # green
		"B":  return Color(0.35, 0.70, 1.00)   # blue
		"C":  return Color(0.80, 0.80, 0.80)   # grey
		"D":  return Color(0.90, 0.55, 0.20)   # orange
		_:    return Color(0.85, 0.25, 0.25)   # red  (F)
