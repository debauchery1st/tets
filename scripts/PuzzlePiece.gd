extends KinematicBody2D

const ACCELERATION = 128
const MAX_SPEED = 256
const GRAVITY = 32
const UP = Vector2(0, -1)
const R_RADIANS = 1.570796  # print(deg2rad(90))
const R_POINT = .1570796

var pos = Vector2()

var GRID_SHAPE = 0
var GRID_STATE = 0
var IN_ROTATION = false
var ROTATED = 0
var DETAILS = []
var WEBSTER = {}
var TOTAL_POINTS = 0
var COLLISION_DELTA = 0
var DFTC = false  # down for the count
var dftc_procs = 0


func _ready():
	pass

func add_to_score(t):
	global.FX_PLAYERS['fx2'].stream = global.SOUND_FX["MAGIC"]
	global.FX_PLAYERS['fx2'].play()
	global.TOTAL_POINTS += t
	get_node("CanvasLayer/RichTextLabel").text = "score: "+str(global.TOTAL_POINTS)

func shape_A2D(i):
	# convert to pure dict
	var diff = Vector2(i[1]['2D'][0], i[1]['2D'][1])  # I
	return {
		"2D": {
			"H": Vector2(i[0]['2D'][0], i[0]['2D'][1]) - diff,
			"I": Vector2(i[1]['2D'][0], i[1]['2D'][1]) - diff,
			"J": Vector2(i[2]['2D'][0], i[2]['2D'][1]) - diff,
			"K": Vector2(i[3]['2D'][0], i[3]['2D'][1]) - diff
			},
		"1D": {
			"H": Vector2(i[0]['1D'][0], i[0]['1D'][1]) - diff,
			"I": Vector2(i[1]['1D'][0], i[1]['1D'][1]) - diff,
			"J": Vector2(i[2]['1D'][0], i[2]['1D'][1]) - diff,
			"K": Vector2(i[3]['1D'][0], i[3]['1D'][1]) - diff
			}
		}

func get_rectangles():
	return WEBSTER

func move_rectangles(vH, vI, vJ, vK):
	WEBSTER['2D']['H'] = vH
	WEBSTER['2D']['I'] = vI
	WEBSTER['2D']['J'] = vJ
	WEBSTER['2D']['K'] = vK
	set_postion(WEBSTER)

func set_postion(i):
	$H.offset = i['2D']['H'];$H_C.position = $H.offset;$H_T.rect_position = $H.offset
	$I.offset = i['2D']['I'];$I_C.position = $I.offset;$I_T.rect_position = $I.offset
	$J.offset = i['2D']['J'];$J_C.position = $J.offset;$J_T.rect_position = $J.offset
	$K.offset = i['2D']['K'];$K_C.position = $K.offset;$K_T.rect_position = $K.offset

func get_shape_pos():
	return WEBSTER['1D']

func set_shape(info, code):
	DETAILS = info  # hold
	GRID_SHAPE = int(code)
	WEBSTER = shape_A2D(DETAILS)
	set_postion(WEBSTER)

func sleepy_timer(n):
	# for reference
	yield(get_tree().create_timer(n), "timeout")  # non-blocking delay

func m5offset():
	var adjustments = {
		"H": $H.offset,
		"I": $I.offset,
		"J": $J.offset,
		"K": $K.offset
	}
	var m5 = [
		[0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0],
		]
	var m5_piece = {}
	var radians = GRID_STATE * R_RADIANS
	# transpose the shape onto 5x5 matrix (m5)
	var o_dict = {}
	var v_dict = {}
	for a in adjustments:
		v_dict[a] = adjustments[a]
		if radians > 0:
			v_dict[a] = adjustments[a].rotated(radians)
		o_dict[a] = v_dict[a]
		v_dict[a] += Vector2(192, 192)
		var x = int(v_dict[a].x / 64)
		var y = int(v_dict[a].y / 64)
		var nw = Vector2(-1, -1) + Vector2(int(x), int(y))
		m5[nw.y][nw.x] = 1
		m5_piece[a] = nw
	return [o_dict, m5_piece]

