extends Control

const SLOT = preload("res://inventory/scenes/slot.tscn")

@export_range(0.25, 2.0, 0.05) var ui_scale: float = 1.0
@export var players_equipment_inv_object: InventoryObject

var player: Node
@export var players_inv_object: InventoryObject
@export var shop_buy_inv_object: InventoryObject
@export var shop_sold_inv_object: InventoryObject

@onready var shop_sold_grid_container: GridContainer = %ShopSoldGridContainer
@onready var shop_ui: TabContainer = %ShopUI
@onready var player_stats: PanelContainer = %PlayerStats
@onready var shop_sold_inventory_panel: Control = %ShopSellInventoryPanel
@onready var shop_buy_inventory_panel: Control = %ShopBuyInventoryPanel
@onready var player_equipment_panel: Control = %PlayerEquipmentPanel
@onready var players_inventory_panel: MarginContainer = %PlayersInventoryPanel
@onready var grabbed_slot: PanelContainer = $GrabbedSlot

var grabbed_item_from_shop: bool = false
var last_pickedup_slotpanel: Node

func _ready() -> void:
	scale = Vector2(ui_scale, ui_scale)
	var p: Node = get_parent()
	while p:
		if p.is_in_group("player"):
			player = p
			break
		p = p.get_parent()
	set_inventory_info(players_inv_object, players_inventory_panel)
	set_inventory_info(shop_buy_inv_object, shop_buy_inventory_panel)
	set_inventory_info(shop_sold_inv_object, shop_sold_inventory_panel)
	set_inventory_info(players_equipment_inv_object, player_equipment_panel)
	_refresh_money_label()
	shop_ui.set_tab_title(0, "Buy Items")
	shop_ui.set_tab_title(1, "Sold Items")
	_update_stats_panel()
	_connect_slot_signals_for_tooltip()

func _physics_process(_delta: float) -> void:
	update_grabbed_slot_visibility()

func _connect_slot_signals_for_tooltip() -> void:
	for slot in _collect_all_slots():
		if slot.has_signal("tooltip_show"):
			slot.tooltip_show.connect(_on_slot_tooltip_show)
		if slot.has_signal("tooltip_hide"):
			slot.tooltip_hide.connect(_on_slot_tooltip_hide)

func _collect_all_slots() -> Array:
	var out: Array = []
	var panels: Array = [players_inventory_panel, player_equipment_panel, shop_buy_inventory_panel, shop_sold_inventory_panel]
	for p in panels:
		for s in get_all_slot_nodes_from_panel(p):
			out.append(s)
	return out

func _on_slot_tooltip_show(rect: Rect2i, item_object: ItemObject) -> void:
	var popup_node: Node = get_parent().get_parent().get_node_or_null("popup")
	if popup_node and popup_node.has_method("show_tooltip"):
		popup_node.show_tooltip(rect, item_object)

func _on_slot_tooltip_hide() -> void:
	var popup_node: Node = get_parent().get_parent().get_node_or_null("popup")
	if popup_node and popup_node.has_method("hide_tooltip"):
		popup_node.hide_tooltip()

func _refresh_money_label() -> void:
	if player and player.get("money") != null:
		%MoneyPanel.text = "money: " + str(player.money)

func set_inventory_info(inventory_object: InventoryObject, inventory_panel: Control) -> void:
	var slot_panels: Array = get_all_slot_nodes_from_panel(inventory_panel)
	var objs_in_inv_obj: Array = inventory_object.items_in_inventory
	populate_inventory_panels(slot_panels, slot_panels.size(), objs_in_inv_obj, inventory_object)

func get_all_slot_nodes_from_panel(inventory_panel: Control) -> Array:
	var nodes_in_group_slot: Array = []
	var queue: Array = [inventory_panel]
	var index: int = 0
	while not queue.is_empty():
		var current_node = queue.pop_front()
		if current_node.is_in_group("slot"):
			nodes_in_group_slot.append(current_node)
			current_node.panels_index = index
			index += 1
		for child in current_node.get_children():
			queue.push_back(child)
	return nodes_in_group_slot

