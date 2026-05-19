extends Area2D

@export var next_scene: PackedScene
@export var is_boss_door: bool = false

func _on_body_entered(body):
	if body.is_in_group("Player"):
		get_tree().call_group("Player", "level_complete_tween")
		AudioManager.play_level_complete()
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://Scenes/UI/LevelComplete.tscn")
