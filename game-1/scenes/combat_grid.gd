extends TileMapLayer

const CELL_SIZE := Vector2(64, 32)
const WINDOW_SIZE := Vector2(640, 360)
const FRAME_WIDTH := 1

signal cell_clicked(cell: Vector2i)

var _hovered_cell := Vector2i(-999, -999)
var occupants: Dictionary = {}  # Vector2i -> Array[Node]
var blocked_cells: Dictionary = {}  # Vector2i -> true (drawn red)
var silent_blocked_cells: Dictionary = {}  # Vector2i -> true (no visual)

@export var debug_grid: TileMapLayer
@export var red_marker_source_id: int = 0  # this source = collision with red mark; other sources = collision without mark

func _ready() -> void:
	if debug_grid:
		for cell in debug_grid.get_used_cells():
			var sid := debug_grid.get_cell_source_id(cell)
			if sid == red_marker_source_id:
				set_cell_walkable(cell, false)
			else:
				set_cell_walkable_silent(cell, false)

func _process(_delta: float) -> void:
	var parent_2d := get_parent() as Node2D
	if not parent_2d:
		return
	var local_mouse := parent_2d.to_local(parent_2d.get_global_mouse_position())
	var cell := local_to_map(local_mouse)
	if cell != _hovered_cell:
		_hovered_cell = cell
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var parent_2d := get_parent() as Node2D
			if not parent_2d:
				return
			var global_click := parent_2d.get_global_mouse_position()
			var cell := world_to_cell(global_click)
			var cols := int(WINDOW_SIZE.x / CELL_SIZE.x)
			var rows := int(WINDOW_SIZE.y / CELL_SIZE.y)
			if cell.x >= 0 and cell.x < cols and cell.y >= 0 and cell.y < rows:
				cell_clicked.emit(cell)

func world_to_cell(global_pos: Vector2) -> Vector2i:
	var parent_2d := get_parent() as Node2D
	if not parent_2d:
		return Vector2i(-999, -999)
	return local_to_map(parent_2d.to_local(global_pos))

func cell_to_world(cell: Vector2i) -> Vector2:
	var parent_2d := get_parent() as Node2D
	if not parent_2d:
		return Vector2.ZERO
	return parent_2d.to_global(map_to_local(cell))

func _draw() -> void:
	var cols := int(WINDOW_SIZE.x / CELL_SIZE.x)
	var rows := int(WINDOW_SIZE.y / CELL_SIZE.y)
	var blocked_color := Color(1.0, 0.0, 0.0, 0.35)

	for col in cols:
		for row in rows:
			var cell := Vector2i(col, row)
			if blocked_cells.has(cell):
				var cell_pos := Vector2(col * CELL_SIZE.x, row * CELL_SIZE.y)
				draw_rect(Rect2(cell_pos, CELL_SIZE), blocked_color)

	if _hovered_cell.x >= 0 and _hovered_cell.x < cols and _hovered_cell.y >= 0 and _hovered_cell.y < rows and is_cell_walkable(_hovered_cell):
		var frame_color := Color.WHITE
		var cell_pos := Vector2(_hovered_cell.x * CELL_SIZE.x, _hovered_cell.y * CELL_SIZE.y)
		draw_rect(Rect2(cell_pos.x, cell_pos.y, CELL_SIZE.x, FRAME_WIDTH), frame_color)
		draw_rect(Rect2(cell_pos.x, cell_pos.y + CELL_SIZE.y - FRAME_WIDTH, CELL_SIZE.x, FRAME_WIDTH), frame_color)
		draw_rect(Rect2(cell_pos.x, cell_pos.y, FRAME_WIDTH, CELL_SIZE.y), frame_color)
		draw_rect(Rect2(cell_pos.x + CELL_SIZE.x - FRAME_WIDTH, cell_pos.y, FRAME_WIDTH, CELL_SIZE.y), frame_color)
	
func register_occupant(who: Node, cell: Vector2i) -> void:
	if not occupants.has(cell):
		occupants[cell] = []
	var list: Array = occupants[cell]
	if who not in list:
		list.append(who)

func unregister_occupant(who: Node, cell: Vector2i) -> void:
	if not occupants.has(cell):
		return
	occupants[cell].erase(who)

func get_occupants_at(cell: Vector2i) -> Array:
	return occupants.get(cell, []).duplicate()

func is_cell_empty(cell: Vector2i) -> bool:
	return get_occupants_at(cell).is_empty()
	
func move_occupant(who: Node, from_cell: Vector2i, to_cell: Vector2i) -> void:
	unregister_occupant(who, from_cell)
	register_occupant(who, to_cell)
	
func set_cell_walkable(cell: Vector2i, walkable: bool) -> void:
	if walkable:
		blocked_cells.erase(cell)
	else:
		blocked_cells[cell] = true
	queue_redraw()

func set_cell_walkable_silent(cell: Vector2i, walkable: bool) -> void:
	if walkable:
		silent_blocked_cells.erase(cell)
	else:
		silent_blocked_cells[cell] = true

func is_cell_walkable(cell: Vector2i) -> bool:
	return not blocked_cells.has(cell) and not silent_blocked_cells.has(cell)

func _get_bounds() -> Vector2i:
	var cols := int(WINDOW_SIZE.x / CELL_SIZE.x)
	var rows := int(WINDOW_SIZE.y / CELL_SIZE.y)
	return Vector2i(cols, rows)

func cell_distance(cell_a: Vector2i, cell_b: Vector2i) -> int:
	var d := cell_b - cell_a
	return maxi(absi(d.x), absi(d.y))

func is_cell_in_range(from_cell: Vector2i, to_cell: Vector2i, min_range: int, max_range: int) -> bool:
	var d := cell_distance(from_cell, to_cell)
	return d >= min_range and d <= max_range

func get_cells_in_range(from_cell: Vector2i, min_range: int, max_range: int) -> Array[Vector2i]:
	var bounds := _get_bounds()
	var out: Array[Vector2i] = []
	for dx in range(-max_range, max_range + 1):
		for dy in range(-max_range, max_range + 1):
			var c := from_cell + Vector2i(dx, dy)
			if c.x < 0 or c.y < 0 or c.x >= bounds.x or c.y >= bounds.y:
				continue
			var dist := cell_distance(from_cell, c)
			if dist >= min_range and dist <= max_range:
				out.append(c)
	return out
