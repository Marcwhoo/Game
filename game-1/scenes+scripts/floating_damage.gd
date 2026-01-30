extends Node2D

var _last_dir: int = -1

func _ready() -> void:
	var t: CanvasItem = get_node_or_null("LabelTemplate")
	if t:
		t.visible = false

func show_damage(amount: float) -> void:
	var template: CanvasItem = get_node_or_null("LabelTemplate")
	if not template:
		return
	var lbl: CanvasItem = template.duplicate()
	add_child(lbl)
	var s: String = str(snapped(amount, 0.01))
	if s.ends_with(".0"):
		s = str(int(amount))
	if lbl is Label:
		(lbl as Label).text = s
	lbl.position = Vector2.ZERO
	lbl.visible = true
	var choices: Array[int] = [0, 1, 2]
	if _last_dir >= 0:
		choices.erase(_last_dir)
	_last_dir = choices[randi() % choices.size()]
	var drift_x: float = 0.0
	match _last_dir:
		0: drift_x = 0.0
		1: drift_x = 30.0
		_: drift_x = -30.0
	var end_pos: Vector2 = Vector2(drift_x, -50.0)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position", end_pos, 1.0)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.2).set_delay(0.8)
	tween.finished.connect(lbl.queue_free)
