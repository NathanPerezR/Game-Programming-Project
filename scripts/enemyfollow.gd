extends CharacterBody2D

# Setup: Add a NavigationAgent2D as a child of this node.
# The player node must be in the "player" group (Project > Project Settings > Groups,
# or call add_to_group("player") in the player's _ready()).

@export var speed := 120.0
@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var player: Node2D = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	await get_tree().physics_frame
	agent.avoidance_enabled = true
	agent.radius = 20.0
	agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		print("Enemy: no valid player found!")
		return

	agent.target_position = player.global_position
	var next_path_pos = agent.get_next_path_position()

	if agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction = (next_path_pos - global_position).normalized()
	agent.velocity = direction * speed

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
