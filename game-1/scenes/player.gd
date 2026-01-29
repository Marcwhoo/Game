extends Node2D

@export var grid: TileMapLayer #combat_grid
@export var player_ui: Control #player_ui

var max_health: float = 10.0
var current_health: float = 10.0

func _ready() -> void:
	if grid:
		var start_cell: Vector2i = Vector2i(2, 6)
		global_position = grid.cell_to_world(start_cell)
		grid.register_occupant(self, start_cell)
	if player_ui and player_ui.has_method("update_health"):
		player_ui.call_deferred("update_health", current_health, max_health)


func move_toward_cell(cell: Vector2i) -> void:
	if not grid:
		return
	var current: Vector2i = grid.world_to_cell(global_position)
	var delta: Vector2i = cell - current
	var step := Vector2i(signi(delta.x), signi(delta.y))
	if step == Vector2i.ZERO:
		return
	var new_cell: Vector2i = current + step
	if not grid.is_cell_walkable(new_cell):
		return
	if not grid.is_cell_empty(new_cell):
		return
	global_position = grid.cell_to_world(new_cell)
	grid.move_occupant(self, current, new_cell)