func populate_inventory_panels(slot_panels: Array, slot_panels_amount: int, objs_in_inv_obj: Array, inventory_object: InventoryObject) -> void:
	for index in slot_panels_amount:
		slot_panels[index].panel_is_in_this_inventory = inventory_object
		if index < objs_in_inv_obj.size() and objs_in_inv_obj[index]:
			slot_panels[index].item_object = objs_in_inv_obj[index]
			slot_panels[index].texture_rect.texture = objs_in_inv_obj[index].texture
			slot_panels[index].update_placeholder_visibility()
		else:
			slot_panels[index].item_object = null
			slot_panels[index].texture_rect.texture = null
			slot_panels[index].update_placeholder_visibility()

func _on_slot_slot_panel_right_clicked(slot_panel: Node) -> void:
	match slot_panel.panel_is_in_this_inventory:
		players_equipment_inv_object:
			transfer_item_from_equip_to_player_inventar(slot_panel)
		players_inv_object:
			handle_players_inventory_interactions_rightclick(slot_panel)
		shop_buy_inv_object:
			transfer_item_from_shop_to_player_inventory(slot_panel)
		shop_sold_inv_object:
			transfer_item_from_shop_to_player_inventory(slot_panel)
	_on_equipment_or_money_changed()

func _on_slot_slot_panel_left_clicked(slot_panel: Node) -> void:
	match slot_panel.panel_is_in_this_inventory:
		players_equipment_inv_object:
			handle_players_equipment_interactions(slot_panel)
		players_inv_object:
			handle_players_inventory_interactions(slot_panel)
		shop_buy_inv_object:
			handle_shop_buy_interactions(slot_panel)
		shop_sold_inv_object:
			handle_shop_sold_interactions(slot_panel)

func _on_equipment_or_money_changed() -> void:
	if player and player.has_method("refresh_stats_from_equipment"):
		player.refresh_stats_from_equipment()
	_refresh_money_label()
	_update_stats_panel()

func handle_players_equipment_interactions(slot_panel: Node) -> void:
	if not grabbed_slot.item_object and slot_panel.item_object:
		handle_item_pickup(slot_panel)
	elif grabbed_slot.item_object and not slot_panel.item_object:
		drop_item_to_player_equipment(slot_panel)
	elif grabbed_slot.item_object and slot_panel.item_object:
		swap_player_equipment_with_grabbed(slot_panel)
	_on_equipment_or_money_changed()

func handle_players_inventory_interactions(slot_panel: Node) -> void:
	if not grabbed_slot.item_object and slot_panel.item_object:
		handle_item_pickup(slot_panel)
	elif grabbed_slot.item_object and not slot_panel.item_object:
		drop_item_to_player_inventory(slot_panel)
	elif grabbed_slot.item_object and slot_panel.item_object:
		swap_player_inventory_with_grabbed(slot_panel)

func handle_shop_buy_interactions(slot_panel: Node) -> void:
	if not grabbed_slot.item_object and slot_panel.item_object:
		handle_item_pickup(slot_panel)
	elif grabbed_slot.item_object and not slot_panel.item_object:
		drop_item_to_shop_sold(slot_panel)

func handle_shop_sold_interactions(slot_panel: Node) -> void:
	if not grabbed_slot.item_object and slot_panel.item_object:
		handle_item_pickup(slot_panel)
	elif grabbed_slot.item_object and not slot_panel.item_object:
		drop_item_to_shop_sold(slot_panel)

func handle_item_pickup(slot_panel: Node) -> void:
	fill_grabbed_slot(slot_panel)
	slot_panel.remove_item()
	last_pickedup_slotpanel = slot_panel
	grabbed_item_from_shop = slot_panel.panel_is_in_this_inventory in [shop_buy_inv_object, shop_sold_inv_object]

