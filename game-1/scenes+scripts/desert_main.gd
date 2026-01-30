extends Node2D

@onready var grid = $combat_grid
@onready var warrior = $Warrior
@onready var turn_manager = $CombatTurnManager

var _player_action_in_progress := false
var _enemy_turn_in_progress := false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var global_pos: Vector2 = get_global_mouse_position()
			var cell: Vector2i = grid.world_to_cell(global_pos)
			print("debug click pos=", mb.position, " global=", global_pos, " cell=", cell)

func _ready() -> void:
	grid.cell_clicked.connect(_on_cell_clicked)
	turn_manager.turn_changed.connect(_on_turn_changed)
	if warrior.player_ui and warrior.player_ui.has_method("update_health"):
		warrior.player_ui.call_deferred("update_health", warrior.current_health, warrior.max_health)


func _on_cell_clicked(cell: Vector2i) -> void:
	if not turn_manager.is_player_turn:
		return
	if _player_action_in_progress:
		return
	var enemies: Array = grid.get_enemies_at(cell)
	var player_cell: Vector2i = warrior.current_cell
	var in_range: bool = grid.is_cell_in_range(player_cell, cell, int(warrior.attack_range_min), int(warrior.attack_range_max))
	if not enemies.is_empty() and not in_range:
		if warrior.player_ui and warrior.player_ui.has_method("show_error"):
			warrior.player_ui.show_error("Ziel außer Reichweite")
		return
	_player_action_in_progress = true
	var did_something: bool = false
	if not enemies.is_empty() and in_range:
		did_something = warrior.try_attack(cell, enemies[0])
	else:
		did_something = await warrior.move_toward_cell(cell)
	_player_action_in_progress = false
	if did_something:
		turn_manager.end_player_turn()


func _on_turn_changed(is_player_turn: bool) -> void:
	if is_player_turn:
		return
	if _enemy_turn_in_progress:
		return
	_enemy_turn_in_progress = true
	await get_tree().create_timer(0.5).timeout
	var enemies: Array = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e.has_method("take_turn"):
			await e.take_turn()
	turn_manager.end_enemy_turn()
	_enemy_turn_in_progress = false
