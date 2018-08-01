extends KinematicBody2D

var pos = Vector2()
var location = Vector2()

func _ready():
	pass
	
func shift_down():
	return Vector2(position.x, position.y + 64)
