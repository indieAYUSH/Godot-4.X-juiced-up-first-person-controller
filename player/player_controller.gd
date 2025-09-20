# PLAYER_MOVEMENT.gd
# ------------------------------------------------------------------------------
# This script controls 3D player movement for a first-person game. It manages:
# - Movement states (walking, sprinting, crouching, jumping, idle, sliding)
# - Visual effects (camera FOV changes, head bobbing, rolling)
# - Animation triggers based on movement and state transitions
# ------------------------------------------------------------------------------
class_name PLAYER_MOVEMENT
extends CharacterBody3D

# ==============================================================================
#                          GLOBAL CONFIGURATION
# ==============================================================================
#======GRAVITY=============#
@export var gravity : float = 9.8


# --- Visual Effects Settings ---
@export_group("gamejuice_things")
@export var sprint_fov: float = 15                   # Additional FOV when sprinting
@export var camera_fov_default: float = 75.0         # Default camera field-of-view
@export var animation_player_speed : float = 1.0     # Speed of animations

# --- Movement Speeds & Parameters ---
@export_group("MOVEMENT_VARIABLE")
var SPEED: float = 0.0                              # Active movement speed
@export var walking_speed: float = 7.0              # Speed when walking
@export var crouch_walking_speed: float = 5.0       # Speed when crouching
@export var sprinting_speed: float = 10.5           # Speed when sprinting
@export var JUMP_VELOCITY = 5.5                           # Impulse strength for jumping

# --- Mouse & Camera Settings ---
@export var sensitivity: float = 0.01               # Mouse look sensitivity
@export var captured: bool = true                   # Whether mouse is captured

# --- Crouching Settings ---
@export var crouching_depth: float = -0.6           # Head lowering value during crouch

#========== SLIDE VAR =========#
var slide_timer : float = 0.0
@export var slide_timer_max : float = 1.0
var slide_dir: Vector2 = Vector2.ZERO
@export var sliding_speed: float = 13.0
@export var slide_tilt :float = -8.0

# --- Head Bobbing & Animation ---
@export_group("Animation_Things")
@export var lerp_speed: float = 15.0                # Lerp factor for smooth transitions
const head_bobing_sprinting_speed : float = 22.0     # Bobbing speed multiplier (sprinting)
const head_bobing_walking_speed : float = 14.0       # Bobbing speed multiplier (walking)
const head_bobing_crouching_speed : float = 8.0      # Bobbing speed multiplier (crouching)
const head_bobing_sprinting_intensity: float = 0.4   # Bobbing intensity (sprinting)
const head_bobing_walking_intensity: float = 0.2     # Bobbing intensity (walking)
const head_bobing_crouching_intensity: float = 0.1   # Bobbing intensity (crouching)

# --- Node References ---
@onready var un_crouched_collision_shape = $un_crouched_collision_shape  # Collision shape (standing)
@onready var crouched_collision_shape = $crouched_collision_shape        # Collision shape (crouched)
@onready var obstacle_checker = $head/obstacle_check/obstacle_checker      # Checks for obstacles overhead
@onready var camera = $head/eye/Camera3D                                   # Main camera node
@onready var head = $head                                                 # Head node (for rotation/position)
@onready var eye = $head/eye                                              # Eye node (for head bobbing)
@onready var player_animation  = $PLAYER_ANIMATION                        # Animation player node
@onready var character_body_3d = $"."

# --- Debug Displays ---
var PLAYER_SPEED = self.velocity.length()            # Current speed for debugging
@onready var speed_label = $UI/player_movement_Debugger/player_states_and_speed/speed_label
@onready var state = $UI/player_movement_Debugger/player_states_and_speed/state

# ==============================================================================
#                          PLAYER STATE & INPUT
# ==============================================================================

# --- Player State Booleans ---
@export_group("Player_states")
var WALKING: bool = false
var CROUCHING: bool = false
var SPRINTING: bool = false
var IDLE: bool = true
var SHOOTING: bool = false
var SLIDING : bool = false
@export var player_state: String = "IDLE"              # Descriptive state for debugging
var can_sprint  : bool = false

