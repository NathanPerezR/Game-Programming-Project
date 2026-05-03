extends CharacterBody2D
class_name Player

# ─────────────────────────────────────────────
#  EXPORTS — set these in the Inspector
# ─────────────────────────────────────────────

## Movement speed in pixels per second.
@export var speed: float = 120.0

## Reference to the TileMapGenerator node so we can check walkability.
## Drag the TileMapGenerator node here in the Inspector.
@export var tile_map_generator: TileMapGenerator

# ─────────────────────────────────────────────
#  INTERNAL STATE
# ─────────────────────────────────────────────

## Cached reference to the TileMapLayer (grabbed from the generator).
var _tile_map: TileMapLayer

## Whether the map has finished generating. The player stays frozen until then.
var _map_ready: bool = false

## Last facing direction — used to flip the sprite correctly.
var _facing_right: bool = true

# ─────────────────────────────────────────────
#  NODE REFERENCES (children of this node)
# ─────────────────────────────────────────────
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _camera: Camera2D = $Camera2D

# ─────────────────────────────────────────────
#  READY
# ─────────────────────────────────────────────
func _ready() -> void:
	# Hide the player until the map tells us where to spawn.
	visible = false

	# Grab the TileMapLayer from the generator so we can query walkability.
	if tile_map_generator:
		_tile_map = tile_map_generator.tileMap
		# Connect to the signal emitted at the end of gen_map.
		tile_map_generator.map_generated.connect(_on_map_generated)
	else:
		push_error("Player: tile_map_generator is not assigned in the Inspector!")

# ─────────────────────────────────────────────
#  MAP-READY CALLBACK
# ─────────────────────────────────────────────
func _on_map_generated(spawn_world_pos: Vector2) -> void:
	global_position = spawn_world_pos
	_map_ready = true
	visible = true

# ─────────────────────────────────────────────
#  PHYSICS LOOP
# ─────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if not _map_ready:
		return

	# ── Read input ──────────────────────────────
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		input_dir.x += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
		input_dir.y += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
		input_dir.y -= 1.0

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()

	# ── Walkability check ──────────────────────
	# Before applying movement, test whether the cell the player would land on
	# is walkable.  We sample the center of the destination position.
	var desired_velocity := input_dir * speed
	var next_pos := global_position + desired_velocity * delta

	if _tile_map and desired_velocity != Vector2.ZERO:
		var next_tile := _tile_map.local_to_map(_tile_map.to_local(next_pos))
		if not _is_walkable(next_tile):
			# Try to slide along a single axis instead of stopping completely.
			# Attempt horizontal-only slide.
			var h_pos := global_position + Vector2(desired_velocity.x, 0.0) * delta
			var h_tile := _tile_map.local_to_map(_tile_map.to_local(h_pos))
			if _is_walkable(h_tile):
				desired_velocity.y = 0.0
			else:
				# Attempt vertical-only slide.
				var v_pos := global_position + Vector2(0.0, desired_velocity.y) * delta
				var v_tile := _tile_map.local_to_map(_tile_map.to_local(v_pos))
				if _is_walkable(v_tile):
					desired_velocity.x = 0.0
				else:
					# Fully blocked — stop.
					desired_velocity = Vector2.ZERO

	velocity = desired_velocity
	move_and_slide()

	# ── Sprite flip ────────────────────────────
	if velocity.x > 0.0:
		_facing_right = true
		_animated_sprite.flip_h = false
	elif velocity.x < 0.0:
		_facing_right = false
		_animated_sprite.flip_h = true

	# ── Animations ─────────────────────────────
	# Phase 1: idle / walk only.
	# (Attack animations will be added in Phase 2.)
	if velocity == Vector2.ZERO:
		_play_animation("idle")
	else:
		_play_animation("walk")

# ─────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────

## Returns true if the tile at tile-coords `pos` has walkable == true.
func _is_walkable(pos: Vector2i) -> bool:
	if _tile_map == null:
		return true  # fail-open so player is never permanently stuck
	var td := _tile_map.get_cell_tile_data(pos)
	if td == null:
		return false
	return td.get_custom_data("walkable") == true

## Safe animation player — only calls play() when the animation name actually
## exists in the SpriteFrames resource, avoiding "animation not found" errors.
func _play_animation(anim_name: String) -> void:
	if _animated_sprite == null:
		return
	if _animated_sprite.sprite_frames == null:
		return
	if not _animated_sprite.sprite_frames.has_animation(anim_name):
		return
	if _animated_sprite.animation != anim_name:
		_animated_sprite.play(anim_name)
