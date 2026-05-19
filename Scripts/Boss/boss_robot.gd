extends CharacterBody2D

signal boss_defeated

@export var move_speed: float = 100
@export var gravity: float = 20
@export var max_health: int = 5
@export var charge_speed: float = 250
@export var stomp_damage: int = 1

enum BossState { IDLE, PATROL, CHARGE, STUNNED, DYING }

var health: int
var state: BossState = BossState.IDLE
var direction: float = 1.0
var is_dead: bool = false
var player_ref: CharacterBody2D = null
var stun_timer: float = 0.0
var state_timer: float = 0.0
var charge_timer: float = 0.0
var hits_taken: int = 0
var _roar_played: bool = false

@onready var sprite = $AnimatedSprite2D
@onready var face_sprite = $FaceSprite
@onready var health_bar = $HealthBar

func _ready():
	add_to_group("Boss")
	add_to_group("Enemies")
	health = max_health
	_load_face_texture()
	_update_health_bar()

func _physics_process(delta):
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity

	match state:
		BossState.IDLE:
			_state_idle(delta)
		BossState.PATROL:
			_state_patrol(delta)
		BossState.CHARGE:
			_state_charge(delta)
		BossState.STUNNED:
			_state_stunned(delta)

	move_and_slide()
	_update_sprite()

func _state_idle(delta):
	velocity.x = 0
	state_timer += delta
	if state_timer > 2.0:
		state_timer = 0
		state = BossState.PATROL

func _state_patrol(delta):
	velocity.x = direction * move_speed
	state_timer += delta

	if is_on_wall():
		direction *= -1

	if state_timer > 3.0 and player_ref:
		state_timer = 0
		direction = sign(player_ref.global_position.x - global_position.x)
		state = BossState.CHARGE
		charge_timer = 0
		_roar_played = false

func _state_charge(delta):
	velocity.x = direction * charge_speed
	charge_timer += delta
	if not _roar_played:
		AudioManager.play_boss_roar()
		_roar_played = true

	if is_on_wall() or charge_timer > 2.0:
		state = BossState.STUNNED
		stun_timer = 0
		velocity.x = 0

func _state_stunned(delta):
	velocity.x = 0
	stun_timer += delta
	if sprite:
		sprite.modulate.a = 0.5 + 0.5 * sin(stun_timer * 10)
	if stun_timer > 2.0:
		sprite.modulate.a = 1.0
		state = BossState.PATROL
		state_timer = 0

func take_hit():
	if state != BossState.STUNNED and state != BossState.DYING:
		return

	health -= 1
	hits_taken += 1
	_update_health_bar()
	_flash_damage()

	if health <= 0:
		die()
	else:
		state = BossState.IDLE
		state_timer = 0

func _flash_damage():
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.15)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func die():
	is_dead = true
	state = BossState.DYING
	velocity = Vector2.ZERO
	AudioManager.play_boss_death()
	emit_signal("boss_defeated")
	GameManager.defeat_enemy()
	GameManager.add_score(100)
	if sprite:
		var tween = create_tween()
		for i in range(5):
			tween.tween_property(sprite, "modulate:a", 0.0, 0.1)
			tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
		tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
		await tween.finished
	queue_free()

func _update_health_bar():
	if health_bar:
		health_bar.value = float(health) / float(max_health) * 100

func _update_sprite():
	if sprite:
		sprite.flip_h = direction < 0
	if face_sprite and face_sprite.visible:
		face_sprite.flip_h = direction < 0

func _load_face_texture():
	if face_sprite:
		var tex = FaceManager.get_face_texture(FaceManager.EntityType.BOSS)
		if tex:
			face_sprite.texture = tex
			face_sprite.visible = true
		else:
			face_sprite.visible = false

func _on_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		player_ref = body

func _on_detection_area_body_exited(body):
	if body.is_in_group("Player"):
		player_ref = null

func _on_hitbox_body_entered(body):
	if body.is_in_group("Player") and not is_dead:
		if body.velocity.y > 0 and body.global_position.y < global_position.y - 20:
			if state == BossState.STUNNED:
				take_hit()
				body.velocity.y = -body.jump_force * 0.7
			else:
				body.velocity.y = -body.jump_force * 0.5
		else:
			body.take_damage()
