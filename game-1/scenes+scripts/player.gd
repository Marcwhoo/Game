extends Node2D

@export var grid: TileMapLayer
@export var equipment: InventoryObject
@export var player_data: PlayerData

var player_ui: Control

var max_health: float = 10.0
var current_health: float = 10.0
var attack_range_min: float = 1
var attack_range_max: float = 1

var current_cell: Vector2i = Vector2i(2, 6)

var damage_output_calc: Node
var damage_input_calc: Node

var _armor: int = 0
var _damage: int = 0
var _attack_speed: float = 1.0
var _move_speed: int = 0
var _money_fallback: int = 0

const MOVE_DURATION := 0.2

func _ready() -> void:
	add_to_group("player")
	damage_output_calc = get_node_or_null("DamageOutputCalculation")
	damage_input_calc = get_node_or_null("DamageInputCalculation")
	player_ui = get_node_or_null("player_ui")
	if player_data:
		current_health = player_data.current_health
		max_health = player_data.max_health
	if grid:
		position = Vector2.ZERO
		current_cell = Vector2i(2, 6)
		var visuals: Node2D = get_node_or_null("player_visuals")
		if visuals:
			visuals.global_position = grid.cell_to_world(current_cell)
		else:
			global_position = grid.cell_to_world(current_cell)
		grid.register_occupant(self, current_cell)
	refresh_stats_from_equipment()
	if player_ui and player_ui.has_method("update_health"):
		player_ui.call_deferred("update_health", current_health, max_health)


func _get_money() -> int:
	if player_data:
		return player_data.money
	return _money_fallback


func _set_money(v: int) -> void:
	if player_data:
		player_data.money = v
	else:
		_money_fallback = v


var money: int:
	get: return _get_money()
	set(v): _set_money(v)


func refresh_stats_from_equipment() -> void:
	var inv: InventoryObject = equipment if equipment else (player_data.equipment if player_data else null)
	if not inv or not inv.items_in_inventory:
		_apply_stats(0, 0, 1.0, 0)
		return
	var d: int = 0
	var a: int = 0
	var asp: float = 0.0
	var msp: int = 0
	var count: int = 0
	for item in inv.items_in_inventory:
		if item:
			d += item.damage
			a += item.armor
			if item.attack_speed > 0.0:
				asp += item.attack_speed
				count += 1
			msp += item.move_speed
	var avg_attack: float = (asp / count) if count > 0 else 1.0
	_apply_stats(d, a, avg_attack, msp)


func _apply_stats(damage_val: int, armor_val: int, attack_speed_val: float, move_speed_val: int) -> void:
	_damage = damage_val
	_armor = armor_val
	_attack_speed = attack_speed_val if attack_speed_val > 0.0 else 1.0
	_move_speed = move_speed_val
	if damage_output_calc:
		damage_output_calc.base_damage = float(max(1, _damage))
	if damage_input_calc:
		damage_input_calc.resistance_multiplier = 1.0 / (1.0 + _armor * 0.01)
	if player_data:
		player_data.max_health = max_health


func get_display_stats() -> Dictionary:
	return {
		"armor": _armor,
		"damage": max(1, _damage),
		"attackspeed": _attack_speed,
		"movementspeed": _move_speed,
		"max_health": int(max_health)
	}


func try_attack(cell: Vector2i, enemy: Node) -> bool:
	if not grid or not damage_output_calc or not enemy.has_method("take_damage"):
		return false
	var step_toward: Vector2i = Vector2i(signi(cell.x - current_cell.x), signi(cell.y - current_cell.y))
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
	if player_data:
		player_data.current_health = current_health
	if player_ui and player_ui.has_method("update_health"):
		player_ui.update_health(current_health, max_health)
	_spawn_floating_damage(final_damage)


func _spawn_floating_damage(amount: float) -> void:
	var fd: Node = get_node_or_null("player_visuals/FloatingDamage")
	if not fd:
		fd = get_node_or_null("FloatingDamage")
	if fd and fd.has_method("show_damage"):
		fd.show_damage(amount)


func move_toward_cell(cell: Vector2i) -> bool:
	if not grid:
		return false
	var current: Vector2i = current_cell
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
	var end_pos: Vector2 = grid.cell_to_world(new_cell)
	grid.move_occupant(self, current, new_cell)
	current_cell = new_cell
	var visuals: Node2D = get_node_or_null("player_visuals")
	if visuals:
		var tween := create_tween()
		tween.tween_property(visuals, "global_position", end_pos, MOVE_DURATION)
		await tween.finished
	else:
		var tween := create_tween()
		tween.tween_property(self, "global_position", end_pos, MOVE_DURATION)
		await tween.finished
	return true


func _set_facing(step: Vector2i) -> void:
	if step.x == 0:
		return
	var spr: Node2D = get_node_or_null("player_visuals/Sprite2D")
	if not spr:
		spr = get_node_or_null("Sprite2D")
	if spr:
		spr.scale.x = -1.0 if step.x < 0 else 1.0
