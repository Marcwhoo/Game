extends RigidBody2D

@export var item_object: ItemObject
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var legendary_particles: CPUParticles2D = $LegendaryParticles
@onready var set_particles: CPUParticles2D = $SetParticles

func _ready() -> void:
	sprite_2d.texture = item_object.texture
	drop_animation()
	
func player_interact() -> void:
	pass

func drop_animation()->void:
	animation_player.play("drop_animation")



func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	if item_object.rarity =="Legendary":
		legendary_particles.emitting=true
	elif item_object.rarity=="Set":
		set_particles.emitting=true
