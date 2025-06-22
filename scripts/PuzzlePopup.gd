extends CanvasLayer

class_name PuzzlePopup

# Puzzle types
enum PuzzleType {
	PATTERN_MATCH,
	SEQUENCE_MEMORY,
	LOGIC_GATE
}

# Puzzle state
var current_puzzle_type = PuzzleType.PATTERN_MATCH
var target_pattern = []
var player_pattern = []
var puzzle_size = 6  # Tripled from 4 to 12
var time_limit = 5.0  # Will be calculated dynamically
var time_remaining = 0.0
var is_active = false
var current_node = null
var transform_type = 0  # For pattern match transformations

# UI Elements (created programmatically)
var title_label: Label
var instruction_label: Label
var timer_label: Label
var pattern_container: GridContainer
var player_container: GridContainer
var submit_button: Button
var close_button: Button
var result_label: Label

# Signals
signal puzzle_completed(success: bool)

func _ready():
	# Set up the popup
	_setup_ui()
	_setup_styling()
	
	# Hide initially
	visible = false

func _setup_ui():
	# Create main control container
	var main_control = Control.new()
	main_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_control)
	
	# Create background panel
	var panel = Panel.new()
	panel.size = Vector2(600, 400)
	panel.position = Vector2(340, 160)  # Center on 1280x720 screen
	main_control.add_child(panel)
	
	# Title
	title_label = Label.new()
	title_label.text = "NEXUS NODE ACTIVATION"
	title_label.position = Vector2(200, 20)
	title_label.add_theme_font_size_override("font_size", 24)
	panel.add_child(title_label)
	
	# Instructions
	instruction_label = Label.new()
	instruction_label.text = "Match the pattern to activate the node"
	instruction_label.position = Vector2(150, 60)
	instruction_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(instruction_label)
	
	# Timer
	timer_label = Label.new()
	timer_label.position = Vector2(250, 90)
	timer_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(timer_label)
	
	# Target pattern container
	var target_label = Label.new()
	target_label.text = "TARGET PATTERN:"
	target_label.position = Vector2(50, 130)
	panel.add_child(target_label)
	
	pattern_container = GridContainer.new()
	pattern_container.columns = 1  # Single column for clean vertical layout
	pattern_container.position = Vector2(50, 160)
	pattern_container.add_theme_constant_override("h_separation", 5)
	pattern_container.add_theme_constant_override("v_separation", 5)
	panel.add_child(pattern_container)
	
	# Player pattern container
	var player_label = Label.new()
	player_label.text = "YOUR PATTERN:"
	player_label.position = Vector2(50, 220)
	panel.add_child(player_label)
	
	player_container = GridContainer.new()
	player_container.columns = puzzle_size
	player_container.position = Vector2(50, 250)
	player_container.add_theme_constant_override("h_separation", 5)
	player_container.add_theme_constant_override("v_separation", 5)
	panel.add_child(player_container)
	
	# Submit button
	submit_button = Button.new()
	submit_button.text = "SUBMIT"
	submit_button.position = Vector2(200, 320)
	submit_button.size = Vector2(100, 40)
	submit_button.pressed.connect(_on_submit_pressed)
	panel.add_child(submit_button)
	
	# Close button
	close_button = Button.new()
	close_button.text = "CANCEL"
	close_button.position = Vector2(320, 320)
	close_button.size = Vector2(100, 40)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)
	
	# Result label
	result_label = Label.new()
	result_label.position = Vector2(200, 280)
	result_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(result_label)

func _setup_styling():
	# Add Nexus-themed colors
	var theme = Theme.new()
	
	# Panel style
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color.CYAN
	
	theme.set_stylebox("panel", "Panel", panel_style)
	
	# Apply theme
	var main_control = get_child(0)
	if main_control.get_child(0) is Panel:
		main_control.get_child(0).theme = theme

func _process(delta):
	if is_active and time_remaining > 0:
		time_remaining -= delta
		timer_label.text = "Time: %.1f" % time_remaining
		
		if time_remaining <= 0:
			_timeout()

