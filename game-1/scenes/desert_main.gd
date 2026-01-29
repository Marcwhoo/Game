extends Node2D

@onready var grid = $combat_grid
@onready var warrior = $Warrior
@onready var player_ui = $Control

func _ready() -> void:
	warrior.player_ui = player_ui
	grid.cell_clicked.connect(warrior.move_toward_cell)
	if player_ui and player_ui.has_method("update_health"):
		player_ui.call_deferred("update_health", warrior.current_health, warrior.max_health)
