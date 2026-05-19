extends Area2D

@export var amplitude := 4
@export var frequency := 5
@export var score_value := 10

var time_passed = 0
var initial_position := Vector2.ZERO

func _ready():
	initial_position = position
	add_to_group("Collectibles")

func _process(delta):
	time_passed += delta
	var new_y = initial_position.y + amplitude * sin(frequency * time_passed)
	position.y = new_y

func _on_body_entered(body):
	if body.is_in_group("Player"):
		AudioManager.play_coin_pickup()
		GameManager.add_gem()
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
		await tween.finished
		queue_free()
