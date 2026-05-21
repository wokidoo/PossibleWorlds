class_name WorldStateFileDialog
extends FileDialog

signal saved_world_state(world_state:PossibleWorldState)
signal loaded_world_state(world_state:PossibleWorldState)

enum MenuMode {SAVE_AS,LOAD}

var menu_mode:MenuMode:
	set(val):
		menu_mode = val
		match menu_mode:
			MenuMode.SAVE_AS:
				file_mode = FileMode.FILE_MODE_SAVE_FILE
			MenuMode.LOAD:
				file_mode = FileDialog.FILE_MODE_OPEN_FILE
	
var possible_world_state:PossibleWorldState:
	set(val):
		possible_world_state = val
		current_path = possible_world_state.resource_path

func _ready() -> void:
	access = FileDialog.ACCESS_USERDATA
	filters = []
	add_filter("*.tres")
	add_filter("*.res")
	file_selected.connect(_on_file_selected)


func _on_file_selected(path:String):
	match menu_mode:
		MenuMode.SAVE_AS:
			if not possible_world_state:
				return
			var res := possible_world_state.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
			var err := ResourceSaver.save(res,path,ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS||ResourceSaver.FLAG_CHANGE_PATH)
			if err == OK:
				possible_world_state = res
				saved_world_state.emit(res)
		MenuMode.LOAD:
			var res :Resource = ResourceLoader.load(path)
			if res is PossibleWorldState:
				possible_world_state = res
				loaded_world_state.emit(possible_world_state)
