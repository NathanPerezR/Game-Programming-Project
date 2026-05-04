extends CanvasLayer
class_name HealthUI

# ─────────────────────────────────────────────
#  EXPORTS — set in the Inspector
# ─────────────────────────────────────────────

## Drag your HealthIcon.png here as a Texture2D.
@export var heart_texture: Texture2D

## Drag an empty / dimmed version of the icon here for empty heart slots.
## If you only have one PNG, leave this blank — empty slots just won't show.
@export var heart_empty_texture: Texture2D

## The Player node. Drag it here in the Inspector.
@export var player: Player

## Size of each heart icon in pixels on screen.
@export var heart_size: Vector2 = Vector2(24, 24)

## Gap between hearts in pixels.
@export var heart_padding: float = 4.0

## Top-left starting position of the first heart.
@export var origin: Vector2 = Vector2(12, 12)

# ─────────────────────────────────────────────
#  INTERNAL
# ─────────────────────────────────────────────

## All the TextureRect nodes, one per heart slot.
var _hearts: Array[TextureRect] = []

## Container node that holds all heart rects.
var _container: Control

# ─────────────────────────────────────────────
#  READY
# ─────────────────────────────────────────────
func _ready() -> void:
	# Build a plain Control to parent the heart rects.
	_container = Control.new()
	_container.name = "HeartsContainer"
	# Make it fill the screen so positions are in screen space.
	_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)

	if player == null:
		push_error("HealthUI: player node not assigned in the Inspector!")
		return

	_build_hearts(player.max_health)
	_refresh(player.max_health)

	# Keep in sync whenever health changes.
	player.health_changed.connect(_refresh)

# ─────────────────────────────────────────────
#  BUILD
# ─────────────────────────────────────────────

## Creates one TextureRect per heart slot and lays them out.
func _build_hearts(total: int) -> void:
	# Clear any previous hearts (useful if the map is regenerated).
	for h in _hearts:
		h.queue_free()
	_hearts.clear()

	# Figure out the wrap boundary — half the viewport width.
	var half_screen: float = get_viewport().get_visible_rect().size.x * 0.5

	var step: float = heart_size.x + heart_padding
	var cursor := origin

	for i in range(total):
		var rect := TextureRect.new()
		rect.texture = heart_texture if heart_texture else null
		rect.custom_minimum_size = heart_size
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.position = cursor
		rect.size = heart_size
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_container.add_child(rect)
		_hearts.append(rect)

		# Advance cursor, wrapping when we'd exceed the half-screen boundary.
		cursor.x += step
		if cursor.x + heart_size.x > half_screen:
			cursor.x = origin.x
			cursor.y += heart_size.y + heart_padding

## Called whenever health_changed fires.
func _refresh(current_health: int) -> void:
	for i in range(_hearts.size()):
		var rect: TextureRect = _hearts[i]
		if i < current_health:
			# Full heart.
			rect.texture = heart_texture
			rect.modulate = Color.WHITE
		else:
			# Empty slot.
			if heart_empty_texture:
				rect.texture = heart_empty_texture
				rect.modulate = Color.WHITE
			else:
				# No empty texture supplied — dim the full texture instead.
				rect.texture = heart_texture
				rect.modulate = Color(1, 1, 1, 0.25)
