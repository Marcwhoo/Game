extends Node

# Viewport bleibt 640x360; Fenster startet HD, skalierbar bis 1440p
func _ready() -> void:
	call_deferred("_apply_window_limits")

func _apply_window_limits() -> void:
	var win := get_window()
	win.min_size = Vector2i(1280, 720)
	win.max_size = Vector2i(2560, 1440)
	win.size = Vector2i(1280, 720)