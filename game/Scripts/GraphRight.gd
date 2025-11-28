extends Node2D

@onready var player: CharacterBody2D = %player
@onready var input_field: LineEdit = %InputField

@export var graph_width := 1200.0
@export var graph_height := 900.0
@export var x_min := 0.0
@export var x_max := 1.0
@export var y_min := -2.0
@export var y_max := 2.0
@export var line_color := Color.CYAN
@export var axis_color := Color(1.0, 1.0, 1.0, 0.20)
@export var grid_color := Color(0.3, 0.3, 0.3, 0.1)
@export var offset_from_player := Vector2(0, -450)

var graph_points: PackedVector2Array = []

var valid := false
var cooldowntimer = 0.0
var cooldown_duration = 0.2
var can_submit =true
var frozen := false
var frozen_position := Vector2.ZERO
var current_function: String = ""

func _ready():
	z_index = 5
	
	input_field.text_submitted.connect(_on_submit)
	input_field.text_changed.connect(_on_text_changed)
	
	_on_text_changed(input_field.text)

func _process(delta: float):
	if cooldowntimer > 0:
		cooldowntimer-=delta
		if cooldowntimer<=0:
			cooldowntimer=0
			can_submit=true
			if input_field:
				input_field.editable=true
	
	
	if frozen:
		global_position = frozen_position
	elif player != null:
		var adjusted_offset = offset_from_player
		global_position = player.global_position + adjusted_offset
	
	queue_redraw()

func evaluate_function(x: float) -> float:
	var expr_str = current_function.replace("x", "(" + str(x) + ")")
	expr_str = replace_math_functions(expr_str, x)
	
	var temp_expr = Expression.new()
	var parse_err = temp_expr.parse(expr_str, [])
	
	if parse_err == OK:
		var result = temp_expr.execute([])
		if not temp_expr.has_execute_failed():
			return result
	
	return NAN

func replace_math_functions(expr_str: String, x: float) -> String:
	var result = expr_str
	
	result = result.replace("PI", str(PI))
	result = result.replace("pi", str(PI))
	
	while true:
		var sin_match = result.find("sin(")
		if sin_match == -1:
			break
		
		var end_paren = find_matching_paren(result, sin_match + 4)
		if end_paren == -1:
			break
		
		var inner = result.substr(sin_match + 4, end_paren - sin_match - 4)
		var inner_value = evaluate_simple_expr(inner, x)
		result = result.substr(0, sin_match) + str(sin(inner_value)) + result.substr(end_paren + 1)
	
	while true:
		var cos_match = result.find("cos(")
		if cos_match == -1:
			break
		
		var end_paren = find_matching_paren(result, cos_match + 4)
		if end_paren == -1:
			break
		
		var inner = result.substr(cos_match + 4, end_paren - cos_match - 4)
		var inner_value = evaluate_simple_expr(inner, x)
		result = result.substr(0, cos_match) + str(cos(inner_value)) + result.substr(end_paren + 1)
	
	while true:
		var tan_match = result.find("tan(")
		if tan_match == -1:
			break
		
		var end_paren = find_matching_paren(result, tan_match + 4)
		if end_paren == -1:
			break
		
		var inner = result.substr(tan_match + 4, end_paren - tan_match - 4)
		var inner_value = evaluate_simple_expr(inner, x)
		result = result.substr(0, tan_match) + str(tan(inner_value)) + result.substr(end_paren + 1)
	
	while true:
		var sqrt_match = result.find("sqrt(")
		if sqrt_match == -1:
			break
		
		var end_paren = find_matching_paren(result, sqrt_match + 5)
		if end_paren == -1:
			break
		
		var inner = result.substr(sqrt_match + 5, end_paren - sqrt_match - 5)
		var inner_value = evaluate_simple_expr(inner, x)
		result = result.substr(0, sqrt_match) + str(sqrt(inner_value)) + result.substr(end_paren + 1)
	
	return result

func evaluate_simple_expr(expr_str: String, x: float) -> float:
	var processed = expr_str.replace("x", str(x))
	processed = processed.replace("PI", str(PI))
	processed = processed.replace("pi", str(PI))
	processed = processed.replace("^", "**")
	
	var temp_expr = Expression.new()
	if temp_expr.parse(processed, []) == OK:
		var result = temp_expr.execute([])
		if not temp_expr.has_execute_failed():
			return result
	return 0.0

func find_matching_paren(text: String, start: int) -> int:
	var depth = 1
	for i in range(start, text.length()):
		if text[i] == "(":
			depth += 1
		elif text[i] == ")":
			depth -= 1
			if depth == 0:
				return i
	return -1

