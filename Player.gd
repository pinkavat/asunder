extends KinematicBody2D

signal fire

const GRAVITY = 50
const TERMINAL_VELOCITY = 1000
const FLOOR_LATERAL_FRICTION = 0.5
const AIR_LATERAL_FRICTION = 0.5
const LATERAL_SPEED = 500
const JUMP_VELOCITY = 1000

const CAMERA_OFFSET_X = 200

var walking = false
var frozen = false
var acceptingControl = true

var velocity = Vector2.ZERO
var vectorToMouse = Vector2.ZERO

# Bullet firing
var gun_doubled = true
var gun_chamber = false	# which chamber of the double gun is firing
const SINGLE_RELOAD_TIME = 0.4
const DOUBLE_RELOAD_TIME = 0.25

onready var bullet_class = preload("res://Bullet.tscn")
const SINGLE_GUN_TIP = Vector2(20, 0)
const DOUBLE_GUN_TIPS = [Vector2(20, -10), Vector2(20, 10)]
const BULLET_SPEED = 30
const BULLET_LIFETIME = 1.0
var time_until_next_shot = 0

func fireBullet():
		var bullet = bullet_class.instance()
		if gun_doubled:
			bullet.global_position = global_position + DOUBLE_GUN_TIPS[int(gun_chamber)].rotated(vectorToMouse.angle())
		else:
			bullet.global_position = global_position + SINGLE_GUN_TIP.rotated(vectorToMouse.angle())
		bullet.rotation = vectorToMouse.angle()
		bullet.motion = (BULLET_SPEED * vectorToMouse)
		bullet.lifetime = BULLET_LIFETIME
		get_parent().add_child_below_node(self, bullet)
		# TODO screen shake / recoil / gun animation

func _physics_process(delta):
	if !frozen:
		walking = false
		
		if !is_on_floor():
			# Gravity
			velocity.y = min(velocity.y + GRAVITY, TERMINAL_VELOCITY)
		
		# Do Input
		if acceptingControl:
			if Input.is_action_pressed("ui_up") and is_on_floor():
				velocity.y = 0.0 - JUMP_VELOCITY
			if Input.is_action_pressed("ui_right"):
				velocity.x = LATERAL_SPEED
				walking = true
			elif Input.is_action_pressed("ui_left"):
				velocity.x = 0.0 - LATERAL_SPEED
				walking = true
			else:
				# Effect friction
				if is_on_floor():
					# Floor friction
					velocity.x = lerp(velocity.x, 0, FLOOR_LATERAL_FRICTION)
				else:
					# Air friction
					velocity.x = lerp(velocity.x, 0, AIR_LATERAL_FRICTION)
		
		# Do walking animation
		# TODO WALKING ANIMATION
		
		# Effect physics
		velocity = move_and_slide(velocity, Vector2.UP)


func _process(delta):
	if time_until_next_shot > 0:
			time_until_next_shot -= delta
	if acceptingControl and not frozen:
		# Point Gun
		vectorToMouse = (get_global_mouse_position() - global_position).normalized()
		$Gun.rotation = vectorToMouse.angle()
		$Gun.flip_v = true if vectorToMouse.x < 0 else false
		$Sprite.flip_h = $Gun.flip_v
		
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			if time_until_next_shot <= 0:
				time_until_next_shot = DOUBLE_RELOAD_TIME if gun_doubled else SINGLE_RELOAD_TIME
				gun_chamber = not gun_chamber
				fireBullet()
				$BulletFireSFX.play()
				emit_signal("fire")
				$GunAnimationPlayer.play("Fire")
				# TODO recoil?
				velocity.x = velocity.x + 500 if(vectorToMouse.x < 0) else velocity.x - 500
	else:
		pass
		# TODO gun rest position?
