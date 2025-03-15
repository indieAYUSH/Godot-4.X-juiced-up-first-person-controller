class_name PLAYER_MOVEMENT
extends CharacterBody3D

@export_group("gamejuice_things")
@export var sprint_fov: float = 30
@export var camera_fov_default: float = 75.0



#NODES
@onready var un_crouched_collision_shape = $un_crouched_collision_shape
@onready var crouched_collision_shape = $crouched_collision_shape
@onready var obstacle_checker = $head/obstacle_check/obstacle_checker
@onready var camera = $head/eye/Camera3D
@onready var head = $head
@onready var eye = $head/eye


# Debug variables
var PLAYER_SPEED = self.velocity.length()
@onready var speed_label = $UI/player_movement_Debugger/player_states_and_speed/speed_label
@onready var state = $UI/player_movement_Debugger/player_states_and_speed/state

# States
@export_group("Player_states")
@export var WALKING: bool = false
@export var CROUCHING: bool = false
@export var SPRINTING: bool = false
@export var IDLE: bool = true
@export var SHOOTING: bool = false
@export var SLIDING : bool = false
@export var player_state: String = "IDLE"
var direction = Vector3.ZERO

# Nodes
@export_group("MOVEMENT_VARIABLE")

# Movement Variables
@export_group("MOVEMENT_VARIABLE")
var SPEED: float = 5.0
const JUMP_VELOCITY = 4.5
@export var walking_speed: float = 8.0
@export var crouch_walking_speed: float = 5.0
@export var sprinting_speed: float = 12.0

# Sensitivity and Mouse Movement
@export var sensitivity: float = 0.01
@export var captured: bool = true

# CROUCHING_HANDLES
@export var crouching_depth: float = -0.6


# VARIABLE_FOR_PROCEDURAL_ANIMATION
@export_group("Animation_Things")
@export var lerp_speed: float = 15.0
  #head_bob_things
const  head_bobing_sprinting_speed : float = 22.0
const  head_bobing_walking_speed : float = 14.0
const  head_bobing_crouching_speed : float = 8.0

const   head_bobing_sprinting_intensity: float = 0.4
const   head_bobing_walking_intensity: float = 0.2
const   head_bobing_crouching_intensity: float = 0.1

var head_bob_vector : Vector2 = Vector2.ZERO
var head_bobing_index: float = 0.0
var head_bobing_current_intensity : float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	SPEED = walking_speed
	speed_label.text = "SPEED: " + str(PLAYER_SPEED)

	# Initialize crouch state
	crouched_collision_shape.disabled = true
	un_crouched_collision_shape.disabled = false
	obstacle_checker.add_exception(self)



# Head rotation handling
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_x(deg_to_rad(-event.relative.y * sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		rotate_y(deg_to_rad(-event.relative.x * sensitivity))

func _physics_process(delta):
	PLAYER_SPEED = self.velocity.length()
	speed_label.text = "SPEED: " + str(PLAYER_SPEED)

	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		player_state = "IN AIR"
	else:
		player_state = "IDLE"  # Default state

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Process movement input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), lerp_speed * delta)

	# Determine movement state before applying speed changes
	var dir_length = direction.length()
	if dir_length > 0.1:
		WALKING = true
		IDLE = false
	else:
		WALKING = false
		IDLE = true

	# Apply movement velocity
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
	# Handle sprinting and crouching before final state decision
	_sprint(delta)
	_crouch(delta)
	_state_manager(delta)
	state.text = "State: " + player_state  # Debug text update
	#head_bob
	_head_bobing_manager(delta)
#SPRINTING_AND_CROUCHING_RELATED_HANDLES
	if !CROUCHING and !SPRINTING:
		SPEED= walking_speed

# SPRINTING_AND_CROUCHING
func _crouch(delta):
	if Input.is_action_pressed("crouch"):
		SPEED = crouch_walking_speed
		CROUCHING = true
		camera.fov = lerp(camera.fov, camera_fov_default - 5, delta * lerp_speed)
		head.position.y = lerp(head.position.y, crouching_depth + 0.651, delta * lerp_speed)
		crouched_collision_shape.disabled = false
		un_crouched_collision_shape.disabled = true
	elif !obstacle_checker.is_colliding():
		CROUCHING = false
		head.position.y = lerp(head.position.y, 0.651, delta * lerp_speed)
		crouched_collision_shape.disabled = true
		un_crouched_collision_shape.disabled = false

func _sprint(delta):
	# Sprinting should only work if WALKING is true and not crouching
	if Input.is_action_pressed("sprint") and WALKING and not CROUCHING  and is_on_floor():
		SPEED = sprinting_speed
		SPRINTING = true
		camera.fov = lerp(camera.fov, sprint_fov + camera_fov_default, delta * lerp_speed)
	else:
		SPRINTING = false



func _state_manager(delta) : 
#head_boband _states
	# Prioritize states: Sprinting > Crouching > Walking > Idle
	if SPRINTING:
		player_state = "Sprinting"
		head_bobing_index += head_bobing_sprinting_speed*delta
		head_bobing_current_intensity = head_bobing_sprinting_intensity
	elif CROUCHING:
		player_state = "Crouched"
		head_bobing_index += head_bobing_crouching_speed*delta
		head_bobing_current_intensity = head_bobing_crouching_intensity
	elif WALKING:
		player_state = "Walking"
		head_bobing_index += head_bobing_walking_speed*delta
		head_bobing_current_intensity = head_bobing_walking_intensity
	else:
		player_state = "Idle"
		head_bobing_index = 0.0
		head_bobing_current_intensity = 0.0


func  _head_bobing_manager(delta):
	if direction.length() > 0.1 and !SLIDING and is_on_floor():
		head_bob_vector.y = sin(head_bobing_index)*head_bobing_current_intensity 
		head_bob_vector.x = sin(head_bobing_index/2.0) *head_bobing_current_intensity + 0.5
		
		eye.position.y = lerp(eye.position.y , head_bob_vector.y/2.0 , delta*lerp_speed)
		eye.position.x = lerp(eye.position.x, head_bob_vector.x , delta*lerp_speed)
