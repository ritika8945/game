extends Node

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal health_changed(new_health: int)
signal level_completed(level_index: int)
signal game_over

var score: int = 0
var lives: int = 3
var max_lives: int = 5
var health: int = 3
var max_health: int = 3
var current_level: int = 1
var total_levels: int = 5
var is_paused: bool = false
var gems_collected: int = 0
var enemies_defeated: int = 0

var level_scenes: Array[String] = [
	"res://Scenes/Levels/Level_01.tscn",
	"res://Scenes/Levels/Level_02.tscn",
	"res://Scenes/Levels/Level_03.tscn",
	"res://Scenes/Levels/Level_04.tscn",
	"res://Scenes/Levels/Level_05.tscn"
]

var level_names: Array[String] = [
	"City Rooftops",
	"Jungle Ruins",
	"School Chaos",
	"Space Factory",
	"Lava Lab"
]

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func reset_game():
	score = 0
	lives = 3
	health = max_health
	current_level = 1
	gems_collected = 0
	enemies_defeated = 0
	is_paused = false
	emit_signal("score_changed", score)
	emit_signal("lives_changed", lives)
	emit_signal("health_changed", health)

func add_score(amount: int = 1):
	score += amount
	emit_signal("score_changed", score)

func add_gem():
	gems_collected += 1
	add_score(10)

func defeat_enemy():
	enemies_defeated += 1
	add_score(25)

func take_damage(amount: int = 1):
	health -= amount
	emit_signal("health_changed", health)
	if health <= 0:
		lose_life()

func heal(amount: int = 1):
	health = min(health + amount, max_health)
	emit_signal("health_changed", health)

func lose_life():
	lives -= 1
	emit_signal("lives_changed", lives)
	if lives <= 0:
		emit_signal("game_over")
	else:
		health = max_health
		emit_signal("health_changed", health)

func add_life():
	lives = min(lives + 1, max_lives)
	emit_signal("lives_changed", lives)

func complete_level():
	VoiceManager.stop_bg_music()
	emit_signal("level_completed", current_level)
	SaveManager.save_level_progress(current_level)
	if current_level < total_levels:
		current_level += 1

func load_level(level_index: int):
	if level_index >= 1 and level_index <= total_levels:
		current_level = level_index
		health = max_health
		score = 0
		gems_collected = 0
		emit_signal("health_changed", health)
		emit_signal("score_changed", score)
		VoiceManager.start_bg_music()
		var scene = load(level_scenes[level_index - 1])
		if scene:
			get_tree().change_scene_to_packed(scene)

func load_next_level(next_scene: PackedScene = null):
	if next_scene:
		get_tree().change_scene_to_packed(next_scene)
	elif current_level < total_levels:
		load_level(current_level + 1)

func restart_level():
	health = max_health
	score = 0
	gems_collected = 0
	emit_signal("health_changed", health)
	emit_signal("score_changed", score)
	get_tree().reload_current_scene()

func go_to_main_menu():
	is_paused = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
