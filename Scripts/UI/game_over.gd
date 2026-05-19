extends Control

@onready var score_label = $VBoxContainer/ScoreLabel
@onready var retry_btn = $VBoxContainer/RetryBtn
@onready var main_menu_btn = $VBoxContainer/MainMenuBtn

func _ready():
	AudioManager.play_game_over()
	if score_label:
		score_label.text = "Score: %d" % GameManager.score
	if retry_btn:
		retry_btn.pressed.connect(_on_retry)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu)

func _on_retry():
	var level_to_retry = GameManager.current_level
	GameManager.reset_game()
	GameManager.load_level(level_to_retry)

func _on_main_menu():
	GameManager.go_to_main_menu()
