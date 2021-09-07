extends KinematicBody2D

const G = preload("nodeless/Globals.gd")


export(bool) var player
export(int) var move_speed = 100
export(int) var max_hp
export(Color) var color = Color.blue

var current_action = null
var next_action = null # lets you queue the action while performing the current one
var guard = 0



func _ready():
	if(player):
		assert(get_tree().get_nodes_in_group('player').size() == 0)
		add_to_group('Player') 

func _physics_process(delta):
	var move_dist = move_speed * delta \
		if (current_action == null or not (current_action.flags() & G.TFlags.move_speed)) \
		else current_action.move_speed
	var move_dir = Vector2.ZERO
			
	if(player):
		move_dist = sqrt(pow(move_dist, 2) / 2) # because it is the move dist in only one direction, pythag theorem
		
		if Input.is_key_pressed(KEY_W):
			move_dir += Vector2(0,-1)
		if Input.is_key_pressed(KEY_A):
			move_dir += Vector2(-1,0)
		if Input.is_key_pressed(KEY_S):
			move_dir += Vector2(0,1)
		if Input.is_key_pressed(KEY_D):
			move_dir += Vector2(1,0)
		
		move_and_collide(move_dir * move_dist)

		if current_action == null:
			var actions = get_actions(true)
			if actions != null:
				for action in actions:
					if Input.is_key_pressed(action.key):
							action.start()
							action.tick()
							break;
		else:
			if(current_action.flags() & G.TFlags.lock_pos):
				current_action.global_position -= move_dir * move_dist
				current_action.tick()
			
	else:
		var p_vector = _p_vector()
		move_dir += p_vector.normalized()
		move_and_collide(move_dir * move_dist)
		
		if current_action == null:
			var actions = get_actions(true)
			if (actions != null):
				start_rand_action_from(actions, p_vector)
				current_action.tick()
					
		else:
			if(current_action.flags() & G.TFlags.lock_pos):
				current_action.global_position -= move_dir * move_dist
				current_action.tick()

func start_rand_action_from(actions, p_vector = _p_vector()):
			var weightsum = 0
			for action in actions:
				if(p_vector.length() <= action.ai_start_range):
					weightsum += action.ai_select_weight
			var roll = (randi() % (weightsum - 2)) + 1
			var rand_action
			for action in actions:
				roll -= action.ai_weight
				if(roll <= 0):
					rand_action = action
					break;
			rand_action.start()

func _p_vector():
	return to_local(get_tree().get_nodes_in_group('Player')[0].global_position)

func get_actions(exclude_combo_only):
	var ret = get_children()
	for i in range(ret.size() - 1):
		if not ret[i].is_in_group('Action') or (exclude_combo_only and ret[i].combo_only):
			ret.remove(i)

func _draw():
	draw_circle(Vector2.ZERO, 10, color);
