extends CharacterBody2D

@export var controller: CanvasLayer
@export var graph_node: Node2D
@onready var animated_sprite = $AnimatedSprite2D 

var is_dying=false
var last_safe_position=Vector2.ZERO
var spawn_position = (Vector2.ZERO)
var GRAVITY: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_dead:=false
var new_position_y:=0.0
var character_speed := 300.0
var t := 0.0
var original_y := 0.0
var original_x := 0.0
var active := false
var prev_y_velocity := 0.0


func _ready():
	original_y = global_position.y
	original_x = global_position.x
	z_index = 20

	spawn_position = Vector2(144,332)
	
	
	if graph_node == null:
		graph_node = get_tree().get_root().find_child("GraphNode", true, false)
		
	add_to_group("player")
	
	if Global.checkpoint_pos != Vector2(-999, -999):
		spawn_position=Global.checkpoint_pos
		global_position=Global.checkpoint_pos




func _process(delta: float) -> void:
	move_and_slide()

func set_checkpoint(checkpoint_position: Vector2):
	spawn_position = checkpoint_position
	print("Checkpoint activated! New spawn_position: ", spawn_position)


func _physics_process(delta):
	if is_dying:
		return
	
	if global_position.y > 900:
		is_dying=true
		active = false
		t = 0
		velocity.x = 0.0
		if graph_node != null and graph_node.has_method("unfreeze"):
			graph_node.unfreeze()
		die()
		await get_tree().process_frame
		is_dying=false
		return
	
	
	if global_position.y < -1000 and active: 
		active = false
		t = 0
		velocity.x = 0.0
		if graph_node != null and graph_node.has_method("unfreeze"):
			graph_node.unfreeze()
		global_position=last_safe_position
		return
	
	
	if Input.is_action_just_pressed("stop") and active:
		active = false
		t = 0
		velocity.x = 0.0
		if graph_node != null and graph_node.has_method("unfreeze"):
			graph_node.unfreeze()
		return
		
	if not active:
		velocity.y += GRAVITY
		animated_sprite.stop()
		
		last_safe_position = global_position
		
		if is_on_floor() and prev_y_velocity > GRAVITY:
			velocity.y = (-prev_y_velocity + 2 * GRAVITY) * 0.3
		prev_y_velocity = velocity.y
		original_y = global_position.y
		return
	
	last_safe_position = global_position
	
	animated_sprite.play("movement")
	
	if not is_instance_valid(graph_node) or not graph_node.valid:
		active = false
		return
	
	t += delta/3
	var y = graph_node.evaluate_function(t)
	
	if is_nan(y) or is_inf(y):
		active = false
		velocity.x = 0.0
		return
		
	var graph_height = graph_node.graph_height
	var y_max = graph_node.y_max
	var y_min = graph_node.y_min
	
	var y_scale = 1
	var screen_y_in_graph = remap(y*y_scale, y_max, y_min, 0.0, graph_height)
	var zero_y_in_graph = remap(0.0, y_max, y_min, 0.0, graph_height)
	var offset_from_zero = screen_y_in_graph - zero_y_in_graph
	
	global_position.y = original_y + offset_from_zero*4.0
	
	var graph_width = graph_node.graph_width
	var x_progress = remap(t, 0.0, 1.0, 0.0, graph_width)
	global_position.x = original_x + x_progress
	
	velocity.x = character_speed
	
	if t >= 1.0:
		active = false
		t = 0
		velocity.x = 0.0
	
		if graph_node != null and graph_node.has_method("unfreeze"):
			graph_node.unfreeze()
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider is TileMapLayer and collider.name == "aktuelt" and active:
			active = false
			t = 0
			velocity = Vector2.ZERO
			global_position = last_safe_position
			if graph_node != null and graph_node.has_method("unfreeze"):
				graph_node.unfreeze()



func die():
	global_position = spawn_position  # Always use spawn_position
	velocity = Vector2.ZERO
	active = false
	t = 0.0






func _on_input_field_text_submitted(new_text: String) -> void:
	active = true
	t = 0.0
	original_y = global_position.y
	original_x = global_position.x

func _on_collision_shape_2d_child_entered_tree(node: Node) -> void:
	pass 



func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_dying:
		return
	
	if body is TileMapLayer and body.name == "deathlayer":
		is_dying=true
		active = false
		t = 0
		velocity.x = 0.0
		if graph_node != null and graph_node.has_method("unfreeze"):
			graph_node.unfreeze()
		die()
		await get_tree().process_frame
		is_dying=false
		return
	
	if body is TileMapLayer and body.name == "aktuelt" and active:
	# Stop the graph movement
		active = false
		t = 0
		velocity.x = 0.0
		if graph_node != null and graph_node.has_method("unfreeze"):
			graph_node.unfreeze()
		global_position = last_safe_position
