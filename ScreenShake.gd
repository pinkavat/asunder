extends Node

const transition = Tween.TRANS_SINE
const easy = Tween.EASE_IN_OUT
var amplitude = 0

onready var camera = get_parent()

func shake(duration = 0.2, frequency = 15, amplitude = 10):
	self.amplitude = amplitude
	$Duration.wait_time = duration
	$Frequency.wait_time = 1 / float(frequency)
	$Duration.start()
	$Frequency.start()
	camera_shake()

func camera_shake():
	var rand = Vector2()
	rand.x = rand_range(-amplitude, amplitude)
	rand.y = rand_range(-amplitude, amplitude)
	
	$Interpolator.interpolate_property(camera, "offset", camera.offset, rand, $Frequency.wait_time, transition , easy)
	$Interpolator.start()

func return_camera():
	$Interpolator.interpolate_property(camera, "offset", camera.offset, Vector2(), $Frequency.wait_time, transition , easy)
	$Interpolator.start()

func _on_Frequency_timeout():
	camera_shake()
	
func _on_Duration_timeout():
	return_camera()
	$Frequency.stop()
