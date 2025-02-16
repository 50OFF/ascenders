extends "res://scripts/state.gd"

@onready var character: Node2D = get_parent().get_parent()
@onready var walk_state = $"../WalkState"
@onready var inventory: Node = $"../../Inventory"

@onready var sprites_left: Node2D = $"../../Sprites Left"
@onready var sprites_right: Node2D = $"../../Sprites Right"

# Skeleton Left
@onready var hand_1_tip_l: Node2D = $"../../Skeleton2D Left/Hips/ShoulderF/ArmF/HandF/Tip"
@onready var hand_2_tip_l: Node2D = $"../../Skeleton2D Left/Hips/ShoulderB/ArmB/HandB/Tip"
@onready var hips_l: Bone2D = $"../../Skeleton2D Left/Hips"

# Skeleton Right
@onready var hand_1_tip_r: Node2D = $"../../Skeleton2D Right/Hips/ShoulderF/ArmF/HandF/Tip"
@onready var hand_2_tip_r: Node2D = $"../../Skeleton2D Right/Hips/ShoulderB/ArmB/HandB/Tip"
@onready var hips_r: Bone2D = $"../../Skeleton2D Right/Hips"

# IK Targets
@onready var ik_targets: Node2D = $"../../IK Targets"
@onready var foot_1: Node2D = $"../../IK Targets/FootF Target"
@onready var foot_2: Node2D = $"../../IK Targets/FootB Target"
@onready var hand_1: Node2D = $"../../IK Targets/HandF Target"
@onready var hand_2: Node2D = $"../../IK Targets/HandB Target"

# Raycasts
@onready var raycasts: Node2D = $"../../Raycasts"
@onready var ground_normal_check: RayCast2D = $"../../Raycasts/GroundNormalCheck"
@onready var fw_step_ray: RayCast2D = $"../../Raycasts/ForwardStepCheck"
@onready var bw_step_ray: RayCast2D = $"../../Raycasts/BackwardStepCheck"

# Preloads
var ice_axe = preload("res://resources/ice_axe.tres")

# State variables
var is_mouse1_held: bool = false
var is_mouse2_held: bool = false
var is_axe1_stuck: bool = false
var is_axe2_stuck: bool = false
var is_crouching: bool = false
var is_looking_left: bool = true

var foot_1_tp: Vector2
var foot_2_tp: Vector2

var ground_normal: Vector2 = Vector2.UP

var hand_1_tip: Node2D
var hand_2_tip: Node2D
var hips: Bone2D


func enter(params):
	print("Idle state entered")
	is_mouse1_held = params["is_mouse1_held"]
	is_mouse2_held = params["is_mouse2_held"]
	if "is_crouching" in params:
		is_crouching = params["is_crouching"]
	if "foot_1_pos" in params and "foot_2_pos" in params:
		foot_1.global_position = params["foot_1_pos"]
		foot_2.global_position = params["foot_2_pos"]
		foot_1_tp = foot_1.global_position
		foot_2_tp = foot_2.global_position
	
	hand_1_tip = hand_1_tip_l
	hand_2_tip = hand_2_tip_l
	hips = hips_l


func exit():
	print("Idle state exited")


func update(delta):
	if is_axe1_stuck or is_axe2_stuck:
		get_parent().change_state("ClimbState")
	elif (Input.is_action_pressed("move_left") and not walk_state.wall_ahead) or Input.is_action_pressed("move_right"):
		get_parent().change_state("WalkState", {"is_mouse1_held": is_mouse1_held, "is_mouse2_held": is_mouse2_held, 
												"is_looking_left": is_looking_left, "is_crouching": is_crouching})
	
	if not (foot_1_tp and foot_2_tp):
		foot_1_tp = fw_step_ray.get_collision_point() + Vector2(30, 0) if fw_step_ray.is_colliding() else Vector2(0,0)
		foot_2_tp = bw_step_ray.get_collision_point() + Vector2(-30, 0) if bw_step_ray.is_colliding() else Vector2(0,0)
	
	foot_1.global_position = foot_1_tp
	foot_2.global_position = foot_2_tp
	
	ground_normal = ground_normal_check.get_collision_normal() if ground_normal_check.is_colliding() else Vector2.UP
	
	move_hands(delta)
	adjust_body_position(delta)


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
				KEY_F:
					is_looking_left = !is_looking_left
					sprites_left.visible = !sprites_left.visible
					sprites_right.visible = !sprites_right.visible
					ik_targets.scale.x *= -1
					raycasts.scale.x *= -1


func adjust_body_position(delta: float):
	character.rotation = lerp(character.rotation, 0.0, 3*delta)
	hips.rotation = lerp(hips.rotation, float(clamp((ground_normal.angle() + PI / 2) * -0.7, -PI / 6, 0))/2, 2 * delta)
	if not is_crouching:
		character.global_position.y = lerp(character.global_position.y, -70 + max(foot_1.global_position.y, foot_2.global_position.y), 7 * delta)
	else:
		character.global_position.y = lerp(character.global_position.y, -45 + max(foot_1.global_position.y, foot_2.global_position.y), 7 * delta)

#движение рук
func move_hands(delta):
	var world_mouse_position
	if is_mouse1_held:
		world_mouse_position = get_viewport().get_camera_2d().get_global_mouse_position()
		hand_1.global_position = lerp(hand_1.global_position, world_mouse_position, 20*delta)
	
	else:
		if inventory.equipped_item1:
			hand_1.global_position = lerp(hand_1.global_position, character.global_position + Vector2(0, 10) + inventory.equipped_item1.tip_pos, 3*delta)
		else:
			hand_1.global_position = lerp(hand_1.global_position, character.global_position + Vector2(0, 10), 3*delta)
	
	if is_mouse2_held:
		world_mouse_position = get_viewport().get_camera_2d().get_global_mouse_position()
		hand_2.global_position = lerp(hand_2.global_position, world_mouse_position, 20*delta)
	else:
		if inventory.equipped_item2:
			hand_2.global_position = lerp(hand_2.global_position, character.global_position + Vector2(0, 10) + inventory.equipped_item2.tip_pos, 3*delta)
		else:
			hand_2.global_position = lerp(hand_2.global_position, character.global_position + Vector2(0, 10), 3*delta)


func _on_hand_f_area_area_entered(area: Area2D) -> void:
	if area.name == "GroundArea" and is_mouse1_held and inventory.equipped_item1.type == "Axe":
		is_mouse1_held = false
		hand_1.global_position = hand_1_tip.global_position
		get_parent().change_state("ClimbState", {"is_mouse1_held": is_mouse1_held, "is_mouse2_held": is_mouse2_held})


func _on_hand_b_area_area_entered(area: Area2D) -> void:
	if area.name == "GroundArea" and is_mouse2_held and inventory.equipped_item2.type == "Axe":
		is_mouse2_held = false
		hand_2.global_position = hand_2_tip.global_position
		get_parent().change_state("ClimbState", {"is_mouse1_held": is_mouse1_held, "is_mouse2_held": is_mouse2_held})
