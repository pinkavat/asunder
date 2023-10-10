extends Control


func setScores(var married, var divorced, var finalScore):
	$ColorRect/CenterContainer/VBoxContainer/ScoreLabel.text = "Joined Together: "+String(married)+" times\n\nPut Asunder: "+String(divorced)+" times\n\n\n\n\n\n\nFinal Score: "+String(finalScore)+"\n\nPress [enter] to play again"

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene("res://World.tscn")

func _ready():
	setScores(ScoreStorage.married, ScoreStorage.divorced, ScoreStorage.finalScore)
