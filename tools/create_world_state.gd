@tool
class_name CreateWorldState
extends EditorScript

var gui := preload("uid://jnnwhyqkgqr1")

var window: Window

func _run() -> void:
	window = Window.new()
	EditorInterface.popup_dialog(window, Rect2(Vector2(100,100),Vector2(500,500)))
	
	var gui_scene :Control = gui.instantiate()
	window.add_child(gui_scene)
	
	window.close_requested.connect(func():
		window.queue_free()
	)