func transfer_item_from_equip_to_player_inventar(slot_panel: Node) -> void:
	var slot_panels: Array = get_all_slot_nodes_from_panel(players_inventory_panel)
	for slot in slot_panels:
		if not slot.item_object and slot_panel.item_object:
			slot.fill_item(slot_panel)
			slot_panel.remove_item()
			_on_equipment_or_money_changed()
			return

func handle_players_inventory_interactions_rightclick(slot_panel: Node) -> void:
	if shop_ui.visible:
		transfer_item_to_shop_sold(slot_panel)
	else:
		transfer_item_to_player_equipment(slot_panel)

func transfer_item_from_shop_to_player_inventory(slot_panel: Node) -> void:
	if not player or player.get("money") == null:
		return
	var slot_panels: Array = get_all_slot_nodes_from_panel(players_inventory_panel)
	for slot in slot_panels:
		if not slot.item_object and slot_panel.item_object and player.money >= slot_panel.item_object.cost:
			player.money -= slot_panel.item_object.cost
			slot.fill_item(slot_panel)
			slot_panel.remove_item()
			shop_sold_inv_cleanup()
			_on_equipment_or_money_changed()
			return

func transfer_item_to_shop_sold(slot_panel: Node) -> void:
	var slot_panels: Array = get_all_slot_nodes_from_panel(shop_sold_inventory_panel)
	var empty_panels: int = 0
	for slot in slot_panels:
		if not slot.item_object:
			empty_panels += 1
		if slot_panel.item_object and not slot.item_object:
			if player:
				player.money += slot_panel.item_object.cost
			slot.fill_item(slot_panel)
			slot_panel.remove_item()
			_on_equipment_or_money_changed()
			break
	if empty_panels <= 1:
		create_and_setup_new_slot(shop_sold_grid_container, shop_sold_inv_object)
		set_inventory_info(shop_sold_inv_object, shop_sold_inventory_panel)

func transfer_item_to_player_equipment(slot_panel_clicked: Node) -> void:
	var temp_slot_panel: Node = slot_panel_clicked.duplicate()
	temp_slot_panel.item_object = slot_panel_clicked.item_object
	var slot_panels: Array = get_all_slot_nodes_from_panel(player_equipment_panel)
	for slot in slot_panels:
		if slot_panel_clicked.item_object and slot_panel_clicked.item_object.type == slot.this_panels_type:
			slot_panel_clicked.fill_item(slot)
			slot.fill_item(temp_slot_panel)
			temp_slot_panel.queue_free()
			_on_equipment_or_money_changed()
			return

func drop_item_to_player_inventory(slot_panel: Node) -> void:
	if grabbed_item_from_shop:
		buy_item_from_shop(slot_panel)
	else:
		slot_panel.fill_item(grabbed_slot)
		empty_grabbed_slot()

func swap_player_inventory_with_grabbed(slot_panel: Node) -> void:
	if last_pickedup_slotpanel.panel_is_in_this_inventory != shop_buy_inv_object:
		slot_panel.swap_item(grabbed_slot)

func buy_item_from_shop(slot_panel: Node) -> void:
	if not player or grabbed_slot.item_object == null:
		return
	if player.money >= grabbed_slot.item_object.cost:
		player.money -= grabbed_slot.item_object.cost
		slot_panel.fill_item(grabbed_slot)
		empty_grabbed_slot()
		shop_sold_inv_cleanup()
		_on_equipment_or_money_changed()

func drop_item_to_player_equipment(slot_panel: Node) -> void:
	if grabbed_slot.item_object and grabbed_slot.item_object.type == slot_panel.this_panels_type:
		if grabbed_item_from_shop:
			buy_item_from_shop(slot_panel)
		else:
			slot_panel.fill_item(grabbed_slot)
			empty_grabbed_slot()
			_on_equipment_or_money_changed()