func rotated_pieces():
	var m5_off = m5offset()
	var m5_piece = m5_off[1]
	var o_dict = m5_off[0]
	var new_pieces = {
		"1D":{"H": Vector2(), "I": Vector2(), "J": Vector2(), "K": Vector2()},
		"2D":{"H": Vector2(), "I": Vector2(), "J": Vector2(), "K": Vector2()}
		}
	for x in ["H", "I", "J", "K"]:
		new_pieces["1D"][x].x = int((position.x + o_dict[x].x) / global.SU)
		new_pieces["1D"][x].y = int((position.y + o_dict[x].y) / global.SU)
		new_pieces["2D"][x].x = new_pieces["1D"][x].x * global.SU
		new_pieces["2D"][x].y = new_pieces["1D"][x].y * global.SU
	return new_pieces

func GRID_move():
	var m5_off = m5offset()
	var o_dict = m5_off[0]
	var m5_piece = m5_off[1]
	for x in ["H", "I", "J", "K"]:
		WEBSTER["1D"][x].x = int((position.x + o_dict[x].x) / global.SU)
		WEBSTER["1D"][x].y = int((position.y + o_dict[x].y) / global.SU)
		WEBSTER["2D"][x].x = WEBSTER["1D"][x].x * global.SU
		WEBSTER["2D"][x].y = WEBSTER["1D"][x].y * global.SU

func _physics_process(delta):
	get_node("CanvasLayer/RichTextLabel").text = "score: "+str(global.TOTAL_POINTS)
	var motion = Vector2(0, 0)
	if global.GAME_OVER:
		return
	if 1 in global.GRID[0]:
		print("GAME OVER")
		global.GAME_OVER = true
		return
	if global.CURRENT[0] != self:
		if is_on_floor():
			return
		motion.y += GRAVITY
		pos.x = lerp(motion.x + pos.x, 0, 0.25)
		pos.y = lerp(motion.y + pos.y, 0, 0.25)
		pos = move_and_slide(pos, UP)
	motion.y += GRAVITY
	if IN_ROTATION:
		if ROTATED > R_RADIANS:
			IN_ROTATION = false
			ROTATED = 0.0
			GRID_STATE = (GRID_STATE + 1) % 4
		else:
			rotate(R_POINT)
			ROTATED += R_POINT
	if Input.is_action_pressed("ui_right"):
		motion.x += min(pos.x+ACCELERATION, MAX_SPEED)
	if Input.is_action_pressed("ui_left"):
		motion.x += max(pos.x-ACCELERATION, -MAX_SPEED)
	if Input.is_action_pressed("ui_down"):
		pass
		motion.y += GRAVITY
	if Input.is_action_just_pressed("ui_up"):
		pass
	if Input.is_action_just_pressed("ui_accept"):
		if GRID_SHAPE != 3:
			IN_ROTATION = true
			global.FX_PLAYERS['fx1'].stream = global.SOUND_FX["ROTATE"]
			global.FX_PLAYERS['fx1'].play()
	pos.x = lerp(motion.x + pos.x, 0, 0.25)
	pos.y = lerp(motion.y + pos.y, 0, 0.25)
	pos = round_up(pos)  # move by integer to help with 2D to 1D projection
	pos = move_and_slide(pos, UP)
	if is_on_ceiling():
		var last_collider = get_slide_collision(0).collider
		if last_collider.is_in_group("ceilings"):
			print("BLAZE ONE UP")
			global.GAME_OVER = true
		else:
			COLLISION_DELTA += .1
			print(COLLISION_DELTA)
			if COLLISION_DELTA-delta < .5:
				print("NICE!")
			else:
				print("BLAZE ONE UP!!!")
				global.GAME_OVER = true
	if is_on_floor() and not global.GAME_OVER:
		if dftc_procs == 0:
			down_for_the_count()
		if not DFTC:
			global.FX_PLAYERS['fx1'].stream =  global.SOUND_FX["SWEDISH"]
			global.FX_PLAYERS['fx1'].play()
			# divide into bricks
			global.stanley_newbrick(self)
	else:
		if not global.GAME_OVER:
			COLLISION_DELTA = 0

func round_up(xy):
	var x1 = xy.x
	var x2 = int(xy.x)
	var y1 = xy.y
	var y2 = int(xy.y)
	if (x1 - x2) > .5:
		xy.x = x1 + 1
	if (y1 - y2) > .5:
		xy.y = y1 + 1
	return xy

func down_for_the_count():
	if dftc_procs > 0:
		return # dont process more than once per piece
	GRID_move()
	position.x = WEBSTER["2D"]["I"].x + 32;position.y = WEBSTER["2D"]["I"].y + 32
	global.stamp_grid(WEBSTER["1D"])
	dftc_procs = 0
