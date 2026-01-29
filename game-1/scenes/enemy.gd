extends Node2D

@export var grid: TileMapLayer

var max_health: float = 5.0
var current_health: float = 5.0

func _ready() -> void:
	if grid:
		var start_cell: Vector2i = Vector2i(7, 7)
		global_position = grid.cell_to_world(start_cell)
		grid.register_occupant(self, start_cell)


func move_toward_cell(cell: Vector2i) -> void:
	if not grid:
		return
	var current: Vector2i = grid.world_to_cell(global_position)
	var delta: Vector2i = cell - current
	var step := Vector2i(signi(delta.x), signi(delta.y))
	if step == Vector2i.ZERO:
		return
	var new_cell: Vector2i = current + step
	if not grid.is_cell_empty(new_cell):
		return
	global_position = grid.cell_to_world(new_cell)
	grid.move_occupant(self, current, new_cell)
