extends Resource

class_name ItemObject

@export var name: String
@export_multiline var discription: String
@export var texture: AtlasTexture
@export var damage: int =0
@export var armor: int =0
@export var cost: int
@export var move_speed: int
@export var playerattack_movement_speed: int
@export var attack_speed: float
@export_enum("Normal", "Heavy", "Whirl") var weapon_type: String

@export_enum("Poor","Common", "Rare", "Epic", "Legendary", "Set") var rarity: String
@export_enum("Helmet","Necklace", "Chest", "Legs", "Shoes", "Ring", "Ring", "Weapon") var type: String
#@export var type_test: Array = ["hallo", "wasgeht"]
