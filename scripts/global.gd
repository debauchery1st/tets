extends Node

var BLOCK = preload("res://scenes/PuzzlePiece.tscn")
var BRICK = preload("res://scenes/Brick.tscn")

var GAME_OVER = false
var COLS = 10
var SU = OS.get_window_size().x/COLS
var ROWS = (OS.get_window_size().y/SU) + 1
var Y_OFFSET = SU * 4
var TOTAL_PIECES = {}
var TOTAL_POINTS = 0
var BCKUP = []
var GRID = []
var CURRENT = []
var PIECES = []
var FX_PLAYERS = {'fx1': '', 'fx2': ''}
var MUSIC = {
	# "SYNTH1": preload("res://audio/music/synth-wave.ogg"),
	"SYNTH2": preload("res://audio/music/tilted-synth.ogg")
	}
var SOUND_FX = {
	"INTRO": preload("res://audio/fx/intro.wav"),
	# "HAT": preload("res://audio/fx/hat.wav"),
	# "KICK": preload("res://audio/fx/kick.wav"),
	"MAGIC": preload("res://audio/fx/magic.wav"),
	# "PLOP": preload("res://audio/fx/plop.wav"),
	# "RATCHET": preload("res://audio/fx/ratchet.wav"),
	"ROTATE": preload("res://audio/fx/rotate.wav"),
	# "SNARE": preload("res://audio/fx/snare.wav"),
	"SWEDISH": preload("res://audio/fx/swedish.wav"),
	# "TICK": preload("res://audio/fx/tick.wav"),
	# "TRIANGLE": preload("res://audio/fx/triangle.wav"),
	#"FIREBALL": preload("res://audio/fx/fireball.wav")
	}

func brick_occupying(v):
	for item in PIECES:
		if item.position == v:
			return item
	return false

func reset_GRID():
	var r = []
	for x in range(ROWS):
		var c = []
		for y in range(COLS):
			c.append(0)
		r.append(c)
	return r 

func _ready():
	GRID = reset_GRID()

func get_random_number(n):
    randomize()
    return randi()%n

func new_piece():
	if len(CURRENT) > 0:
		PIECES.append(CURRENT.pop_back())
	var sh = get_random_number(7)
	# var sh = 5
	# var sh = 0
	CURRENT = add_spawn(spawn_block(0, 0, 0, sh), sh)

func as_dictionary(s):
	return {
		'h': {'x': s[0][0], 'y': s[0][1]},
		'i': {'x': s[1][0], 'y': s[1][1]},
		'j': {'x': s[2][0], 'y': s[2][1]},
		'k': {'x': s[3][0], 'y': s[3][1]}
	}

func add_spawn(result, sh):
	var new_block = BLOCK.instance()
	new_block.set_shape(result, sh)
	get_node('.').add_child(new_block)
	return [new_block]


func stanley_newbrick(b):
	b.WEBSTER = b.rotated_pieces()
	for item in b.WEBSTER["2D"]:
		var newbrick = BRICK.instance()
		newbrick.position = Vector2(b.WEBSTER["2D"][item].x + 32, b.WEBSTER["2D"][item].y + 32)
		var gy = int(newbrick.position.y/64)
		if gy > len(GRID)-1:
			gy -=1
		var gx = int(newbrick.position.x/64)
		if gx > len(GRID[0])-1:
			gx -=1
		PIECES.append(newbrick)
		get_node('.').add_child(newbrick)
		GRID[gy][gx] = 1
	scan_gameboard()
	var wr = weakref(b)
	if !wr.get_ref():
		# instance has previously been freed
		pass
	else:
		get_node('.').remove_child(b)
		b.queue_free()
	global.new_piece()


func rebrick():
	var swap_space = []
	var limit = len(GRID)-1
	for oldbrick in PIECES:
		var wr = weakref(oldbrick)
		if !wr.get_ref():
			# instance has previously been freed
			pass
		else:
			get_node('.').remove_child(oldbrick)
			oldbrick.queue_free()
	for y in range(0, limit):
		for x in range(len(GRID[0])):
			if GRID[y][x] == 1:
				var new_location = Vector2((x*64)+32, (y*64)+32)
				var new_brick = BRICK.instance()
				new_brick.position = new_location
				get_node('.').add_child(new_brick)
				swap_space.append(new_brick)
	PIECES = swap_space

func print_gameboard():
	var idx = 0
	for item in global.GRID:
		if not 0 in item:
			print(item, '    cleared @ ', idx)
		else:
			print(item)
		idx += 1

