extends Node2D


onready var lightRingTexture = preload("res://Assets/LightRing.png")

const EXIT_RADIUS = 2
const EXIT_TIME = 0.1

var lightRingRadius = 50
const BASE_LIGHT_RING_ROTATION_SPEED = PI / 2
var lightRingRotationSpeed = BASE_LIGHT_RING_ROTATION_SPEED
const lightRingRotationSpeedMul = 1.2
const maxVisibleMultiplier = 10

var multiplier = 1


func augmentMultiplierCallback():
	multiplier += 1
	$ContCont/VBoxContainer/MulNum.text = "x " + String(multiplier)
	if multiplier < maxVisibleMultiplier:
		if multiplier == 2:
			var newLightRing = Sprite.new()
			newLightRing.texture = lightRingTexture
			$LightRing.add_child(newLightRing)
		var newLightRing = Sprite.new()
		newLightRing.texture = lightRingTexture
		$LightRing.add_child(newLightRing)
		var i = 0
		var arc = (2 * PI) / multiplier
		for child in $LightRing.get_children():
			child.position = Vector2(lightRingRadius, 0).rotated(i * arc)
			i += 1
		lightRingRotationSpeed *= lightRingRotationSpeedMul


func resetMultiplier():
	multiplier = 1
	$ContCont/VBoxContainer/MulNum.text = "x " + String(multiplier)
	for child in $LightRing.get_children():
		$FlyOff.interpolate_property(child, "position", child.position, child.position * EXIT_RADIUS, EXIT_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	lightRingRotationSpeed = BASE_LIGHT_RING_ROTATION_SPEED
	$FlyOff.start()


func _process(delta):
	$LightRing.rotation = fmod($LightRing.rotation + (delta * lightRingRotationSpeed), 2.0 * PI)

func augmentMultiplier():
	$AnimationPlayer.play("Augment")


func _on_FlyOff_tween_all_completed():
	for child in $LightRing.get_children():
		child.queue_free()
