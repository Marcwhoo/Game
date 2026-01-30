@tool
extends TileMapLayer

const CELL_SIZE := Vector2(64, 32)
const WINDOW_SIZE := Vector2(640, 360)
const FRAME_WIDTH := 1

@export var red_tile_source_id: int = 0
@export var white_tile_source_id: int = 1

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
	else:
		visible = false
		process_mode = PROCESS_MODE_DISABLED

func _draw() -> void:
	var cols := int(WINDOW_SIZE.x / CELL_SIZE.x)
	var rows := int(WINDOW_SIZE.y / CELL_SIZE.y)
	var frame_color := Color.WHITE

	for i in cols + 1:
		var x := i * CELL_SIZE.x
		draw_rect(Rect2(x, 0, FRAME_WIDTH, WINDOW_SIZE.y), frame_color)
	for j in rows + 1:
		var y := j * CELL_SIZE.y
		draw_rect(Rect2(0, y, WINDOW_SIZE.x, FRAME_WIDTH), frame_color)

	for col in cols:
		for row in rows:
			var cell := Vector2i(col, row)
			var cell_pos := Vector2(col * CELL_SIZE.x, row * CELL_SIZE.y)
			var sid := get_cell_source_id(cell)
			if sid == red_tile_source_id:
				draw_rect(Rect2(cell_pos, CELL_SIZE), Color(0.6, 0.0, 0.0, 0.4))
			elif sid == white_tile_source_id:
				draw_rect(Rect2(cell_pos, CELL_SIZE), Color(0.85, 0.85, 0.85, 0.35))
			var text := "%d,%d" % [col, row]
			var font := ThemeDB.fallback_font
			var font_size := 9
			var text_size := Vector2(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size))
			var center := cell_pos + CELL_SIZE / 2
			var ascent := font.get_ascent(font_size)
			var descent := font.get_descent(font_size)
			var baseline_y := center.y + (ascent - descent) / 2.0
			var text_pos := Vector2(center.x - text_size.x / 2.0, baseline_y)
			draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
