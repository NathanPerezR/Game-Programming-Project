extends Node
@onready var map_maker_ui: CanvasLayer = %MapMakerUI

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Toggle_Map"):
		map_maker_ui.visible = !map_maker_ui.visible
