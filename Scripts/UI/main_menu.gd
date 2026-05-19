extends Control

@onready var title_label = $VBoxContainer/TitleLabel
@onready var tagline_label = $VBoxContainer/TaglineLabel
@onready var new_game_btn = $VBoxContainer/ButtonsContainer/NewGameBtn
@onready var continue_btn = $VBoxContainer/ButtonsContainer/ContinueBtn
@onready var face_setup_btn = $VBoxContainer/ButtonsContainer/FaceSetupBtn
@onready var settings_btn = $VBoxContainer/ButtonsContainer/SettingsBtn
@onready var about_btn = $VBoxContainer/ButtonsContainer/AboutBtn
@onready var privacy_btn = $VBoxContainer/ButtonsContainer/PrivacyBtn
@onready var offline_badge = $OfflineBadge

func _ready():
	_connect_buttons()
	_update_continue_state()
	_animate_entrance()

func _connect_buttons():
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game)
	if continue_btn:
		continue_btn.pressed.connect(_on_continue)
	if face_setup_btn:
		face_setup_btn.pressed.connect(_on_face_setup)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings)
	if about_btn:
		about_btn.pressed.connect(_on_about)
	if privacy_btn:
		privacy_btn.pressed.connect(_on_privacy)

func _update_continue_state():
	if continue_btn:
		var highest = SaveManager.get_highest_level()
		continue_btn.disabled = highest <= 1
		if highest > 1:
			continue_btn.text = "Continue (Level %d)" % highest

func _animate_entrance():
	if title_label:
		title_label.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(title_label, "modulate:a", 1.0, 0.5)

func _on_new_game():
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://Scenes/UI/LevelSelect.tscn")

func _on_continue():
	var highest = SaveManager.get_highest_level()
	GameManager.reset_game()
	GameManager.load_level(min(highest, GameManager.total_levels))

func _on_face_setup():
	get_tree().change_scene_to_file("res://Scenes/UI/FaceSetup.tscn")

func _on_settings():
	get_tree().change_scene_to_file("res://Scenes/UI/Settings.tscn")

func _on_about():
	get_tree().change_scene_to_file("res://Scenes/UI/About.tscn")

func _on_privacy():
	get_tree().change_scene_to_file("res://Scenes/UI/Privacy.tscn")