func swap_player_equipment_with_grabbed(slot_panel: Node) -> void:
	if last_pickedup_slotpanel.panel_is_in_this_inventory != shop_buy_inv_object and grabbed_slot.item_object and grabbed_slot.item_object.type == slot_panel.this_panels_type:
		slot_panel.swap_item(grabbed_slot)
		_on_equipment_or_money_changed()

func drop_item_to_shop_sold(_slot_panel: Node) -> void:
	if last_pickedup_slotpanel.panel_is_in_this_inventory in [shop_buy_inv_object, shop_sold_inv_object]:
		last_pickedup_slotpanel.fill_item(grabbed_slot)
		empty_grabbed_slot()
	else:
		var slot_panels: Array = get_all_slot_nodes_from_panel(shop_sold_inventory_panel)
		for slot in slot_panels:
			if not slot.item_object and grabbed_slot.item_object:
				if player:
					player.money += grabbed_slot.item_object.cost
				slot.fill_item(grabbed_slot)
				empty_grabbed_slot()
				_on_equipment_or_money_changed()
				break
		var remaining: int = 0
		for s in slot_panels:
			if s.item_object:
				remaining += 1
		if remaining <= 1:
			create_and_setup_new_slot(shop_sold_grid_container, shop_sold_inv_object)
			set_inventory_info(shop_sold_inv_object, shop_sold_inventory_panel)

func shop_sold_inv_cleanup() -> void:
	var remaining_item_objects: Array = []
	for item_object in shop_sold_inv_object.items_in_inventory:
		if item_object != null:
			remaining_item_objects.append(item_object)
	shop_sold_inv_object.items_in_inventory.clear()
	for item_object in remaining_item_objects:
		shop_sold_inv_object.items_in_inventory.append(item_object)
	var slot_panels: Array = get_all_slot_nodes_from_panel(shop_sold_inventory_panel)
	var to_remove: Array = []
	for i in range(slot_panels.size()):
		if i < remaining_item_objects.size():
			slot_panels[i].item_object = remaining_item_objects[i]
			slot_panels[i].texture_rect.texture = remaining_item_objects[i].texture if remaining_item_objects[i] else null
		else:
			slot_panels[i].item_object = null
			slot_panels[i].texture_rect.texture = null
			to_remove.append(slot_panels[i])
	for slot in to_remove:
		shop_sold_grid_container.remove_child(slot)
		slot.queue_free()
	create_and_setup_new_slot(shop_sold_grid_container, shop_sold_inv_object)
	set_inventory_info(shop_sold_inv_object, shop_sold_inventory_panel)

func update_grabbed_slot_visibility() -> void:
	if grabbed_slot.item_object:
		grabbed_slot.global_position = get_global_mouse_position() + Vector2(5, 5)
		grabbed_slot.show()
	else:
		grabbed_slot.hide()

func create_and_setup_new_slot(where_to_put_slot: Node, inventory_object: InventoryObject) -> void:
	var new_slot: Node = SLOT.instantiate()
	where_to_put_slot.add_child(new_slot)
	inventory_object.items_in_inventory.append(null)
	new_slot.slot_panel_left_clicked.connect(_on_slot_slot_panel_left_clicked)
	new_slot.slot_panel_right_clicked.connect(_on_slot_slot_panel_right_clicked)
	if new_slot.has_signal("tooltip_show"):
		new_slot.tooltip_show.connect(_on_slot_tooltip_show)
	if new_slot.has_signal("tooltip_hide"):
		new_slot.tooltip_hide.connect(_on_slot_tooltip_hide)

func fill_grabbed_slot(slot_panel: Node) -> void:
	grabbed_slot.item_object = slot_panel.item_object
	grabbed_slot.texture_rect.texture = grabbed_slot.item_object.texture if grabbed_slot.item_object else null

func empty_grabbed_slot() -> void:
	grabbed_slot.item_object = null
	grabbed_slot.texture_rect.texture = null

func _update_stats_panel() -> void:
	if player_stats and player_stats.has_method("update_from_player") and player:
		player_stats.update_from_player(player)
