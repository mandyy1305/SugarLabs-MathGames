extends Control

# References to nodes
@onready var map_generator: MapGenerator = $MapGenerator
@onready var regenerate_button: Button = $TopPanel/RegenerateButton
@onready var color_buttons: Array = [
	$TopPanel/WhiteButton,
	$TopPanel/RedButton,
	$TopPanel/BlueButton, 
	$TopPanel/GreenButton,
	$TopPanel/YellowButton
]
@onready var status_label: Label = $TopPanel/StatusLabel

# Game state
var selected_color: int = 0  # Default to white/eraser
var is_game_won: bool = false

func _ready():
	print("HELLOO")
	# Connect button signals
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	
	# Connect color button signals
	for i in range(color_buttons.size()):
		color_buttons[i].pressed.connect(_on_color_button_pressed.bind(i))
	
	# Set initial selection
	_on_color_button_pressed(0)
	
	# Update status
	status_label.text = "Selected: Eraser"

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_game_won:
				# Convert global position to map_generator's local position
				var local_pos = map_generator.get_local_mouse_position()
				var region_id = map_generator.handle_click(local_pos)
				print("Local pos: ", local_pos)
				print("Region ID: ", region_id)
				
				if region_id >= 0:
					map_generator.color_region(region_id)
					_check_win_condition()

func _on_regenerate_pressed():
	map_generator.regenerate()
	is_game_won = false
	status_label.text = "Map regenerated. Selected: " + get_color_name(selected_color)

func _on_color_button_pressed(color_idx: int):
	selected_color = color_idx
	map_generator.set_selected_color(color_idx)
	
	# Update status
	status_label.text = "Selected: " + get_color_name(color_idx)
	
	# Update button appearance
	for i in range(color_buttons.size()):
		if i == color_idx:
			color_buttons[i].add_theme_stylebox_override("normal", create_selected_style())
		else:
			color_buttons[i].remove_theme_stylebox_override("normal")

func get_color_name(idx: int) -> String:
	print("COLOR INDEX", idx)
	match idx:
		0: return "Eraser"
		1: return "Red"
		2: return "Blue"
		3: return "Green"
		4: return "Yellow"
		_: return "Unknown"

func create_selected_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.3)
	style.border_width_bottom = 3
	style.border_color = Color.WHITE
	return style

func _check_win_condition():
	# The game is won when all regions are colored (not white) and no adjacent regions have the same color
	var all_colored = true
	
	for region in map_generator.regions:
		if region.color == 0:  # Not colored or white
			all_colored = false
			break
	
	if all_colored:
		# Check if any adjacent regions have the same color
		var valid_coloring = true
		for region in map_generator.regions:
			for neighbor in region.neighbors:
				if region.color == neighbor.color and region.color != 0:
					valid_coloring = false
					break
			if not valid_coloring:
				break
		
		if valid_coloring:
			is_game_won = true
			_show_win_message()

func _show_win_message():
	var dialog = AcceptDialog.new()
	dialog.title = "Congratulations!"
	dialog.dialog_text = "You've successfully colored the map using the four color theorem!"
	add_child(dialog)
	dialog.popup_centered()
	status_label.text = "Congratulations! You've solved the map!"
