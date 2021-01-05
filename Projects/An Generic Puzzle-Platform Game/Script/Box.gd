extends KinematicBody2D

var up = Global.up
var gravity = Global.gravity
var velocity = Global.velocity
var denis = Vector2(0,0)

onready var wall_detection = get_node("WallDetection") 

func _physics_process(_delta):
	velocity.y += gravity
	velocity = move_and_slide(velocity, up)