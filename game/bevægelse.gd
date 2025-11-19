extends Node2D


var expr := Expression.new()
var valid := false
var last_value := 0.0

func _ready():
	$"InputField".text_submitted.connect(_on_submit)

func _on_submit(text):
	valid = false
	var parse_err = expr.parse(text, ["x"])
	if parse_err == OK:
		valid = true
	print(text)
