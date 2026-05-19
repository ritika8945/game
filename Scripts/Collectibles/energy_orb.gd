extends Area2D

@export var heal_amount: int = 1

var time_passed: float = 0.0

func _process(delta):
	time_passed += delta
	rotation = sin(time_passed * 3) * 0.2

func _on_body_entered(body):
	if body.is_in_group("Player"):
		GameManager.heal(heal_amount)
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
		tween.tween_property(self, "modulate:a", 0.0, 0.15)
		await tween.finished
		queue_free()
