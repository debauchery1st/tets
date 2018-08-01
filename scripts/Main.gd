extends Node

func _ready():
	$AudioStreamPlayer.stream = global.SOUND_FX["INTRO"]
	$AudioStreamPlayer.volume_db -= 20
	$AudioStreamPlayer.play()

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		_on_Button_pressed()

func _on_Button_pressed():
	get_tree().change_scene("res://scenes/Default.tscn")


func _on_quitButton_pressed():
	get_tree().quit()
