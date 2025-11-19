extends CharacterBody2D

@export var controller: Node2D

var GRAVITY: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var character_speed=300
var t := 0.0
var base_y := 0.0
var active := false


func _ready():
	base_y = global_position.y



func _physics_process(delta):
	if controller.valid and not active:
		t=0.0
		active=true
	if active:
		t += delta
		if t>1.0:
			active=false
			controller.valid=false
		else:
			var y = controller.expr.execute([t])
			print(y,typeof(y))
			if typeof(y) == TYPE_FLOAT:
				global_position.y = base_y - y
		velocity.x = 120.0
		move_and_slide()


#func _physics_process(delta: float) -> void:
#	var direction = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
#	velocity = direction * character_speed
#	position=position+velocity*delta
#	velocity.y += GRAVITY * delta*7
#	move_and_slide()
	


func _on_collision_shape_2d_child_entered_tree(node: Node) -> void:
	pass 
