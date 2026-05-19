extends Control

@onready var back_btn = $TopBar/BackBtn
@onready var entities_container = $ScrollContainer/EntitiesContainer
@onready var delete_all_btn = $BottomBar/DeleteAllBtn
@onready var privacy_note = $BottomBar/PrivacyNote

var entity_cards: Dictionary = {}

func _ready():
	if back_btn:
		back_btn.pressed.connect(_on_back)
	if delete_all_btn:
		delete_all_btn.pressed.connect(_on_delete_all)
	_build_entity_cards()

func _build_entity_cards():
	if not entities_container:
		return

	for child in entities_container.get_children():
		child.queue_free()

	for entity_type in FaceManager.EntityType.values():
		var card = _create_entity_card(entity_type)
		entities_container.add_child(card)

func _create_entity_card(entity_type: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 120)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	var face_preview = TextureRect.new()
	face_preview.custom_minimum_size = Vector2(80, 80)
	face_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	var tex = FaceManager.get_face_texture(entity_type)
	if tex:
		face_preview.texture = tex
	hbox.add_child(face_preview)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label = Label.new()
	name_label.text = FaceManager.get_entity_display_name(entity_type)
	name_label.add_theme_font_size_override("font_size", 22)
	info_vbox.add_child(name_label)

	var status_label = Label.new()
	if FaceManager.has_face(entity_type):
		status_label.text = "Face assigned"
		status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		status_label.text = "Default sprite"
		status_label.add_theme_color_override("font_color", Color.GRAY)
	info_vbox.add_child(status_label)

	var btn_hbox = HBoxContainer.new()

	var assign_btn = Button.new()
	assign_btn.text = "Pick Photo"
	assign_btn.pressed.connect(_on_pick_photo.bind(entity_type))
	btn_hbox.add_child(assign_btn)

	if FaceManager.has_face(entity_type):
		var remove_btn = Button.new()
		remove_btn.text = "Remove"
		remove_btn.pressed.connect(_on_remove_face.bind(entity_type))
		btn_hbox.add_child(remove_btn)

	info_vbox.add_child(btn_hbox)
	hbox.add_child(info_vbox)

	entity_cards[entity_type] = panel
	return panel

func _on_pick_photo(entity_type: int):
	if Engine.has_singleton("FaceRunPlugin"):
		FaceManager.pick_image_from_gallery()
	else:
		_show_desktop_notice(entity_type)

func _show_desktop_notice(entity_type: int):
	var dialog = AcceptDialog.new()
	dialog.title = "Photo Selection"
	dialog.dialog_text = "Photo selection requires Android device.\nOn Android, tap 'Pick Photo' to select from gallery.\n\nEntity: %s" % FaceManager.get_entity_display_name(entity_type)
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func _on_remove_face(entity_type: int):
	FaceManager.remove_face(entity_type)
	_build_entity_cards()

func _on_delete_all():
	var confirm = ConfirmationDialog.new()
	confirm.title = "Delete All Face Data"
	confirm.dialog_text = "This will remove all assigned face images.\nAre you sure?"
	add_child(confirm)
	confirm.popup_centered()
	confirm.confirmed.connect(func():
		FaceManager.delete_all_faces()
		_build_entity_cards()
		confirm.queue_free()
	)
	confirm.canceled.connect(func(): confirm.queue_free())

func _on_back():
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
