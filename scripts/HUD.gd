extends CanvasLayer

class_name HUD

# UI Elements
var shard_count_label: Label
var level_progress_label: Label
var instruction_label: Label
var lives_label: Label
var nexus_logo: Control

# Game state
var current_shards = 0
var total_shards = 0
var nodes_completed = 0
var total_nodes = 0
var current_lives = 3

func _ready():
	_setup_hud()
	_setup_nexus_branding()

func _setup_hud():
	# Shard counter
	var shard_panel = Panel.new()
	shard_panel.size = Vector2(180, 60)
	shard_panel.position = Vector2(20, 20)
	add_child(shard_panel)
	
	var shard_icon = Label.new()
	shard_icon.text = "💎"
	shard_icon.position = Vector2(10, 15)
	shard_icon.add_theme_font_size_override("font_size", 24)
	shard_panel.add_child(shard_icon)
	
	shard_count_label = Label.new()
	shard_count_label.text = "0 / 0"
	shard_count_label.position = Vector2(50, 20)
	shard_count_label.add_theme_font_size_override("font_size", 18)
	shard_count_label.modulate = Color.CYAN
	shard_panel.add_child(shard_count_label)
	
	# Level progress
	var progress_panel = Panel.new()
	progress_panel.size = Vector2(200, 60)
	progress_panel.position = Vector2(220, 20)
	add_child(progress_panel)
	
	# Lives counter
	var lives_panel = Panel.new()
	lives_panel.size = Vector2(120, 60)
	lives_panel.position = Vector2(440, 20)
	add_child(lives_panel)
	
	var heart_icon = Label.new()
	heart_icon.text = "❤️"
	heart_icon.position = Vector2(10, 15)
	heart_icon.add_theme_font_size_override("font_size", 24)
	lives_panel.add_child(heart_icon)
	
	lives_label = Label.new()
	lives_label.text = "3"
	lives_label.position = Vector2(50, 20)
	lives_label.add_theme_font_size_override("font_size", 18)
	lives_label.modulate = Color.RED
	lives_panel.add_child(lives_label)
	
	var nodes_icon = Label.new()
	nodes_icon.text = "🔷"
	nodes_icon.position = Vector2(10, 15)
	nodes_icon.add_theme_font_size_override("font_size", 24)
	progress_panel.add_child(nodes_icon)
	
	level_progress_label = Label.new()
	level_progress_label.text = "Nodes: 0 / 0"
	level_progress_label.position = Vector2(50, 20)
	level_progress_label.add_theme_font_size_override("font_size", 16)
	level_progress_label.modulate = Color.GREEN
	progress_panel.add_child(level_progress_label)
	
	# Instructions
	instruction_label = Label.new()
	instruction_label.text = "Collect shards to power Nexus Nodes! Press E to interact."
	instruction_label.position = Vector2(20, 680)
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.modulate = Color.WHITE
	add_child(instruction_label)
	
	# Style panels
	_style_panels()

func _setup_nexus_branding():
	# Nexus logo/title in top-right
	var branding_panel = Panel.new()
	branding_panel.size = Vector2(300, 80)
	branding_panel.position = Vector2(960, 20)
	add_child(branding_panel)
	
	var title_label = Label.new()
	title_label.text = "NODE RUNNER"
	title_label.position = Vector2(20, 10)
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.modulate = Color.CYAN
	branding_panel.add_child(title_label)
	
	var subtitle_label = Label.new()
	subtitle_label.text = "NEXUS EDITION"
	subtitle_label.position = Vector2(20, 40)
	subtitle_label.add_theme_font_size_override("font_size", 14)
	subtitle_label.modulate = Color.YELLOW
	branding_panel.add_child(subtitle_label)

func _style_panels():
	# Create Nexus-themed panel style
	var theme = Theme.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.1, 0.2, 0.8)
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.0, 0.8, 1.0, 0.6)
	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.corner_radius_bottom_right = 5
	
	theme.set_stylebox("panel", "Panel", panel_style)
	
	# Apply to all panels
	for child in get_children():
		if child is Panel:
			child.theme = theme

