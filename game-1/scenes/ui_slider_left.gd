extends Control

var _open_x: float
var _closed_x: float
var _is_collapsed: bool = true
var _blocker: Control

const SLIDER_TWEEN_DURATION := 0.2

func _ready() -> void:
	add_to_group("game_ui")
	_open_x = position.x
	var arrow: Node2D = get_node_or_null("UiArrow")
	if arrow:
		_closed_x = _open_x - arrow.position.x + 6.0
	else:
		_closed_x = _open_x - size.x
	_blocker = Control.new()
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.add_to_group("game_ui")
	add_child(_blocker)
	var btn: Button = Button.new()
	btn.flat = true
	if arrow and arrow is Sprite2D and (arrow as Sprite2D).texture:
		var t: Vector2 = (arrow as Sprite2D).texture.get_size()
		btn.position = arrow.position - t / 2.0
		btn.size = t
	else:
		btn.size = Vector2(32, 32)
	add_child(btn)
	btn.pressed.connect(_on_arrow_pressed)
	_is_collapsed = true
	position.x = _closed_x
	_update_blocker()

func _on_arrow_pressed() -> void:
	_is_collapsed = not _is_collapsed
	var target_x: float = _closed_x if _is_collapsed else _open_x
	var tween := create_tween()
	tween.tween_property(self, "position", Vector2(target_x, position.y), SLIDER_TWEEN_DURATION)
	tween.finished.connect(_update_blocker)

func _update_blocker() -> void:
	if not _blocker:
		return
	if _is_collapsed:
		_blocker.set_size(Vector2.ZERO)
	else:
		var arrow: Node2D = get_node_or_null("UiArrow")
		var w: float = size.x
		if arrow and arrow is Sprite2D and (arrow as Sprite2D).texture:
			w = arrow.position.x + (arrow as Sprite2D).texture.get_size().x
		_blocker.set_position(Vector2.ZERO)
		_blocker.set_size(Vector2(w, size.y))
