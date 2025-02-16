extends "res://scripts/state.gd"

@onready var character = get_parent().get_parent()

@onready var hand_1_tip: Node2D = $"../../Skeleton2D Left/Hips/ShoulderF/ArmF/HandF/Tip"
@onready var hand_2_tip: Node2D = $"../../Skeleton2D Left/Hips/ShoulderB/ArmB/HandB/Tip"
@onready var hips: Bone2D = $"../../Skeleton2D Left/Hips"

@onready var foot_1: Node2D = $"../../IK Targets/FootF Target"
@onready var foot_2: Node2D = $"../../IK Targets/FootB Target"
@onready var hand_1: Node2D = $"../../IK Targets/HandF Target"
@onready var hand_2: Node2D = $"../../IK Targets/HandB Target"

@onready var up_step_ray: RayCast2D = $"../../Raycasts/UpStepCheck"
@onready var down_step_ray: RayCast2D = $"../../Raycasts/DownStepCheck"
@onready var wall_normal_check: RayCast2D = $"../../Raycasts/WallNormalCheck"

@onready var walk_state = $"../WalkState"


var wall_normal: Vector2

#FEET
var step_distance: float = 60.0
var step_speed: float = 2.0

var moving_foot_1: bool = false
var moving_foot_2: bool = false

var foot_1_tp: Vector2
var foot_2_tp: Vector2

var step_progress_1: float = 0.0
var step_progress_2: float = 0.0

var foot_1_start_pos: Vector2
var foot_2_start_pos: Vector2

#hands
var hand_1_tp: Vector2
var hand_2_tp: Vector2

var is_mouse1_held: bool = false
var is_mouse2_held: bool = false

var is_axe1_stuck: bool = false
var is_axe2_stuck: bool = false

var world_mouse_position: Vector2

var last_position = Vector2.ZERO


func enter(params):
	print("Climb state entered")
	is_mouse1_held = params["is_mouse1_held"]
	is_mouse2_held = params["is_mouse2_held"]
	
	foot_1_tp = foot_1.global_position
	foot_2_tp = foot_2.global_position
	foot_1_start_pos = foot_1_tp
	foot_2_start_pos = foot_2_tp
	
	hand_1_tp = hand_1.global_position
	hand_2_tp = hand_2.global_position


func exit():
	print("Climb state exited")


func update(delta: float) -> void:
	moving_foot_1 = false
	moving_foot_2 = false
	
	if hips.rotation != 0:
		hips.rotation = lerp(hips.rotation, 0.0, 3*delta)
	
	wall_normal = wall_normal_check.get_collision_normal() if wall_normal_check.is_colliding() else Vector2.UP
	
	up_step_ray.global_rotation = wall_normal.angle() + PI/2
	down_step_ray.global_rotation = wall_normal.angle() + PI/2
	
	var direction_y = sign(character.global_position.y - last_position.y)
	last_position = character.global_position
	
	move_hands(delta)
	update_step_targets(direction_y)
	adjust_body_position(delta)
	move_feet(delta)


func input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				is_mouse1_held = event.pressed
			MOUSE_BUTTON_RIGHT:
				is_mouse2_held = event.pressed

#движение рук
func move_hands(delta: float):
	if is_mouse1_held:
		is_axe1_stuck = false
		world_mouse_position = get_viewport().get_camera_2d().get_global_mouse_position()
		hand_1.global_position = lerp(hand_1.global_position, world_mouse_position, 20*delta)
		hand_1_tp = world_mouse_position
	elif is_axe1_stuck:
		hand_1.global_position = hand_1_tp
	else:
		hand_1.global_position = lerp(hand_1.global_position, character.global_position + Vector2(-25, +20), 3*delta)
	
	if is_mouse2_held:
		is_axe2_stuck = false
		world_mouse_position = get_viewport().get_camera_2d().get_global_mouse_position()
		hand_2.global_position = lerp(hand_2.global_position, world_mouse_position, 20*delta)
		hand_2_tp = world_mouse_position
	elif is_axe2_stuck:
		hand_2.global_position = hand_2_tp
	else:
		hand_2.global_position =  lerp(hand_2.global_position, character.global_position + Vector2(-25, +20), 3*delta)


