extends Node2D

var reveal_delay = 0.2
var show_delay = 0.5

var state = 0

func set_text(var text):
	$HBoxContainer/Label.text = text

func _ready():
	$Timer.start(reveal_delay)


func _on_Tween_tween_all_completed():
	if state == 1:
		state = 2
		$Timer.start(show_delay)
	elif state == 2:
		queue_free()


func _on_Timer_timeout():
	if state == 0:
		state = 1
		show()
		$Tween.interpolate_property(self, "global_position", global_position, global_position + Vector2(0, -50), 1.0, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		$Tween.start()
	else:
		$Tween.interpolate_property(self, "global_position", global_position, global_position + Vector2(0, 50), 0.25, Tween.TRANS_EXPO, Tween.EASE_IN)
		$Tween.start()
