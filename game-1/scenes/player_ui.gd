extends Control

var _bar_full: Sprite2D
var _tex_width: float
var _tex_height: float
var _initial_pos: Vector2
var _use_scale_x: bool = false
var _error_container: Control
var _error_timer: float = -1.0

var _slider: Control
var _slider_open_x: float
var _slider_closed_x: float
var _slider_is_collapsed: bool = false

var _slider_right: Control
var _slider_right_open_x: float
var _slider_right_closed_x: float
var _slider_right_is_collapsed: bool = false

const SLIDER_TWEEN_DURATION := 0.2

func _ready() -> void:
	var slider_left := get_node_or_null("ui_slider_left")
	if slider_left:
		slider_left.add_to_group("game_ui")
	var slider_right := get_node_or_null("ui_slider_right")
	if slider_right:
		slider_right.add_to_group("game_ui")
	var vp_rect: Rect2 = get_viewport_rect()
	set_position(Vector2.ZERO)
	set_size(vp_rect.size)
	_error_container = get_node_or_null("ErrorMessageOutline")
	_bar_full = get_node_or_null("ui_slider_left/Control/Healthbar_full")
	if _bar_full and _bar_full.texture:
		_tex_width = float(_bar_full.texture.get_width())
		_tex_height = float(_bar_full.texture.get_height())
		_use_scale_x = _tex_width > _tex_height
		_initial_pos = _bar_full.position
		_bar_full.region_enabled = true
		_bar_full.region_rect = Rect2(0, 0, _tex_width, _tex_height)
	_setup_slider()
	_setup_slider_right()

func update_health(current: float, max_val: float) -> void:
	if max_val <= 0.0 or not _bar_full:
		return
	var ratio := clampf(current / max_val, 0.0, 1.0)
	_bar_full.scale = Vector2(1.0, 1.0)
	_bar_full.position = _initial_pos
	if _use_scale_x:
		var w := ratio * _tex_width
		_bar_full.region_rect = Rect2(_tex_width - w, 0, w, _tex_height)
		_bar_full.offset = Vector2((_tex_width - w) / 2.0, 0.0)
	else:
		var h := ratio * _tex_height
		_bar_full.region_rect = Rect2(0, _tex_height - h, _tex_width, h)
		_bar_full.offset = Vector2(0.0, (_tex_height - h) / 2.0)

func show_error(text: String) -> void:
	if not _error_container:
		return
	for child in _error_container.get_children():
		if child is Label:
			child.text = text
			child.visible = true
	_error_container.visible = true
	_error_timer = 2.0

func _setup_slider() -> void:
	_slider = get_node_or_null("ui_slider_left")
	if not _slider:
		return
	_slider_open_x = _slider.position.x
	var arrow: Node2D = _slider.get_node_or_null("UiArrow")
	if arrow:
		_slider_closed_x = _slider_open_x - arrow.position.x + 6.0
	else:
		_slider_closed_x = _slider_open_x - _slider.size.x
	var btn: Button = Button.new()
	btn.flat = true
	if arrow and arrow is Sprite2D and (arrow as Sprite2D).texture:
		var t: Vector2 = (arrow as Sprite2D).texture.get_size()
		btn.position = arrow.position - t / 2.0
		btn.size = t
	else:
		btn.size = Vector2(32, 32)
	_slider.add_child(btn)
	btn.pressed.connect(_on_arrow_pressed)

func _setup_slider_right() -> void:
	_slider_right = get_node_or_null("ui_slider_right")
	if not _slider_right:
		return
	_slider_right_open_x = _slider_right.position.x
	var arrow: Node2D = _slider_right.get_node_or_null("UiArrow")
	if arrow:
		var leftmost: float = 0.0
		for child in _slider_right.get_children():
			var px: float = 0.0
			if child is Node2D:
				px = (child as Node2D).position.x
			elif child is Control:
				px = (child as Control).position.x
			leftmost = minf(leftmost, px)
		var vp_w: float = get_viewport_rect().size.x
		var slide_right: float = vp_w - _slider_right_open_x - leftmost - 8.0
		_slider_right_closed_x = _slider_right_open_x + slide_right
	else:
		_slider_right_closed_x = _slider_right_open_x + _slider_right.size.x
	var btn: Button = Button.new()
	btn.flat = true
	if arrow and arrow is Sprite2D and (arrow as Sprite2D).texture:
		var t: Vector2 = (arrow as Sprite2D).texture.get_size()
		btn.position = arrow.position - t / 2.0
		btn.size = t
	else:
		btn.size = Vector2(32, 32)
	_slider_right.add_child(btn)
	btn.pressed.connect(_on_arrow_right_pressed)

func _on_arrow_pressed() -> void:
	if not _slider:
		return
	_slider_is_collapsed = not _slider_is_collapsed
	var target_x: float = _slider_closed_x if _slider_is_collapsed else _slider_open_x
	var tween := create_tween()
	tween.tween_property(_slider, "position", Vector2(target_x, _slider.position.y), SLIDER_TWEEN_DURATION)

func _on_arrow_right_pressed() -> void:
	if not _slider_right:
		return
	_slider_right_is_collapsed = not _slider_right_is_collapsed
	var target_x: float = _slider_right_closed_x if _slider_right_is_collapsed else _slider_right_open_x
	var tween := create_tween()
	tween.tween_property(_slider_right, "position", Vector2(target_x, _slider_right.position.y), SLIDER_TWEEN_DURATION)

func _process(delta: float) -> void:
	if _error_timer < 0.0:
		return
	_error_timer -= delta
	if _error_timer <= 0.0:
		_error_timer = -1.0
		if _error_container:
			_error_container.visible = false
