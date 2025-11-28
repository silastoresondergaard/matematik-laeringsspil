extends Node

var checkpoint_pos: Vector2 = Vector2(-999,-999)
#på (-999, -999) skal der indsættes start positionen i tilfælde af at falde ud af bounds uden checkpoint
 
var previous_checkpoint_node: Sprite2D=null
