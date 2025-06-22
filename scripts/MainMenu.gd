extends Control

class_name MainMenu

# UI references
@onready var title_label = $TitleLabel
@onready var subtitle_label = $SubtitleLabel
@onready var start_button = $StartButton
@onready var instructions_button = $InstructionsButton
@onready var quit_button = $QuitButton
@onready var instructions_panel = $InstructionsPanel
@onready var back_button = $InstructionsPanel/BackButton

func _ready():
	# Style the menu with Nexus theme
	_setup_nexus_styling()
	
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	instructions_button.pressed.connect(_on_instructions_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Start with a nice entrance animation
	_animate_entrance()

func _setup_nexus_styling():
	# Style the title with Nexus colors
	title_label.modulate = Color.CYAN
	subtitle_label.modulate = Color.YELLOW
	
	# Style buttons with Nexus theme
	var button_theme = Theme.new()
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.1, 0.2, 0.4, 0.8)
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_width_top = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color.CYAN
	button_style.corner_radius_top_left = 5
	button_style.corner_radius_top_right = 5
	button_style.corner_radius_bottom_left = 5
	button_style.corner_radius_bottom_right = 5
	
	var button_hover_style = StyleBoxFlat.new()
	button_hover_style.bg_color = Color(0.2, 0.3, 0.5, 0.9)
	button_hover_style.border_width_left = 2
	button_hover_style.border_width_right = 2
	button_hover_style.border_width_top = 2
	button_hover_style.border_width_bottom = 2
	button_hover_style.border_color = Color.WHITE
	button_hover_style.corner_radius_top_left = 5
	button_hover_style.corner_radius_top_right = 5
	button_hover_style.corner_radius_bottom_left = 5
	button_hover_style.corner_radius_bottom_right = 5
	
	button_theme.set_stylebox("normal", "Button", button_style)
	button_theme.set_stylebox("hover", "Button", button_hover_style)
	button_theme.set_stylebox("pressed", "Button", button_hover_style)
	
	# Apply theme to all buttons
	start_button.theme = button_theme
	instructions_button.theme = button_theme
	quit_button.theme = button_theme
	back_button.theme = button_theme
	
	# Style instructions panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.15, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color.CYAN
	
	var panel_theme = Theme.new()
	panel_theme.set_stylebox("panel", "Panel", panel_style)
	instructions_panel.theme = panel_theme

func _animate_entrance():
	# Fade in title
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	
	# Scale buttons to 0
	start_button.scale = Vector2.ZERO
	instructions_button.scale = Vector2.ZERO
	quit_button.scale = Vector2.ZERO
	
	# Animate entrance
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in titles
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 1.0).set_delay(0.5)
	
	# Scale in buttons
	tween.tween_property(start_button, "scale", Vector2.ONE, 0.5).set_delay(1.0)
	tween.tween_property(instructions_button, "scale", Vector2.ONE, 0.5).set_delay(1.2)
	tween.tween_property(quit_button, "scale", Vector2.ONE, 0.5).set_delay(1.4)
	
	# Add some sparkle effect to title
	_add_sparkle_effect()

func _add_sparkle_effect():
	# Simple sparkle effect for the title
	var sparkle_timer = Timer.new()
	sparkle_timer.wait_time = 2.0
	sparkle_timer.timeout.connect(_sparkle_title)
	sparkle_timer.autostart = true
	add_child(sparkle_timer)

func _sparkle_title():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Quick scale pulse
	tween.tween_property(title_label, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.1)
	
	# Color shift
	tween.tween_property(title_label, "modulate", Color.WHITE, 0.1)
	tween.tween_property(title_label, "modulate", Color.CYAN, 0.1).set_delay(0.1)

func _on_start_pressed():
	_play_button_sound()
	_transition_to_game()

func _on_instructions_pressed():
	_play_button_sound()
	_show_instructions()

func _on_quit_pressed():
	_play_button_sound()
	get_tree().quit()

func _on_back_pressed():
	_play_button_sound()
	_hide_instructions()

func _play_button_sound():
	# TODO: Add button sound effect
	pass

func _transition_to_game():
	# Fade out menu
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	
	# Load the game scene
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

func _show_instructions():
	instructions_panel.visible = true
	
	# Animate instructions panel
	instructions_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(instructions_panel, "modulate:a", 1.0, 0.3)

func _hide_instructions():
	var tween = create_tween()
	tween.tween_property(instructions_panel, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	instructions_panel.visible = false 