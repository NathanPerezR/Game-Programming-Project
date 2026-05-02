extends Node2D

# Setup: Attach this script to a Node2D that has a NavigationRegion2D child.
# The NavigationRegion2D should have a NavigationPolygon resource assigned and
# painted to cover only the tiles this agent type is allowed to traverse.

@onready var nav_region: NavigationRegion2D = $NavigationRegion2D

func _ready() -> void:
	await get_tree().physics_frame
	nav_region.bake_navigation_polygon()
