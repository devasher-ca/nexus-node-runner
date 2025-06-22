extends StaticBody2D

class_name NexusNode

# Node states
enum NodeState {
	INACTIVE,
	READY,
	ACTIVE,
	COMPLETED
}

var current_state = NodeState.INACTIVE
var required_shards = 12  # Dramatically increased from 3 to 12
var is_player_nearby = false

# Visual effects
var glow_intensity = 0.0
var pulse_speed = 2.0

# Signals
signal puzzle_requested(node)
signal node_completed(node)

func _ready():
	# Add to nexus nodes group
	add_to_group("nexus_nodes")
	
	# Set up visuals
	_setup_node_visuals()
	
	# Set up collision layers
	collision_layer = 8  # Nodes layer
	collision_mask = 0   # Nodes don't collide with anything

func _setup_node_visuals():
	# Create main sprite if it doesn't exist
	if not $Sprite2D:
		var sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
		
		# Create node texture
		var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		
		# Draw hexagonal node
		var center = Vector2(32, 32)
		var radius = 28
		
		# Fill hexagon
		for x in range(64):
			for y in range(64):
				var pos = Vector2(x, y)
				var dist = pos.distance_to(center)
				if dist <= radius:
					var hex_dist = _hexagon_distance(pos - center, radius)
					if hex_dist <= 1.0:
						var alpha = 1.0 - hex_dist
						image.set_pixel(x, y, Color(0.2, 0.8, 1.0, alpha))
		
		var texture = ImageTexture.create_from_image(image)
		sprite.texture = texture
	
	# Create glow effect
	if not $GlowSprite:
		var glow_sprite = Sprite2D.new()
		glow_sprite.name = "GlowSprite"
		glow_sprite.texture = $Sprite2D.texture
		glow_sprite.modulate = Color(0.0, 1.0, 1.0, 0.0)
		glow_sprite.scale = Vector2(1.5, 1.5)
		glow_sprite.z_index = -1
		add_child(glow_sprite)

func _hexagon_distance(pos: Vector2, radius: float) -> float:
	# Simplified hexagon distance calculation
	var abs_pos = pos.abs()
	var q = abs_pos.x * 0.866025 + abs_pos.y * 0.5
	var r = abs_pos.y
	return max(abs(q), abs(r), abs(q - r)) / radius

func _physics_process(delta):
	_update_visuals(delta)
	_check_activation_conditions()

func _update_visuals(delta):
	match current_state:
		NodeState.INACTIVE:
			glow_intensity = lerp(glow_intensity, 0.0, delta * 3.0)
		NodeState.READY:
			var time = Time.get_ticks_msec() / 1000.0
			var pulse = sin(time * pulse_speed) * 0.5 + 0.5
			glow_intensity = lerp(glow_intensity, 0.3 + pulse * 0.4, delta * 5.0)
		NodeState.ACTIVE:
			glow_intensity = lerp(glow_intensity, 0.8, delta * 5.0)
		NodeState.COMPLETED:
			glow_intensity = lerp(glow_intensity, 1.0, delta * 2.0)
	
	if $GlowSprite:
		$GlowSprite.modulate.a = glow_intensity

func _check_activation_conditions():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var old_state = current_state
	
	# Check if player has enough shards and is ready to activate
	if current_state == NodeState.INACTIVE and player.shards_collected >= required_shards:
		current_state = NodeState.READY
	
	# If state changed, update visuals
	if old_state != current_state:
		_on_state_changed()

func _on_state_changed():
	match current_state:
		NodeState.READY:
			_show_ready_indicator()
		NodeState.ACTIVE:
			_show_active_indicator()
		NodeState.COMPLETED:
			_show_completed_indicator()

func _show_ready_indicator():
	# Create floating text indicator
	if not $ReadyLabel:
		var label = Label.new()
		label.name = "ReadyLabel"
		label.text = "READY TO ACTIVATE"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(-64, -80)
		label.modulate = Color.YELLOW
		add_child(label)

func _show_active_indicator():
	if $ReadyLabel:
		$ReadyLabel.queue_free()

func _show_completed_indicator():
	if not $CompletedLabel:
		var label = Label.new()
		label.name = "CompletedLabel"
		label.text = "NODE ACTIVATED"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(-64, -80)
		label.modulate = Color.GREEN
		add_child(label)

func activate():
	if current_state != NodeState.READY:
		return false
	
	# Check if game is over - disable activation
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.current_state == game_manager.GameState.GAME_OVER:
		return false
	
	current_state = NodeState.ACTIVE
	puzzle_requested.emit(self)
	return true

func complete_puzzle(success: bool):
	if success:
		current_state = NodeState.COMPLETED
		node_completed.emit(self)
		_play_completion_effect()
	else:
		current_state = NodeState.READY

func _play_completion_effect():
	# Create completion particles/effects
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scale pulse effect
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.2)
	
	# Sound effect
	if $CompletionSound:
		$CompletionSound.play() 
