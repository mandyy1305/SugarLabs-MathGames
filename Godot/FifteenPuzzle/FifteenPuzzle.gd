extends Control

# Tile data
var grid_size = 4  # Default is medium (4x4)
var tile_size = 100
var tile_margin = 5
var tile_count = 0  # Will be calculated based on grid_size
var grid = []
var empty_pos = Vector2i()  # Will be set based on grid_size
var move_history = []
var moves_count = 0
var time_elapsed = 0
var game_running = false
var solved = false

# UI references
@export var game_container: Node# = $GameContainer
@export var moves_label: Node# = $UI/StatsContainer/MovesContainer/MovesValue
@export var timer_label: Node# = $UI/StatsContainer/TimeContainer/TimeValue
@export var timer: Node# = $Timer
@export var win_panel: Node# = $WinPanel
@export var difficulty_buttons: Node# = $UI/DifficultyContainer/DifficultyButtons
@export var status_label: Node #$WinPanel/VBoxContainer/StatsLabel
@export var difficulty_label: Node
@export var back_button: Button

func _ready():
	randomize()
	setup_ui()
	set_difficulty("medium")  # Default to medium difficulty

func _process(_delta):
	if game_running and not solved:
		update_timer_display()

func setup_ui():
	# Set timer to update every second
	timer.wait_time = 1.0
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	back_button.connect("pressed", _on_back_button_pressed)
	
	# Setup win panel
	win_panel.visible = false

func set_difficulty(difficulty):
	# Clear existing game
	clear_game()
	
	# Set grid size based on difficulty
	match difficulty:
		"easy":
			grid_size = 3
		"medium":
			grid_size = 4
		"hard":
			grid_size = 5
	
	# Calculate tile count and empty position
	tile_count = grid_size * grid_size - 1
	empty_pos = Vector2i(grid_size - 1, grid_size - 1)
	
	# Adjust tile size for different grid sizes
	match grid_size:
		3:
			tile_size = 120
		4:
			tile_size = 100
		5:
			tile_size = 80
	
	# Update game
	create_grid()
	shuffle_grid()

func clear_game():
	# Remove all existing tiles
	for child in game_container.get_children():
		child.queue_free()
	
	# Clear grid data
	grid.clear()
	move_history.clear()
	moves_count = 0
	time_elapsed = 0
	game_running = false
	solved = false
	
	moves_label.text = "0"
	timer_label.text = "0:00"
	timer.stop()
	win_panel.visible = false

func create_grid():
	grid.clear()
	
	# Initialize the grid with tiles in sorted order
	for y in range(grid_size):
		var row = []
		for x in range(grid_size):
			var tile_index = y * grid_size + x + 1
			
			if tile_index <= tile_count:
				var tile = create_tile(tile_index, x, y)
				game_container.add_child(tile)
				row.append(tile)
			else:
				# This is the empty space
				row.append(null)
				
		grid.append(row)
	
	update_tile_positions()

func create_tile(number, x, y):
	var tile = Node2D.new()
	tile.name = "Tile" + str(number)
	
	var button = Button.new()
	button.name = "Button"
	button.custom_minimum_size = Vector2(tile_size, tile_size)
	button.text = str(number)
	button.connect("pressed", Callable(self, "_on_tile_pressed").bind(number))
	
	var font = button.get_theme_font("font")
	var font_size = button.get_theme_font_size("font_size")
	button.add_theme_font_size_override("font_size", 32)
	
	# Add hover effect
	button.mouse_entered.connect(Callable(self, "_on_tile_mouse_entered").bind(button))
	button.mouse_exited.connect(Callable(self, "_on_tile_mouse_exited").bind(button))
	
	tile.add_child(button)
	tile.set_meta("number", number)
	tile.set_meta("grid_pos", Vector2i(x, y))
	
	return tile

func update_tile_positions(animate = false):
	for y in range(grid_size):
		for x in range(grid_size):
			var tile = grid[y][x]
			if tile != null:
				var target_pos = Vector2(
					x * (tile_size + tile_margin),
					y * (tile_size + tile_margin)
				)
				
				if animate:
					var tween = create_tween()
					tween.tween_property(tile, "position", target_pos, 0.2).set_ease(Tween.EASE_OUT)
				else:
					tile.position = target_pos
				
				# Update the grid position metadata
				tile.set_meta("grid_pos", Vector2i(x, y))

func _on_tile_mouse_entered(button):
	var tile = button.get_parent()
	var grid_pos = tile.get_meta("grid_pos")
	
	# Check if this tile can move
	if can_move(grid_pos.x, grid_pos.y):
		button.modulate = Color(0.9, 0.9, 1.0)  # Subtle highlight

func _on_tile_mouse_exited(button):
	button.modulate = Color(1, 1, 1)  # Reset to normal