func show_puzzle(node: NexusNode, puzzle_type: PuzzleType = PuzzleType.PATTERN_MATCH):
	# Check if game is over - don't show puzzle
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.current_state == game_manager.GameState.GAME_OVER:
		return
	
	current_node = node
	
	# Randomize puzzle type for variety
	var random_type = randi() % 3
	current_puzzle_type = PuzzleType.values()[random_type]
	
	# Calculate dynamic time limit based on current level and puzzle type
	_calculate_time_limit(current_puzzle_type, game_manager)
	
	# Generate puzzle
	_generate_puzzle()
	
	# Show UI
	visible = true
	is_active = true
	time_remaining = time_limit
	
	# Pause the game
	get_tree().paused = true

func _calculate_time_limit(type: PuzzleType, game_manager):
	# Get current level
	var current_level = 1
	if game_manager and "current_level" in game_manager:
		current_level = game_manager.current_level
	
	# Base time limits for each puzzle type at level 1 (generous starting times)
	var base_times = {
		PuzzleType.PATTERN_MATCH: 15.0,    # Hardest puzzle gets most time initially
		PuzzleType.SEQUENCE_MEMORY: 10.0,  # Memory puzzle gets medium time  
		PuzzleType.LOGIC_GATE: 8.0        # Logic puzzle gets least time (easiest)
	}
	
	# Calculate time reduction per level (gets progressively harder)
	var base_time = base_times[type]
	var time_reduction_per_level = base_time * 0.2  # 20% reduction per level
	var minimum_time = base_time * 0.25  # Never go below 25% of base time
	
	# Calculate final time limit
	time_limit = max(base_time - (time_reduction_per_level * (current_level - 1)), minimum_time)
	
	# Round to 1 decimal place for cleaner display
	time_limit = round(time_limit * 10.0) / 10.0
	
	print("Level ", current_level, " - ", PuzzleType.keys()[type], " puzzle time: ", time_limit, "s")

func _generate_puzzle():
	match current_puzzle_type:
		PuzzleType.PATTERN_MATCH:
			_generate_pattern_match()
		PuzzleType.SEQUENCE_MEMORY:
			_generate_sequence_memory()
		PuzzleType.LOGIC_GATE:
			_generate_logic_gate()

func _generate_pattern_match():
	# Clear existing patterns
	_clear_containers()
	
	# Generate challenging pattern matching puzzle with transformations
	target_pattern.clear()
	player_pattern.clear()
	
	# Set up proper grid layout for pattern match
	pattern_container.columns = 1  # Vertical layout for XOR display or horizontal for others
	player_container.columns = puzzle_size  # Horizontal layout for input
	
	# Choose a random transformation type
	transform_type = 2  # Force XOR for testing: randi() % 3  # 0=Invert, 1=Mirror, 2=XOR
	
	# Generate base pattern
	var base_pattern = []
	for i in puzzle_size:
		base_pattern.append(randi() % 2)
		player_pattern.append(0)
	
	# Apply transformation to create target pattern
	match transform_type:
		0: # INVERT: Flip all bits
			instruction_label.text = "INVERT: Flip each bit (0→1, 1→0)"
			for i in puzzle_size:
				target_pattern.append(1 - base_pattern[i])
		1: # MIRROR: Reverse the pattern
			instruction_label.text = "MIRROR: Reverse the pattern"
			for i in puzzle_size:
				target_pattern.append(base_pattern[puzzle_size - 1 - i])
		2: # XOR: XOR with a fixed mask
			instruction_label.text = "XOR: Apply mask to each bit (0^0=0, 0^1=1, 1^0=1, 1^1=0)"
			var mask = [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]  # Alternating pattern
			for i in puzzle_size:
				target_pattern.append((base_pattern[i] + mask[i]) % 2)  # XOR operation
	
	# Time limit is now calculated dynamically in _calculate_time_limit()
	
	# Clean, simple layout for all puzzle types
	if current_puzzle_type == PuzzleType.PATTERN_MATCH and transform_type == 2:  # XOR puzzle
		# Show original pattern in a clean horizontal layout
		var original_text = "ORIGINAL: "
		for i in puzzle_size:
			original_text += str(base_pattern[i]) + " "
		
		var original_label = Label.new()
		original_label.text = original_text
		original_label.add_theme_font_size_override("font_size", 14)
		original_label.modulate = Color.YELLOW
		pattern_container.add_child(original_label)
		
		# Show mask pattern
		var mask = [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]
		var mask_text = "MASK        : "
		for i in puzzle_size:
			mask_text += str(mask[i]) + " "
		
		var mask_label = Label.new()
		mask_label.text = mask_text
		mask_label.add_theme_font_size_override("font_size", 14)
		mask_label.modulate = Color.CYAN
		pattern_container.add_child(mask_label)
		
		# Show separator line
		var separator = Label.new()
		separator.text = "--------------------------------"
		separator.add_theme_font_size_override("font_size", 12)
		separator.modulate = Color.GRAY
		pattern_container.add_child(separator)
		
	else:
		# Simple layout for other puzzle types
		for i in puzzle_size:
			var button = Button.new()
			button.size = Vector2(30, 30)
			button.disabled = true
			button.text = str(base_pattern[i])
			button.modulate = Color.YELLOW if base_pattern[i] == 1 else Color.GRAY
			pattern_container.add_child(button)
	
	# Player answer buttons - consistent layout for all puzzle types
	for i in puzzle_size:
		var button = Button.new()
		button.size = Vector2(30, 30)
		button.text = "0"
		button.modulate = Color.DARK_GRAY
		button.set_meta("button_index", i)
		button.pressed.connect(_on_pattern_button_pressed.bind(i))
		player_container.add_child(button)

