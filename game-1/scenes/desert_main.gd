extends Node2D

@onready var grid = $combat_grid
@onready var warrior = $Warrior
@onready var player_ui = $Control
@onready var turn_manager = $CombatTurnManager

func _ready() -> void:
	warrior.player_ui = player_ui
	grid.cell_clicked.connect(_on_cell_clicked)
	turn_manager.turn_changed.connect(_on_turn_changed)
	if player_ui and player_ui.has_method("update_health"):
		player_ui.call_deferred("update_health", warrior.current_health, warrior.max_health)


func _on_cell_clicked(cell: Vector2i) -> void:
	if not turn_manager.is_player_turn:
		return
	var enemies: Array = grid.get_enemies_at(cell)
	var player_cell: Vector2i = grid.world_to_cell(warrior.global_position)
	var in_range: bool = grid.is_cell_in_range(player_cell, cell, int(warrior.attack_range_min), int(warrior.attack_range_max))
	if not enemies.is_empty() and not in_range:
		if player_ui and player_ui.has_method("show_error"):
			player_ui.show_error("Ziel außer Reichweite")
		return
	var did_something: bool = false
	if not enemies.is_empty() and in_range:
		did_something = warrior.try_attack(cell, enemies[0])
	else:
		did_something = warrior.move_toward_cell(cell)
	if did_something:
		turn_manager.end_player_turn()


func _on_turn_changed(is_player_turn: bool) -> void:
	if is_player_turn:
		return
	await get_tree().create_timer(0.8).timeout
	var enemies: Array = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e.has_method("take_turn"):
			e.take_turn()
	turn_manager.end_enemy_turn()
