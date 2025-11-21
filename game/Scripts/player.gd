extends CharacterBody2D

@export var controller: CanvasLayer

var GRAVITY: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var new_position_y:=0.0
var character_speed := 300.0
var t := 0.0
var original_y := 0.0
var active := false
var prev_y_velocity := 0.0

func _ready():
	pass
	#original_y = global_position.y

func _process(delta: float) -> void:
	move_and_slide()
	z_index=20

func _physics_process(delta):
	if not active:
		velocity.y += GRAVITY
		if is_on_floor() and prev_y_velocity > GRAVITY:
			velocity.y = (-prev_y_velocity + 2 * GRAVITY) * 0.3
		prev_y_velocity = velocity.y
		original_y=global_position.y
		return
	if not controller.valid: return
	
	t += delta*2.05
	
	var y = controller.expr.execute([t])
	var factor:=60.0
	global_position.y = original_y - y*factor
	velocity.x = character_speed
	
	if t >= 1.0:
		active = false
		new_position_y = global_position.y
		t = 0
		velocity.x = 0.0

func _on_input_field_text_submitted(new_text: String) -> void:
	active = true

func _on_collision_shape_2d_child_entered_tree(node: Node) -> void:
	pass 
