extends Control

func _ready():
	# Connect button signals
	$UI/VBoxContainer/BrokenCalculatorButton.connect("pressed", _on_broken_calculator_pressed)
	$UI/VBoxContainer/FourColorMapButton.connect("pressed", _on_four_color_map_pressed)
	$UI/VBoxContainer/FifteenPuzzle.connect("pressed", _on_fifteen_puzzle_pressed)
func _on_broken_calculator_pressed():
	# Change to the Broken Calculator scene
	get_tree().change_scene_to_file("res://BrokenCalculator/BrokenCalculator.tscn")

func _on_four_color_map_pressed():
	get_tree().change_scene_to_file("res://FourColorTheory/FourColorGame.tscn")
	
func _on_fifteen_puzzle_pressed():
	get_tree().change_scene_to_file("res://FifteenPuzzle/FifteenPuzzle.tscn")
	
	# Hide notification after 2 seconds
	var tween = create_tween()
	tween.tween_property($UI/NotificationLabel, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.tween_interval(2.0)
	tween.tween_property($UI/NotificationLabel, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func(): $UI/NotificationLabel.visible = false)
