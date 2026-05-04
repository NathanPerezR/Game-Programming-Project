extends CharacterBody2D

@export var speed := 120.0
@export var damage_to_player := 1
@export var attack_cooldown := 1.0

const MAX_HEALTH = 2
var health: int = MAX_HEALTH
var is_dead: bool = false
var hearts: Array[ColorRect] = []
var _attack_timer: float = 0.0

@onready var agent: NavigationAgent2D = $NavigationAgent2D
var player: Node2D = null

func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	agent.avoidance_enabled = false
	_build_health_display()
	_build_hurtbox()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Find player if we don't have a reference
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(player):
			return

	# Tick attack cooldown
	if _attack_timer > 0.0:
		_attack_timer -= delta

	# Navigate toward player
	agent.target_position = player.global_position
	if agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		# Damage player on contact if cooldown is ready
		if _attack_timer <= 0.0:
			var dist = global_position.distance_to(player.global_position)
			if dist < 40.0:
				player.take_damage(damage_to_player)
				_attack_timer = attack_cooldown
		return

	var next_pos = agent.get_next_path_position()
	velocity = (next_pos - global_position).normalized() * speed
	move_and_slide()

	# Also check contact damage while moving
	if _attack_timer <= 0.0:
		var dist = global_position.distance_to(player.global_position)
		if dist < 40.0:
			player.take_damage(damage_to_player)
			_attack_timer = attack_cooldown

func _build_hurtbox() -> void:
	var hurtbox := Area2D.new()
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 2

	var shape := CircleShape2D.new()
	shape.radius = 20.0
	var col := CollisionShape2D.new()
	col.shape = shape
	hurtbox.add_child(col)
	add_child(hurtbox)

	# Connect after adding to tree so node is ready
	hurtbox.area_entered.connect(_on_hit)

func _on_hit(_area: Area2D) -> void:
	take_damage(1)

func _build_health_display() -> void:
	var ui_root := Node2D.new()
	ui_root.position = Vector2(-20, -50)
	add_child(ui_root)
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	ui_root.add_child(container)
	for i in range(MAX_HEALTH):
		var heart := ColorRect.new()
		heart.custom_minimum_size = Vector2(16, 16)
		heart.color = Color.RED
		container.add_child(heart)
		hearts.append(heart)

func _update_hearts() -> void:
	for i in range(hearts.size()):
		hearts[i].color = Color.RED if i < health else Color(0.3, 0.3, 0.3)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health = clamp(health - amount, 0, MAX_HEALTH)
	_update_hearts()
	if health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	await get_tree().create_timer(0.3).timeout
	queue_free()
