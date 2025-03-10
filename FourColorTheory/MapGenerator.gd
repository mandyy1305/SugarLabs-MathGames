extends Node2D

class_name MapGenerator

# Configuration parameters
@export var min_distance_between_lines: float = 50.0
@export var min_area: float = 2500.0  # 50x50
@export var max_area: float = 15000.0  # ~120x120
@export var map_width: float = 800.0
@export var map_height: float = 600.0
@export var border_width: float = 20.0
@export var max_subdivisions: int = 15

# Region class to store information about each polygon
class Region:
	var polygon: PackedVector2Array
	var area: float
	var color: int = 0  # Default to 0 (white/uncolored)
	var neighbors: Array[Region] = []
	var id: int
	
	func _init(p: PackedVector2Array, i: int):
		polygon = p
		id = i
		# Calculate area
		area = calculate_area(polygon)
	
	# Calculate polygon area using shoelace formula
	func calculate_area(poly: PackedVector2Array) -> float:
		var a = 0.0
		var n = poly.size()
		for i in range(n):
			var j = (i + 1) % n
			a += poly[i].x * poly[j].y - poly[j].x * poly[i].y
		return abs(a) / 2.0

# Variables
var regions: Array[Region] = []
var region_counter: int = 0
var selected_color: int = 0  # 0 means white/uncolored

# Color constants
var region_colors = [
	Color.WHITE,  # Default color (uncolored)
	Color.RED,
	Color.BLUE,
	Color.GREEN,
	Color.YELLOW
]

func _ready():
	# Generate map on start
	generate_map()

func generate_map():
	print("HELLOO")
	regions.clear()
	region_counter = 0
	
	# Create initial rectangle (the map border)
	var initial_polygon = PackedVector2Array([
		Vector2(border_width, border_width),
		Vector2(map_width - border_width, border_width),
		Vector2(map_width - border_width, map_height - border_width),
		Vector2(border_width, map_height - border_width)
	])
	
	var initial_region = Region.new(initial_polygon, region_counter)
	region_counter += 1
	regions.append(initial_region)
	
	# Subdivide until we reach desired complexity
	var subdivisions = 0
	while subdivisions < max_subdivisions:
		# Find largest region to subdivide
		var largest_region_index = find_largest_region()
		if largest_region_index == -1 or regions[largest_region_index].area < min_area * 2:
			break
		
		# Subdivide the largest region
		if subdivide_region(largest_region_index):
			subdivisions += 1
		else:
			break
	
	# After subdivision, calculate neighbors
	calculate_all_neighbors()
	
	# Debug: Print region information
	print("Generated map with ", regions.size(), " regions")
	for region in regions:
		print("Region ", region.id, " - Area: ", region.area, " - Neighbors: ", region.neighbors.size())
	
	# Queue redraw to visualize the map
	queue_redraw()

