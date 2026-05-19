extends Control

@onready var title_label = $VBoxContainer/TitleLabel
@onready var score_label = $VBoxContainer/ScoreLabel
@onready var gems_label = $VBoxContainer/GemsLabel
@onready var next_btn = $VBoxContainer/NextLevelBtn
@onready var menu_btn = $VBoxContainer/MainMenuBtn

var completed_level: int = 0

func _ready():
	completed_level = GameManager.current_level
	if title_label:
		title_label.text = "Level %d Complete!" % completed_level
	if score_label:
		score_label.text = "Score: %d" % GameManager.score
	if gems_label:
		gems_label.text = "Gems: %d" % GameManager.gems_collected
	if next_btn:
		next_btn.pressed.connect(_on_next_level)
		if completed_level >= GameManager.total_levels:
			next_btn.text = "You Win!"
	if menu_btn:
		menu_btn.pressed.connect(_on_main_menu)

	GameManager.complete_level()

func _on_next_level():
	if completed_level >= GameManager.total_levels:
		get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
	else:
		GameManager.load_level(GameManager.current_level)

func _on_main_menu():
	GameManager.go_to_main_menu()
