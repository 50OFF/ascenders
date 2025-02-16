extends Node

@onready var hand_1l: Sprite2D = $"../Sprites Left/HandF"
@onready var hand_2l: Sprite2D = $"../Sprites Left/HandB"

@onready var hand_1r: Sprite2D = $"../Sprites Right/HandF"
@onready var hand_2r: Sprite2D = $"../Sprites Right/HandB"


@onready var tip1l: Node2D = $"../Skeleton2D Left/Hips/ShoulderF/ArmF/HandF/Tip"
@onready var tip2l: Node2D = $"../Skeleton2D Left/Hips/ShoulderB/ArmB/HandB/Tip"

@onready var tip1r: Node2D = $"../Skeleton2D Right/Hips/ShoulderF/ArmF/HandF/Tip"
@onready var tip2r: Node2D = $"../Skeleton2D Right/Hips/ShoulderB/ArmB/HandB/Tip"

@onready var hand_1l_area: Area2D = $"../Skeleton2D Left/Hips/ShoulderF/ArmF/HandF/HandF Area"
@onready var hand_2l_area: Area2D = $"../Skeleton2D Left/Hips/ShoulderB/ArmB/HandB/HandB Area"

@onready var hand_1r_area: Area2D = $"../Skeleton2D Right/Hips/ShoulderF/ArmF/HandF/HandF Area"
@onready var hand_2r_area: Area2D = $"../Skeleton2D Right/Hips/ShoulderB/ArmB/HandB/HandB Area"


@onready var ice_axe_1: RigidBody2D = $"../Sprites Left/IceAxe1"
@onready var ice_axe_2: RigidBody2D = $"../Sprites Left/IceAxe2"

const ice_axe = preload("res://resources/ice_axe.tres")

var equipped_item1: ItemResource = null
var equipped_item2: ItemResource = null


var item1l_sprite
var item2l_sprite

var item1r_sprite
var item2r_sprite


func equip1(item: ItemResource):
	if item == ice_axe:
		ice_axe_1.visible = false
	equipped_item1 = item
	item1l_sprite = Sprite2D.new()
	item1l_sprite.texture = item.sprite_texture
	item1l_sprite.offset = item.offset
	item1l_sprite.rotation = item.rotation
	item1l_sprite.position = Vector2(0, 3)
	tip1l.position = item.tip_pos
	hand_1l_area.position = item.tip_pos
	hand_1l.add_child(item1l_sprite)
	
	item1r_sprite = item1l_sprite.duplicate()
	item1r_sprite.rotation = - item.rotation
	item1r_sprite.offset = Vector2(-item.offset.x, item.offset.y)
	item1r_sprite.flip_h = true
	tip1r.position = Vector2(-item.tip_pos.x, item.tip_pos.y)
	hand_1r_area.position = Vector2(-item.tip_pos.x, item.tip_pos.y)
	hand_1r.add_child(item1r_sprite)


func equip2(item: ItemResource):
	if item == ice_axe:
		ice_axe_2.visible = false
	equipped_item2 = item
	item2l_sprite = Sprite2D.new()
	item2l_sprite.texture = item.sprite_texture
	item2l_sprite.offset = item.offset
	item2l_sprite.rotation = item.rotation
	item2l_sprite.position = Vector2(0, 3)
	tip2l.position = item.tip_pos
	hand_2l_area.position = item.tip_pos
	hand_2l.add_child(item2l_sprite)
	
	item2r_sprite = item2l_sprite.duplicate()
	item2r_sprite.rotation = - item.rotation
	item2r_sprite.offset = Vector2(-item.offset.x, item.offset.y)
	item2r_sprite.flip_h = true
	tip2r.position = Vector2(-item.tip_pos.x, item.tip_pos.y)
	hand_2r_area.position = Vector2(-item.tip_pos.x, item.tip_pos.y)
	hand_2r.add_child(item2r_sprite)


func unequip1():
	ice_axe_1.visible = true
	equipped_item1 = null
	hand_1l.get_child(0).queue_free()
	hand_1r.get_child(0).queue_free()
	tip1l.position = Vector2(0, 0)
	hand_1l_area.position = Vector2(0, 0)
	tip1r.position = Vector2(0, 0)
	hand_1l_area.position = Vector2(0, 0)

func unequip2():
	ice_axe_2.visible = true
	equipped_item2 = null
	hand_2l.get_child(0).queue_free()
	hand_2r.get_child(0).queue_free()
	tip2l.position = Vector2(0, 0)
	hand_2l_area.position = Vector2(0, 0)
	tip2r.position = Vector2(0, 0)
	hand_2l_area.position = Vector2(0, 0)
