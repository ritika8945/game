extends CharacterBody2D

@export_category("Player Properties")
@export var move_speed: float = 300
@export var jump_force: float = 550
@export var gravity: float = 25
@export var max_jump_count: int = 2
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.1

@export_category("Toggle Functions")
@export var double_jump: bool = true

var jump_count: int = 2
var is_grounded: bool = false
var movement_enabled: bool = true
var is_invincible: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var touch_input_x: float = 0.0
var touch_jump_pressed: bool = false

@onready var player_sprite = $AnimatedSprite2D
@onready var spawn_point = %SpawnPoint
@onready var particle_trails = $ParticleTrails
@onready var death_particles = $DeathParticles
@onready var face_sprite = $FaceSprite
@onready var invincibility_timer = $InvincibilityTimer
@onready var hitbox = $HitboxArea

func _ready():
	add_to_group("Player")
	_load_face_texture()
	if invincibility_timer:
		invincibility_timer.timeout.connect(_on_invincibility_timeout)

func _physics_process(delta):
	if movement_enabled:
		_update_coyote_time(delta)
		_update_jump_buffer(delta)
		movement()

func _process(_delta):
	player_animations()
	flip_player()

func _load_face_texture():
	if face_sprite:
		var tex = FaceManager.get_face_texture(FaceManager.EntityType.HERO)
		if tex:
			face_sprite.texture = tex
			face_sprite.visible = true
		else:
			face_sprite.visible = false

func _update_coyote_time(delta):
	if was_on_floor and not is_on_floor():
		coyote_timer = coyote_time
	if coyote_timer > 0:
		coyote_timer -= delta
	was_on_floor = is_on_floor()

func _update_jump_buffer(delta):
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

func movement():
	if not is_on_floor():
		velocity.y += gravity
	elif is_on_floor():
		jump_count = max_jump_count

	handle_jumping()

	var input_axis = touch_input_x
	if input_axis == 0.0:
		input_axis = Input.get_axis("Left", "Right")
	velocity.x = input_axis * move_speed
	move_and_slide()

func handle_jumping():
	var jump_requested = touch_jump_pressed or Input.is_action_just_pressed("Jump")
	touch_jump_pressed = false

	if jump_requested:
		jump_buffer_timer = jump_buffer_time

	var can_coyote_jump = coyote_timer > 0 and not is_on_floor()
	var can_ground_jump = is_on_floor()
	var can_double_jump = double_jump and jump_count > 0 and not is_on_floor()

	if jump_buffer_timer > 0:
		if can_ground_jump or can_coyote_jump:
			jump()
			jump_buffer_timer = 0
			coyote_timer = 0
			if is_on_floor():
				jump_count -= 1
		elif can_double_jump:
			jump()
			jump_count -= 1
			jump_buffer_timer = 0

func jump():
	jump_tween()
	AudioManager.jump_sfx.play()
	velocity.y = -jump_force

func player_animations():
	if not particle_trails:
		return
	particle_trails.emitting = false

	if is_on_floor():
		if abs(velocity.x) > 0:
			particle_trails.emitting = true
			player_sprite.play("Walk", 1.5)
		else:
			player_sprite.play("Idle")
	else:
		player_sprite.play("Jump")

func flip_player():
	if velocity.x < 0:
		player_sprite.flip_h = true
		if face_sprite and face_sprite.visible:
			face_sprite.flip_h = true
	elif velocity.x > 0:
		player_sprite.flip_h = false
		if face_sprite and face_sprite.visible:
			face_sprite.flip_h = false

func take_damage():
	if is_invincible:
		return
	AudioManager.death_sfx.play()
	GameManager.take_damage()
	if GameManager.health <= 0:
		death_tween()
	else:
		_start_invincibility()
		_damage_flash()

func _start_invincibility():
	is_invincible = true
	if invincibility_timer:
		invincibility_timer.start(1.5)

func _on_invincibility_timeout():
	is_invincible = false
	player_sprite.modulate.a = 1.0

func _damage_flash():
	var tween = create_tween()
	for i in range(5):
		tween.tween_property(player_sprite, "modulate:a", 0.3, 0.1)
		tween.tween_property(player_sprite, "modulate:a", 1.0, 0.1)

func death_tween():
	movement_enabled = false
	if death_particles:
		death_particles.emitting = true
	var tween = create_tween()
	tween.tween_property(player_sprite, "scale", Vector2.ZERO, 0.15)
	tween.parallel().tween_property(player_sprite, "position", Vector2.ZERO, 0.15)
	await tween.finished

	if GameManager.lives <= 0:
		get_tree().change_scene_to_file("res://Scenes/UI/GameOver.tscn")
		return

	global_position = spawn_point.global_position
	await get_tree().create_timer(0.3).timeout
	movement_enabled = true
	GameManager.health = GameManager.max_health
	GameManager.emit_signal("health_changed", GameManager.health)
	AudioManager.respawn_sfx.play()
	respawn_tween()

func respawn_tween():
	var tween = create_tween()
	tween.stop()
	tween.play()
	tween.tween_property(player_sprite, "scale", Vector2.ONE, 0.15)
	tween.parallel().tween_property(player_sprite, "position", Vector2(0, -48), 0.15)

func jump_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.7, 1.4), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func set_touch_input(x: float):
	touch_input_x = x

func set_touch_jump():
	touch_jump_pressed = true

func update_checkpoint(new_spawn: Vector2):
	if spawn_point:
		spawn_point.global_position = new_spawn

func _on_collision_body_entered(body):
	if body.is_in_group("Traps"):
		take_damage()
	elif body.is_in_group("Enemies"):
		if velocity.y > 0 and global_position.y < body.global_position.y:
			velocity.y = -jump_force * 0.6
			body.take_hit()
			GameManager.defeat_enemy()
		else:
			take_damage()
