extends Node

onready var time_start = OS.get_unix_time()

func _ready():
	if global.CURRENT == []:
		$AudioStreamPlayer.stream = global.MUSIC["SYNTH2"]
		$AudioStreamPlayer.play()
		global.FX_PLAYERS['fx1'] = get_node("fx1")
		global.FX_PLAYERS['fx2'] = get_node("fx2")
		global.new_piece()
