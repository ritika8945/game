extends CanvasLayer

@onready var score_label = $TopBar/ScoreLabel
@onready var level_label = $TopBar/LevelLabel
@onready var health_container = $TopBar/HealthContainer
@onready var lives_label = $TopBar/LivesLabel
@onready var pause_btn = $TopBar/PauseBtn
@onready var touch_left = $TouchControls/LeftBtn
@onready var touch_right = $TouchControls/RightBtn
@onready var touch_jump = $TouchControls/JumpBtn

var player_ref: CharacterBody2D = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_signals()
	_update_all_ui()
	_setup_touch_controls()

func _connect_signals():
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.health_changed.connect(_on_health_changed)
	if pause_btn:
		pause_btn.pressed.connect(_on_pause)

func _process(_delta):
	if not player_ref:
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			player_ref = players[0]

func _update_all_ui():
	_on_score_changed(GameManager.score)
	_on_lives_changed(GameManager.lives)
	_on_health_changed(GameManager.health)
	if level_label:
		level_label.text = "Level %d" % GameManager.current_level

func _on_score_changed(new_score: int):
	if score_label:
		score_label.text = "Score: %d" % new_score

func _on_lives_changed(new_lives: int):
	if lives_label:
		lives_label.text = "x%d" % new_lives

func _on_health_changed(new_health: int):
	if health_container:
		for i in range(health_container.get_child_count()):
			var heart = health_container.get_child(i)
			if heart is TextureRect or heart is Label:
				heart.modulate.a = 1.0 if i < new_health else 0.3

func _on_pause():
	GameManager.toggle_pause()
	if GameManager.is_paused:
		$PauseOverlay.visible = true
	else:
		$PauseOverlay.visible = false

func _setup_touch_controls():
	var show_touch = SaveManager.get_setting("gameplay", "show_touch_controls", true)
	if not show_touch:
		if touch_left: touch_left.visible = false
		if touch_right: touch_right.visible = false
		if touch_jump: touch_jump.visible = false
		return

	if touch_left:
		touch_left.button_down.connect(func(): _set_touch_input(-1.0))
		touch_left.button_up.connect(func(): _set_touch_input(0.0))
	if touch_right:
		touch_right.button_down.connect(func(): _set_touch_input(1.0))
		touch_right.button_up.connect(func(): _set_touch_input(0.0))
	if touch_jump:
		touch_jump.pressed.connect(_on_touch_jump)

func _set_touch_input(x: float):
	if player_ref:
		player_ref.set_touch_input(x)

func _on_touch_jump():
	if player_ref:
		player_ref.set_touch_jump()
