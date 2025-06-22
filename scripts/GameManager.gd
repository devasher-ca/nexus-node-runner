extends Node

class_name GameManager

# Game state
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	LEVEL_COMPLETE
}

var current_state = GameState.MENU
var current_level = 1
var max_levels = 3

# Scene references
var player: Player
var hud: HUD
var puzzle_popup: PuzzlePopup
var level_scene: Node2D
var camera: Camera2D
var pause_menu: CanvasLayer

# Game statistics
var total_shards_in_level = 0
var total_nodes_in_level = 0
var completed_nodes = 0

# Player life system
var player_lives = 3
var max_lives = 3
var checkpoint_position = Vector2.ZERO
var shards_lost_on_death = 2
var puzzle_failure_penalty = 1

# Level timer for extreme difficulty
var level_time_limit = 90.0  # Only 45 seconds per level!
var level_timer = 0.0

# Signals
signal level_completed
signal game_completed

func _ready():
	# Connect to scene tree events
	get_tree().paused = false
	
	# Set up pause handling
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Get references
	hud = $HUD
	puzzle_popup = $PuzzlePopup
	camera = $Camera2D
	pause_menu = $PauseMenu
	
	# Connect puzzle popup signals
	if puzzle_popup:
		puzzle_popup.puzzle_completed.connect(_on_puzzle_completed)
	
	# Add to game manager group for easy access
	add_to_group("game_manager")
	
	# Start the game
	start_game()

func _input(event):
	# Debug logging for input events
	if event.is_action_pressed("ui_cancel"):
		print("ESC pressed - Current state: ", GameState.keys()[current_state])
	if event.is_action_pressed("restart_level"):
		print("R pressed - Current state: ", GameState.keys()[current_state])
	
	# Handle game over inputs first (highest priority)
	if current_state == GameState.GAME_OVER:
		if event.is_action_pressed("restart_level"):  # R key
			print("Restarting level from game over")
			restart_current_level()
			get_viewport().set_input_as_handled()  # Prevent other nodes from handling this event
			return
		elif event.is_action_pressed("ui_cancel"):  # ESC key
			print("Returning to menu from game over")
			return_to_menu()
			get_viewport().set_input_as_handled()  # Prevent other nodes from handling this event
			return
	
	# Handle pause only if not already paused and in playing state
	# Let PauseMenu handle ESC when already paused
	if event.is_action_pressed("ui_cancel") and current_state == GameState.PLAYING:
		if pause_menu and not pause_menu.is_paused:
			print("Pausing game")
			toggle_pause()
			get_viewport().set_input_as_handled()  # Prevent other nodes from handling this event

func start_game():
	current_state = GameState.PLAYING
	current_level = 1
	_load_level(current_level)

func _load_level(level_number: int):
	print("Loading level: ", level_number)
	
	# Clean up existing level
	if level_scene:
		level_scene.queue_free()
	
	# Create new level scene
	_create_level_scene(level_number)
	
	# Reset game statistics
	_reset_level_stats()
	
	# Update HUD
	if hud:
		hud.reset_hud()
		hud.update_shard_count(0, total_shards_in_level)
		hud.update_node_progress(0, total_nodes_in_level)
		hud.update_lives(player_lives)

func _create_level_scene(level_number: int):
	# Create the main level scene
	level_scene = Node2D.new()
	level_scene.name = "Level" + str(level_number)
	get_tree().current_scene.add_child(level_scene)
	
	# Create player
	_create_player()
	
	# Create level geometry
	_create_level_geometry(level_number)
	
	# Create moving platforms
	_create_moving_platforms(level_number)
	
	# Create collectibles and nodes
	_create_level_objects(level_number)
	
	# Create obstacles and challenges
	_create_challenges(level_number)

