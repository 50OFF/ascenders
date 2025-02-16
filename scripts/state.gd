extends Node

func enter(params):
	pass  # Вызывается при входе в состояние

func exit():
	pass  # Вызывается при выходе из состояния

func update(delta):
	pass  # Логика в `_process`

func physics_update(delta):
	pass  # Логика в `_physics_process`

func input(event):
	pass # Логика в '_input'
