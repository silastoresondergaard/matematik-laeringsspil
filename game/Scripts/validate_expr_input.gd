extends CanvasLayer

@export var player:CharacterBody2D
var expr := Expression.new()
var valid := false
var last_value := 0.0

func _ready():
	$"InputField".text_submitted.connect(_on_submit)

func _on_submit(text: String):
	valid = false
	var parsed_text = parse_implicit_multiplication(text.replace("^", "**"))
	var parse_err = expr.parse(parsed_text, ["x"])
	if parse_err == OK:
		valid = true
	print(parsed_text)

func parse_implicit_multiplication(input: String) -> String:
	var result = input

	# Remove spaces for easier processing
	result = result.replace(" ", "")

	var regex = RegEx.new()

	# Pattern 1: Number followed by letter (2x -> 2*x)
	regex.compile("([0-9.])([a-zA-Z])")
	result = regex.sub(result, "$1*$2", true)

	# Pattern 2: Letter followed by number (x2 -> x*2) 
	regex.compile("([a-zA-Z])([0-9])")
	result = regex.sub(result, "$1*$2", true)

	# Pattern 3: Closing paren followed by letter ((2+3)x -> (2+3)*x)
	regex.compile("(\\))([a-zA-Z])")
	result = regex.sub(result, "$1*$2", true)

	# Pattern 4: Letter followed by opening paren (x(2+3) -> x*(2+3))
	regex.compile("([a-zA-Z])(\\()")
	result = regex.sub(result, "$1*$2", true)

	# Pattern 5: Closing paren followed by opening paren ((2)(3) -> (2)*(3))
	regex.compile("(\\))(\\()")
	result = regex.sub(result, "$1*$2", true)

	# Pattern 6: Number followed by opening paren (2(3+x) -> 2*(3+x))
	regex.compile("([0-9.])(\\()")
	result = regex.sub(result, "$1*$2", true)

	# Pattern 7: Letter followed by letter (xy -> x*y)
	regex.compile("([a-zA-Z])([a-zA-Z])")
	result = regex.sub(result, "$1*$2", true)

	return result
