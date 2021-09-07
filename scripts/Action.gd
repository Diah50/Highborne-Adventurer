extends Node2D

const G = preload("nodeless/Globals.gd")

export(int) var key

export(int) var arc # in terms of 2PI
export(int) var rng # "range" namespace is taken

export(int) var ai_start_range
export(float) var ai_weight
export(Array, NodePath) var combo_actions = []
export(bool) var combo_only = false
export(float) var move_speed


export(int) var dmg
export(int) var stun
export(float) var stun_time
export(int) var guard




# phase_times[max] is the end tick, exclusive.
# Otherwise phase_times[x] corresponds to start time of phase_flags[x]
export(Array, int) var phase_times = [60]
export(Array, int, FLAGS, "damage_and_stun", \
"move_speed", "guard", "invincibility", "telegraph", "lock_pos", "no_rot") var phase_flags = [16]
export(Color) var hitbox_border_color = Color.yellow
export(Color) var hitbox_damage_color = Color.red
export(Color) var hitbox_color = Color.lightgray

var tick_no = -1 # -1 for inactive, otherwise which tick we are on, starting at 0
var interval_no = 0
var damaged_units = []
var remaining_guard : int

func _ready():
	for flags in phase_flags:
		# assure no incompatible flag combos
		assert(not ((flags % G.TFlags.damage_and_stun) and (flags % G.TFlags.telegraph))) 


# starts the action, but does NOT tick it.
func start():
	get_parent().current_action = self
	tick_no = -1
	interval_no = 0
	get_parent().guard = guard

func tick():
	tick_no += 1
	if(phase_times[interval_no] < tick_no):
		interval_no += 1
		
	var flags = flags()
	
	if not (flags & G.TFlags.landing):
		position = Vector2.ZERO
		rotation = 0
	
	if flags & G.TFlags.damage_and_stun:
		for unit in get_tree().get_nodes_in_group("Unit"):
			var vec = unit.global_position - global_position
			if(vec.length() <= rng and abs(vec.angle() - global_rotation) <= arc / 2):
				damage_and_stun(unit)

	if(phase_times[phase_times.size()-1] == tick_no+1):
		end()

func damage_and_stun(unit):
	unit.hp -= dmg
	if(unit.hp <= 0):
		unit.queue_free()
	var action = unit.current_action
	if action == null or not (action.flags() & G.TFlags.guard):
		unit.stun(stun_time)
	else:
		unit.guard -= stun
		if(unit.guard <= 0):
			unit.stun(stun_time)

func end():
	var parent = get_parent()
	if parent.player or combo_actions == []:
		parent.current_action = parent.next_action
		parent.next_action = null
	else:
		parent.start_rand_action_from(combo_actions)

func flags():
	return phase_flags[interval_no]
	
	
	
	
func _draw():
	if(flags() & G.TFlags.damage_and_stun):
		_draw_arc_poly(hitbox_damage_color)
	elif(flags() & G.TFlags.telegraph):
		_draw_arc_poly(hitbox_color)
		_draw_arc_border(hitbox_border_color)


func _draw_arc_border(color):
		draw_arc(Vector2.ZERO, rng , deg2rad(-arc - 0), deg2rad(arc + 0), G.circle_points, color, 2, true)
		draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(deg2rad(-arc)) * rng, color, 2, true)
		draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(deg2rad(arc)) * rng, color, 2, true)
	
# https://godotengine.org/qa/3843/is-it-possible-to-draw-a-circular-arc	
func _draw_arc_poly(color):
	var pointsArc = PoolVector2Array([])
	pointsArc.push_back(Vector2.ZERO)
	for i in range(G.circle_points+1):
		var anglePoint = deg2rad(arc) + i*(deg2rad(-arc)-deg2rad(arc))/G.circle_points
		pointsArc.push_back(Vector2.ZERO + Vector2( cos(anglePoint), sin(anglePoint) )* rng)
	draw_polygon(pointsArc, PoolColorArray([color]), PoolVector2Array(), null, null, true)
