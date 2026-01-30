extends Node2D

@export var grid: TileMapLayer

var max_health: float = 5.0
var current_health: float = 5.0
var attack_range_min: int = 1
var attack_range_max: int = 1

var damage_input_calc: Node
var damage_output_calc: Node

var current_cell: Vector2i = Vector2i(7, 7)

const MOVE_DURATION := 0.2
const ANIM_WALKING := "walking"
const ANIM_DEATH := "death"

var _anim_player: AnimationPlayer
var _is_dead := false

func _ready() -> void:
	add_to_group("enemy")
	_anim_player = get_node_or_null("AnimationPlayer")
	damage_input_calc = get_node_or_null("DamageInputCalculation")
	damage_output_calc = get_node_or_null("DamageOutputCalculation")
	if grid:
		current_cell = Vector2i(7, 7)
		global_position = grid.cell_to_world(current_cell)
		grid.register_occupant(self, current_cell)
	if has_node("Control") and get_node("Control").has_method("update_health"):
		get_node("Control").call_deferred("update_health", current_health, max_health)
	_play_idle()


func take_damage(raw_damage: float) -> void:
	if _is_dead:
		return
	var incoming: float = float(raw_damage)
	var final_damage: float = incoming
	if damage_input_calc and damage_input_calc.has_method("apply_resistances"):
		final_damage = float(damage_input_calc.apply_resistances(incoming))
	current_health = current_health - final_damage
	if current_health < 0.0:
		current_health = 0.0
	if has_node("Control") and get_node("Control").has_method("update_health"):
		get_node("Control").update_health(current_health, max_health)
	_spawn_floating_damage(final_damage)
	if current_health <= 0.0:
		_is_dead = true
		_die()


func _spawn_floating_damage(amount: float) -> void:
	var fd: Node = get_node_or_null("FloatingDamage")
	if fd and fd.has_method("show_damage"):
		fd.show_damage(amount)


func try_attack(_cell: Vector2i, target: Node) -> bool:
	if not grid or not damage_output_calc or not target.has_method("take_damage"):
		return false
	var raw_damage: float = float(damage_output_calc.calculate_raw_damage())
	target.take_damage(raw_damage)
	return true


func take_turn() -> void:
	if not grid or _is_dead or current_health <= 0.0:
		return
	var target: Node = get_tree().get_first_node_in_group("player")
	if not target:
		return
	var my_cell: Vector2i = current_cell
	var target_cell: Vector2i
	if "current_cell" in target:
		target_cell = target.current_cell
	else:
		target_cell = grid.world_to_cell(target.global_position)
	if grid.is_cell_in_range(my_cell, target_cell, attack_range_min, attack_range_max):
		var step_toward: Vector2i = Vector2i(signi(target_cell.x - my_cell.x), signi(target_cell.y - my_cell.y))
		_set_facing(step_toward)
		try_attack(target_cell, target)
		return
	var path: Array = grid.get_cell_path(my_cell, target_cell)
	if not path.is_empty():
		var next_cell: Vector2i = path[0]
		await move_toward_cell(next_cell)
	else:
		var delta: Vector2i = target_cell - my_cell
		var step := Vector2i(signi(delta.x), signi(delta.y))
		if step != Vector2i.ZERO:
			var candidates: Array[Vector2i] = []
			candidates.append(my_cell + step)
			if step.x != 0:
				candidates.append(my_cell + Vector2i(step.x, 0))
			if step.y != 0:
				candidates.append(my_cell + Vector2i(0, step.y))
			for next_cell in candidates:
				if grid.is_cell_walkable(next_cell) and grid.is_cell_empty(next_cell):
					await move_toward_cell(next_cell)
					break
	_play_idle()


func move_toward_cell(cell: Vector2i) -> void:
	if not grid:
		return
	var current: Vector2i = current_cell
	var delta: Vector2i = cell - current
	var step := Vector2i(signi(delta.x), signi(delta.y))
	if step == Vector2i.ZERO:
		return
	var new_cell: Vector2i = current + step
	if not grid.is_cell_walkable(new_cell) or not grid.is_cell_empty(new_cell):
		return
	_set_facing(step)
	var end_pos: Vector2 = grid.cell_to_world(new_cell)
	grid.move_occupant(self, current, new_cell)
	current_cell = new_cell
	_play_walking()
	var tween := create_tween()
	tween.tween_property(self, "global_position", end_pos, MOVE_DURATION)
	await tween.finished


func _set_facing(step: Vector2i) -> void:
	if step.x == 0:
		return
	var spr: Node2D = get_node_or_null("BearQuadrupedEast")
	if spr:
		spr.scale.x = 1.0 if step.x < 0 else -1.0


func _play_idle() -> void:
	if _anim_player and _anim_player.has_animation("idle"):
		_anim_player.play("idle")


func _play_walking() -> void:
	if _anim_player and _anim_player.has_animation(ANIM_WALKING):
		_anim_player.play(ANIM_WALKING)


func _die() -> void:
	if grid:
		grid.unregister_occupant(self, current_cell)
	remove_from_group("enemy")
	z_index = 3
	if _anim_player and _anim_player.has_animation(ANIM_DEATH):
		_anim_player.play(ANIM_DEATH)
