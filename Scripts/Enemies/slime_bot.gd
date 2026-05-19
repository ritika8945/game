extends CharacterBody2D

@export var move_speed: float = 80
@export var gravity: float = 20
@export var health: int = 2
@export var patrol_distance: float = 150

var direction: float = 1.0
var start_position: Vector2
var is_dead: bool = false

@onready var sprite = $AnimatedSprite2D
@onready var face_sprite = $FaceSprite
@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var ray_cast_floor = $RayCastFloor

func _ready():
	add_to_group("Enemies")
	start_position = global_position
	_load_face_texture()

func _physics_process(_delta):
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity

	_patrol()
	velocity.x = direction * move_speed
	move_and_slide()

	if sprite:
		sprite.flip_h = direction < 0
	if face_sprite and face_sprite.visible:
		face_sprite.flip_h = direction < 0

func _patrol():
	if ray_cast_right and ray_cast_right.is_colliding():
		direction = -1
	elif ray_cast_left and ray_cast_left.is_colliding():
		direction = 1

	if ray_cast_floor and not ray_cast_floor.is_colliding():
		direction *= -1
		ray_cast_floor.position.x = 20 * direction

	if abs(global_position.x - start_position.x) > patrol_distance:
		direction *= -1

func take_hit():
	health -= 1
	_flash_damage()
	if health <= 0:
		die()

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
		tween.tween_property(sprite, "scale", Vector2.ZERO, 0.2)
		await tween.finished
	queue_free()

func _load_face_texture():
	if face_sprite:
		var tex = FaceManager.get_face_texture(FaceManager.EntityType.ENEMY_1)
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
