extends Control

@onready var back_btn = $TopBar/BackBtn
@onready var levels_container = $ScrollContainer/LevelsContainer

func _ready():
	if back_btn:
		back_btn.pressed.connect(_on_back)
	_populate_levels()

func _populate_levels():
	if not levels_container:
		return
	var highest_unlocked = SaveManager.get_highest_level()
	for i in range(GameManager.total_levels):
		var level_num = i + 1
		var btn = Button.new()
		btn.text = "Level %d\n%s" % [level_num, GameManager.level_names[i]]
		btn.custom_minimum_size = Vector2(280, 100)
		btn.add_theme_font_size_override("font_size", 20)

		if level_num <= highest_unlocked:
			btn.pressed.connect(_on_level_selected.bind(level_num))
			btn.modulate = Color.WHITE
		else:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5, 0.7)

		levels_container.add_child(btn)

func _on_level_selected(level: int):
	GameManager.reset_game()
	GameManager.load_level(level)

func _on_back():
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
