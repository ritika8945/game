extends CharacterBody2D

@export var move_speed: float = 60
@export var amplitude: float = 40
@export var frequency: float = 2.0
@export var health: int = 1

var direction: float = 1.0
var start_position: Vector2
var time_passed: float = 0.0
var is_dead: bool = false

@onready var sprite = $AnimatedSprite2D
@onready var face_sprite = $FaceSprite

func _ready():
	add_to_group("Enemies")
	start_position = global_position
	_load_face_texture()

func _physics_process(delta):
	if is_dead:
		return

	time_passed += delta
	velocity.x = direction * move_speed
	velocity.y = sin(time_passed * frequency) * amplitude

	move_and_slide()

	if sprite:
		sprite.flip_h = direction < 0
	if face_sprite and face_sprite.visible:
		face_sprite.flip_h = direction < 0

	if abs(global_position.x - start_position.x) > 200:
		direction *= -1

func take_hit():
	health -= 1
	if health <= 0:
		die()
	else:
		_flash_damage()

func _flash_damage():
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func die():
	is_dead = true
	velocity = Vector2.ZERO
	if sprite:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		await tween.finished
	queue_free()

func _load_face_texture():
	if face_sprite:
		var tex = FaceManager.get_face_texture(FaceManager.EntityType.ENEMY_2)
		if tex:
			face_sprite.texture = tex
			face_sprite.visible = true
		else:
			face_sprite.visible = false

func _on_hitbox_body_entered(body):
	if body.is_in_group("Player") and not is_dead:
		if body.velocity.y > 0 and body.global_position.y < global_position.y - 10:
			take_hit()
			body.velocity.y = -body.jump_force * 0.6
			GameManager.defeat_enemy()
		else:
			body.take_damage()