func _generate_sequence_memory():
	# Clear existing patterns
	_clear_containers()
	
	# Generate sequence for memory game
	target_pattern.clear()
	player_pattern.clear()
	
	puzzle_size = 6  # Larger for sequence memory
	
	for i in puzzle_size:
		target_pattern.append(randi() % 2)
		player_pattern.append(0)
	
	instruction_label.text = "Remember the sequence, then recreate it!"
	
	# Set up proper grid layout for sequence memory
	pattern_container.columns = puzzle_size  # Horizontal layout for sequence
	player_container.columns = puzzle_size   # Horizontal layout for input
	
	# Show sequence briefly, then hide
	_show_sequence_briefly()

func _show_sequence_briefly():
	# Create display buttons (non-interactive during show phase)
	for i in puzzle_size:
		var button = Button.new()
		button.size = Vector2(40, 40)
		button.disabled = true
		if target_pattern[i] == 1:
			button.modulate = Color.YELLOW
			button.text = "1"
		else:
			button.modulate = Color.DARK_GRAY
			button.text = "0"
		pattern_container.add_child(button)
	
	# Create player input buttons (initially hidden)
	for i in puzzle_size:
		var button = Button.new()
		button.size = Vector2(40, 40)
		button.text = "0"
		button.modulate = Color.DARK_GRAY
		button.set_meta("button_index", i)
		button.pressed.connect(_on_pattern_button_pressed.bind(i))
		button.visible = false
		player_container.add_child(button)
	
	# Show sequence for 4 seconds, then switch to input mode
	await get_tree().create_timer(4.0).timeout
	
	# Hide sequence, show input
	for child in pattern_container.get_children():
		child.visible = false
	for child in player_container.get_children():
		child.visible = true
	
	instruction_label.text = "Recreate the sequence you saw!"

