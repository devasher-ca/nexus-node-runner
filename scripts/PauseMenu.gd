extends CanvasLayer

class_name PauseMenu

# UI Elements
var pause_panel: Panel
var resume_button: Button
var restart_button: Button
var menu_button: Button
var quit_button: Button
var background_overlay: ColorRect

var is_paused = false

func _ready():
	_setup_pause_menu()
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _setup_pause_menu():
	# Create background overlay
	background_overlay = ColorRect.new()
	background_overlay.color = Color(0, 0, 0, 0.7)
	background_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_overlay)
	
	# Create main pause panel
	pause_panel = Panel.new()
	pause_panel.size = Vector2(400, 300)
	pause_panel.position = Vector2(440, 210)  # Center on screen
	add_child(pause_panel)
	
	# Title
	var title_label = Label.new()
	title_label.text = "GAME PAUSED"
	title_label.position = Vector2(150, 20)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.modulate = Color.CYAN
	pause_panel.add_child(title_label)
	
	# Resume button
	resume_button = Button.new()
	resume_button.text = "RESUME"
	resume_button.position = Vector2(150, 80)
	resume_button.size = Vector2(100, 40)
	resume_button.pressed.connect(_on_resume_pressed)
	pause_panel.add_child(resume_button)
	
	# Restart level button
	restart_button = Button.new()
	restart_button.text = "RESTART LEVEL"
	restart_button.position = Vector2(130, 130)
	restart_button.size = Vector2(140, 40)
	restart_button.pressed.connect(_on_restart_pressed)
	pause_panel.add_child(restart_button)
	
	# Return to menu button
	menu_button = Button.new()
	menu_button.text = "MAIN MENU"
	menu_button.position = Vector2(140, 180)
	menu_button.size = Vector2(120, 40)
	menu_button.pressed.connect(_on_menu_pressed)
	pause_panel.add_child(menu_button)
	
	# Quit button
	quit_button = Button.new()
	quit_button.text = "QUIT GAME"
	quit_button.position = Vector2(140, 230)
	quit_button.size = Vector2(120, 40)
	quit_button.pressed.connect(_on_quit_pressed)
	pause_panel.add_child(quit_button)
	
	# Style the panel
	_style_pause_menu()

func _style_pause_menu():
	var theme = Theme.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color.CYAN
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	
	theme.set_stylebox("panel", "Panel", panel_style)
	pause_panel.theme = theme

func _input(event):
	# Only handle ESC if we're actually paused
	# This prevents conflicts with GameManager
	if event.is_action_pressed("ui_cancel") and is_paused:
		print("ESC pressed in PauseMenu - Resuming game")
		toggle_pause()
		get_viewport().set_input_as_handled()  # Prevent other nodes from handling this event

func toggle_pause():
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	is_paused = true
	visible = true
	get_tree().paused = true

func resume_game():
	is_paused = false
	visible = false
	get_tree().paused = false

func _on_resume_pressed():
	resume_game()
	# Sync with GameManager
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.current_state == game_manager.GameState.PAUSED:
		game_manager.current_state = game_manager.GameState.PLAYING

func _on_restart_pressed():
	resume_game()
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		# Ensure we're in the right state before restarting
		game_manager.current_state = game_manager.GameState.PLAYING
		game_manager.restart_level()

func _on_menu_pressed():
	resume_game()
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.current_state = game_manager.GameState.MENU
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_quit_pressed():
	get_tree().quit() 