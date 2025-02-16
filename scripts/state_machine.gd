extends Node

@export var initial_state: NodePath
var current_state = null


func _ready():
	# Устанавливаем начальное состояние
	if initial_state:
		current_state = get_node(initial_state)
		current_state.enter({"is_mouse1_held": false, "is_mouse2_held": false})


func _process(delta):
	if current_state:
		current_state.update(delta)


func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)


func _input(event: InputEvent) -> void:
	if current_state:
		current_state.input(event)


func change_state(new_state_path: NodePath, params = {}):
	var new_state = get_node(new_state_path)
	if new_state and new_state != current_state:
		if current_state:
			current_state.exit()
		current_state = new_state
		current_state.enter(params)