func _generate_logic_gate():
	# Clear existing patterns
	_clear_containers()
	
	# Generate logic gate puzzle (AND/OR operations)
	target_pattern.clear()
	player_pattern.clear()
	
	# Set up proper grid layout for logic gate
	pattern_container.columns = 1  # Vertical layout for gate display
	player_container.columns = 2   # Horizontal layout for 2 output buttons
	
	# Create two input pairs and expected outputs
	var input_a = [randi() % 2, randi() % 2]
	var input_b = [randi() % 2, randi() % 2]
	var gate_type = randi() % 2  # 0 = AND, 1 = OR
	
	var gate_name = "AND" if gate_type == 0 else "OR"
	instruction_label.text = gate_name + " Gate: Calculate the outputs"
	
	# Calculate expected outputs
	var output_1 = (input_a[0] && input_b[0]) if gate_type == 0 else (input_a[0] || input_b[0])
	var output_2 = (input_a[1] && input_b[1]) if gate_type == 0 else (input_a[1] || input_b[1])
	
	# Store the complete pattern for checking
	target_pattern = input_a + input_b + [1 if output_1 else 0, 1 if output_2 else 0]
	player_pattern = input_a + input_b + [0, 0]  # Copy inputs, only outputs are player input
	puzzle_size = 6
	
	# Create a clean, readable layout showing the gate operations
	# First operation: A[0] AND/OR B[0] = ?
	var operation1_text = str(input_a[0]) + " " + gate_name + " " + str(input_b[0]) + " = ?"
	var op1_label = Label.new()
	op1_label.text = operation1_text
	op1_label.add_theme_font_size_override("font_size", 16)
	op1_label.modulate = Color.WHITE
	pattern_container.add_child(op1_label)
	
	# Second operation: A[1] AND/OR B[1] = ?
	var operation2_text = str(input_a[1]) + " " + gate_name + " " + str(input_b[1]) + " = ?"
	var op2_label = Label.new()
	op2_label.text = operation2_text
	op2_label.add_theme_font_size_override("font_size", 16)
	op2_label.modulate = Color.WHITE
	pattern_container.add_child(op2_label)
	
	
	# Player answer buttons
	for i in range(2):
		var button = Button.new()
		button.size = Vector2(40, 40)
		button.text = "0"
		button.modulate = Color.DARK_GRAY
		button.set_meta("button_index", i + 4)  # Indices 4 and 5 in the pattern
		button.pressed.connect(_on_pattern_button_pressed.bind(i + 4))
		player_container.add_child(button)

func _clear_containers():
	for child in pattern_container.get_children():
		child.queue_free()
	for child in player_container.get_children():
		child.queue_free()

func _on_pattern_button_pressed(index: int):
	if not is_active:
		return
	
	# Check if index is valid
	if index >= player_pattern.size():
		return
	
	# Toggle the bit
	player_pattern[index] = 1 - player_pattern[index]
	
	# Find the correct button - need to search through player container
	var button_found = false
	for child in player_container.get_children():
		if child is Button and child.has_meta("button_index") and child.get_meta("button_index") == index:
			if player_pattern[index] == 1:
				child.text = "1"
				child.modulate = Color.CYAN
			else:
				child.text = "0"
				child.modulate = Color.DARK_GRAY
			button_found = true
			break
	
	# Fallback: try to get by child index if meta not found
	if not button_found and index < player_container.get_child_count():
		var button = player_container.get_child(index)
		if button and button is Button:
			if player_pattern[index] == 1:
				button.text = "1"
				button.modulate = Color.CYAN
			else:
				button.text = "0"
				button.modulate = Color.DARK_GRAY

func _on_submit_pressed():
	if not is_active:
		return
	
	var success = _check_solution()
	_complete_puzzle(success)

func _check_solution() -> bool:
	if player_pattern.size() != target_pattern.size():
		return false
	
	for i in range(player_pattern.size()):
		if player_pattern[i] != target_pattern[i]:
			return false
	
	return true

func _on_close_pressed():
	_complete_puzzle(false)

func _timeout():
	result_label.text = "TIME'S UP!"
	result_label.modulate = Color.RED
	await get_tree().create_timer(1.0).timeout
	_complete_puzzle(false)

func _complete_puzzle(success: bool):
	is_active = false
	
	if success:
		result_label.text = "SUCCESS! Node activated!"
		result_label.modulate = Color.GREEN
	else:
		result_label.text = "FAILED! Try again."
		result_label.modulate = Color.RED
	
	# Show result briefly
	await get_tree().create_timer(1.5).timeout
	
	# Hide popup
	visible = false
	get_tree().paused = false
	
	# Notify completion
	puzzle_completed.emit(success)
	
	# Reset result label
	result_label.text = "" 
