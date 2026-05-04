extends Node
@onready var map_maker_ui: CanvasLayer = %MapMakerUI
@onready var shader_fog: CanvasLayer = $ShaderFog

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Toggle_Map"):
		shader_fog.visible = !shader_fog.visible
		map_maker_ui.visible = !map_maker_ui.visible
