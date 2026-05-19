extends Area2D

@export var activated_color: Color = Color.GREEN
var is_activated: bool = false

@onready var sprite = $Sprite2D

func _ready():
	add_to_group("Checkpoints")

func _on_body_entered(body):
	if body.is_in_group("Player") and not is_activated:
		is_activated = true
		body.update_checkpoint(global_position + Vector2(0, -32))
		if sprite:
			sprite.modulate = activated_color
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(self, "scale", Vector2.ONE, 0.1)
