# Manages the dungeon map grid with two layers:
#   base_data[row][col]    = room/corridor/wall tile (or null)
#   overlay_data[row][col] = encounter tile drawn on top (or null)
class_name MapGrid
extends Control

const CELL_SIZE: int = 48
const GRID_COLS: int = 24
const GRID_ROWS: int = 16

const BORDER_COLOR = Color(0.25, 0.22, 0.18, 1.0)
const EMPTY_COLOR = Color(0.08, 0.07, 0.06, 1.0)
const GRID_LINE_COLOR = Color(0.18, 0.16, 0.14, 0.8)
const HOVER_COLOR = Color(1.0, 1.0, 1.0, 0.15)
const FONT_SIZE: int = 11

var base_data: Array = []
var overlay_data: Array = []
var hovered_cell: Vector2i = Vector2i(-1, -1)
var selected_tile_data: DungeonTile = null
var is_dragging: bool = false

signal tile_placed(grid_pos: Vector2i, tile: DungeonTile)
signal tile_removed(grid_pos: Vector2i)

func _ready() -> void:
	_init_grid()
	custom_minimum_size = Vector2(GRID_COLS * CELL_SIZE, GRID_ROWS * CELL_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _init_grid() -> void:
	base_data.clear()
	overlay_data.clear()
	for r in GRID_ROWS:
		var base_row = []
		var overlay_row = []
		for c in GRID_COLS:
			base_row.append(null)
			overlay_row.append(null)
		base_data.append(base_row)
		overlay_data.append(overlay_row)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.05, 0.04, 1.0))

	for r in GRID_ROWS:
		for c in GRID_COLS:
			var cell_rect = Rect2(c * CELL_SIZE, r * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			var base: DungeonTile = base_data[r][c]
			var overlay: DungeonTile = overlay_data[r][c]

			if base != null:
				_draw_tile(cell_rect, base)
			else:
				draw_rect(cell_rect, EMPTY_COLOR)

			if overlay != null:
				_draw_overlay(cell_rect, overlay)

			draw_rect(cell_rect, GRID_LINE_COLOR, false, 1.0)

	if hovered_cell.x >= 0 and hovered_cell.y >= 0:
		var hover_rect = Rect2(
			hovered_cell.x * CELL_SIZE, hovered_cell.y * CELL_SIZE,
			CELL_SIZE, CELL_SIZE
		)
		draw_rect(hover_rect, HOVER_COLOR)
		if selected_tile_data != null and selected_tile_data.tile_type != DungeonTile.TileType.EMPTY:
			_draw_tile_ghost(hover_rect, selected_tile_data)

func _draw_tile(rect: Rect2, tile: DungeonTile) -> void:
	var T = DungeonTile.TileType
	match tile.tile_type:
		T.CORRIDOR_H, T.CORRIDOR_V, T.CORRIDOR_CROSS, \
		T.CORRIDOR_T_UP, T.CORRIDOR_T_DOWN, \
		T.CORRIDOR_T_LEFT, T.CORRIDOR_T_RIGHT, \
		T.CORNER_TL, T.CORNER_TR, T.CORNER_BL, T.CORNER_BR:
			_draw_corridor_tile(rect, tile)
		_:
			_draw_standard_tile(rect, tile)

func _draw_standard_tile(rect: Rect2, tile: DungeonTile) -> void:
	var bg_color = tile.color.darkened(0.3)
	bg_color.a = 0.9
	draw_rect(rect, bg_color)
	var inner = rect.grow(-3)
	draw_rect(inner, tile.color.darkened(0.1))
	if tile.symbol != "":
		var font = ThemeDB.fallback_font
		var font_size = FONT_SIZE + 4
		var text_size = font.get_string_size(tile.symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos = rect.get_center() - text_size * 0.5
		text_pos.y += text_size.y * 0.35
		draw_string(font, text_pos, tile.symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)
	draw_rect(rect, tile.color.lightened(0.2), false, 1.5)

func _draw_corridor_tile(rect: Rect2, tile: DungeonTile) -> void:
	var T = DungeonTile.TileType
	var floor_color = tile.color
	var wall_color  = tile.color.darkened(0.45)
	draw_rect(rect, wall_color)
	var cx = rect.position.x + rect.size.x * 0.5
	var cy = rect.position.y + rect.size.y * 0.5
	var hw = rect.size.x * 0.28
	var hh = rect.size.y * 0.28
	var open_up    = tile.tile_type in [T.CORRIDOR_V, T.CORRIDOR_CROSS,
					  T.CORRIDOR_T_UP, T.CORRIDOR_T_LEFT, T.CORRIDOR_T_RIGHT,
					  T.CORNER_TL, T.CORNER_TR]
	var open_down  = tile.tile_type in [T.CORRIDOR_V, T.CORRIDOR_CROSS,
					  T.CORRIDOR_T_DOWN, T.CORRIDOR_T_LEFT, T.CORRIDOR_T_RIGHT,
					  T.CORNER_BL, T.CORNER_BR]
	var open_left  = tile.tile_type in [T.CORRIDOR_H, T.CORRIDOR_CROSS,
					  T.CORRIDOR_T_UP, T.CORRIDOR_T_DOWN, T.CORRIDOR_T_LEFT,
					  T.CORNER_TL, T.CORNER_BL]
	var open_right = tile.tile_type in [T.CORRIDOR_H, T.CORRIDOR_CROSS,
					  T.CORRIDOR_T_UP, T.CORRIDOR_T_DOWN, T.CORRIDOR_T_RIGHT,
					  T.CORNER_TR, T.CORNER_BR]
	if open_up:
		draw_rect(Rect2(cx - hw, rect.position.y, hw * 2, cy - rect.position.y + hh), floor_color)
	if open_down:
		draw_rect(Rect2(cx - hw, cy - hh, hw * 2, rect.end.y - (cy - hh)), floor_color)
	if open_left:
		draw_rect(Rect2(rect.position.x, cy - hh, cx - rect.position.x + hw, hh * 2), floor_color)
	if open_right:
		draw_rect(Rect2(cx - hw, cy - hh, rect.end.x - (cx - hw), hh * 2), floor_color)
	draw_rect(Rect2(cx - hw, cy - hh, hw * 2, hh * 2), floor_color)
	draw_rect(rect, wall_color.lightened(0.15), false, 1.0)

func _draw_overlay(rect: Rect2, tile: DungeonTile) -> void:
	var badge_size = rect.size * 0.55
	var badge_rect = Rect2(rect.get_center() - badge_size * 0.5, badge_size)
	draw_circle(rect.get_center(), badge_size.x * 0.5, tile.color.darkened(0.3))
	draw_arc(rect.get_center(), badge_size.x * 0.5, 0, TAU, 24, tile.color.lightened(0.2), 1.5)
	if tile.symbol != "":
		var font = ThemeDB.fallback_font
		var font_size = FONT_SIZE + 2
		var text_size = font.get_string_size(tile.symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos = rect.get_center() - text_size * 0.5
		text_pos.y += text_size.y * 0.35
		draw_string(font, text_pos, tile.symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

func _draw_tile_ghost(rect: Rect2, tile: DungeonTile) -> void:
	if tile.is_overlay:
		var badge_size = rect.size * 0.55
		var ghost_col = tile.color
		ghost_col.a = 0.4
		draw_circle(rect.get_center(), badge_size.x * 0.5, ghost_col)
		if tile.symbol != "":
			var font = ThemeDB.fallback_font
			var font_size = FONT_SIZE + 2
			var text_size = font.get_string_size(tile.symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var text_pos = rect.get_center() - text_size * 0.5
			text_pos.y += text_size.y * 0.35
			var sym_color = Color.WHITE
			sym_color.a = 0.5
			draw_string(font, text_pos, tile.symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, sym_color)
		return

	var T = DungeonTile.TileType
	var is_corridor = tile.tile_type in [
		T.CORRIDOR_H, T.CORRIDOR_V, T.CORRIDOR_CROSS,
		T.CORRIDOR_T_UP, T.CORRIDOR_T_DOWN, T.CORRIDOR_T_LEFT, T.CORRIDOR_T_RIGHT,
		T.CORNER_TL, T.CORNER_TR, T.CORNER_BL, T.CORNER_BR]
	if is_corridor:
		modulate.a = 0.45
		_draw_corridor_tile(rect, tile)
		modulate.a = 1.0
	else:
		var ghost_color = tile.color
		ghost_color.a = 0.35
		draw_rect(rect.grow(-2), ghost_color)
		if tile.symbol != "":
			var font = ThemeDB.fallback_font
			var font_size = FONT_SIZE + 4
			var text_size = font.get_string_size(tile.symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var text_pos = rect.get_center() - text_size * 0.5
			text_pos.y += text_size.y * 0.35
			var sym_color = Color.WHITE
			sym_color.a = 0.5
			draw_string(font, text_pos, tile.symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, sym_color)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var cell = _get_cell_at(event.position)
		if cell != hovered_cell:
			hovered_cell = cell
			queue_redraw()
		if is_dragging and _is_valid_cell(cell):
			_place_or_erase(cell)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			if event.pressed:
				var cell = _get_cell_at(event.position)
				if _is_valid_cell(cell):
					_place_or_erase(cell)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var cell = _get_cell_at(event.position)
			if _is_valid_cell(cell):
				_erase_tile(cell)

func _place_or_erase(cell: Vector2i) -> void:
	if selected_tile_data == null or selected_tile_data.tile_type == DungeonTile.TileType.EMPTY:
		_erase_tile(cell)
	else:
		_place_tile(cell, selected_tile_data)

func _place_tile(cell: Vector2i, tile: DungeonTile) -> void:
	if tile.is_overlay:
		overlay_data[cell.y][cell.x] = tile
	else:
		base_data[cell.y][cell.x] = tile
	tile_placed.emit(cell, tile)
	queue_redraw()

func _erase_tile(cell: Vector2i) -> void:
	if overlay_data[cell.y][cell.x] != null:
		overlay_data[cell.y][cell.x] = null
		tile_removed.emit(cell)
		queue_redraw()
	elif base_data[cell.y][cell.x] != null:
		base_data[cell.y][cell.x] = null
		tile_removed.emit(cell)
		queue_redraw()

func _get_cell_at(pos: Vector2) -> Vector2i:
	return Vector2i(int(pos.x) / CELL_SIZE, int(pos.y) / CELL_SIZE)

func _is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_COLS and cell.y >= 0 and cell.y < GRID_ROWS

func set_selected_tile(tile: DungeonTile) -> void:
	selected_tile_data = tile
	queue_redraw()

func clear_map() -> void:
	_init_grid()
	queue_redraw()

func get_tile_count() -> int:
	var count = 0
	for r in GRID_ROWS:
		for c in GRID_COLS:
			if base_data[r][c] != null or overlay_data[r][c] != null:
				count += 1
	return count

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		hovered_cell = Vector2i(-1, -1)
		queue_redraw()