func scan_gameboard():
	var blank_row = []
	var points = len(GRID[0])
	for x in range(points):
		blank_row.append(0)
	var dif = 0
	var cpy = []
	for row in range(ROWS):
		if not 0 in GRID[row]:
			CURRENT[0].add_to_score(points)
			dif += 1
		else:
			cpy.append(GRID[row])
	for x in range(dif):
		cpy.insert(0, blank_row)
	for y in range(len(GRID)):
		# long copy
		GRID[y] = cpy[y]
	rebrick()

func stamp_grid(loc):
	for item_name in loc:
		var x = loc[item_name].x
		if x == len(GRID[0]):
			x -= 1
		var y = loc[item_name].y
		GRID[y][x] = 1

func spawn_block(x, y, state, shape):
	var i = "shape"+str(shape+1)
	if not i in TOTAL_PIECES:
		TOTAL_PIECES[i] = 0
	TOTAL_PIECES[i] += 1
	# print(TOTAL_PIECES)
	var result = []
	var bd = as_dictionary(get_shape(x, y, SU, state, shape))
	for c in ['h', 'i', 'j', 'k']:
		var cy = bd[c]['y'] / SU
		var cx = bd[c]['x'] / SU
		result.append({'2D': [bd[c]['x'], bd[c]['y']], '1D': [cx, cy]})
	return result

#      o o
#    o o
func shape1a(x, y, di):
    var h = [x+di, y, di, di]
    var i = [x, y, di, di]
    var j = [x-di, y+di, di, di]
    var k = [x, y+di, di, di]
    return [h, i, j, k]

func shape1b(x, y, di):
    var h = [x, y-di, di, di]
    var i = [x, y, di, di]
    var j = [x+di, y, di, di]
    var k = [x+di, y+di, di, di]
    return [h, i, j, k]


func shape1c(x, y, di):
    return shape1a(x, y, di)

func shape1d(x, y, di):
    return shape1b(x, y, di)

#   o o o o
func shape2a(x, y, di):
    var h = [x, y, di, di]
    var i = [x, y + di, di, di]
    var j = [x, y + di*2, di, di]
    var k = [x, y + di*3, di, di]
    return [h, i, j, k]

func shape2b(x, y, di):
    var h = [x, y, di, di]
    var i = [x + di, y, di, di]
    var j = [x + di*2, y, di, di]
    var k = [x + di*3, y, di, di]
    return [h, i, j, k]

func shape2c(x, y, di):
    return shape2a(x, y, di)

func shape2d(x, y, di):
    return shape2b(x, y, di)

#   o o o
#   o
func shape3a(x, y, di):
    var h = [x, y, di, di]
    var i = [x, y + di, di, di]
    var j = [x, y + di*2, di, di]
    var k = [x+di, y + di*2, di, di]
    return [h, i, j, k]

func shape3b(x, y, di):
    var h = [x, y, di, di]
    var i = [x + di, y, di, di]
    var j = [x + di*2, y, di, di]
    var k = [x, y+di, di, di]
    return [h, i, j, k]

func shape3c(x, y, di):
    var h = [x+di, y, di, di]
    var i = [x, y, di, di]
    var j = [x+di, y + di, di, di]
    var k = [x+di, y + di*2, di, di]
    return [h, i, j, k]

func shape3d(x, y, di):
    var h = [x, y+di, di, di]
    var i = [x + di, y+di, di, di]
    var j = [x + di*2, y+di, di, di]
    var k = [x + di*2, y, di, di]
    return [h, i, j, k]
#     o o
#     o o
func shape4a(x, y, di):
    var h = [x, y, di, di]
    var i = [x, y + di, di, di]
    var j = [x+di, y, di, di]
    var k = [x+di, y + di, di, di]
    return [h, i, j, k]

func shape4b(x, y, di):
    return shape4a(x, y, di)

func shape4c(x, y, di):
    return shape4a(x, y, di)

func shape4d(x, y, di):
    return shape4a(x, y, di)
#    o o
#      o o
func shape5a(x, y, di):
    var h = [x+di, y, di, di]
    var i = [x, y+di, di, di]
    var j = [x+di, y+di, di, di]
    var k = [x, y+di*2, di, di]
    return [h, i, j, k]

func shape5b(x, y, di):
    var h = [x, y+di, di, di]
    var i = [x+di, y+di, di, di]
    var j = [x+di, y+di*2, di, di]
    var k = [x+di*2, y+di*2, di, di]
    return [h, i, j, k]

