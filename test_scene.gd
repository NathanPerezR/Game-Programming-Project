extends Node2D

@onready var mm: CanvasLayer = %MapMakerUI 
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Toggle_Map"):
		mm.visible = !mm.visible
