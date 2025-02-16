extends "res://scripts/state.gd"

@onready var character = get_parent().get_parent()
@onready var idle_state: Node = $"../IdleState"
@onready var inventory: Node = $"../../Inventory"

@onready var hips: Bone2D = $"../../Skeleton2D Left/Hips"

@onready var foot_1: Node2D = $"../../IK Targets/FootF Target"
@onready var foot_2: Node2D = $"../../IK Targets/FootB Target"
@onready var hand_1: Node2D = $"../../IK Targets/HandF Target"
@onready var hand_2: Node2D = $"../../IK Targets/HandB Target"

@onready var fw_step_ray: RayCast2D = $"../../Raycasts/ForwardStepCheck"
@onready var bw_step_ray: RayCast2D = $"../../Raycasts/BackwardStepCheck"
@onready var ground_normal_check: RayCast2D = $"../../Raycasts/GroundNormalCheck"

var step_rays = [fw_step_ray, bw_step_ray]

var ice_axe = preload("res://resources/ice_axe.tres")

var speed: float = 50.0

var step_distance: float = 100.0
var step_speed: float = 2.0

var moving_foot_1: bool = false
var moving_foot_2: bool = false
var target_position1: Vector2
var target_position2: Vector2
var step_progress_1: float = 0.0
var step_progress_2: float = 0.0
var start_pos_1: Vector2
var start_pos_2: Vector2

var ground_normal: Vector2

var wall_ahead: bool = false

var is_mouse1_held: bool = false
var is_mouse2_held: bool = false

var is_looking_left: bool = true
var is_crouching: bool = false

var world_mouse_position


func enter(params):
	print("Walk state entered")
	is_mouse1_held = params["is_mouse1_held"]
	is_mouse2_held = params["is_mouse2_held"]
	is_crouching = params["is_crouching"]
	is_looking_left = params["is_looking_left"]
	target_position1 = foot_1.global_position
	target_position2 = foot_2.global_position
	start_pos_1 = target_position1
	start_pos_2 = target_position2


func exit():
	print("Walk state exited")


func input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				is_mouse1_held = event.pressed
			MOUSE_BUTTON_RIGHT:
				is_mouse2_held = event.pressed
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				if inventory.equipped_item1 != ice_axe:
					inventory.equip1(ice_axe)
			KEY_2:
				if inventory.equipped_item1:
					inventory.unequip1()
			KEY_3:
				if inventory.equipped_item2 != ice_axe:
					inventory.equip2(ice_axe)
			KEY_4:
				if inventory.equipped_item2:
					inventory.unequip2()
			KEY_CTRL:
				is_crouching = !is_crouching


func update(delta: float) -> void:
	if not is_moving() and not moving_foot_1 and not moving_foot_2:
		get_parent().change_state("IdleState", {"is_mouse1_held": is_mouse1_held, "is_mouse2_held": is_mouse2_held,
												"foot_1_pos": foot_1.global_position, "foot_2_pos": foot_2.global_position,
												"is_crouching": is_crouching})
	if wall_ahead and not moving_foot_1 and not moving_foot_2:
		get_parent().change_state("IdleState", {"is_mouse1_held": is_mouse1_held, "is_mouse2_held": is_mouse2_held,
												"foot_1_pos": foot_1.global_position, "foot_2_pos": foot_2.global_position})
	
	moving_foot_1 = false
	moving_foot_2 = false
	ground_normal = ground_normal_check.get_collision_normal() if ground_normal_check.is_colliding() else Vector2.UP
	
	var direction = get_input_direction()
	
	if not (direction < 0 and wall_ahead):
		character.global_position += Vector2(-ground_normal.y, ground_normal.x) * direction * speed * delta
	
	update_step_targets(direction)
	adjust_body_position(delta)
	move_feet(delta)
	move_hands(delta)


