extends CharacterBody2D
class_name Enemy

@export var player: Player = null
@export var tile_map: TileMapGenerator
@export var speed: float = 80.0
@export var stop_distance: float = 20

var chase_player: bool = false

@onready var enemy_pathfinding: NavigationAgent2D = %EnemyPathfinding

var nav_layer_rid: RID


func _ready() -> void:
	assert(player, "SET THE PLAYER BRO")
	assert(tile_map, "SET THE TILEMAP BRO")

	nav_layer_rid = tile_map.get_nav_rid()
	enemy_pathfinding.set_navigation_map(nav_layer_rid)

	# Optional tuning. Adjust as needed.
	enemy_pathfinding.path_desired_distance = 8.0
	enemy_pathfinding.target_desired_distance = stop_distance


func _physics_process(delta: float) -> void:
	if not chase_player:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distance_to_player := global_position.distance_to(player.global_position)

	if distance_to_player <= stop_distance:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	enemy_pathfinding.target_position = player.global_position

	if enemy_pathfinding.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var next_path_position := enemy_pathfinding.get_next_path_position()
	var direction := global_position.direction_to(next_path_position)

	velocity = direction * speed
	move_and_slide()

func _on_player_detection_body_entered(body: Node2D) -> void:
	if body == player:
		chase_player = true


func _on_player_detection_body_exited(body: Node2D) -> void:
	if body == player:
		chase_player = false
		velocity = Vector2.ZERO
