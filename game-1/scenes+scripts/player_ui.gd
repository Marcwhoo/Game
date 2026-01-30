extends Control

var _bar_full: Sprite2D
var _tex_width: float
var _tex_height: float
var _initial_pos: Vector2
var _use_scale_x: bool = false
var _error_container: Control
var _error_timer: float = -1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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

func _process(delta: float) -> void:
	if _error_timer < 0.0:
		return
	_error_timer -= delta
	if _error_timer <= 0.0:
		_error_timer = -1.0
		if _error_container:
			_error_container.visible = false