func _create_player():
	# Create player
	player = preload("res://scripts/Player.gd").new()
	player.name = "Player"
	player.position = Vector2(100, 550)  # Position above the ground
	
	# Set up player collision layers
	player.collision_layer = 1  # Player layer
	player.collision_mask = 4   # Collides with platforms layer
	
	# Set up player collision
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(32, 48)
	collision_shape.shape = rect_shape
	player.add_child(collision_shape)
	
	# Create player sprite
	var sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	player.add_child(sprite)
	_create_player_sprite_frames(sprite)
	
	# Create interaction area
	var interaction_area = Area2D.new()
	interaction_area.name = "InteractionArea"
	interaction_area.collision_layer = 0    # Doesn't emit collisions
	interaction_area.collision_mask = 8     # Detects nodes layer
	var area_collision = CollisionShape2D.new()
	var area_shape = RectangleShape2D.new()
	area_shape.size = Vector2(64, 64)
	area_collision.shape = area_shape
	interaction_area.add_child(area_collision)
	player.add_child(interaction_area)
	
	# Connect interaction area signals
	interaction_area.body_entered.connect(player._on_area_2d_body_entered)
	interaction_area.body_exited.connect(player._on_area_2d_body_exited)
	
	# Connect player signals
	player.shard_collected.connect(_on_shard_collected)
	player.node_interaction.connect(_on_node_interaction)
	
	# Add to scene and groups
	player.add_to_group("player")
	level_scene.add_child(player)
	
	# Set up camera following
	if camera:
		_setup_camera_following()
	
	# Set up background
	_setup_background()