# --- Direction & Input ---
var direction = Vector3.ZERO                        # 3D movement direction vector
var input_dir: Vector2                              # 2D input vector from player

# --- Last Velocity Storage ---
var LAST_VELOCITY : Vector3 = Vector3.ZERO         # To detect landing impact and trigger animations

# --- Head Bobbing Variables ---
var head_bob_vector : Vector2 = Vector2.ZERO         # Stores computed bobbing offset
var head_bobing_index: float = 0.0                   # Sine wave index for bobbing
var head_bobing_current_intensity : float = 0.0      # Current bobbing intensity based on state

# ==============================================================================
#                                FUNCTIONS
# ==============================================================================

# --- _ready: Initialization ---
func _ready():
	# Capture the mouse for FPS control.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Initialize speed and debug display.
	SPEED = walking_speed
	speed_label.text = "SPEED: " + str(PLAYER_SPEED)
	
	# Set initial collision shapes for standing.
	crouched_collision_shape.disabled = true
	un_crouched_collision_shape.disabled = false
	
	# Prevent self-collision in obstacle checking.
	obstacle_checker.add_exception(self)

# --- _unhandled_input: Mouse Look ---
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Vertical rotation: adjust head pitch and clamp between -89° and 89°.
		head.rotate_x(deg_to_rad(-event.relative.y * sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		# Horizontal rotation: rotate the player body.
		rotate_y(deg_to_rad(-event.relative.x * sensitivity))

# --- _physics_process: Main Loop ---
func _physics_process(delta):
	# Update debug speed.
	PLAYER_SPEED = self.velocity.length()
	speed_label.text = "SPEED: " + str(PLAYER_SPEED)
	
	# ----- Gravity and Landing -----
	if not is_on_floor():
		velocity.y -= gravity * delta
		player_state = "IN AIR"
	else:
		player_state = "IDLE"
		if LAST_VELOCITY.y < -10.0:
			player_animation.play("roll")
			print(LAST_VELOCITY)
		elif LAST_VELOCITY.y < 0.0:
			print("land")
			player_animation.play("landing")
	
	# ----- Jumping -----
	if Input.is_action_just_pressed("jump") and is_on_floor():
		player_animation.play("jump")
		velocity.y = JUMP_VELOCITY
		SLIDING = false

	# ----- Movement Input -----
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	# Smooth directional input based on current state.
	if is_on_floor():
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), lerp_speed * delta)
	elif input_dir != Vector2(0, 0):
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), lerp_speed * delta)
	
	# Set WALKING state if there is sufficient input.
	if direction.length() > 0.1:
		WALKING = true
		IDLE = false
	else:
		WALKING = false
		IDLE = true
	
	#===== APPLYING SLIDE MOVEMENT =====#
	if SLIDING:
		velocity.x = direction.x * (slide_timer + 0.1) * sliding_speed  
		velocity.z = direction.z * (slide_timer + 0.1) * sliding_speed  
	else:
		# ----- Apply Standard Movement -----
		velocity.x = direction.x * SPEED if direction else 0.0
		velocity.z = direction.z * SPEED if direction else 0.0

	LAST_VELOCITY = velocity
	move_and_slide()
	
	# ----- State-Specific Actions -----
	_sprint(delta)
	_crouch(delta)
	_state_manager(delta)
	_head_bobing_manager(delta)
	_slide(delta)
	state.text = "State: " + player_state
	
	# Reset to walking speed and default FOV if neither sprinting nor crouching.
	if not CROUCHING and not SPRINTING and !SLIDING:
		SPEED = walking_speed
		camera.fov = lerp(camera.fov, camera_fov_default, delta * lerp_speed)
	
	# ----- Sideway Animation Handling -----
	_handle_sideway_animation()
	
	#===========================SPRINT SHITS
 

