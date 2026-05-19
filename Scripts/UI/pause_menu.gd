extends Control

@onready var resume_btn = $PanelContainer/VBoxContainer/ResumeBtn
@onready var restart_btn = $PanelContainer/VBoxContainer/RestartBtn
@onready var main_menu_btn = $PanelContainer/VBoxContainer/MainMenuBtn

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if resume_btn:
		resume_btn.pressed.connect(_on_resume)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu)

func _input(event):
	if event.is_action_pressed("ui_pause"):
		toggle_pause()

func toggle_pause():
	GameManager.toggle_pause()
	visible = GameManager.is_paused

func _on_resume():
	toggle_pause()

func _on_restart():
	GameManager.is_paused = false
	get_tree().paused = false
	GameManager.restart_level()

func _on_main_menu():
	GameManager.go_to_main_menu()
