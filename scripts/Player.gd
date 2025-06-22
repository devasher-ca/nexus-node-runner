extends CharacterBody2D

class_name Player

# Movement constants
const SPEED = 300.0
const JUMP_VELOCITY = -650.0  # Increased for better platform reaching
const ACCELERATION = 1500.0
const FRICTION = 1200.0

# Game state
var shards_collected = 0
var can_interact = false
var nearby_node = null

# Signals
signal shard_collected(count)
signal node_interaction(node)

func _ready():
	# Connect to game events
	pass

func _physics_process(delta):
	# Check if game is over - disable all player input
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.current_state == game_manager.GameState.GAME_OVER:
		# Only apply gravity, no player input allowed
		if not is_on_floor():
			velocity.y += get_gravity().y * delta
		# Stop horizontal movement
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		move_and_slide()
		return
	
	# Add gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_play_jump_sound()
	
	# Handle movement
	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		_update_sprite_direction(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	# Handle node interaction
	if Input.is_action_just_pressed("interact") and can_interact and nearby_node:
		node_interaction.emit(nearby_node)
	
	move_and_slide()

func _update_sprite_direction(direction):
	if direction > 0:
		$AnimatedSprite2D.flip_h = false
	elif direction < 0:
		$AnimatedSprite2D.flip_h = true

func _play_jump_sound():
	if $JumpSound:
		$JumpSound.play()

func collect_shard():
	shards_collected += 1
	shard_collected.emit(shards_collected)
	_play_collect_sound()

func _play_collect_sound():
	if $CollectSound:
		$CollectSound.play()

func _on_area_2d_body_entered(body):
	if body.is_in_group("nexus_nodes"):
		can_interact = true
		nearby_node = body
		_show_interaction_hint()

func _on_area_2d_body_exited(body):
	if body.is_in_group("nexus_nodes"):
		can_interact = false
		nearby_node = null
		_hide_interaction_hint()

func _show_interaction_hint():
	if $InteractionHint:
		$InteractionHint.visible = true

func _hide_interaction_hint():
	if $InteractionHint:
		$InteractionHint.visible = false

func reset_player():
	shards_collected = 0
	velocity = Vector2.ZERO
	can_interact = false
	nearby_node = null 