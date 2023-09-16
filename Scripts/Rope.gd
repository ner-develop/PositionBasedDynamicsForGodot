extends Node3D

class_name Rope

@export_category("Settings")
@export var particles:Array[Particle] = []

@export_category("Input")
@export  var speed:float = 3.0

var simulator
var velocity:Vector3 = Vector3.ZERO

func _ready():
	var priority: int = -1
	for node in get_children():
		if node is PBD and node.priority > priority:
			priority = node.priority
			simulator = node as PBD
		if node is XPBD and node.priority > priority:
			priority = node.priority
			simulator = node as XPBD
	
	if simulator != null:
		simulator.initialize(particles)


func _physics_process(delta):
	global_position += velocity * delta
	velocity = lerp(velocity, Vector3.ZERO, 3 * delta)
	simulator.step(delta)


func _input(event):
	velocity = Vector3.ZERO
	if event.is_action("move_forward"):
		velocity += speed * Vector3.FORWARD
	if event.is_action("move_back"):
		velocity += speed * Vector3.BACK
	if event.is_action("move_right"):
		velocity += speed * Vector3.RIGHT
	if event.is_action("move_left"):
		velocity += speed * Vector3.LEFT
	if event.is_action("move_up"):
		velocity += speed * Vector3.UP
	if event.is_action("move_down"):
		velocity += speed * Vector3.DOWN
	
