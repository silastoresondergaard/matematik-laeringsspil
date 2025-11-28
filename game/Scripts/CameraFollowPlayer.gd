extends Camera2D

@export var player: CharacterBody2D
@export var drag_enabled := true
@export var lerp_speed := 5.0
@export var snap_distance := 10.0

var is_dragging := false
var drag_offset := Vector2.ZERO
var last_mouse_position := Vector2.ZERO
var is_returning := false

func _ready():
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if not drag_enabled:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				is_returning = false
				last_mouse_position = event.position
				drag_offset = Vector2.ZERO
			else:
				is_dragging = false
				is_returning = true
	
	elif event is InputEventMouseMotion and is_dragging:
		var current_mouse_position = event.position
		var delta_movement = (last_mouse_position - current_mouse_position) / zoom
		drag_offset += delta_movement
		last_mouse_position = current_mouse_position

func _process(delta: float) -> void:
	if player == null:
		return
	
	var target_position = player.global_position
	
	if is_dragging:
		global_position = target_position + drag_offset
	elif is_returning:
		var distance_to_player = global_position.distance_to(target_position)
		
		if distance_to_player < snap_distance:
			global_position = target_position
			is_returning = false
			drag_offset = Vector2.ZERO
		else:
			global_position = global_position.lerp(target_position, lerp_speed * delta)
			drag_offset = global_position - target_position
	else:
		global_position = target_position
