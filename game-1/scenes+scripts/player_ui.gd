extends Control

var _bar_full: Sprite2D
var _tex_width: float
var _tex_height: float
var _initial_pos: Vector2
var _use_scale_x: bool = false
var _error_container: Control
var _error_timer: float = -1.0
var _current_health: float = 0.0
var _max_health: float = 0.0
var _healthbar_tooltip: PanelContainer
var _healthbar_hover_area: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp_rect: Rect2 = get_viewport_rect()
	set_position(Vector2.ZERO)
	set_size(vp_rect.size)
	_error_container = get_node_or_null("ErrorMessageOutline")
	_bar_full = get_node_or_null("ui_slider_left/healthbar/Healthbar_full")
	if _bar_full and _bar_full.texture:
		_tex_width = float(_bar_full.texture.get_width())
		_tex_height = float(_bar_full.texture.get_height())
		_use_scale_x = _tex_width > _tex_height
		_initial_pos = _bar_full.position
		_bar_full.region_enabled = true
		_bar_full.region_rect = Rect2(0, 0, _tex_width, _tex_height)
	_setup_healthbar_tooltip()
	_setup_healthbar_hover_area()

func update_health(current: float, max_val: float) -> void:
	_current_health = current
	_max_health = max_val
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

func _setup_healthbar_tooltip() -> void:
	_healthbar_tooltip = PanelContainer.new()
	_healthbar_tooltip.visible = false
	_healthbar_tooltip.z_index = 100
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.set_border_width_all(1)
	style.border_color = Color(0.4, 0.4, 0.5)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(6)
	_healthbar_tooltip.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	lbl.name = "HealthbarTooltipLabel"
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.custom_minimum_size = Vector2(36, 18)
	_healthbar_tooltip.add_child(lbl)
	add_child(_healthbar_tooltip)

func _setup_healthbar_hover_area() -> void:
	var ui_left: Control = get_node_or_null("ui_slider_left")
	if not ui_left or _tex_width <= 0 or _tex_height <= 0:
		return
	_healthbar_hover_area = Control.new()
	_healthbar_hover_area.mouse_filter = Control.MOUSE_FILTER_STOP
	# bar is rotated 90 deg, so visual bounding box has width/height swapped
	var w := _tex_height
	var h := _tex_width
	_healthbar_hover_area.set_position(Vector2(318.0 + 12.0 - w / 2.0, -5.0 + 273.0 - h / 2.0))
	_healthbar_hover_area.set_size(Vector2(w, h))
	_healthbar_hover_area.mouse_entered.connect(_on_healthbar_mouse_entered)
	_healthbar_hover_area.mouse_exited.connect(_on_healthbar_mouse_exited)
	ui_left.add_child(_healthbar_hover_area)

func _on_healthbar_mouse_entered() -> void:
	if not _healthbar_tooltip:
		return
	var lbl: Label = _healthbar_tooltip.get_node_or_null("HealthbarTooltipLabel")
	if lbl:
		lbl.text = "%d/%d" % [int(_current_health), int(_max_health)]
	_healthbar_tooltip.visible = true
	if _healthbar_hover_area:
		var pad := 8
		_healthbar_tooltip.global_position = _healthbar_hover_area.global_position + Vector2((_healthbar_hover_area.size.x -5) + pad, _healthbar_hover_area.size.y - 30)

func _on_healthbar_mouse_exited() -> void:
	if _healthbar_tooltip:
		_healthbar_tooltip.visible = false

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
