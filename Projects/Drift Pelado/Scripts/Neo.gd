extends KinematicBody2D

const UP = Vector2(0, -1)
const GRAVITY = 20
const MAX_SPEED = 200
const ACCELERATION = 50
const JUMP_HEIGHT = -550
var motion = Vector2()
onready var sprite = get_node("Sprite") 

func _physics_process(delta):
	motion.y += GRAVITY;
	var friction = false
	
	if Input.is_action_pressed("ui_right") and !Input.is_action_pressed("ui_left"):
		motion.x = min(motion.x+ACCELERATION, MAX_SPEED)
		sprite.flip_h = false
		sprite.play("Run")
	elif Input.is_action_pressed("ui_left") and  !Input.is_action_pressed("ui_right"):
		motion.x = max(motion.x-ACCELERATION, -MAX_SPEED)
		sprite.flip_h = true
		sprite.play("Run")
	else:
		sprite.play("Idle")
		friction = true
		
	if is_on_floor():
		if Input.is_action_just_pressed("ui_up"):
			motion.y = JUMP_HEIGHT - GRAVITY
		if friction == true:
			motion.x = lerp(motion.x, 0, 0.2);
	else:
		if motion.y <= JUMP_HEIGHT + (GRAVITY * 3):
			sprite.play("JumpStart")
			if Input.is_action_just_released("ui_up"):
				motion.y = 0
		elif motion.y < 0:
			sprite.play("Jump")
			if Input.is_action_just_released("ui_up"):
				motion.y = 0
		elif motion.y > 0 and motion.y <= (GRAVITY * 20):
			sprite.play("FallStart")
		else:
			sprite.play("FallEnd")
			
		if friction == true:
			motion.x = lerp(motion.x, 0, 0.5);
	
	motion = move_and_slide(motion, UP)	
	pass
