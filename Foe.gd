extends Area2D

signal reached_altar
signal dead

const JUMP_SPEED = 600
const FLEE_SPEED = 1000
const DEATH_YEET_SPEED = 1500
const DEATH_YEET_EXTRA_Y = 30
const FALL_SPEED = 600
const EXTRA_JUMP_HEIGHT = 40

var health = 1
var knockbackTime = 0.3
var walkingSpeed = 200

# Which side of the aise this foe is on
var side = 0

func on_bullet_hit(bullet):
	health -= 1
	if health <= 0:
		# death
		step = -2
		emit_signal("dead")
		$DeathSFX.play()
		$CollisionShape2D.set_deferred("disabled", true)
		$Walking.stop_all()
		$Sprite.scale = Vector2(4, 4)
		$Sprite.rotation_degrees = -30 if (randi() % 2) > 0 else 30
		var flight_target = Vector2(-1000 if bullet.global_position.x > global_position.x else 2500, global_position.y - DEATH_YEET_EXTRA_Y)
		var time = abs(flight_target.x - global_position.x) / DEATH_YEET_SPEED
		$Walking.interpolate_property(self, "global_position", global_position, flight_target, time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Walking.start()
		$WalkTimer.start(time)
	else:
		$WalkAnimationPlayer.stop(false)
		$HurtTimer.wait_time = 0.1
		$HurtTimer.start()
		$KnockbackTimer.wait_time = knockbackTime
		$KnockbackTimer.start()
		$Sprite.modulate = Color.red
		$Sprite.scale = Vector2(4.5, 4.5)
		$Walking.stop_all()
		$Jumping.stop_all()
		$WalkTimer.paused = true
	
func _on_HurtTimer_timeout():
	$Sprite.modulate = Color.white
	$Sprite.scale = Vector2(4, 4)

func _on_KnockbackTimer_timeout():
	$WalkAnimationPlayer.play()
	$Walking.resume_all()
	$Jumping.resume_all()
	$WalkTimer.paused = false



var step = -1

func _ready():
	$Sprite.frame += 1 if side == 1 else 0
	$Sprite.scale = Vector2(4, 0)
	$Sprite.offset = Vector2(0, 40)
	var target = $LevelMap.getNextTarget(step, side)
	global_position = target[0]
	step = target[2]
	$WalkAnimationPlayer.play("Spawn")
	$BarkSFX.play()

# Callback from the animation player
func spawn_complete():
	$WalkTimer.start(0.0001)


# Invoked by the world controller to cause this Foe to reverse direction and
# exit the screen
var retreat = false
var jumping = false
func pacify(var marriageState):
	if side == marriageState:
		retreat = true
		$Sprite.flip_h = not bool(marriageState)

func _process(delta):
	if retreat and not jumping:
		retreat = false
		step = -2
		$Walking.stop_all()
		$WalkAnimationPlayer.play("Walk")
		var flight_target = $LevelMap.getFlightTarget(global_position)
		var time = abs(flight_target.x - global_position.x) / FLEE_SPEED
		$Walking.interpolate_property(self, "global_position", global_position, flight_target, time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Walking.start()
		$WalkTimer.start(time)


var jumpTarget = Vector2.ZERO
# Called by the walking timer upon timer completion
func next_step():
	$Walking.stop_all()
	var target = $LevelMap.getNextTarget(step, side)
	step = target[2]
	if step < 0:
		# Done walking (-1) or fled (-2)
		queue_free()
	else:
		if step == 8:
			emit_signal("reached_altar")
		$Sprite.flip_h = true if target[0].x < global_position.x else false
		if target[1] == "walk":
			# Walk
			$WalkAnimationPlayer.play("Walk")
			var time = (target[0] - global_position).length() / walkingSpeed
			$Walking.interpolate_property(self, "global_position", global_position, target[0], time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$Walking.start()
			$WalkTimer.start(time)
		else:
			# Jump
			var time = (target[0] - global_position).length() / JUMP_SPEED
			$Walking.interpolate_property(self, "global_position:x", global_position.x, target[0].x, time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$Jumping.interpolate_property(self, "global_position:y", global_position.y, min(global_position.y, target[0].y) - EXTRA_JUMP_HEIGHT, time / 2, Tween.TRANS_QUAD, Tween.EASE_OUT)
			# Deferred start
			jumpTarget = target[0]
			$WalkTimer.wait_time = time
			$WalkAnimationPlayer.stop()
			$WalkAnimationPlayer.play("Jump")
			# NASTY KLUDGE to stop sprite from showing tail on balcony-to-altar jump
			if step == 6:
				$Sprite.z_index = 6

# Called by the animation player once the jump windup is complete
func jump_windup_complete():
	$Walking.start()
	$Jumping.start()
	$WalkTimer.start()
	$BarkSFX.play()
	jumping = true

var midair = true
# Called Mid- or End- jump by Jumping Tween
func _on_Jumping_tween_all_completed():
	if jumpTarget != Vector2.ZERO:	# Kludge to deal with "resume" on nonrunning tween triggering this
		if midair:
			midair = false
			var time = abs(jumpTarget.y - global_position.y) / FALL_SPEED
			$Jumping.interpolate_property(self, "global_position:y", global_position.y, jumpTarget.y, time, Tween.TRANS_QUAD, Tween.EASE_IN)
			$Jumping.start()
			$Sprite.z_index = 0
		else:
			midair = true
			jumping = false
			jumpTarget = Vector2.ZERO