func _on_submit(text: String):
	if not can_submit:
		return
	
	valid = false
	
	if text == "": text = "0x"
	else: text = text + "+0x"
	
	var parsed_text = parse_implicit_multiplication(text.replace("^", "**"))
	current_function = parsed_text
	
	var test_val = evaluate_function(0.5)
	if not is_nan(test_val):
		valid = true
		update_graph()
		
		frozen = true
		frozen_position = global_position
		
		can_submit=false
		if input_field:
			input_field.editable=false
		
		if player != null and player.has_method("_on_input_field_text_submitted"):
			player._on_input_field_text_submitted(text)

func _on_text_changed(text: String):
	if text == "": text = "0x"
	else: text = text + "+0x"
	
	var parsed_text = parse_implicit_multiplication(text.replace("^", "**"))
	current_function = parsed_text
	
	var test_val = evaluate_function(0.5)
	if not is_nan(test_val):
		valid = true
		update_graph()
	else:
		valid = false
		graph_points.clear()
		queue_redraw()

func update_graph():
	if not valid:
		return
	
	graph_points.clear()
	var steps := 200
	var x_step := (x_max - x_min) / steps
	
	var y_scale:=4
	
	for i in range(steps + 1):
		var x := x_min + i * x_step
		var y = evaluate_function(x)
		
		if not is_nan(y) and not is_inf(y):
			var screen_x := remap(x, x_min, x_max, 0, graph_width)
			var screen_y := remap(y*y_scale, y_max, y_min, 0, graph_height)
			graph_points.append(Vector2(screen_x, screen_y))
		else:
			if graph_points.size() > 0:
				graph_points.append(Vector2(INF, INF))
	
	queue_redraw()

func _draw():
	var graph_pos = Vector2.ZERO
	
	draw_rect(Rect2(graph_pos, Vector2(graph_width, graph_height)), Color(0.1, 0.1, 0.1, 0.1))
	draw_grid(graph_pos)
	draw_axes(graph_pos)
	
	if valid and graph_points.size() > 1:
		draw_function(graph_pos)

func draw_grid(offset: Vector2):
	var grid_lines_x := 10
	var grid_lines_y := 10
	
	for i in range(grid_lines_x + 1):
		var x := i * graph_width / grid_lines_x
		draw_line(offset + Vector2(x, 0), offset + Vector2(x, graph_height), grid_color, 1.0)
	
	for i in range(grid_lines_y + 1):
		var y := i * graph_height / grid_lines_y
		draw_line(offset + Vector2(0, y), offset + Vector2(graph_width, y), grid_color, 1.0)

func draw_axes(offset: Vector2):
	if y_min <= 0 and y_max >= 0:
		var y_pos := remap(0, y_max, y_min, 0, graph_height)
		draw_line(offset + Vector2(0, y_pos), offset + Vector2(graph_width, y_pos), axis_color, 2.0)
	
	if x_min <= 0 and x_max >= 0:
		var x_pos := remap(0, x_min, x_max, 0, graph_width)
		draw_line(offset + Vector2(x_pos, 0), offset + Vector2(x_pos, graph_height), axis_color, 2.0)

func draw_function(offset: Vector2):
	var prev_point: Vector2
	var started := false
	
	for i in range(graph_points.size()):
		var point := graph_points[i]
		
		if point.x == INF or point.y == INF or is_nan(point.x) or is_nan(point.y):
			started = false
			continue
		
		if point.y < -100 or point.y > graph_height + 100:
			started = false
			continue
		
		if started:
			draw_line(offset + prev_point, offset + point, line_color, 2.0)
		
		prev_point = point
		started = true

func parse_implicit_multiplication(input: String) -> String:
	var result = input
	result = result.replace(" ", "")
	
	var regex = RegEx.new()
	regex.compile("([0-9.])([a-zA-Z])")
	result = regex.sub(result, "$1*$2", true)
	regex.compile("([a-zA-Z])([0-9])")
	result = regex.sub(result, "$1*$2", true)
	regex.compile("(\\))([a-zA-Z])")
	result = regex.sub(result, "$1*$2", true)
	regex.compile("([0-9.])(\\()")
	result = regex.sub(result, "$1*$2", true)
	
	return result

func unfreeze():
	if player != null:
		global_position = player.global_position
	
	frozen = false
	
	cooldowntimer=cooldown_duration
	can_submit=false
	if input_field:
		input_field.editable=false
