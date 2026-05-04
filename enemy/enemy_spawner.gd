extends Node
class_name EnemySpawner

@export var tile_generator: TileMapGenerator = null
@export var enemy: PackedScene = preload("uid://1vnjlg5cbw6t")
@export var player: Player = null
@export_range(3,20, 1) var max_spawns: int = 20
var min_spawns: int = 2
var num_of_spawns: int
@export_flags_2d_navigation var nav_layer_mask: int = 1

const debug_tag: String = "[SPAWNER]: "

func _ready() -> void:
	assert(player, "SET THE PLAYER BRO")
	assert(tile_generator, "SET THE TILE GENERATOR")
	num_of_spawns = randi_range(min_spawns, max_spawns)
	for i in range(num_of_spawns):
		call_deferred("spawn")

func spawn() -> Node:
	var rid = tile_generator.tileMap.get_navigation_map()
	# Let TileMap navigation register/sync.
	await get_tree().physics_frame
	
	if not rid.is_valid():
		push_error("Failing to grab RID of tilemap navigation")
	
	NavigationServer2D.map_force_update(rid)
	var point = NavigationServer2D.map_get_random_point(rid, nav_layer_mask, true)
	var e: Enemy = enemy.instantiate()
	print(debug_tag, "Enemy spawned at", point)
	e.global_position = point
	e.player = self.player
	e.tile_map = self.tile_generator
	e.scale = Vector2(0.2, 0.2)
	
	print(debug_tag, "Map RID:", rid)
	print(debug_tag, "Map iteration:", NavigationServer2D.map_get_iteration_id(rid))
	print(debug_tag, "Regions:", NavigationServer2D.map_get_regions(rid))
	print(debug_tag, "Layer mask:", nav_layer_mask)
	
	add_child(e)
	return e