func _create_player_sprite_frames(sprite: AnimatedSprite2D):
	# Create sprite frames programmatically
	var sprite_frames = SpriteFrames.new()
	
	# Create a simple player texture
	var image = Image.create(32, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw simple player character
	for x in range(8, 24):
		for y in range(8, 40):
			if y < 16:  # Head
				image.set_pixel(x, y, Color.PINK)
			elif y < 32:  # Body
				image.set_pixel(x, y, Color.BLUE)
			else:  # Legs
				image.set_pixel(x, y, Color.DARK_BLUE)
	
	var texture = ImageTexture.create_from_image(image)
	sprite_frames.add_animation("default")
	sprite_frames.add_frame("default", texture)
	sprite.sprite_frames = sprite_frames
	sprite.play("default")

func _create_level_geometry(level_number: int):
	# Create simple platform geometry
	var platforms = []
	
	match level_number:
		1:
			platforms = [
				{"pos": Vector2(0, 600), "size": Vector2(400, 120)},       # Ground start
				{"pos": Vector2(500, 600), "size": Vector2(300, 120)},     # Ground gap
				{"pos": Vector2(900, 600), "size": Vector2(380, 120)},     # Ground end
				{"pos": Vector2(250, 480), "size": Vector2(120, 20)},      # Platform 1
				{"pos": Vector2(450, 380), "size": Vector2(100, 20)},      # Platform 2  
				{"pos": Vector2(650, 280), "size": Vector2(80, 20)},       # Platform 3
				{"pos": Vector2(850, 180), "size": Vector2(60, 20)},       # Platform 4 (tiny)
				{"pos": Vector2(1050, 120), "size": Vector2(80, 20)},      # Platform 5
				{"pos": Vector2(400, 200), "size": Vector2(60, 20)},       # Bonus platform
			]
		2:
			platforms = [
				{"pos": Vector2(0, 600), "size": Vector2(200, 120)},       # Ground start
				{"pos": Vector2(350, 600), "size": Vector2(150, 120)},     # Ground island 1
				{"pos": Vector2(650, 600), "size": Vector2(150, 120)},     # Ground island 2  
				{"pos": Vector2(950, 600), "size": Vector2(330, 120)},     # Ground end
				{"pos": Vector2(120, 480), "size": Vector2(80, 20)},       # Platform 1
				{"pos": Vector2(280, 400), "size": Vector2(60, 20)},       # Platform 2
				{"pos": Vector2(520, 380), "size": Vector2(60, 20)},       # Platform 3
				{"pos": Vector2(720, 320), "size": Vector2(60, 20)},       # Platform 4
				{"pos": Vector2(850, 260), "size": Vector2(60, 20)},       # Platform 5
				{"pos": Vector2(1100, 200), "size": Vector2(80, 20)},      # Platform 6
				{"pos": Vector2(400, 150), "size": Vector2(50, 20)},       # Bonus platform
				{"pos": Vector2(600, 100), "size": Vector2(50, 20)},       # Bonus platform 2
			]
		3:
			platforms = [
				{"pos": Vector2(0, 600), "size": Vector2(150, 120)},       # Ground start
				{"pos": Vector2(250, 600), "size": Vector2(100, 120)},     # Tiny island 1
				{"pos": Vector2(450, 600), "size": Vector2(100, 120)},     # Tiny island 2
				{"pos": Vector2(650, 600), "size": Vector2(100, 120)},     # Tiny island 3
				{"pos": Vector2(850, 600), "size": Vector2(100, 120)},     # Tiny island 4
				{"pos": Vector2(1050, 600), "size": Vector2(230, 120)},    # Ground end
				{"pos": Vector2(80, 500), "size": Vector2(60, 20)},        # Platform 1
				{"pos": Vector2(180, 420), "size": Vector2(50, 20)},       # Platform 2
				{"pos": Vector2(320, 480), "size": Vector2(50, 20)},       # Platform 3
				{"pos": Vector2(420, 400), "size": Vector2(50, 20)},       # Platform 4
				{"pos": Vector2(520, 340), "size": Vector2(50, 20)},       # Platform 5
				{"pos": Vector2(620, 480), "size": Vector2(50, 20)},       # Platform 6
				{"pos": Vector2(720, 300), "size": Vector2(50, 20)},       # Platform 7
				{"pos": Vector2(800, 220), "size": Vector2(50, 20)},       # Platform 8
				{"pos": Vector2(920, 380), "size": Vector2(50, 20)},       # Platform 9
				{"pos": Vector2(1150, 200), "size": Vector2(60, 20)},      # Platform 10
				{"pos": Vector2(300, 150), "size": Vector2(40, 20)},       # Bonus platform
				{"pos": Vector2(500, 80), "size": Vector2(40, 20)},        # Bonus platform 2
				{"pos": Vector2(750, 50), "size": Vector2(40, 20)},        # Bonus platform 3
			]
	
	# Create death zones (lava pits) between platforms
	_create_death_zones(level_number)
	
	# Create platform bodies
	for platform_data in platforms:
		var platform = StaticBody2D.new()
		platform.position = platform_data.pos
		platform.collision_layer = 4  # Platforms layer
		platform.collision_mask = 0   # Platforms don't need to detect anything
		
		var collision_shape = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = platform_data.size
		collision_shape.shape = rect_shape
		# Position collision shape at center of platform
		collision_shape.position = Vector2(platform_data.size.x / 2, platform_data.size.y / 2)
		platform.add_child(collision_shape)
		
		# Create platform sprite
		var sprite = Sprite2D.new()
		var image = Image.create(int(platform_data.size.x), int(platform_data.size.y), false, Image.FORMAT_RGBA8)
		image.fill(Color(0.3, 0.3, 0.3))
		# Add some detail
		for x in range(0, int(platform_data.size.x), 20):
			for y in range(0, int(platform_data.size.y)):
				if x < platform_data.size.x:
					image.set_pixel(x, y, Color(0.4, 0.4, 0.4))
		
		var texture = ImageTexture.create_from_image(image)
		sprite.texture = texture
		# Position sprite at center of platform
		sprite.position = Vector2(platform_data.size.x / 2, platform_data.size.y / 2)
		platform.add_child(sprite)
		
		level_scene.add_child(platform)

func _create_death_zones(level_number: int):
	# Create hazardous death zones that instantly kill the player
	var death_zones = []
	
	match level_number:
		1:
			death_zones = [
				{"pos": Vector2(400, 650), "size": Vector2(100, 80)},     # Gap 1
				{"pos": Vector2(800, 650), "size": Vector2(100, 80)},     # Gap 2
			]
		2:
			death_zones = [
				{"pos": Vector2(200, 650), "size": Vector2(150, 80)},     # Gap 1
				{"pos": Vector2(500, 650), "size": Vector2(150, 80)},     # Gap 2
				{"pos": Vector2(800, 650), "size": Vector2(150, 80)},     # Gap 3
			]
		3:
			death_zones = [
				{"pos": Vector2(150, 650), "size": Vector2(100, 80)},     # Gap 1
				{"pos": Vector2(350, 650), "size": Vector2(100, 80)},     # Gap 2
				{"pos": Vector2(550, 650), "size": Vector2(100, 80)},     # Gap 3
				{"pos": Vector2(750, 650), "size": Vector2(100, 80)},     # Gap 4
				{"pos": Vector2(950, 650), "size": Vector2(100, 80)},     # Gap 5
			]
	
	# Create death zone bodies
	for zone_data in death_zones:
		var death_zone = Area2D.new()
		death_zone.position = zone_data.pos
		death_zone.collision_layer = 32  # Death zones layer
		death_zone.collision_mask = 1    # Detects player
		
		var collision_shape = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = zone_data.size
		collision_shape.shape = rect_shape
		collision_shape.position = Vector2(zone_data.size.x / 2, zone_data.size.y / 2)
		death_zone.add_child(collision_shape)
		
		# Create lava visual
		var sprite = Sprite2D.new()
		var image = Image.create(int(zone_data.size.x), int(zone_data.size.y), false, Image.FORMAT_RGBA8)
		# Animated lava effect
		for x in range(int(zone_data.size.x)):
			for y in range(int(zone_data.size.y)):
				var noise_value = sin(x * 0.1 + y * 0.1) * 0.5 + 0.5
				var red_intensity = 0.8 + noise_value * 0.2
				image.set_pixel(x, y, Color(red_intensity, 0.2, 0.0, 0.9))
		
		var texture = ImageTexture.create_from_image(image)
		sprite.texture = texture
		sprite.position = Vector2(zone_data.size.x / 2, zone_data.size.y / 2)
		death_zone.add_child(sprite)
		
		# Connect death signal
		death_zone.body_entered.connect(_on_death_zone_entered)
		death_zone.add_to_group("death_zones")
		
		level_scene.add_child(death_zone)

func _on_death_zone_entered(body):
	if body.is_in_group("player"):
		# Instant death - lose a life and respawn
		_player_died("fell into lava")

func _create_level_objects(level_number: int):
	# Create shards and nodes based on level
	var shard_positions = []
	var node_positions = []
	
	match level_number:
		1:
			shard_positions = [
				# Regular shards - spread across level
				Vector2(320, 420), Vector2(520, 320), Vector2(720, 220),
				Vector2(920, 120), Vector2(1120, 80), Vector2(170, 440), 
				Vector2(390, 350), Vector2(580, 240), Vector2(780, 140),
				Vector2(1020, 90), Vector2(60, 520), Vector2(450, 150),
				# Challenging shards requiring precision jumps
				Vector2(430, 160), Vector2(630, 60), Vector2(830, 40),
				Vector2(1160, 50), Vector2(280, 280), Vector2(480, 50)
			]
			node_positions = [Vector2(1100, 150)]
		2:
			shard_positions = [
				# Regular shards on platforms
				Vector2(150, 430), Vector2(310, 350), Vector2(550, 330),
				Vector2(750, 270), Vector2(880, 210), Vector2(1130, 150),
				Vector2(420, 100), Vector2(620, 50), Vector2(80, 450),
				Vector2(430, 330), Vector2(590, 280), Vector2(770, 220),
				Vector2(950, 160), Vector2(1050, 120), Vector2(300, 300),
				# Extremely challenging shards
				Vector2(450, 30), Vector2(650, 20), Vector2(850, 10),
				Vector2(250, 120), Vector2(480, 80), Vector2(680, 60),
				Vector2(880, 40), Vector2(1080, 70), Vector2(320, 50)
			]
			node_positions = [Vector2(1100, 150)]
		3:
			shard_positions = [
				# Regular platform shards
				Vector2(110, 450), Vector2(210, 370), Vector2(350, 430),
				Vector2(450, 350), Vector2(550, 290), Vector2(650, 430),
				Vector2(750, 250), Vector2(830, 170), Vector2(950, 330),
				Vector2(1180, 150), Vector2(120, 350), Vector2(280, 220),
				Vector2(420, 180), Vector2(620, 100), Vector2(820, 80),
				Vector2(1020, 160), Vector2(180, 280), Vector2(380, 120),
				Vector2(580, 60), Vector2(780, 40), Vector2(980, 90),
				# Ultra challenging bonus shards
				Vector2(330, 100), Vector2(530, 30), Vector2(730, 20),
				Vector2(930, 10), Vector2(1130, 40), Vector2(250, 80),
				Vector2(450, 60), Vector2(650, 40), Vector2(850, 30),
				Vector2(1050, 50), Vector2(80, 300), Vector2(320, 160)
			]
			node_positions = [Vector2(1100, 200)]
	
	# Create shards
	for pos in shard_positions:
		var shard = preload("res://scripts/Shard.gd").new()
		shard.position = pos
		
		# Set up shard collision layers
		shard.collision_layer = 8   # Collectibles layer
		shard.collision_mask = 1    # Detects player layer
		
		# Set up shard collision
		var collision_shape = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 16
		collision_shape.shape = circle_shape
		shard.add_child(collision_shape)
		
		level_scene.add_child(shard)
	
	# Create nodes
	for pos in node_positions:
		var node = preload("res://scripts/NexusNode.gd").new()
		node.position = pos
		
		# Set up node collision
		var collision_shape = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(64, 64)
		collision_shape.shape = rect_shape
		# Center the collision shape
		collision_shape.position = Vector2(0, 0)
		node.add_child(collision_shape)
		
		# Connect node signals
		node.puzzle_requested.connect(_on_puzzle_requested)
		node.node_completed.connect(_on_node_completed)
		
		level_scene.add_child(node)
	
	# Update totals
	total_shards_in_level = shard_positions.size()
	total_nodes_in_level = node_positions.size()

func _reset_level_stats():
	completed_nodes = 0
	player_lives = max_lives
	checkpoint_position = Vector2(100, 550)  # Reset checkpoint
	level_timer = 0.0  # Reset level timer

func _on_shard_collected(count: int):
	if hud:
		hud.update_shard_count(count, total_shards_in_level)

func _on_node_interaction(node: NexusNode):
	if node.activate():
		# Node activation successful, will trigger puzzle
		pass

func _on_puzzle_requested(node: NexusNode):
	if puzzle_popup:
		puzzle_popup.show_puzzle(node)

func _on_node_completed(node: NexusNode):
	completed_nodes += 1
	
	if hud:
		hud.update_node_progress(completed_nodes, total_nodes_in_level)
	
	# Check if level is complete
	if completed_nodes >= total_nodes_in_level:
		_complete_level()

func _complete_level():
	current_state = GameState.LEVEL_COMPLETE
	level_completed.emit()
	
	# Wait a moment, then proceed
	await get_tree().create_timer(3.0).timeout
	
	# Check if game is complete
	if current_level >= max_levels:
		_complete_game()
	else:
		_next_level()

func _next_level():
	current_level += 1
	_load_level(current_level)
	current_state = GameState.PLAYING

func _complete_game():
	current_state = GameState.GAME_OVER
	game_completed.emit()
	
	# Show completion message
	if hud:
		var completion_label = Label.new()
		completion_label.text = "NEXUS NETWORK ACTIVATED!\nThanks for playing!"
		completion_label.position = Vector2(400, 200)
		completion_label.add_theme_font_size_override("font_size", 28)
		completion_label.modulate = Color.GREEN
		completion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hud.add_child(completion_label)

func toggle_pause():
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		if pause_menu:
			pause_menu.pause_game()
	elif current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		if pause_menu:
			pause_menu.resume_game()

func restart_level():
	_load_level(current_level)
	current_state = GameState.PLAYING

func quit_to_menu():
	current_state = GameState.MENU
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_puzzle_completed(success: bool):
	if puzzle_popup.current_node:
		puzzle_popup.current_node.complete_puzzle(success)
		
		# Apply puzzle failure penalty
		if not success:
			_apply_puzzle_penalty()

func _player_died(cause: String):
	if current_state != GameState.PLAYING:
		return
		
	player_lives -= 1
	print("Player died! Cause: ", cause, " Lives remaining: ", player_lives)
	
	# Lose some shards on death
	var shards_lost = min(player.shards_collected, shards_lost_on_death)
	player.shards_collected = max(0, player.shards_collected - shards_lost)
	
	# Update HUD
	if hud:
		hud.update_shard_count(player.shards_collected, total_shards_in_level)
		hud.update_lives(player_lives)
		_show_death_message(cause, shards_lost)
	
	if player_lives <= 0:
		_game_over()
	else:
		_respawn_player()

func _respawn_player():
	# Reset player position
	player.global_position = checkpoint_position
	player.velocity = Vector2.ZERO
	
	# Brief invincibility effect
	_make_player_invincible(2.0)

func _make_player_invincible(duration: float):
	# Visual feedback for invincibility
	var tween = create_tween()
	tween.set_loops(int(duration * 5))  # Blink effect
	tween.tween_property(player, "modulate:a", 0.5, 0.1)
	tween.tween_property(player, "modulate:a", 1.0, 0.1)

func _apply_puzzle_penalty():
	# Small penalty for puzzle failure
	var shards_lost = min(player.shards_collected, puzzle_failure_penalty)
	player.shards_collected = max(0, player.shards_collected - shards_lost)
	
	if hud:
		hud.update_shard_count(player.shards_collected, total_shards_in_level)
		hud.show_interaction_hint("Puzzle failed! Lost " + str(shards_lost) + " shard(s)")

func _show_death_message(cause: String, shards_lost: int):
	var message = ""
	match cause:
		"fell":
			message = "You fell off the map! Lost " + str(shards_lost) + " shards"
		"ran out of time":
			message = "Time's up! Lost " + str(shards_lost) + " shards"
		_:
			message = "You died! Lost " + str(shards_lost) + " shards"
	
	if hud:
		hud.show_interaction_hint(message)

func _game_over():
	current_state = GameState.GAME_OVER
	
	if hud:
		var game_over_label = Label.new()
		game_over_label.text = "GAME OVER!\nPress R to restart or ESC for menu"
		game_over_label.position = Vector2(400, 250)
		game_over_label.add_theme_font_size_override("font_size", 28)
		game_over_label.modulate = Color.RED
		game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game_over_label.z_index = 100
		game_over_label.name = "GameOverLabel"
		hud.add_child(game_over_label)

func restart_current_level():
	# Clean up game over UI
	if hud and hud.has_node("GameOverLabel"):
		hud.get_node("GameOverLabel").queue_free()
	
	# Reset game state
	current_state = GameState.PLAYING
	player_lives = max_lives
	
	# Reload current level
	_load_level(current_level)

func return_to_menu():
	# Clean up game over UI
	if hud and hud.has_node("GameOverLabel"):
		hud.get_node("GameOverLabel").queue_free()
	
	# Switch to main menu scene
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _set_checkpoint(position: Vector2):
	checkpoint_position = position
	print("Checkpoint set at: ", position)

func _update_moving_platforms(delta: float):
	var moving_platforms = get_tree().get_nodes_in_group("moving_platforms")
	
	for platform in moving_platforms:
		if platform is CharacterBody2D:
			var start_pos = platform.get_meta("start_pos")
			var end_pos = platform.get_meta("end_pos")
			var move_speed = platform.get_meta("move_speed")
			var direction = platform.get_meta("direction")
			
			var target = end_pos if direction == 1 else start_pos
			var distance = platform.position.distance_to(target)
			
			if distance < 5.0:
				direction *= -1
				platform.set_meta("direction", direction)
			
			var move_dir = (target - platform.position).normalized()
			platform.velocity = move_dir * move_speed
			platform.move_and_slide()

func _setup_camera_following():
	# Simple camera following with smoothing
	var tween = create_tween()
	tween.set_loops()
	tween.tween_method(_update_camera_position, camera.global_position, player.global_position, 0.1)

func _update_camera_position(pos: Vector2):
	if camera and player:
		var target_pos = player.global_position
		target_pos.y -= 50  # Offset camera slightly up
		camera.global_position = camera.global_position.lerp(target_pos, 0.05)

func _process(delta):
	# Only update game mechanics if not in game over state
	if current_state != GameState.GAME_OVER:
		# Update camera to follow player
		if camera and player and current_state == GameState.PLAYING:
			var target_pos = player.global_position
			target_pos.y -= 50
			camera.global_position = camera.global_position.lerp(target_pos, 0.05)
			
			# Check if player fell off the map
			if player.global_position.y > 800:  # Death threshold
				_player_died("fell")
			
			# Update level timer - EXTREME TIME PRESSURE
			level_timer += delta
			if hud:
				hud.update_level_timer(level_time_limit - level_timer)
			
			if level_timer >= level_time_limit:
				_player_died("ran out of time")
		
		# Update moving platforms
		_update_moving_platforms(delta)

func _setup_background():
	# Create Nexus-themed starfield background
	var background_node = get_tree().current_scene.get_node("Background")
	if not background_node:
		return
	
	# Get background sprites
	var bg_sprite1 = background_node.get_node("ParallaxLayer/BackgroundSprite")
	var bg_sprite2 = background_node.get_node("ParallaxLayer2/BackgroundSprite2")
	
	if bg_sprite1:
		bg_sprite1.texture = _create_starfield_texture(1280, 720, 100)
	if bg_sprite2:
		bg_sprite2.texture = _create_starfield_texture(1280, 720, 50)

func _create_moving_platforms(level_number: int):
	var moving_platforms = []
	
	match level_number:
		2:
			moving_platforms = [
				{"start": Vector2(400, 250), "end": Vector2(700, 250), "speed": 150.0, "size": Vector2(80, 20)},
				{"start": Vector2(200, 200), "end": Vector2(500, 200), "speed": 120.0, "size": Vector2(60, 20)},
				{"start": Vector2(800, 180), "end": Vector2(1100, 180), "speed": 180.0, "size": Vector2(50, 20)}
			]
		3:
			moving_platforms = [
				{"start": Vector2(250, 400), "end": Vector2(600, 400), "speed": 200.0, "size": Vector2(50, 20)},
				{"start": Vector2(400, 250), "end": Vector2(750, 250), "speed": 220.0, "size": Vector2(40, 20)},
				{"start": Vector2(600, 150), "end": Vector2(950, 150), "speed": 250.0, "size": Vector2(40, 20)},
				{"start": Vector2(300, 350), "end": Vector2(300, 100), "speed": 180.0, "size": Vector2(60, 20)}, # Vertical
				{"start": Vector2(900, 400), "end": Vector2(900, 150), "speed": 160.0, "size": Vector2(50, 20)} # Vertical
			]
	
	for platform_data in moving_platforms:
		var platform = CharacterBody2D.new()
		platform.position = platform_data.start
		platform.collision_layer = 4
		platform.collision_mask = 0
		
		# Create collision shape
		var collision_shape = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = platform_data.size
		collision_shape.shape = rect_shape
		collision_shape.position = Vector2(platform_data.size.x / 2, platform_data.size.y / 2)
		platform.add_child(collision_shape)
		
		# Create sprite
		var sprite = Sprite2D.new()
		var image = Image.create(int(platform_data.size.x), int(platform_data.size.y), false, Image.FORMAT_RGBA8)
		image.fill(Color(0.5, 0.3, 0.8))  # Purple moving platforms
		var texture = ImageTexture.create_from_image(image)
		sprite.texture = texture
		sprite.position = Vector2(platform_data.size.x / 2, platform_data.size.y / 2)
		platform.add_child(sprite)
		
		# Add custom variables for movement
		platform.set_meta("start_pos", platform_data.start)
		platform.set_meta("end_pos", platform_data.end)
		platform.set_meta("move_speed", platform_data.speed)
		platform.set_meta("direction", 1)
		
		# Add to moving platforms group for processing
		platform.add_to_group("moving_platforms")
		
		level_scene.add_child(platform)

func _create_challenges(level_number: int):
	# Add bonus shards and obstacles
	match level_number:
		1:
			# Add some bonus shards in harder-to-reach places
			_create_bonus_shard(Vector2(50, 300))  # High jump required
		2:
			# Add timer challenge area
			_create_timer_challenge(Vector2(750, 100))
			_create_bonus_shard(Vector2(300, 100))
		3:
			# Add multiple challenges
			_create_timer_challenge(Vector2(400, 50))
			_create_bonus_shard(Vector2(100, 200))
			_create_bonus_shard(Vector2(1200, 100))

func _create_bonus_shard(pos: Vector2):
	var shard = preload("res://scripts/Shard.gd").new()
	shard.position = pos
	shard.collision_layer = 8
	shard.collision_mask = 1
	
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 16
	collision_shape.shape = circle_shape
	shard.add_child(collision_shape)
	
	# Make bonus shards golden
	if shard.has_method("_setup_shard_visuals"):
		shard.modulate = Color.GOLD
	
	level_scene.add_child(shard)
	total_shards_in_level += 1

func _create_timer_challenge(pos: Vector2):
	# Create a timed collection area
	var challenge_area = Area2D.new()
	challenge_area.position = pos
	challenge_area.collision_layer = 0
	challenge_area.collision_mask = 1
	
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(100, 100)
	collision_shape.shape = rect_shape
	challenge_area.add_child(collision_shape)
	
	# Visual indicator
	var sprite = Sprite2D.new()
	var image = Image.create(100, 100, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.5, 0.0, 0.3))  # Orange challenge zone
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	challenge_area.add_child(sprite)
	
	# Challenge logic
	var script = GDScript.new()
	script.source_code = """extends Area2D

var is_player_inside = false
var challenge_timer = 0.0
var challenge_duration = 3.0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == 'Player':
		is_player_inside = true
		challenge_timer = 0.0
		print('Timer Challenge Started!')

func _on_body_exited(body):
	if body.name == 'Player':
		is_player_inside = false
		challenge_timer = 0.0

func _process(delta):
	if is_player_inside:
		challenge_timer += delta
		if challenge_timer >= challenge_duration:
			print('Timer Challenge Completed!')
			# Award bonus points or special shard
			queue_free()
"""
	challenge_area.set_script(script)
	level_scene.add_child(challenge_area)

