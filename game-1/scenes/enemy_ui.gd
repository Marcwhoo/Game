extends Control

var _bar_full: Sprite2D
var _tex_width: float
var _tex_height: float
var _initial_pos: Vector2
var _use_scale_x: bool = false

func _ready() -> void:
	_bar_full = $HealthbarEnemyFull
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
