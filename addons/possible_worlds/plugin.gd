@tool
extends EditorPlugin

const CREATE_MIND_COMMAND = "possible_worlds/create_possible_world_mind"
const CREATE_MIND_MENU = preload("res://addons/possible_worlds/GUI/create_mind_menu.tscn")

func _enter_tree() -> void:
	EditorInterface.get_command_palette().add_command(
		"Create World State",
		CREATE_MIND_COMMAND,
		_on_create_mind_editor_command
	)

func _exit_tree() -> void:
	EditorInterface.get_command_palette().remove_command(CREATE_MIND_COMMAND)

func _on_create_mind_editor_command():
	var	window := Window.new()
	EditorInterface.popup_dialog(window, Rect2(Vector2(100,100),Vector2(500,500)))
	
	var gui_scene :Control = CREATE_MIND_MENU.instantiate()
	window.add_child(gui_scene)
	
	window.close_requested.connect(func():
		window.queue_free()
	)
