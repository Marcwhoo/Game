extends Node2D

@export var grid: TileMapLayer #combat_grid
@export var player_ui: Control #player_ui

var max_health: float = 10.0
var current_health: float = 10.0
var attack_range_min: float = 1
var attack_range_max: float = 1

var damage_output_calc: Node
var damage_input_calc: Node

func _ready() -> void:
	add_to_group("player")
	damage_output_calc = get_node_or_null("DamageOutputCalculation")
	damage_input_calc = get_node_or_null("DamageInputCalculation")
	if grid:
		var start_cell: Vector2i = Vector2i(2, 6)
		global_position = grid.cell_to_world(start_cell)
		grid.register_occupant(self, start_cell)
	if player_ui and player_ui.has_method("update_health"):
		player_ui.call_deferred("update_health", current_health, max_health)


func try_attack(cell: Vector2i, enemy: Node) -> bool:
	if not grid or not damage_output_calc or not enemy.has_method("take_damage"):
		return false
	var my_cell: Vector2i = grid.world_to_cell(global_position)
	var step_toward: Vector2i = Vector2i(signi(cell.x - my_cell.x), signi(cell.y - my_cell.y))
	_set_facing(step_toward)
	var raw_damage: float = float(damage_output_calc.calculate_raw_damage())
	enemy.take_damage(raw_damage)
	return true


func take_damage(raw_damage: float) -> void:
	var incoming: float = float(raw_damage)
	var final_damage: float = incoming
	if damage_input_calc and damage_input_calc.has_method("apply_resistances"):
		final_damage = float(damage_input_calc.apply_resistances(incoming))
	current_health = current_health - final_damage
	if current_health < 0.0:
		current_health = 0.0
	if player_ui and player_ui.has_method("update_health"):
		player_ui.update_health(current_health, max_health)
	_spawn_floating_damage(final_damage)


func _spawn_floating_damage(amount: float) -> void:
	var fd: Node = get_node_or_null("FloatingDamage")
	if fd and fd.has_method("show_damage"):
		fd.show_damage(amount)


func move_toward_cell(cell: Vector2i) -> bool:
	if not grid:
		return false
	var current: Vector2i = grid.world_to_cell(global_position)
	var delta: Vector2i = cell - current
	var step := Vector2i(signi(delta.x), signi(delta.y))
	if step == Vector2i.ZERO:
		return false
	var new_cell: Vector2i = current + step
	if not grid.is_cell_walkable(new_cell):
		return false
	if not grid.is_cell_empty(new_cell):
		return false
	_set_facing(step)
	global_position = grid.cell_to_world(new_cell)
	grid.move_occupant(self, current, new_cell)
	return true


func _set_facing(step: Vector2i) -> void:
	if step.x == 0:
		return
	var spr: Node2D = get_node_or_null("Sprite2D")
	if spr:
		spr.scale.x = -1.0 if step.x < 0 else 1.0