func _on_tile_pressed(number):
	if solved:
		return
		
	# Find the tile with this number
	var tile_pos = find_tile_by_number(number)
	if tile_pos != null:
		if move_tile(tile_pos.x, tile_pos.y):
			moves_count += 1
			moves_label.text = str(moves_count)
			
			# Start the timer if this is the first move
			if not game_running:
				game_running = true
				timer.start()
			
			# Check if the puzzle is solved
			if is_solved():
				on_puzzle_solved()

func find_tile_by_number(number):
	for y in range(grid_size):
		for x in range(grid_size):
			var tile = grid[y][x]
			if tile != null and tile.get_meta("number") == number:
				return Vector2i(x, y)
	return null

func move_tile(x, y):
	if can_move(x, y):
		# Save the move for undo - store the tile reference itself
		var moved_tile = grid[y][x]
		move_history.append({
			"tile": moved_tile,
			"from_pos": Vector2i(x, y),
			"to_pos": empty_pos
		})
		
		# Swap tile with empty space
		grid[empty_pos.y][empty_pos.x] = grid[y][x]
		grid[y][x] = null
		
		# Update empty position
		empty_pos = Vector2i(x, y)
		
		# Update tile positions with animation
		update_tile_positions(true)
		
		return true
	
	return false

func can_move(x, y):
	# Check if the tile is adjacent to the empty space
	return (
		(abs(x - empty_pos.x) == 1 and y == empty_pos.y) or
		(abs(y - empty_pos.y) == 1 and x == empty_pos.x)
	)

func shuffle_grid():
	# Reset state
	moves_count = 0
	time_elapsed = 0
	move_history.clear()
	game_running = false
	solved = false
	moves_label.text = "0"
	timer_label.text = "0:00"
	timer.stop()
	win_panel.visible = false
	
	# Perform random moves to shuffle
	var last_empty_pos = null
	for _i in range(100 * grid_size):  # Scale number of random moves with grid size
		var valid_moves = []
		
		# Check all 4 directions
		var directions = [
			Vector2i(1, 0), Vector2i(-1, 0),
			Vector2i(0, 1), Vector2i(0, -1)
		]
		
		for dir in directions:
			var new_pos = empty_pos + dir
			
			# Avoid moving back and forth
			if last_empty_pos == new_pos:
				continue
				
			if new_pos.x >= 0 and new_pos.x < grid_size and new_pos.y >= 0 and new_pos.y < grid_size:
				valid_moves.append(new_pos)
		
		if valid_moves.size() > 0:
			var rand_idx = randi() % valid_moves.size()
			var move_pos = valid_moves[rand_idx]
			
			# Swap
			last_empty_pos = empty_pos
			grid[empty_pos.y][empty_pos.x] = grid[move_pos.y][move_pos.x]
			grid[move_pos.y][move_pos.x] = null
			empty_pos = move_pos
	
	# Update positions without animation
	update_tile_positions()

func undo_move():
	if move_history.size() > 0 and game_running and not solved:
		var last_move = move_history.pop_back()
		
		# Get positions from the saved move
		var from_pos = last_move.from_pos
		var to_pos = last_move.to_pos
		var tile = last_move.tile
		
		# Move the tile back to its original position
		grid[from_pos.y][from_pos.x] = tile
		grid[to_pos.y][to_pos.x] = null
		
		# Update the tile's grid_pos metadata
		tile.set_meta("grid_pos", from_pos)
		
		# Update empty position
		empty_pos = to_pos
		
		# Update tile positions with animation
		update_tile_positions(true)
		
		# Update move counter
		moves_count -= 1
		moves_label.text = str(moves_count)

func is_solved():
	for y in range(grid_size):
		for x in range(grid_size):
			var expected_number = y * grid_size + x + 1
			
			if expected_number <= tile_count:
				var tile = grid[y][x]
				if tile == null or tile.get_meta("number") != expected_number:
					return false
			else:
				# This should be the empty space
				if grid[y][x] != null:
					return false
	
	return true

func on_puzzle_solved():
	solved = true
	timer.stop()
	win_panel.visible = true
	status_label.text = "Moves: " + str(moves_count) + "\nTime: " + timer_label.text

func _on_timer_timeout():
	time_elapsed += 1
	update_timer_display()

func update_timer_display():
	var minutes = time_elapsed / 60
	var seconds = time_elapsed % 60
	timer_label.text = str(minutes) + ":" + "%02d" % seconds

func _on_shuffle_button_pressed():
	shuffle_grid()

func _on_undo_button_pressed():
	undo_move()

func _on_play_again_button_pressed():
	shuffle_grid()

func _on_easy_button_pressed():
	difficulty_label.text = "Difficulty: Easy"
	set_difficulty("easy")

func _on_medium_button_pressed():
	difficulty_label.text = "Difficulty: Medium"
	set_difficulty("medium")

func _on_hard_button_pressed():
	difficulty_label.text = "Difficulty: Hard"
	set_difficulty("hard")

func _on_back_button_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://MainMenu/MainMenu.tscn")
