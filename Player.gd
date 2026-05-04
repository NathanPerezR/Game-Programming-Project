extends CharacterBody2D
class_name Player

# ─────────────────────────────────────────────
#  EXPORTS — set these in the Inspector
# ─────────────────────────────────────────────

## Movement speed in pixels per second.
@export var speed: float = 120.0

## Reference to the TileMapGenerator node so we can check walkability.
@export var tile_map_generator: TileMapGenerator

## Maximum and starting health.
@export var max_health: int = 10

## Pixels the magic attack sprite is offset from the player center.
@export var attack_offset: float = 32.0

## How long (seconds) the attack hitbox stays active.
@export var attack_duration: float = 1.0

# ─────────────────────────────────────────────
#  SIGNALS
# ─────────────────────────────────────────────

## Emitted the moment the attack hitbox becomes active.
## Your teammate's monster script should connect to this (or monitor the
## Area2D overlap directly — see COMBAT INTEGRATION note at the bottom).
signal player_attacked(hitbox: Area2D)

## Emitted whenever the player's health changes (e.g. to update the UI).
signal health_changed(new_health: int)

## Emitted when health reaches zero.
signal player_died()

# ─────────────────────────────────────────────
#  INTERNAL STATE
# ─────────────────────────────────────────────

var _tile_map: TileMapLayer
var _map_ready: bool = false
var _facing_right: bool = true

## Tracks last facing as a direction string for attack positioning.
## Possible values: "right", "left", "up", "down"
var _last_direction: String = "right"

var _current_health: int
var _is_attacking: bool = false
var _attack_timer: float = 0.0

# ─────────────────────────────────────────────
#  NODE REFERENCES
# ─────────────────────────────────────────────
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _camera: Camera2D = $Camera2D

## Sprite that shows the blue magic effect during an attack.
@onready var _attack_sprite: Sprite2D = $MagicAttack/Sprite2D

## Area2D used as the damage hitbox — monsters check overlap with this.
@onready var _attack_area: Area2D = $MagicAttack

# ─────────────────────────────────────────────
#  READY
# ─────────────────────────────────────────────
func _ready() -> void:
	z_index = 1
	visible = false
	_current_health = max_health

	# Hide the attack effect until the player fires.
	_attack_area.visible = false
	_attack_area.monitoring = false

	if tile_map_generator:
		_tile_map = tile_map_generator.tileMap
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
#  PHYSICS / INPUT LOOP
# ─────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if not _map_ready:
		return

	_handle_attack_input(delta)
	_handle_movement(delta)
	_update_animations()

# ─────────────────────────────────────────────
#  MOVEMENT
# ─────────────────────────────────────────────
func _handle_movement(delta: float) -> void:
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

	var desired_velocity := input_dir * speed
	var next_pos := global_position + desired_velocity * delta

	if _tile_map and desired_velocity != Vector2.ZERO:
		var next_tile := _tile_map.local_to_map(_tile_map.to_local(next_pos))
		if not _is_walkable(next_tile):
			var h_pos := global_position + Vector2(desired_velocity.x, 0.0) * delta
			var h_tile := _tile_map.local_to_map(_tile_map.to_local(h_pos))
			if _is_walkable(h_tile):
				desired_velocity.y = 0.0
			else:
				var v_pos := global_position + Vector2(0.0, desired_velocity.y) * delta
				var v_tile := _tile_map.local_to_map(_tile_map.to_local(v_pos))
				if _is_walkable(v_tile):
					desired_velocity.x = 0.0
				else:
					desired_velocity = Vector2.ZERO

	velocity = desired_velocity
	move_and_slide()

# ─────────────────────────────────────────────
#  ATTACK
# ─────────────────────────────────────────────
func _handle_attack_input(delta: float) -> void:
	if _is_attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_end_attack()
		return

	if Input.is_action_just_pressed("attack"):
		_start_attack()

