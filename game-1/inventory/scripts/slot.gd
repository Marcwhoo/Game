extends PanelContainer

@onready var texture_rect: TextureRect = $MarginContainer/TextureRect

var panel_is_in_this_inventory: InventoryObject
var this_panels_type: String = self.name
var panels_index: int

signal slot_panel_left_clicked()
signal slot_panel_right_clicked()
signal tooltip_show(rect: Rect2i, item_object: ItemObject)
signal tooltip_hide()

var item_object: ItemObject

func _ready() -> void:
	this_panels_type = self.name
	if this_panels_type == "Ring2":
		this_panels_type = "Ring"

func update_placeholder_visibility() -> void:
	var background_node: Node = find_child("Background", true, false)
	if background_node:
		background_node.visible = not item_object
	var punchhole_node: Node = find_child("punchhole", true, false)
	if punchhole_node:
		punchhole_node.visible = item_object != null

func fill_item(grabbed_slot: Node) -> void:
	if grabbed_slot.item_object:
		item_object = grabbed_slot.item_object
		texture_rect.texture = grabbed_slot.item_object.texture
		panel_is_in_this_inventory.items_in_inventory[panels_index] = item_object
		update_placeholder_visibility()
	else:
		remove_item()

func remove_item() -> void:
	item_object = null
	texture_rect.texture = null
	panel_is_in_this_inventory.items_in_inventory[panels_index] = null
	var punchhole_node: Node = find_child("punchhole", true, false)
	if punchhole_node:
		punchhole_node.visible = false
	update_placeholder_visibility()

func swap_item(grabbed_slot: Node) -> void:
	var temp_item: ItemObject = item_object
	fill_item(grabbed_slot)
	grabbed_slot.item_object = temp_item
	grabbed_slot.texture_rect.texture = grabbed_slot.item_object.texture if grabbed_slot.item_object else null
	grabbed_slot.update_placeholder_visibility()

func _on_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.is_pressed():
		return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			slot_panel_left_clicked.emit(self)
		MOUSE_BUTTON_RIGHT:
			slot_panel_right_clicked.emit(self)

func _on_mouse_entered() -> void:
	if item_object:
		tooltip_show.emit(Rect2i(Vector2i(global_position), Vector2i(size)), item_object)

func _on_mouse_exited() -> void:
	tooltip_hide.emit()
