extends Popup

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass


func _process(delta):
	if Input.is_action_just_pressed("ui_start"):
		global.GAME_PAUSED = not global.GAME_PAUSED
		if global.GAME_PAUSED:
			show();get_tree().paused = true
		else:
			hide();get_tree().paused = false

func _on_resume_tets_pressed():
	global.GAME_PAUSED = not global.GAME_PAUSED
	hide();get_tree().paused = false
