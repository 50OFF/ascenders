extends "res://scripts/state.gd"

@onready var character = get_parent().get_parent()
@onready var idle_state: Node = $"../IdleState"
@onready var inventory: Node = $"../../Inventory"

@onready var hips: Bone2D = $"../../Skeleton2D Left/Hips"

@onready var foot_1: Node2D = $"../../IK Targets/FootF Target"
@onready var foot_2: Node2D = $"../../IK Targets/FootB Target"
@onready var hand_1: Node2D = $"../../IK Targets/HandF Target"
@onready var hand_2: Node2D = $"../../IK Targets/HandB Target"

@onready var up_step_ray: RayCast2D = $"../../Raycasts/UpStepCheck"
@onready var down_step_ray: RayCast2D = $"../../Raycasts/DownStepCheck"
@onready var wall_normal_check: RayCast2D = $"../../Raycasts/WallNormalCheck"

var step_rays = [up_step_ray, down_step_ray]

const ice_axe = preload("res://resources/ice_axe.tres")
const ice_screw = preload("res://resources/ice_screw.tres")

var speed: float = 30.0

var step_distance: float = 80.0
var step_speed: float = 2

var moving_foot_1: bool = false
var moving_foot_2: bool = false
var target_position1: Vector2
var target_position2: Vector2
var step_progress_1: float = 0.0
var step_progress_2: float = 0.0
var start_pos_1: Vector2
var start_pos_2: Vector2

var wall_normal: Vector2

var is_mouse1_held: bool = false
var is_mouse2_held: bool = false

var is_looking_left: bool = true

var is_crouching: bool = false

var world_mouse_position

var rope_system

var is_on_wall: bool = false

func enter(params):
	print("Rope state entered")
	is_mouse1_held = params["is_mouse1_held"]
	is_mouse2_held = params["is_mouse2_held"]
	if "foot_1_pos" in params and "foot_2_pos" in params:
		foot_1.global_position = params["foot_1_pos"]
		foot_2.global_position = params["foot_2_pos"]
		target_position1 = foot_1.global_position
		target_position2 = foot_2.global_position
		start_pos_1 = target_position1
		start_pos_2 = target_position2
	
	rope_system = get_tree().current_scene.get_node("RopeSystem")


func exit():
	print("Rope state exited")

func update(delta):
	#сделать переход в climb state и в idle state при спуске на землю
	
	wall_normal = wall_normal_check.get_collision_normal() if wall_normal_check.is_colliding() else Vector2.RIGHT
	var direction = get_input_direction()
	is_on_wall = character.global_position.x >= rope_system.anchors[-2].x and wall_normal.angle() <= 0
	
	moving_foot_1 = false
	moving_foot_2 = false
	
	if is_on_wall:
		character.global_position += Vector2(-wall_normal.y, wall_normal.x) * -direction * speed * delta
	else:
		if direction < 0:
			character.global_position += Vector2.DOWN * -direction * speed * delta
	
	move_feet(delta)
	update_step_targets(direction)
	adjust_body_position(delta)
	move_hands(delta)
	


func physics_update(delta):
	pass


func input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				is_mouse1_held = event.pressed
			MOUSE_BUTTON_RIGHT:
				is_mouse2_held = event.pressed
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_CTRL:
				is_crouching = !is_crouching


func adjust_body_position(delta: float):
	if is_on_wall:
		character.rotation = lerp(character.rotation, wall_normal.angle() + PI/10, 2*delta)
		hips.rotation = lerp(hips.rotation, clampf(character.rotation + PI/6, -PI/2, PI/2) , 2*delta)
	else:
		character.rotation = lerp(character.rotation, wall_normal.angle() + PI/10, 2*delta)
		hips.global_rotation = lerp(hips.global_rotation, clampf(character.rotation + PI/6, -PI/2, PI/2) , 2*delta)
	
	var hanging_x = rope_system.anchors[-2].x
	var feet_x = 55 + max(foot_1.global_position.x, foot_2.global_position.x)
	
	if not is_crouching:
		character.global_position.x = lerp(character.global_position.x, max(hanging_x, feet_x), 2*delta)
	elif is_on_wall:
		character.global_position.x = lerp(character.global_position.x, max(hanging_x, feet_x) - 25, 2*delta)


