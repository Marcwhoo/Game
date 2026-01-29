extends Node

signal turn_changed(is_player_turn: bool)

var is_player_turn: bool = true

func end_player_turn() -> void:
	is_player_turn = false
	turn_changed.emit(is_player_turn)

func end_enemy_turn() -> void:
	is_player_turn = true
	turn_changed.emit(is_player_turn)
