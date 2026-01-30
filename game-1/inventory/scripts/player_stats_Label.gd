extends PanelContainer

@onready var movementspeed_label: Label = %MovementspeedLabel
@onready var attackspeed_label: Label = %AttackspeedLabel
@onready var health_label: Label = %HealthLabel
@onready var armor_label: Label = %ArmorLabel
@onready var damage_label: Label = %DamageLabel

func update_from_player(p: Node) -> void:
	if not p or not p.has_method("get_display_stats"):
		return
	var stats: Dictionary = p.get_display_stats()
	armor_label.text = str(stats.get("armor", 0))
	attackspeed_label.text = str(stats.get("attackspeed", 0)) + "/s"
	damage_label.text = str(stats.get("damage", 0))
	movementspeed_label.text = str(stats.get("movementspeed", 0) / 2) + "%"
	health_label.text = str(stats.get("max_health", 0))
