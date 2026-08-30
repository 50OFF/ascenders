extends CanvasLayer

func _process(delta:float):
	$Control.global_position = get_viewport().get_camera_2d().global_position