func update_step_targets(direction: int): 
	var ground_pos = foot_1.global_position
	var next_ground_normal = Vector2.UP
	
	if (direction < 0 and is_looking_left) or (direction > 0 and not is_looking_left):
		ground_pos = down_step_ray.get_collision_point() if down_step_ray.is_colliding() else foot_1.global_position
		next_ground_normal = down_step_ray.get_collision_normal() if down_step_ray.is_colliding() else Vector2.UP
	if (direction > 0 and is_looking_left) or (direction < 0 and not is_looking_left):
		ground_pos = up_step_ray.get_collision_point() if up_step_ray.is_colliding() else foot_1.global_position
		next_ground_normal = up_step_ray.get_collision_normal() if up_step_ray.is_colliding() else Vector2.UP
	
	if foot_1.global_position.distance_to(ground_pos) >= step_distance:
		#wall_ahead = rad_to_deg(next_ground_normal.angle()) + 90 >= 50
		var prev_step_bias = step_distance/2 - ground_pos.distance_to(foot_2.global_position)
		var step_vector = (ground_pos - foot_2.global_position).normalized()
		target_position1 = ground_pos + step_vector * prev_step_bias
	elif foot_2.global_position.distance_to(ground_pos) >= step_distance:
		#wall_ahead = rad_to_deg(next_ground_normal.angle()) + 90 >= 50
		var prev_step_bias = step_distance/2 - ground_pos.distance_to(foot_1.global_position)
		var step_vector = (ground_pos - foot_1.global_position).normalized()
		target_position2 = ground_pos + step_vector * prev_step_bias


func move_hands(delta):
	hand_1.global_position = rope_system.rope_segments[-1] - (rope_system.rope_segments[-1] - rope_system.rope_segments[-2]).normalized() * 40
	hand_2.global_position = rope_system.rope_segments[-1] - (rope_system.rope_segments[-1] - rope_system.rope_segments[-2]).normalized() * 30
	#if is_mouse1_held:
		#world_mouse_position = get_viewport().get_camera_2d().get_global_mouse_position()
		#hand_1.global_position = lerp(hand_1.global_position, world_mouse_position, 20*delta)
	#else:
		#if inventory.equipped_item1:
			#hand_1.global_position = lerp(hand_1.global_position, 
				#foot_2.global_position + Vector2(-10, -60) + inventory.equipped_item1.tip_pos if is_looking_left else foot_2.global_position + Vector2(10, -60) + inventory.equipped_item1.tip_pos, 
				#3*delta)
		#else:
			#hand_1.global_position = lerp(hand_1.global_position,
				#foot_2.global_position + Vector2(-10, -60) if is_looking_left else foot_2.global_position + Vector2(10, -60), 
				#3*delta)
	#
	#if is_mouse2_held:
		#world_mouse_position = get_viewport().get_camera_2d().get_global_mouse_position()
		#hand_2.global_position = lerp(hand_2.global_position, world_mouse_position, 20*delta)
	#else:
		#if inventory.equipped_item2:
			#hand_2.global_position = lerp(hand_2.global_position, 
				#foot_1.global_position + Vector2(-10, -60) + inventory.equipped_item2.tip_pos if is_looking_left else foot_1.global_position + Vector2(10, -60) + inventory.equipped_item2.tip_pos, 
				#3*delta)
		#else:
			#hand_2.global_position = lerp(hand_2.global_position,
				#foot_1.global_position + Vector2(-10, -60) if is_looking_left else foot_1.global_position + Vector2(10, -60), 
				#3*delta)


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


func get_input_direction() -> int:
	if Input.is_action_pressed("move_up"):
		return 1
	elif Input.is_action_pressed("move_down"):
		return -1
	return 0


func move_along_curve(moving_object: Node2D, start_pos: Vector2, end_pos: Vector2, step_progress: float, delta: float, curve_heigth: float):
	var control_point = (start_pos + end_pos) * 0.5
	control_point += wall_normal * curve_heigth
	var new_pos = (1 - step_progress) * (1 - step_progress) * start_pos + 2 * (1 - step_progress) * step_progress * control_point + step_progress * step_progress * end_pos
	moving_object.global_position = new_pos 