func move_hands(delta):
	if is_mouse1_held:
		world_mouse_position = get_viewport().get_camera_2d().get_global_mouse_position()
		hand_1.global_position = lerp(hand_1.global_position, world_mouse_position, 20*delta)
	else:
		if inventory.equipped_item1:
			hand_1.global_position = lerp(hand_1.global_position, 
				foot_2.global_position + Vector2(-10, -60) + inventory.equipped_item1.tip_pos if is_looking_left else foot_2.global_position + Vector2(10, -60) + inventory.equipped_item1.tip_pos, 
				3*delta)
		else:
			hand_1.global_position = lerp(hand_1.global_position,
				foot_2.global_position + Vector2(-10, -60) if is_looking_left else foot_2.global_position + Vector2(10, -60), 
				3*delta)
	
	if is_mouse2_held:
		world_mouse_position = get_viewport().get_camera_2d().get_global_mouse_position()
		hand_2.global_position = lerp(hand_2.global_position, world_mouse_position, 20*delta)
	else:
		if inventory.equipped_item2:
			hand_2.global_position = lerp(hand_2.global_position, 
				foot_1.global_position + Vector2(-10, -60) + inventory.equipped_item2.tip_pos if is_looking_left else foot_1.global_position + Vector2(10, -60) + inventory.equipped_item2.tip_pos, 
				3*delta)
		else:
			hand_2.global_position = lerp(hand_2.global_position,
				foot_1.global_position + Vector2(-10, -60) if is_looking_left else foot_1.global_position + Vector2(10, -60), 
				3*delta)


func is_moving() -> bool:
	return Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left")


func get_input_direction() -> int:
	if Input.is_action_pressed("move_right"):
		return 1
	elif Input.is_action_pressed("move_left"):
		return -1
	return 0


func update_step_targets(direction: int):
	var ground_pos = foot_1.global_position
	var next_ground_normal = Vector2.UP
	
	if (direction > 0 and is_looking_left) or (direction < 0 and not is_looking_left):
		ground_pos = bw_step_ray.get_collision_point() if bw_step_ray.is_colliding() else foot_1.global_position
		next_ground_normal = bw_step_ray.get_collision_normal() if bw_step_ray.is_colliding() else Vector2.UP
	if (direction < 0 and is_looking_left) or (direction > 0 and not is_looking_left):
		ground_pos = fw_step_ray.get_collision_point() if fw_step_ray.is_colliding() else foot_1.global_position
		next_ground_normal = fw_step_ray.get_collision_normal() if fw_step_ray.is_colliding() else Vector2.UP
	
	if rad_to_deg(next_ground_normal.angle()) + 90 >= 50:
		wall_ahead = true
	else:
		wall_ahead = false
	
	if foot_1.global_position.distance_to(ground_pos) >= step_distance:
		var prev_step_bias = step_distance/2 - ground_pos.distance_to(foot_2.global_position)
		var step_vector = (ground_pos - foot_2.global_position).normalized()
		target_position1 = ground_pos + step_vector * prev_step_bias
	elif foot_2.global_position.distance_to(ground_pos) >= step_distance:
		var prev_step_bias = step_distance/2 - ground_pos.distance_to(foot_1.global_position)
		var step_vector = (ground_pos - foot_1.global_position).normalized()
		target_position2 = ground_pos + step_vector * prev_step_bias


func adjust_body_position(delta: float):
	hips.rotation = lerp(hips.rotation, float(clamp((ground_normal.angle() + PI / 2) * -0.7, -PI / 6, 0)), 2 * delta)
	if not is_crouching:
		character.global_position.y = lerp(character.global_position.y, -70 + max(foot_1.global_position.y, foot_2.global_position.y), 7 * delta)
	else:
		character.global_position.y = lerp(character.global_position.y, -45 + max(foot_1.global_position.y, foot_2.global_position.y), 7 * delta)


func move_feet(delta: float):
	moving_foot_1 = foot_1.global_position.distance_to(target_position1) > 2
	moving_foot_2 = foot_2.global_position.distance_to(target_position2) > 2
	
	if moving_foot_1:
		if step_progress_1 < 1:
			move_along_curve(foot_1, start_pos_1, target_position1, step_progress_1, delta, 30)
			step_progress_1 += step_speed * delta
		else:
			step_progress_1 = 0
	else:
		foot_1.global_position = target_position1
		start_pos_1 = target_position1

	if moving_foot_2:
		if step_progress_2 < 1:
			move_along_curve(foot_2, start_pos_2, target_position2, step_progress_2, delta, 30)
			step_progress_2 += step_speed * delta
		else:
			step_progress_2 = 0
	else:
		foot_2.global_position = target_position2
		start_pos_2 = target_position2


func move_along_curve(moving_object: Node2D, start_pos: Vector2, end_pos: Vector2, step_progress: float, delta: float, curve_heigth: float):
	var control_point = (start_pos + end_pos) * 0.5
	control_point += ground_normal * curve_heigth
	var new_pos = (1 - step_progress) * (1 - step_progress) * start_pos + 2 * (1 - step_progress) * step_progress * control_point + step_progress * step_progress * end_pos
	moving_object.global_position = new_pos  