func update_shard_count(current: int, total: int):
	current_shards = current
	total_shards = total
	if shard_count_label:
		shard_count_label.text = "%d / %d" % [current, total]
		
		# Add visual feedback for collection
		if current > 0:
			_animate_shard_counter()

func update_node_progress(completed: int, total: int):
	nodes_completed = completed
	total_nodes = total
	if level_progress_label:
		level_progress_label.text = "Nodes: %d / %d" % [completed, total]
		
		# Check for level completion
		if completed >= total and total > 0:
			_show_level_complete()

func _animate_shard_counter():
	if shard_count_label:
		# Quick scale animation when shard is collected
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(shard_count_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(shard_count_label, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.1)
		tween.tween_property(shard_count_label, "modulate", Color.WHITE, 0.1)
		tween.tween_property(shard_count_label, "modulate", Color.CYAN, 0.1).set_delay(0.1)

func _show_level_complete():
	# Show completion message
	var completion_label = Label.new()
	completion_label.text = "LEVEL COMPLETE!"
	completion_label.position = Vector2(500, 300)
	completion_label.add_theme_font_size_override("font_size", 36)
	completion_label.modulate = Color.GREEN
	completion_label.z_index = 100
	add_child(completion_label)
	
	# Animate completion text
	var tween = create_tween()
	tween.set_parallel(true)
	
	completion_label.modulate.a = 0.0
	completion_label.scale = Vector2(2.0, 2.0)
	
	tween.tween_property(completion_label, "modulate:a", 1.0, 0.5)
	tween.tween_property(completion_label, "scale", Vector2(1.0, 1.0), 0.5)
	
	# Remove after delay
	await get_tree().create_timer(3.0).timeout
	completion_label.queue_free()

func show_interaction_hint(text: String):
	if instruction_label:
		instruction_label.text = text
		instruction_label.modulate = Color.YELLOW
		
		# Animate hint
		var tween = create_tween()
		tween.tween_property(instruction_label, "modulate", Color.WHITE, 1.0)

func hide_interaction_hint():
	if instruction_label:
		instruction_label.text = "Collect shards to power Nexus Nodes! Use WASD/Arrows to move, Space to jump."
		instruction_label.modulate = Color.WHITE

func show_puzzle_hint():
	show_interaction_hint("Press E to activate the Nexus Node!")

func update_lives(lives: int):
	current_lives = lives
	if lives_label:
		lives_label.text = str(lives)
		
		# Visual feedback for low lives
		if lives <= 1:
			lives_label.modulate = Color.RED
			# Pulsing effect when critical
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(lives_label, "scale", Vector2(1.2, 1.2), 0.5)
			tween.tween_property(lives_label, "scale", Vector2(1.0, 1.0), 0.5)
		elif lives <= 2:
			lives_label.modulate = Color.ORANGE
		else:
			lives_label.modulate = Color.GREEN

func reset_hud():
	current_shards = 0
	total_shards = 0
	nodes_completed = 0
	total_nodes = 0
	current_lives = 3
	update_shard_count(0, 0)
	update_node_progress(0, 0)
	update_lives(3)
	hide_interaction_hint()
	
	# Clean up timer label if it exists
	var timer_label = get_node_or_null("TimerLabel")
	if timer_label:
		timer_label.queue_free()

func update_level_timer(time_remaining: float):
	var timer_label = get_node_or_null("TimerLabel")
	if not timer_label:
		# Create timer label if it doesn't exist
		timer_label = Label.new()
		timer_label.name = "TimerLabel"
		timer_label.text = "TIME: 45.0"
		timer_label.position = Vector2(580, 20)
		timer_label.add_theme_font_size_override("font_size", 24)
		add_child(timer_label)
	
	# Update timer with urgency color coding
	if time_remaining <= 10:
		timer_label.modulate = Color.RED  # Critical time
		# Pulsing effect when critical
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(timer_label, "scale", Vector2(1.3, 1.3), 0.3)
		tween.tween_property(timer_label, "scale", Vector2(1.0, 1.0), 0.3)
	elif time_remaining <= 20:
		timer_label.modulate = Color.ORANGE  # Warning time
	else:
		timer_label.modulate = Color.WHITE  # Normal time
	
	timer_label.text = "TIME: %.1f" % max(0.0, time_remaining) 