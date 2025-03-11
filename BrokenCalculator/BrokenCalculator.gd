extends Control

@export var new_game_button: Button
@export var difficulty_button: Button
@export var number_pad: Node
@export var operators: Node
@export var button_equals: Node
@export var button_clear: Node
@export var button_backspace: Node
@export var eq_tracker_vboxcontainer: Node
@export var target_display: Node
@export var eq_counter: Node
@export var eq_display: Node
@export var toast: Node
@export var back_button: Button

# Game variables
var current_difficulty = "Medium" # Default difficulty
var target_number = 0
var available_numbers = []
var available_operators = []
var blocked_numbers = []
var blocked_operators = []
var submitted_equations = []
var equation_count = 0
var current_equation = ""

# Constants
const OPERATORS = ["+", "-", "*", "/"]
const NUMBERS = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
const MAX_EQUATIONS = 5

# Called when the node enters the scene tree for the first time
func _ready():
	randomize()
	setup_ui()
	new_game()

# Setup UI elements and connect signals
func setup_ui():
	# Connect button signals
	new_game_button.connect("pressed", new_game)
	difficulty_button.connect("pressed", toggle_difficulty)
	back_button.connect("pressed", _on_back_button_pressed)
	
	# Connect number buttons
	for i in range(10):
		var button = number_pad.get_node("Button" + str(i))
		button.connect("pressed", func(): append_to_equation(str(i)))
	
	# Connect operator buttons
	for op in OPERATORS:
		var button_name = ""
		match op:
			"+": button_name = "Plus"
			"-": button_name = "Minus"
			"*": button_name = "Multiply"
			"/": button_name = "Divide"
		
		var button = operators.get_node("Button" + button_name)
		button.connect("pressed", func(): append_to_equation(op))
	
	# Connect other buttons
	button_equals.connect("pressed", check_equation)
	button_clear.connect("pressed", clear_equation)
	button_backspace.connect("pressed", backspace_equation)

# Start a new game
func new_game():
	# Reset variables
	submitted_equations = []
	equation_count = 0
	current_equation = ""
	update_equation_display()
	
	# Clear previous equations
	for child in eq_tracker_vboxcontainer.get_children():
		child.queue_free()
	
	# Generate target and available items based on difficulty
	generate_game_elements()
	
	# Update UI
	target_display.text = "Target: " + str(target_number)
	difficulty_button.text = "Difficulty: " + current_difficulty
	eq_counter.text = "Equations: 0/" + str(MAX_EQUATIONS)
	
	# Update button states
	update_button_states()

# Generate target number and available/blocked elements
func generate_game_elements():
	# Generate target between 1 and 99
	target_number = randi() % 99 + 1
	
	# Determine how many elements to block based on difficulty
	var num_blocked_numbers = 0
	var num_blocked_operators = 0
	
	match current_difficulty:
		"Easy":
			num_blocked_numbers = randi() % 2 + 1  # 1-2 blocked numbers
			num_blocked_operators = randi() % 2    # 0-1 blocked operators
		"Medium":
			num_blocked_numbers = randi() % 3 + 2  # 2-4 blocked numbers
			num_blocked_operators = 1              # 1 blocked operator
		"Hard":
			num_blocked_numbers = randi() % 3 + 4  # 4-6 blocked numbers
			num_blocked_operators = randi() % 2 + 1 # 1-2 blocked operators
	
	# Block numbers
	blocked_numbers = []
	while blocked_numbers.size() < num_blocked_numbers:
		var num = NUMBERS[randi() % NUMBERS.size()]
		if not num in blocked_numbers:
			blocked_numbers.append(num)
	
	# Block operators
	blocked_operators = []
	while blocked_operators.size() < num_blocked_operators:
		var op = OPERATORS[randi() % OPERATORS.size()]
		if not op in blocked_operators:
			blocked_operators.append(op)
	
	# Ensure at least one digit of the target is blocked
	var target_str = str(target_number)
	var any_digit_blocked = false
	for digit in target_str:
		if digit in blocked_numbers:
			any_digit_blocked = true
			break
	
	if not any_digit_blocked:
		var random_digit = target_str[randi() % target_str.length()]
		if not random_digit in blocked_numbers:
			blocked_numbers.append(random_digit)
			
			# If we added a new number and we're over our limit, remove a random one
			if blocked_numbers.size() > num_blocked_numbers:
				var to_remove = null
				for num in blocked_numbers:
					if not target_str.contains(num):
						to_remove = num
						break
				
				if to_remove:
					blocked_numbers.erase(to_remove)
				else:
					# If we can't find a digit not in the target, just remove the last one
					# that isn't the one we just added
					for num in blocked_numbers:
						if num != random_digit:
							blocked_numbers.erase(num)
							break

