extends Control

@onready var back_btn = $TopBar/BackBtn
@onready var title_label = $TopBar/TitleLabel
@onready var scroll_container = $ScrollContainer
@onready var voice_list = $ScrollContainer/VoiceList
@onready var delete_all_btn = $BottomBar/DeleteAllBtn

var _pending_category: int = -1
var _android_plugin = null

func _ready():
	if back_btn:
		back_btn.pressed.connect(_on_back)
	if delete_all_btn:
		delete_all_btn.pressed.connect(_on_delete_all)

	_try_init_android_plugin()
	_build_voice_cards()

func _try_init_android_plugin():
	if Engine.has_singleton("FaceRunPlugin"):
		_android_plugin = Engine.get_singleton("FaceRunPlugin")
		if _android_plugin and _android_plugin.has_signal("audio_picked"):
			_android_plugin.connect("audio_picked", _on_audio_picked)

func _build_voice_cards():
	if not voice_list:
		return
	for child in voice_list.get_children():
		child.queue_free()

	for cat in VoiceManager.VoiceCategory.values():
		var card = _create_voice_card(cat)
		voice_list.add_child(card)

func _create_voice_card(category: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = VoiceManager.get_category_display_name(category)
	info_vbox.add_child(name_label)

	var status_label = Label.new()
	status_label.name = "StatusLabel"
	if VoiceManager.has_voice(category):
		var path = VoiceManager.get_voice_path_for_category(category)
		status_label.text = path.get_file()
		status_label.modulate = Color(0.5, 1.0, 0.5)
	else:
		status_label.text = "No audio set"
		status_label.modulate = Color(0.6, 0.6, 0.6)
	info_vbox.add_child(status_label)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 8)
	hbox.add_child(btn_hbox)

	var pick_btn = Button.new()
	pick_btn.text = "Pick Audio"
	pick_btn.custom_minimum_size = Vector2(120, 40)
	pick_btn.pressed.connect(func(): _on_pick_audio(category))
	btn_hbox.add_child(pick_btn)

	if VoiceManager.has_voice(category):
		var remove_btn = Button.new()
		remove_btn.text = "Remove"
		remove_btn.custom_minimum_size = Vector2(90, 40)
		remove_btn.pressed.connect(func(): _on_remove_voice(category))
		btn_hbox.add_child(remove_btn)

		var preview_btn = Button.new()
		preview_btn.text = "Play"
		preview_btn.custom_minimum_size = Vector2(70, 40)
		preview_btn.pressed.connect(func(): _on_preview_voice(category))
		btn_hbox.add_child(preview_btn)

	return panel

func _on_pick_audio(category: int):
	_pending_category = category
	if _android_plugin and _android_plugin.has_method("pickAudioFromDevice"):
		_android_plugin.pickAudioFromDevice()
	else:
		print("Audio picker not available - running in editor/desktop mode")
		print("On Android, this opens the system file picker for .mp3/.wav files")

func _on_audio_picked(path: String):
	if _pending_category < 0:
		return
	var local_path = VoiceManager.copy_audio_to_local(path, _pending_category)
	if local_path != "":
		VoiceManager.assign_voice(_pending_category, local_path)
	_pending_category = -1
	_build_voice_cards()

func _on_remove_voice(category: int):
	VoiceManager.remove_voice(category)
	_build_voice_cards()

func _on_preview_voice(category: int):
	VoiceManager.play_voice(category)

func _on_delete_all():
	VoiceManager.delete_all_voices()
	_build_voice_cards()

func _on_back():
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