func _on_hand_f_area_area_entered(area: Area2D) -> void:
	if get_parent().current_state == self and area.name == "GroundArea":
		is_axe1_stuck = true
		is_mouse1_held = false
		hand_1.global_position = hand_1_tip.global_position
		hand_1_tp = hand_1_tip.global_position


func _on_hand_b_area_area_entered(area: Area2D) -> void:
	if get_parent().current_state == self and area.name == "GroundArea":
		is_axe2_stuck = true
		is_mouse2_held = false
		hand_2.global_position = hand_2_tip.global_position
		hand_2_tp = hand_2_tip.global_position

#обновление целей шага
func update_step_targets(direction: int):
	var ground_pos = up_step_ray.get_collision_point() if up_step_ray.is_colliding() else foot_1.global_position
	if direction > 0:
		ground_pos = down_step_ray.get_collision_point() if down_step_ray.is_colliding() else foot_1.global_position
	
	if foot_1.global_position.distance_to(ground_pos) >= step_distance:
		var prev_step_bias = step_distance/2 - ground_pos.distance_to(foot_2.global_position)
		var step_vector = (ground_pos - foot_2.global_position).normalized()
		foot_1_tp = ground_pos + step_vector * prev_step_bias
	elif foot_2.global_position.distance_to(ground_pos) >= step_distance:
		var prev_step_bias = step_distance/2 - ground_pos.distance_to(foot_1.global_position)
		var step_vector = (ground_pos - foot_1.global_position).normalized()
		foot_2_tp = ground_pos + step_vector * prev_step_bias

#корректировка положения тела
func adjust_body_position(delta: float):
	character.rotation = lerp(character.rotation, wall_normal.angle() + PI/10, delta)
	var foot
	var hand
	var ch_pos
	var hf

	foot = (foot_1_tp + foot_2_tp)/2
	
	if (is_axe1_stuck and is_axe2_stuck) or (is_axe1_stuck and is_mouse2_held) or (is_mouse1_held and is_axe2_stuck):
		hand = (hand_1_tip.global_position + hand_2_tip.global_position)/2
	elif (is_axe1_stuck and not is_mouse2_held):
		hand = hand_1_tip.global_position
	elif (is_axe2_stuck and not is_mouse1_held):
		hand = hand_2_tip.global_position
	else:
		if rad_to_deg(wall_normal.angle()) + 90 < 50:
			get_parent().change_state("IdleState", {"is_mouse1_held": is_mouse1_held, "is_mouse2_held": is_mouse2_held,
													"foot_1_pos": foot_1.global_position, "foot_2_pos": foot_2.global_position})
		else:
			get_parent().change_state("FallState", {})
		return
	
	hf = hand - foot
	ch_pos = foot + hf/2.5 + Vector2(-hf.y, hf.x).normalized() * 40
	
	character.global_position = lerp(character.global_position, ch_pos, 2 * delta)

#плавное переставление ног
func move_feet(delta: float):
	moving_foot_1 = foot_1.global_position.distance_to(foot_1_tp) > 2
	moving_foot_2 = foot_2.global_position.distance_to(foot_2_tp) > 2
	
	if moving_foot_1:
		if step_progress_1 < 1:
			move_along_curve(foot_1, foot_1_start_pos, foot_1_tp, step_progress_1, delta, 30)
			step_progress_1 += step_speed * delta
		else:
			step_progress_1 = 0
	else:
		foot_1.global_position = foot_1_tp
		foot_1_start_pos = foot_1_tp

	if moving_foot_2:
		if step_progress_2 < 1:
			move_along_curve(foot_2, foot_2_start_pos, foot_2_tp, step_progress_2, delta, 30)
			step_progress_2 += step_speed * delta
		else:
			step_progress_2 = 0
	else:
		foot_2.global_position = foot_2_tp
		foot_2_start_pos = foot_2_tp

#движение объекта по дуге
func move_along_curve(moving_object: Node2D, start_pos: Vector2, end_pos: Vector2, step_progress: float, delta: float, curve_heigth: float):
	var control_point = (start_pos + end_pos) * 0.5
	control_point += wall_normal * curve_heigth
	var new_pos = (1 - step_progress) * (1 - step_progress) * start_pos + 2 * (1 - step_progress) * step_progress * control_point + step_progress * step_progress * end_pos
	moving_object.global_position = new_pos
