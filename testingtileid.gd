extends TileMapLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for row in [0,1,2]:
		for col in [0,1,2]:
			checktileid(Vector2i(row,col))

func checktileid(pos: Vector2i) -> void:
	var id = self.get_cell_source_id(pos)
	print(id)
