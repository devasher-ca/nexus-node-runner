extends Area2D

class_name Shard

# Visual effects
var float_height = 10.0
var float_speed = 2.0
var rotation_speed = 2.0
var original_position: Vector2
var collected = false

# Nexus-themed colors
var nexus_colors = [
	Color.CYAN,
	Color.BLUE,
	Color.MAGENTA,
	Color.GREEN
]

func _ready():
	original_position = global_position
	
	# Set up the shard appearance
	_setup_shard_visuals()
	
	# Connect collection signal
	body_entered.connect(_on_body_entered)
	
	# Add to collectibles group
	add_to_group("shards")
	
	# Random color for variety
	if $Sprite2D:
		$Sprite2D.modulate = nexus_colors[randi() % nexus_colors.size()]

func _setup_shard_visuals():
	# Create sprite if it doesn't exist
	if not $Sprite2D:
		var sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
		
		# Create a simple square texture for the shard
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color.CYAN)
		# Add some detail to make it look more like a compute shard
		for x in range(8, 24):
			for y in range(8, 24):
				if (x + y) % 4 == 0:
					image.set_pixel(x, y, Color.WHITE)
		
		var texture = ImageTexture.create_from_image(image)
		sprite.texture = texture

func _physics_process(delta):
	if collected:
		return
		
	# Floating animation
	var time = Time.get_ticks_msec() / 1000.0
	global_position.y = original_position.y + sin(time * float_speed) * float_height
	
	# Rotation animation
	rotation += rotation_speed * delta
	
	# Pulsing effect
	var pulse = 0.8 + sin(time * 3.0) * 0.2
	scale = Vector2(pulse, pulse)

func _on_body_entered(body):
	if collected:
		return
	
	# Check if game is over - disable collection
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.current_state == game_manager.GameState.GAME_OVER:
		return
		
	if body is Player:
		collect()

func collect():
	if collected:
		return
		
	collected = true
	
	# Notify player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.collect_shard()
	
	# Collection effect
	_play_collection_effect()
	
	# Remove from scene
	queue_free()

func _play_collection_effect():
	# Create a quick particle effect
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scale up and fade out
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	# Sound effect
	if $CollectSound:
		$CollectSound.play() 