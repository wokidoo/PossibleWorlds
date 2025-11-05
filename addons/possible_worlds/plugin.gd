@tool
extends EditorPlugin

const CREATE_WORLD_STATE_COMMAND = "possible_worlds/create_world_state"
const CREATE_WORLD_SCENE:= preload("uid://jnnwhyqkgqr1")

func _enter_tree() -> void:
	add_custom_type("PW","Object",preload("res://addons/possible_worlds/scripts/possible_worlds.gd"),preload("res://icon.svg"))
	add_custom_type("World","Resource",preload("res://addons/possible_worlds/scripts/world.gd"),preload("res://icon.svg"))
	add_custom_type("Character","Resource",preload("res://addons/possible_worlds/scripts/character.gd"),preload("res://icon.svg"))
	add_custom_type("WorldState","Resource",preload("res://addons/possible_worlds/scripts/world_state.gd"),preload("res://icon.svg"))
	EditorInterface.get_command_palette().add_command(
		"Create World State",
		CREATE_WORLD_STATE_COMMAND,
		_on_create_world_editor_command
	)

func _exit_tree() -> void:
	EditorInterface.get_command_palette().remove_command(CREATE_WORLD_STATE_COMMAND)
	remove_custom_type("WorldState")
	remove_custom_type("Character")
	remove_custom_type("World")
	remove_custom_type("PW")

func _on_create_world_editor_command():
	var	window := Window.new()
	EditorInterface.popup_dialog(window, Rect2(Vector2(100,100),Vector2(500,500)))
	
	var gui_scene :Control = CREATE_WORLD_SCENE.instantiate()
	window.add_child(gui_scene)
	
	window.close_requested.connect(func():
		window.queue_free()
	)