# Toggle between difficulty levels
func toggle_difficulty():
	match current_difficulty:
		"Easy":
			current_difficulty = "Medium"
		"Medium":
			current_difficulty = "Hard"
		"Hard":
			current_difficulty = "Easy"
	
	difficulty_button.text = "Difficulty: " + current_difficulty
	new_game()

# Update the visual state of buttons based on what's blocked
func update_button_states():
	# Update number buttons
	for i in range(10):
		var button = number_pad.get_node("Button" + str(i))
		if str(i) in blocked_numbers:
			button.disabled = true
			button.modulate = Color(0.5, 0.5, 0.5, 0.5)
		else:
			button.disabled = false
			button.modulate = Color(1, 1, 1, 1)
	
	# Update operator buttons
	for op in OPERATORS:
		var button_name = ""
		match op:
			"+": button_name = "Plus"
			"-": button_name = "Minus"
			"*": button_name = "Multiply"
			"/": button_name = "Divide"
		
		var button = operators.get_node("Button" + button_name)
		
		if op in blocked_operators:
			button.disabled = true
			button.modulate = Color(0.5, 0.5, 0.5, 0.5)
		else:
			button.disabled = false
			button.modulate = Color(1, 1, 1, 1)

# Append character to the current equation
func append_to_equation(char):
	current_equation += char
	update_equation_display()

# Update the equation display
func update_equation_display():
	eq_display.text = current_equation

# Backspace in the equation
func backspace_equation():
	if current_equation.length() > 0:
		current_equation = current_equation.substr(0, current_equation.length() - 1)
		update_equation_display()

# Clear the current equation
func clear_equation():
	current_equation = ""
	update_equation_display()

# Check if the equation is valid and equals the target
func check_equation():
	if current_equation.is_empty():
		show_toast("Please enter an equation")
		return
	
	# Check if the equation contains at least one operator
	var has_operator = false
	for op in OPERATORS:
		if current_equation.find(op) != -1:
			has_operator = true
			break
	
	if not has_operator:
		show_toast("Equation must contain at least one operation")
		return
	
	# Check for invalid characters or syntax
	var expression = Expression.new()
	var error = expression.parse(current_equation, [])
	
	if error != OK:
		show_toast("Invalid equation")
		return
	
	# Calculate the result
	var result = expression.execute([], null, true)
	
	if expression.has_execute_failed():
		show_toast("Invalid equation")
		return
	
	# Check if the equation has already been submitted
	if current_equation in submitted_equations:
		show_toast("Equation already used")
		return
	
	# Check if result matches target
	if result == target_number:
		# Add to submitted equations
		submitted_equations.append(current_equation)
		equation_count += 1
		
		# Update counter
		eq_counter.text = "Equations: " + str(equation_count) + "/" + str(MAX_EQUATIONS)
		
		# Add to tracker
		var label = Label.new()
		label.text = current_equation + " = " + str(target_number)
		eq_tracker_vboxcontainer.add_child(label)
		
		# Clear input
		clear_equation()
		
		# Show success message
		show_toast("Correct!")
		
		# Check if level complete
		if equation_count >= MAX_EQUATIONS:
			show_toast("Level Complete! Starting new level...")
			await get_tree().create_timer(2.0).timeout
			new_game()
	else:
		show_toast("Incorrect! Result is " + str(result))

# Show a toast message
func show_toast(message):
	toast.text = message
	toast.visible = true
	
	# Hide after 2 seconds
	var tween = create_tween()
	tween.tween_property(toast, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.tween_interval(1.5)
	tween.tween_property(toast, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func(): toast.visible = false)

func _on_back_button_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://MainMenu/MainMenu.tscn")
