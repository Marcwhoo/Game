extends Control
@onready var item_tooltip: PanelContainer = %ItemTooltip 

var poor = Color(157/255.0, 157/255.0, 157/255.0)
var common = Color(255/255.0,255/255.0,255/255.0)
var rare = Color(0/255.0,112/255.0,221/255.0)
var epic = Color(163/255.0,53/255.0,238/255.0)
var legendary = Color(255/255.0,128/255.0,0/255.0)
var sets = Color(30/255.0,255/255.0,0/255.0)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	%ItemTooltip.visible = false

const TOOLTIP_SCALE := 0.4
const MOUSE_OFFSET_RIGHT := 8
const MOUSE_OFFSET_ABOVE := 4
const TOOLTIP_APPROX_SIZE := Vector2(288, 358)

func show_tooltip(slot: Rect2i, item: ItemObject) -> void:
	if item:
		set_value(item)
	%ItemTooltip.size = Vector2i.ZERO
	%ItemTooltip.scale = Vector2(TOOLTIP_SCALE, TOOLTIP_SCALE)
	var mouse := get_global_mouse_position()
	var tt_size := TOOLTIP_APPROX_SIZE * TOOLTIP_SCALE
	var gp := Vector2(mouse.x + MOUSE_OFFSET_RIGHT, mouse.y - tt_size.y - MOUSE_OFFSET_ABOVE)
	var vp_rect := get_viewport_rect()
	gp.x = clampf(gp.x, 0.0, vp_rect.size.x - tt_size.x)
	gp.y = clampf(gp.y, 0.0, vp_rect.size.y - tt_size.y)
	%ItemTooltip.position = gp - get_global_position()
	%ItemTooltip.visible = true

func hide_tooltip() -> void:
	%ItemTooltip.visible = false

func set_value(item:ItemObject)->void:

	%Name.text=item.name
	%DamageValue.text="Damage:"
	
	if item.damage!=0: 
		%DamageValue.text=str(item.damage)
		%DamageH.show()
	else: %DamageH.hide()
	
	if item.armor!=0: 
		%ArmorValue.text=str(item.armor)
		%ArmorH.show()
	else: %ArmorH.hide()
	
	if item.attack_speed!=0: 
		%AtkSpdValue.text=str(item.attack_speed)
		%AtkSpdH.show()
	else: %AtkSpdH.hide()
	
	if item.move_speed != 0: 
		%MovespeedValue.text=str(item.move_speed)
		%MoveSpeedH.show()
	else: %MoveSpeedH.hide()
	
	if item.playerattack_movement_speed != 0: 
		%AtkMovespeedValue.text=str(item.playerattack_movement_speed)
		%AtkMoveSpeedH.show()
	else: %AtkMoveSpeedH.hide()
	
	%CostValue.text=str(item.cost)
	
	var rarity_color: Color
	
	%Type.text = item.type

	match item.rarity:
		"Poor":
			rarity_color = poor
		"Common": 
			rarity_color = common
		"Rare":
			rarity_color = rare
		"Epic": 
			rarity_color = epic
		"Legendary": 
			rarity_color = legendary
		"Set": 
			rarity_color = sets
			
	%Rarity.text = item.rarity
	%Name.add_theme_color_override("font_color", rarity_color)
	%Rarity.add_theme_color_override("font_color", rarity_color)
	
	var style = item_tooltip.get_theme_stylebox("panel").duplicate()
	if style is StyleBoxFlat:
		style.set_border_color(rarity_color)
		item_tooltip.add_theme_stylebox_override("panel", style)
