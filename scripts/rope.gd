extends Node2D

@onready var rope: Line2D = $Line2D  # Верёвка
var anchors: Array = []  # Массив точек (якоря + персонаж)
var rope_segments: Array = []  # Дополнительные точки для провисания
var segment_count: int = 10  # Количество промежуточных точек
var gravity: float = 20.0  # Гравитация для провисания
var elasticity: float = 0.1  # Упругость
@onready var player: Node2D = $"../Character"

func _ready():
	anchors.append(Vector2(player.position.x - 30, player.position.y))  # Первая точка — персонаж
	update_rope()

func add_anchor(anchor_pos: Vector2):
	anchors.insert(anchors.size() - 1, anchor_pos)  # Вставляем перед персонажем
	update_rope()

func update_rope():
	rope.clear_points()
	rope_segments.clear()
	
	for i in range(anchors.size() - 2):
		var start = anchors[i]
		var end = anchors[i + 1]
		
		for j in range(segment_count):
			var t = j / float(segment_count)
			var mid_point = start.lerp(end, t)
			mid_point.y += sin(t * PI) * gravity  # Добавляем провисание
			rope_segments.append(mid_point)
	
	if anchors.size() > 1:
		var start = anchors[-2]
		var end = anchors[-1]
		
		if end.y >= start.y:
			rope_segments.append(start)
			rope_segments.append(end)
		else:
			for j in range(segment_count):
				var t = j / float(segment_count)
				var mid_point = start.lerp(end, t)
				mid_point.y += sin(t * PI) * gravity  # Добавляем провисание
				rope_segments.append(mid_point)
			rope_segments.append(anchors[-1])  # Последняя точка — персонаж
	for point in rope_segments:
		rope.add_point(point)

func _process(delta):
	if anchors.size() > 0:
		anchors[-1] = player.position  # Последняя точка — персонаж
		update_rope()
