extends CanvasLayer

@onready var restart: Button = %Restart
@onready var quit: Button = %Quit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	restart.pressed.connect(_restart_game)
	quit.pressed.connect(_quit_game)
	pass # Replace with function body.

func _restart_game() -> void:
	get_tree().change_scene_to_file("uid://lvq3qltn2day")

func _quit_game() -> void:
	get_tree().quit()
