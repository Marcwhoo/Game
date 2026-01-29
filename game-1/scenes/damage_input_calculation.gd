extends Node

var resistance_multiplier: float = 1.0

func apply_resistances(raw_damage: float) -> float:
	var d: float = float(raw_damage)
	var m: float = float(resistance_multiplier)
	return d * m
