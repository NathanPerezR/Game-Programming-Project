extends CanvasLayer

# ── Node references ───────────────────────────────────────────────────────────
var score_panel:      Control
var menu_panel:       Control
var score_icon_btn:   TextureButton
var menu_icon_btn:    TextureButton

var label_total:    Label
var label_exact:    Label
var label_near:     Label
var label_cluster:  Label
var label_wrong:    Label
var label_missing:  Label
var label_grade:    Label

var _map_visible:        bool    = true
var _menu_btn_position:  Vector2 = Vector2.ZERO


# ── Ready ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_score_panel()

# ── Score panel ───────────────────────────────────────────────────────────────
func _build_score_panel() -> void:
	score_panel = Control.new()
	score_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	score_panel.visible = false
	add_child(score_panel)

	var backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.55) # 55% opacity
	backdrop.gui_input.connect(_on_backdrop_input)
	score_panel.add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	score_panel.add_child(center)

	var panel_root = Control.new()
	panel_root.custom_minimum_size = Vector2(480, 380)
	center.add_child(panel_root)

	var bg = TextureRect.new()
	bg.texture      = load("res://sprites/Progress_Menu_PopUp.png")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	panel_root.add_child(bg)

	var content = VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 6)
	content.offset_left   =  28
	content.offset_right  = -28
	content.offset_top    =  28
	content.offset_bottom = -28
	panel_root.add_child(content)

	var title = _make_label("SCORE SUMMARY", 18, Color(0.10, 0.22, 0.14), true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	content.add_child(_make_divider())

	label_grade = _make_label("", 32, Color(1, 1, 1), true)
	label_grade.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(label_grade)

	label_total   = _make_label("", 13, Color(0.10, 0.22, 0.14))
	label_exact   = _make_label("", 12, Color(0.12, 0.25, 0.16)) # green — positive
	label_near    = _make_label("", 12, Color(0.12, 0.25, 0.16)) # green — positive
	label_cluster = _make_label("", 12, Color(0.12, 0.25, 0.16)) # green — positive
	label_wrong   = _make_label("", 12, Color(0.22, 0.10, 0.10)) # red — negative
	label_missing = _make_label("", 12, Color(0.22, 0.10, 0.10)) # red — negative

	for lbl in [label_total, label_exact, label_near, label_cluster, label_wrong, label_missing]:
		content.add_child(lbl)

	content.add_child(_make_divider())

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(btn_row)

	var restart_btn = _make_action_button("Play Again", Color(0.14, 0.38, 0.22)) # green
	var exit_btn    = _make_action_button("Exit",       Color(0.38, 0.14, 0.14)) # red
	var close_btn   = _make_action_button("Close",      Color(0.16, 0.24, 0.20)) # dark green

	btn_row.add_child(restart_btn)
	btn_row.add_child(exit_btn)
	btn_row.add_child(close_btn)

	restart_btn.pressed.connect(_on_restart_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	close_btn.pressed.connect(_on_close_pressed)


# ── UI helpers ────────────────────────────────────────────────────────────────
func _make_label(text: String, size: int, color: Color, bold: bool = false) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	if bold:
		lbl.add_theme_font_size_override("font_size", size)
	return lbl


func _make_divider() -> HSeparator:
	var sep   = HSeparator.new()
	var style = StyleBoxFlat.new()
	style.bg_color              = Color(0.10, 0.28, 0.18, 0.5)
	style.content_margin_top    = 2
	style.content_margin_bottom = 2
	sep.add_theme_stylebox_override("separator", style)
	return sep


func _make_action_button(label: String, color: Color) -> Button:
	var btn    = Button.new()
	btn.text   = label
	btn.custom_minimum_size = Vector2(120, 36)

	var normal = StyleBoxFlat.new()
	normal.bg_color     = color.darkened(0.2)
	normal.border_color = color.lightened(0.2)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", normal)

	var hover      = normal.duplicate()
	hover.bg_color = color
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", Color(0.92, 0.96, 0.92))
	btn.add_theme_font_size_override("font_size", 13)
	return btn


# ── Public API ────────────────────────────────────────────────────────────────
func show_score_result(result: Object) -> void:
	var grade     := result.get_grade() as String
	var grade_col := _grade_color(grade)

	label_grade.text = grade
	label_grade.add_theme_color_override("font_color", grade_col)

	label_total.text   = "Total:    %d / %d   (%.0f%%)"                    % [result.total_score,    result.max_score,      result.accuracy * 100.0]
	label_exact.text   = "Exact:    %d tiles  ->  +%d pts"                 % [result.correct_count,  result.base_points]
	label_near.text    = "Near:     %d tiles  ->  +%d pts"                 % [result.near_miss_count, result.near_miss_points]
	label_cluster.text = "Cluster:  %d regions ->  +%d pts  (largest: %d)" % [result.cluster_count,  result.cluster_bonus,  result.largest_cluster]
	label_wrong.text   = "Wrong:    %d tiles"                               % result.wrong_count
	label_missing.text = "Missing:  %d tiles"                               % result.missing_count

	score_panel.visible = true


func _grade_color(grade: String) -> Color:
	match grade:
		"S":  return Color(1.00, 0.85, 0.20) # gold
		"A":  return Color(0.40, 0.90, 0.45) # green
		"B":  return Color(0.35, 0.70, 1.00) # blue
		"C":  return Color(0.80, 0.80, 0.80) # grey
		"D":  return Color(0.90, 0.55, 0.20) # orange
		_:    return Color(0.85, 0.25, 0.25) # red


# ── Button callbacks ──────────────────────────────────────────────────────────
func _on_score_icon_pressed() -> void:
	menu_panel.visible  = false
	score_panel.visible = !score_panel.visible

func _on_close_pressed() -> void:
	score_panel.visible = false


func _on_restart_pressed() -> void:
	# currently set to main, need to set to testScene
	get_tree().change_scene_to_file("uid://lvq3qltn2day")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		score_panel.visible = false

func _on_menu_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		menu_panel.visible = false
