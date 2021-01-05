extends KinematicBody2D

export(NodePath) var tilemap_nodepath
export(NodePath) var blockwall_nodepath

onready var tilemap_node = get_node(tilemap_nodepath)
onready var blockwall_node = get_node(blockwall_nodepath)
onready var sprite = get_node("DumiSprite")
onready var walljump_timer = get_node("WalljumpTimer")
onready var floor_area = get_node("FloorArea")
onready var wall_area = get_node("WallArea")
onready var box_detection_l = get_node("BoxDetectionL")
onready var box_detection_r = get_node("BoxDetectionR")
onready var held_box = get_node("HeldBox")h
onready var box = preload("res://Scene/Box.tscn")

var up = Global.up
var gravity = Global.gravity
var velocity = Global.velocity

var walk_max_speed = 200
var walk_acceleration = 10
var run_max_speed = 300
var run_acceleration = 5
var jump_speed = -365
var wall_drag_timer = 2 
var inertia = 100

var player_state = {
	input_direction = Vector2(0, 0),
	movement = Vector2(0, 0),
	is_running = false,
	is_wall_dragging = false,
	is_wall_drag_enabled = true,
	is_grabbing_box = false
}


func _physics_process(_delta):
	set_movement()
	box_movement()
	pass


func set_movement():
	player_state.input_direction.x = int(Input.is_action_pressed("ui_right")) + int(Input.is_action_pressed("ui_left")) * -1
	player_state.input_direction.y = int(Input.is_action_pressed("ui_down")) + int(Input.is_action_pressed("ui_up")) * -1
	player_state.is_running = Input.is_action_pressed("ui_run")
	player_state.movement.x = sign(velocity.x)
	player_state.movement.y = sign(velocity.y)
	
	velocity.y += gravity	
	var friction = false
	var just_jumped = Input.is_action_just_pressed("ui_jump")
	var max_speed = run_max_speed if player_state.is_running else walk_max_speed
	
	if abs(velocity.x) >= walk_max_speed and !is_on_floor():
		max_speed = abs(velocity.x)
		
	var acceleration = run_acceleration if player_state.is_running and (abs(velocity.x) >= walk_max_speed) else walk_acceleration
	
	if player_state.input_direction.x == 1:
		if player_state.movement.x != player_state.input_direction.x and is_on_floor():
			 velocity.x = int(lerp(velocity.x, 0, 0.2))
		velocity.x = min(velocity.x + acceleration, max_speed) 
		sprite.flip_h = false
		sprite.play("Run")
		sprite.frames.set_animation_speed("Run", 10 if abs(velocity.x) < run_max_speed else 20)
	elif player_state.input_direction.x == -1:
		if player_state.movement.x != player_state.input_direction.x and is_on_floor():
			 velocity.x = int(lerp(velocity.x, 0, 0.2))
		velocity.x = max(velocity.x - acceleration, - max_speed) 
		sprite.flip_h = true
		sprite.play("Run")
		sprite.frames.set_animation_speed("Run", 10 if abs(velocity.x) < run_max_speed else 20)
	else:
		sprite.play("Idle")
		friction = true
					
	if is_on_floor():
		walljump_timer.stop()
		wall_drag_timer = 1
		player_state.is_wall_drag_enabled = true	
		if just_jumped:
			velocity.y = jump_speed if abs(velocity.x) < run_max_speed else jump_speed * 1.1			
		if friction == true:
			velocity.x = int(lerp(velocity.x, 0, 0.2))
	else:
		if velocity.y < (jump_speed + gravity * 5):
			sprite.play("Jump1")
			if Input.is_action_just_released("ui_jump"):
				velocity.y = 0
		elif  velocity.y < 0:
			sprite.play("Jump2")
			if !Input.is_action_just_pressed("ui_jump") and Input.is_action_just_released("ui_jump"):
				velocity.y = 0
		elif velocity.y > 0 and velocity.y <= gravity * 10:
			sprite.play("Fall1")
		else:
			sprite.play("Fall2")
			player_state.movement.y = 0
			
		if player_state.input_direction.x != 0 and player_state.input_direction.x != player_state.movement.x:
			velocity.x = int(lerp(velocity.x, 0, 0.05))
	
	set_wall_jump(just_jumped)
	
	velocity = move_and_slide(velocity, up, false, 4, PI/4, false)


func set_wall_jump(player_jumped):
	if !is_on_floor() and is_on_wall() and !is_wall_jump_blocked() and !player_state.is_grabbing_box:
		if player_state.is_wall_drag_enabled and sign(velocity.y) > 0:
			if walljump_timer.is_stopped():
				walljump_timer.start()
			sprite.flip_h = player_state.input_direction.x > 0
			velocity.y /= 4
			player_state.is_wall_dragging = true
		else:
			player_state.is_wall_dragging = false	

		if player_jumped: 	 
			velocity = Vector2(wall_jump_distance(), jump_speed)


func box_movement():
	if box_detection_r.is_colliding():
		var collider = box_detection_r.get_collider()
		if collider.is_in_group("Boxes") and player_state.input_direction.x > 0:
			if player_state.is_running:
				collider.free()
				player_state.is_grabbing_box = true
			else:
				if !collider.wall_detection.overlaps_body(tilemap_node):
					collider.move_and_slide(Vector2(inertia, 0), up)
			
	if box_detection_l.is_colliding() :
		var collider = box_detection_l.get_collider()
		if collider.is_in_group("Boxes") and player_state.input_direction.x < 0:
			if player_state.is_running:
				collider.free()
				player_state.is_grabbing_box = true
			else:
				if !collider.wall_detection.overlaps_body(tilemap_node):
					collider.move_and_slide(Vector2(-inertia, 0), up)

	if player_state.is_grabbing_box:
		if player_state.is_running == false:
			player_state.is_grabbing_box = false
			held_box.visible = false
			var box_obj = box.instance()
			match sprite.flip_h:
				true:
					box_obj.position = Vector2(self.position.x - 13 if is_on_wall() else - 13, self.position.y + 5)
					get_parent().add_child(box_obj)
				false:
					box_obj.position = Vector2(self.position.x + (13 if !is_on_wall() else 0), self.position.y + 5)
					get_parent().add_child(box_obj)
		else:
			if player_state.input_direction.x > 0:
				held_box.position = Vector2(sprite.position.x + 13, sprite.position.y + 5)
				held_box.visible = true
			
			if player_state.input_direction.x < 0:
				held_box.position = Vector2(sprite.position.x - 13, sprite.position.y + 5)
				held_box.visible = true


func wall_jump_distance():
	var distance = tan(deg2rad(45 if player_state.is_running else 30)) * jump_speed
	return distance if player_state.input_direction.x > 0 else distance * -1


func is_wall_jump_blocked():
	return floor_area.overlaps_body(tilemap_node) or wall_area.overlaps_body(blockwall_node)


func _on_Timer_timeout():
	wall_drag_timer -= 1
	if wall_drag_timer <= 0:
		player_state.is_wall_drag_enabled = false


func _on_DeathArea_body_entered(_body):
	return get_tree().reload_current_scene()