# --- _crouch: Manage Crouching ---
func _crouch(delta):
	if Input.is_action_pressed("crouch") or SLIDING:
		SPEED = crouch_walking_speed
		CROUCHING = true
		# Lower camera FOV slightly for crouching.
		camera.fov = lerp(camera.fov, camera_fov_default - 5, delta * lerp_speed)
		# Lower head position.
		head.position.y = lerp(head.position.y, crouching_depth + 0.651, delta * lerp_speed)
		crouched_collision_shape.disabled = false
		un_crouched_collision_shape.disabled = true
		# -------- SLIDE MANAGEMENT --------
		if SPRINTING and input_dir != Vector2.ZERO:
			SLIDING = true
			slide_dir = input_dir
			slide_timer = slide_timer_max
			print("can_slide")
	elif not obstacle_checker.is_colliding():
		# Stand up if no obstacle overhead.
		CROUCHING = false
		head.position.y = lerp(head.position.y, 0.651, delta * lerp_speed)
		crouched_collision_shape.disabled = true
		un_crouched_collision_shape.disabled = false

# --- _sprint: Manage Sprinting ---
func _sprint(delta):
	# Sprint if moving forward, walking, not crouching, and on the ground.
	if Input.is_action_pressed("sprint") and WALKING and not CROUCHING and is_on_floor() and input_dir.y == -1 :
		SPEED = sprinting_speed
		SPRINTING = true
		# Widen camera FOV during sprint.
		camera.fov = lerp(camera.fov, sprint_fov + camera_fov_default, delta * lerp_speed)
	else:
		SPRINTING = false

# --- _state_manager: Update State & Head Bobbing Setup ---
func _state_manager(delta):
	# Prioritize: Sprint > Sliding > Crouch > Walk > Idle.
	if SPRINTING:
		player_state = "Sprinting"
		head_bobing_index += head_bobing_sprinting_speed * delta
		head_bobing_current_intensity = head_bobing_sprinting_intensity
	elif  SLIDING:
		player_state = "Sliding"
		head_bobing_index += head_bobing_crouching_speed * delta*0
		head_bobing_current_intensity = head_bobing_crouching_intensity*0
	elif CROUCHING:
		player_state = "Crouched"
		head_bobing_index += head_bobing_crouching_speed * delta
		head_bobing_current_intensity = head_bobing_crouching_intensity
	elif WALKING:
		player_state = "Walking"
		head_bobing_index += head_bobing_walking_speed * delta
		head_bobing_current_intensity = head_bobing_walking_intensity
	else:
		player_state = "Idle"
		head_bobing_index = 0.0
		head_bobing_current_intensity = 0.0

# --- _head_bobing_manager: Calculate and Apply Head Bobbing ---
func _head_bobing_manager(delta):
	if direction.length() > 0.1 and not SLIDING and is_on_floor():
		# Compute vertical and horizontal bobbing offsets.
		head_bob_vector.y = sin(head_bobing_index) * head_bobing_current_intensity
		head_bob_vector.x = sin(head_bobing_index / 2.0) * head_bobing_current_intensity + 0.5
		print(head_bob_vector)
		# Smoothly update eye position.
		eye.position.y = lerp(eye.position.y, head_bob_vector.y / 2.0, delta * lerp_speed)
		eye.position.x = lerp(eye.position.x, head_bob_vector.x, delta * lerp_speed)

# ----- Handling Sideway Animation -----
func _handle_sideway_animation():
	if input_dir.x == 1.0:
		player_animation.play("side_way_movement_right", animation_player_speed)
	if input_dir.x == -1.0:
		player_animation.play("side_way_movement_left", animation_player_speed)

# ================== SLIDE MANAGEMENT =================#
func _slide(delta):
	if SLIDING:
		slide_timer -= delta
		camera.rotation.z = lerp(camera.rotation.z , -deg_to_rad(slide_tilt) , delta*lerp_speed)
		camera.fov = lerp(camera.fov , 25 + camera_fov_default, delta * lerp_speed)
		if slide_timer <= 0:
			SLIDING = false
			camera.rotation.z = lerp(eye.rotation.x , 0.0  , delta *lerp_speed)
			print("slide ended")
			print(slide_dir)
