extends Sprite2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var checkpoint_pos = $Marker2D.global_position
		Global.checkpoint_pos = checkpoint_pos
		body.set_checkpoint(checkpoint_pos) 
		Global.previous_checkpoint_node = self