func subdivide_region(region_index: int) -> bool:
	var region = regions[region_index]
	var polygon = region.polygon
	
	# Find min and max bounds of the polygon
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for point in polygon:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)
	
	var width = max_x - min_x
	var height = max_y - min_y
	
	# Don't subdivide if resulting regions would be too small
	if width < min_distance_between_lines * 2 or height < min_distance_between_lines * 2:
		return false
	
	# Decide how to subdivide (horizontal or vertical)
	var horizontal_cut = width > height
	
	# Randomly position the dividing line, but ensure minimum distance from edges
	var cut_pos
	if horizontal_cut:
		cut_pos = randf_range(min_x + min_distance_between_lines, max_x - min_distance_between_lines)
	else:
		cut_pos = randf_range(min_y + min_distance_between_lines, max_y - min_distance_between_lines)
	
	# Create two new polygons
	var poly1: PackedVector2Array = PackedVector2Array()
	var poly2: PackedVector2Array = PackedVector2Array()
	
	# For each edge in the original polygon
	var n = polygon.size()
	for i in range(n):
		var j = (i + 1) % n
		var p1 = polygon[i]
		var p2 = polygon[j]
		
		# Check if the edge crosses our dividing line
		var intersects = false
		var intersection = Vector2()
		
		if horizontal_cut:
			# Vertical dividing line
			if (p1.x < cut_pos and p2.x > cut_pos) or (p1.x > cut_pos and p2.x < cut_pos):
				# Calculate intersection point
				intersects = true
				var t = (cut_pos - p1.x) / (p2.x - p1.x)
				intersection = Vector2(cut_pos, p1.y + t * (p2.y - p1.y))
		else:
			# Horizontal dividing line
			if (p1.y < cut_pos and p2.y > cut_pos) or (p1.y > cut_pos and p2.y < cut_pos):
				# Calculate intersection point
				intersects = true
				var t = (cut_pos - p1.y) / (p2.y - p1.y)
				intersection = Vector2(p1.x + t * (p2.x - p1.x), cut_pos)
		
		# Add points to the appropriate new polygon
		if horizontal_cut:
			if p1.x <= cut_pos:
				poly1.append(p1)
			else:
				poly2.append(p1)
				
			if intersects:
				poly1.append(intersection)
				poly2.append(intersection)
		else:
			if p1.y <= cut_pos:
				poly1.append(p1)
			else:
				poly2.append(p1)
				
			if intersects:
				poly1.append(intersection)
				poly2.append(intersection)
	
	# Verify we have valid polygons
	if poly1.size() < 3 or poly2.size() < 3:
		return false
	
	# Create new regions from the polygons
	var region1 = Region.new(poly1, region_counter)
	region_counter += 1
	var region2 = Region.new(poly2, region_counter)
	region_counter += 1
	
	# Check if the areas are within the desired range
	if region1.area < min_area or region2.area < min_area:
		return false
	
	# Replace the original region with the two new ones
	regions.remove_at(region_index)
	regions.append(region1)
	regions.append(region2)
	
	return true

func find_largest_region() -> int:
	var largest_area = 0.0
	var largest_index = -1
	
	for i in range(regions.size()):
		if regions[i].area > largest_area and regions[i].area > max_area:
			largest_area = regions[i].area
			largest_index = i
	
	return largest_index

func calculate_all_neighbors():
	# Clear existing neighbors
	for region in regions:
		region.neighbors.clear()
	
	# Check each pair of regions
	for i in range(regions.size()):
		for j in range(i + 1, regions.size()):
			if are_regions_adjacent(regions[i], regions[j]):
				regions[i].neighbors.append(regions[j])
				regions[j].neighbors.append(regions[i])

func are_regions_adjacent(region1: Region, region2: Region) -> bool:
	# Two regions are adjacent if they share at least one edge segment
	var poly1 = region1.polygon
	var poly2 = region2.polygon
	
	# For each edge in region1
	for i in range(poly1.size()):
		var edge1_start = poly1[i]
		var edge1_end = poly1[(i + 1) % poly1.size()]
		
		# For each edge in region2
		for j in range(poly2.size()):
			var edge2_start = poly2[j]
			var edge2_end = poly2[(j + 1) % poly2.size()]
			
			# Check if edges overlap (accounting for reverse direction)
			if (edge1_start.is_equal_approx(edge2_start) and edge1_end.is_equal_approx(edge2_end)) or \
			   (edge1_start.is_equal_approx(edge2_end) and edge1_end.is_equal_approx(edge2_start)):
				return true
			
			# Check if the edges share a segment
			if segments_overlap(edge1_start, edge1_end, edge2_start, edge2_end):
				return true
	
	return false

