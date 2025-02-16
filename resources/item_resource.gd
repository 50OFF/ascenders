extends Resource
class_name ItemResource  # Позволяет использовать как тип в @export

@export var name: String = "Unknown Item"
@export var type: String = "default"
@export var sprite_texture: Texture
@export var offset: Vector2 = Vector2.ZERO
@export var rotation: float = 0.0
@export var tip_pos: Vector2 = Vector2(16, 16)
