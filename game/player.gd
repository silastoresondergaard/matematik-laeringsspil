extends CharacterBody2D
var character_speed=300

var GRAVITY: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	velocity = direction * character_speed
	position=position+velocity*delta
	velocity.y += GRAVITY * delta*7
	move_and_slide()
	
