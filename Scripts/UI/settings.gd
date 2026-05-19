extends Control

@onready var back_btn = $TopBar/BackBtn
@onready var music_toggle = $SettingsContainer/MusicToggle
@onready var sfx_toggle = $SettingsContainer/SfxToggle
@onready var touch_toggle = $SettingsContainer/TouchToggle
@onready var reset_btn = $SettingsContainer/ResetProgressBtn

func _ready():
	if back_btn:
		back_btn.pressed.connect(_on_back)
	if music_toggle:
		music_toggle.button_pressed = SaveManager.is_music_enabled()
		music_toggle.toggled.connect(_on_music_toggled)
	if sfx_toggle:
		sfx_toggle.button_pressed = SaveManager.is_sfx_enabled()
		sfx_toggle.toggled.connect(_on_sfx_toggled)
	if touch_toggle:
		touch_toggle.button_pressed = SaveManager.get_setting("gameplay", "show_touch_controls", true)
		touch_toggle.toggled.connect(_on_touch_toggled)
	if reset_btn:
		reset_btn.pressed.connect(_on_reset_progress)

func _on_music_toggled(enabled: bool):
	SaveManager.set_setting("audio", "music_enabled", enabled)

func _on_sfx_toggled(enabled: bool):
	SaveManager.set_setting("audio", "sfx_enabled", enabled)

func _on_touch_toggled(enabled: bool):
	SaveManager.set_setting("gameplay", "show_touch_controls", enabled)

func _on_reset_progress():
	var confirm = ConfirmationDialog.new()
	confirm.title = "Reset Progress"
	confirm.dialog_text = "This will reset all game progress.\nAre you sure?"
	add_child(confirm)
	confirm.popup_centered()
	confirm.confirmed.connect(func():
		SaveManager.reset_progress()
		confirm.queue_free()
	)
	confirm.canceled.connect(func(): confirm.queue_free())

func _on_back():
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
