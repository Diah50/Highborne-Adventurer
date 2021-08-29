extends Node2D

const Globals = preload("nodeless/Globals.gd")
const TFlags = preload("nodeless/TFlags.gd")

export(int) var key

export(int) var arc # in terms of 2PI
export(int) var rng # "range" namespace is taken

export(int) var ai_start_range
export(float) var ai_start_select_weight
export(Array, float) var ai_followup_action_chances = []
export(Array, NodePath) var followup_actions = []


export(int) var dmg
export(int) var stun
export(float) var stun_time
export(int) var guard
export(int) var guard_break
export(float) var speed_mod



# timeline_intervals[max] is the end tick, exclusive.
# Otherwise timeline_intervals[x] corresponds to start time of timeline_flags[x]
export(Array, int) var timeline_intervals 
export(Array, int, FLAGS, "damage_and_stun", \
"guard", "speed_mod", "telegraph", "lock_pos", "no_rot") var timeline_flags = []
export(Color) var hitbox_border_color
export(Color) var hitbox_damage_color
export(Color) var hitbox_color

var tick_no = -1 # -1 for inactive, otherwise which tick we are on, starting at 0
var interval_no = 0
var damaged_units = []
var remaining_guard : int

func _ready():
	for flags in timeline_flags:
		# assure no incompatible flag combos
		assert(not ((flags % TFlags.damage_and_stun) and (flags % TFlags.telegraph))) 


# starts the action, but does NOT tick it.
func start():
	get_parent().current_action = self
	tick_no = -1
	interval_no = 0
	get_parent().guard = guard

func tick():
	tick_no += 1
	if(timeline_intervals[interval_no] < tick_no):
		interval_no += 1
		
	var flags = flags()
	
	if not (flags & TFlags.landing):
		position = Vector2.ZERO
		rotation = 0
	
	if flags & TFlags.damage_and_stun:
		for unit in get_tree().get_nodes_in_group("Unit"):
			var vec = unit.global_position - global_position
			if(vec.length() <= rng and abs(vec.angle() - global_rotation) <= arc):
				damage_and_stun(unit)

	if(timeline_intervals[timeline_intervals.size()-1] == tick_no+1):
		end()

func damage_and_stun(unit):
	unit.hp -= dmg
	if(unit.hp <= 0):
		unit.queue_free()
	var action = unit.current_action
	if action == null or not (action.flags() & TFlags.guard):
		unit.stun(stun_time)
	else:
		unit.guard -= stun
		if(unit.guard <= 0):
			unit.stun(stun_time)

func end():
	var parent = get_parent()
	if parent.player or parent.ai_followup_action_chances == []:
		parent.current_action = parent.next_action
		parent.next_action = null
	else:
		parent.start_rand_action_from(ai_followup_action_chances)

func flags():
	return timeline_flags[interval_no]
	
# https://godotengine.org/qa/3843/is-it-possible-to-draw-a-circular-arc	
func draw_arc_border(color):
	draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(-arc) * rng, color)
	draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(arc) * rng, color)
	var pointsArc = PoolVector2Array([])
	var angleFrom = -arc
	var angleTo = arc
	for i in range(Globals.circle_points+1):
		var anglePoint = angleFrom + i*(angleTo-angleFrom)/Globals.circle_points - 90
		pointsArc.push_back(Vector2.ZERO + Vector2( cos( deg2rad(anglePoint) ), sin( deg2rad(anglePoint) ) )* rng)
		draw_polygon(pointsArc, PoolColorArray([color]))
	
func _draw():
	if(timeline_flags % TFlags.damage_and_stun):
		draw_arc(Vector2.ZERO, rng, -arc, arc, Globals.circle_points, hitbox_damage_color)
	elif(timeline_flags % TFlags.telegraph):
		draw_arc(Vector2.ZERO, rng, -arc, arc, Globals.circle_points, hitbox_color)