func _start_attack() -> void:
	_is_attacking = true
	_attack_timer = attack_duration

	# Position and rotate the attack sprite based on last facing direction.
	var offset := Vector2.ZERO
	var rotation_deg := 0.0

	match _last_direction:
		"right":
			offset = Vector2(attack_offset, 0.0)
			rotation_deg = 0.0
		"left":
			offset = Vector2(-attack_offset, 0.0)
			rotation_deg = 180.0
		"down":
			offset = Vector2(0.0, attack_offset)
			rotation_deg = 90.0
		"up":
			offset = Vector2(0.0, -attack_offset)
			rotation_deg = -90.0

	_attack_area.position = offset
	_attack_area.rotation_degrees = rotation_deg
	_attack_area.visible = true
	_attack_area.monitoring = true

	emit_signal("player_attacked", _attack_area)

func _end_attack() -> void:
	_is_attacking = false
	_attack_area.visible = false
	_attack_area.monitoring = false

# ─────────────────────────────────────────────
#  HEALTH
# ─────────────────────────────────────────────

## Called by a monster (or any damage source) to reduce player health.
## amount should be a positive integer.
func take_damage(amount: int) -> void:
	_current_health = max(0, _current_health - amount)
	emit_signal("health_changed", _current_health)
	if _current_health == 0:
		emit_signal("player_died")
		_on_death()

## Called by healing items or effects.
func heal(amount: int) -> void:
	_current_health = min(max_health, _current_health + amount)
	emit_signal("health_changed", _current_health)

func get_health() -> int:
	return _current_health

func _on_death() -> void:
	# Placeholder — add game-over logic here later.
	push_warning("Player died!")

# ─────────────────────────────────────────────
#  ANIMATIONS
# ─────────────────────────────────────────────
func _update_animations() -> void:
	# Track last direction while moving so attack + idle face correctly.
	if velocity.x > 0.0:
		_last_direction = "right"
	elif velocity.x < 0.0:
		_last_direction = "left"
	elif velocity.y > 0.0:
		_last_direction = "down"
	elif velocity.y < 0.0:
		_last_direction = "up"

	_animated_sprite.flip_h = false

	if _is_attacking:
		# No separate player attack animation — keep current frame frozen.
		return

	if velocity == Vector2.ZERO:
		_play_animation("idle")
	else:
		if abs(velocity.y) >= abs(velocity.x):
			if velocity.y > 0.0:
				_play_animation("front_walk")
			else:
				_play_animation("back_walk")
		else:
			if velocity.x > 0.0:
				_play_animation("right_walk")
			else:
				_play_animation("left_walk")

# ─────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────
func _is_walkable(pos: Vector2i) -> bool:
	if _tile_map == null:
		return true
	var td := _tile_map.get_cell_tile_data(pos)
	if td == null:
		return false
	return td.get_custom_data("walkable") == true

func _play_animation(anim_name: String) -> void:
	if _animated_sprite == null:
		return
	if _animated_sprite.sprite_frames == null:
		return
	if not _animated_sprite.sprite_frames.has_animation(anim_name):
		return
	if _animated_sprite.animation != anim_name:
		_animated_sprite.play(anim_name)

# ─────────────────────────────────────────────
#  COMBAT INTEGRATION NOTE (for your teammate)
# ─────────────────────────────────────────────
# Two equally valid patterns to hook monsters into this attack:
#
# OPTION 1 — Signal (loose coupling, recommended):
#   In the monster script:
#     player.player_attacked.connect(_on_player_attacked)
#   func _on_player_attacked(hitbox: Area2D) -> void:
#     if hitbox.overlaps_body(self):
#       take_damage(player_attack_damage)
#
# OPTION 2 — Area2D overlap (no signal needed):
#   Give each monster its own Area2D hurtbox.
#   Set the MagicAttack Area2D to collision layer 2
#   and monster hurtboxes to collision mask 2.
#   Connect area_entered on the monster hurtbox and call take_damage() there.
#
# Either approach works — Option 2 is simpler to set up in the editor
# without needing to find and reference the Player node at runtime.