func shape5c(x, y, di):
    return shape5a(x, y, di)

func shape5d(x, y, di):
    return shape5b(x, y, di)
#     o
#   o o o
func shape6a(x, y, di):
    var h = [x, y, di, di]
    var i = [x+di, y, di, di]
    var j = [x+di*2, y, di, di]
    var k = [x+di, y + di, di, di]
    return [h, i, j, k]

func shape6b(x, y, di):
    var h = [x, y, di, di]
    var i = [x + di, y-di, di, di]
    var j = [x + di, y, di, di]
    var k = [x + di, y+di, di, di]
    return [h, i, j, k]

func shape6c(x, y, di):
    var h = [x, y, di, di]
    var i = [x+di, y, di, di]
    var j = [x+di*2, y, di, di]
    var k = [x+di, y - di, di, di]
    return [h, i, j, k]

func shape6d(x, y, di):
    var h = [x+di, y, di, di]
    var i = [x, y-di, di, di]
    var j = [x, y, di, di]
    var k = [x, y+di, di, di]
    return [h, i, j, k]
#   o o o
#       o
func shape7a(x, y, di):
    var h = [x+di, y, di, di]
    var i = [x+di, y + di, di, di]
    var j = [x+di, y + di*2, di, di]
    var k = [x, y + di*2, di, di]
    return [h, i, j, k]

func shape7b(x, y, di):
    var h = [x, y, di, di]
    var i = [x, y+di, di, di]
    var j = [x + di, y+di, di, di]
    var k = [x + di*2, y+di, di, di]
    return [h, i, j, k]

func shape7c(x, y, di):
    var h = [x, y, di, di]
    var i = [x+di, y, di, di]
    var j = [x, y + di, di, di]
    var k = [x, y + di*2, di, di]
    return [h, i, j, k]

func shape7d(x, y, di):
    var h = [x, y, di, di]
    var i = [x+di, y, di, di]
    var j = [x+di*2, y, di, di]
    var k = [x+di*2, y+di, di, di]
    return [h, i, j, k]

func shapetrix(row, col, x, y, SU):
    if row == 0:
        if col == 0:
            return shape1a(x, y, SU)
        elif col == 1:
            return shape1b(x, y, SU)
        elif col == 2:
            return shape1c(x, y, SU)
        elif col == 3:
            return shape1d(x, y, SU)
    if row == 1:
        if col == 0:
            return shape2a(x, y, SU)
        elif col == 1:
            return shape2b(x, y, SU)
        elif col == 2:
            return shape2c(x, y, SU)
        elif col == 3:
            return shape2d(x, y, SU)
    if row == 2:
        if col == 0:
            return shape3a(x, y, SU)
        elif col == 1:
            return shape3b(x, y, SU)
        elif col == 2:
            return shape3c(x, y, SU)
        elif col == 3:
            return shape3d(x, y, SU)
    if row == 3:
        if col == 0:
            return shape4a(x, y, SU)
        elif col == 1:
            return shape4b(x, y, SU)
        elif col == 2:
            return shape4c(x, y, SU)
        elif col == 3:
            return shape4d(x, y, SU)
    if row == 4:
        if col == 0:
            return shape5a(x, y, SU)
        elif col == 1:
            return shape5b(x, y, SU)
        elif col == 2:
            return shape5c(x, y, SU)
        elif col == 3:
            return shape5d(x, y, SU)
    if row == 5:
        if col == 0:
            return shape6a(x, y, SU)
        elif col == 1:
            return shape6b(x, y, SU)
        elif col == 2:
            return shape6c(x, y, SU)
        elif col == 3:
            return shape6d(x, y, SU)
    if row == 6:
        if col == 0:
            return shape7a(x, y, SU)
        elif col == 1:
            return shape7b(x, y, SU)
        elif col == 2:
            return shape7c(x, y, SU)
        elif col == 3:
            return shape7d(x, y, SU)

func get_shape(x, y, SU, state, shape):
    var choice = 0
    if shape > 0:
        choice = shape % 7
    var rotation = state % 4
    var output = shapetrix(choice, rotation, x, y, SU)
    var h = output[0]
    var i = output[1]
    var j = output[2]
    var k = output[3]
    var xs = [h[0], i[0], j[0], k[0], x]
    var ys = [h[1], i[1], j[1], k[1], y]
    return [h, i, j, k]
