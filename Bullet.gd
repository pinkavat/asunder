extends Area2D

var motion = Vector2.ZERO
var lifetime = 0
var impacted = false

func explode():
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite.hide()
	$Blast.show()
	$Blast/AnimationPlayer.play("Explode")
	motion = Vector2.ZERO
	lifetime = 200

# Called when the node enters the scene tree for the first time.
func _physics_process(delta):
	translate(motion)
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_Bullet_area_entered(area):
	if area.is_in_group("bullet_react"):
		#Impact on reactive entity
		if area.has_method("on_bullet_hit") and not impacted:
			impacted = true
			area.on_bullet_hit(self)
		explode()


func _on_Bullet_body_entered(body):
	if body.is_in_group("bullet_react"):
		#Impact on reactive entity
		if body.has_method("on_bullet_hit") and not impacted:
			impacted = true
			body.on_bullet_hit(self)
		explode()


func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()