func segments_overlap(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	# Check if line segments AB and CD share a portion
	# First, check if they're collinear
	if !are_points_collinear(a, b, c) or !are_points_collinear(a, b, d):
		return false
	
	# Check if the segments overlap
	# For horizontal lines
	if is_equal_approx(a.y, b.y) and is_equal_approx(c.y, d.y) and is_equal_approx(a.y, c.y):
		var min_ab_x = min(a.x, b.x)
		var max_ab_x = max(a.x, b.x)
		var min_cd_x = min(c.x, d.x)
		var max_cd_x = max(c.x, d.x)
		
		return max_ab_x >= min_cd_x and max_cd_x >= min_ab_x
	
	# For vertical lines
	if is_equal_approx(a.x, b.x) and is_equal_approx(c.x, d.x) and is_equal_approx(a.x, c.x):
		var min_ab_y = min(a.y, b.y)
		var max_ab_y = max(a.y, b.y)
		var min_cd_y = min(c.y, d.y)
		var max_cd_y = max(c.y, d.y)
		
		return max_ab_y >= min_cd_y and max_cd_y >= min_ab_y
	
	return false

func are_points_collinear(a: Vector2, b: Vector2, c: Vector2) -> bool:
	# Check if points are collinear (on the same line)
	var area = a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y)
	return is_zero_approx(area)

func is_equal_approx(a: float, b: float) -> bool:
	return abs(a - b) < 0.001

func _draw():
	# Draw all regions
	for region in regions:
		# Get the appropriate color for the region
		var color_index = region.color
		var color = region_colors[0]  # Default to white
		if color_index >= 0 and color_index < region_colors.size():
			color = region_colors[color_index]
		
		# Draw the polygon
		draw_colored_polygon(region.polygon, color)
		
		# Draw the outline
		for j in range(region.polygon.size()):
			var start = region.polygon[j]
			var end = region.polygon[(j + 1) % region.polygon.size()]
			draw_line(start, end, Color.BLACK, 2.0)
		
		# Draw region ID at center
		var center = Vector2.ZERO
		for point in region.polygon:
			center += point
		center /= region.polygon.size()
		
		var font = ThemeDB.fallback_font
		var font_size = ThemeDB.fallback_font_size
		draw_string(font, center, str(region.id), HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)

# Call this to generate a new map
func regenerate():
	generate_map()

# Method to get regions for the game logic
func get_regions() -> Array[Region]:
	return regions

# Set the currently selected color (0-based index, 0 is white/uncolored)
func set_selected_color(color_idx: int):
	selected_color = color_idx
	
# Color a region when clicked
func color_region(region_id: int):
	if selected_color < 0 or selected_color >= region_colors.size():
		return

	# Find the region with the matching ID
	var target_region = null
	for region in regions:
		if region.id == region_id:
			target_region = region
			break
	
	if target_region:
		if is_valid_color_for_region(target_region, selected_color):
			target_region.color = selected_color
			queue_redraw()
			print("Colored region ", region_id, " with color ", selected_color)
		else:
			print("Color ", selected_color, " is not valid for region ", region_id)

# Check if the selected color is valid for the region (no adjacent regions with same color)
func is_valid_color_for_region(region: Region, color_idx: int) -> bool:
	# Skip validation for eraser (white color)
	if color_idx == 0:
		return true
		
	for neighbor in region.neighbors:
		if neighbor.color == color_idx:
			return false
	return true

# Use ray casting algorithm for more reliable point-in-polygon detection
func is_point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var inside = false
	var n = polygon.size()
	var j = n - 1
	
	for i in range(n):
		if ((polygon[i].y > point.y) != (polygon[j].y > point.y)) and \
		   (point.x < polygon[i].x + (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / (polygon[j].y - polygon[i].y)):
			inside = !inside
		j = i
	
	return inside

# Handle click and return the region ID that was clicked
func handle_click(click_position: Vector2) -> int:
	print("Click at position: ", click_position)
	
	# Check each region to see if the click is inside
	for region in regions:
		if is_point_in_polygon(click_position, region.polygon):
			print("Click detected in region: ", region.id)
			return region.id
	
	# No region found
	print("No region found at click position")
	return -1