func _create_starfield_texture(width: int, height: int, star_count: int) -> ImageTexture:
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.05, 0.05, 0.15, 1.0))  # Dark blue space background
	
	# Add stars
	for i in range(star_count):
		var x = randi() % width
		var y = randi() % height
		var brightness = randf_range(0.3, 1.0)
		var star_color = Color(brightness, brightness * 0.8, brightness * 1.2, 1.0)  # Slightly blue-tinted
		
		# Make some stars bigger
		if randf() < 0.3:
			# Multi-pixel star
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var star_x = clamp(x + dx, 0, width - 1)
					var star_y = clamp(y + dy, 0, height - 1)
					var pixel_brightness = brightness * (1.0 - (abs(dx) + abs(dy)) * 0.3)
					var pixel_color = Color(pixel_brightness, pixel_brightness * 0.8, pixel_brightness * 1.2, 1.0)
					image.set_pixel(star_x, star_y, pixel_color)
		else:
			image.set_pixel(x, y, star_color)
	
	# Add some nebula effects
	for i in range(5):
		var center_x = randi() % width
		var center_y = randi() % height
		var radius = randi_range(50, 150)
		var nebula_color = Color(randf_range(0.1, 0.3), randf_range(0.1, 0.4), randf_range(0.3, 0.6), 0.3)
		
		for x in range(max(0, center_x - radius), min(width, center_x + radius)):
			for y in range(max(0, center_y - radius), min(height, center_y + radius)):
				var dist = Vector2(x - center_x, y - center_y).length()
				if dist < radius:
					var alpha = (1.0 - dist / radius) * nebula_color.a
					var current_color = image.get_pixel(x, y)
					var blend_color = current_color.lerp(nebula_color, alpha)
					image.set_pixel(x, y, blend_color)
	
	return ImageTexture.create_from_image(image) 
