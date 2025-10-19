class_name FileMenuButton
extends MenuButton

signal loaded_world_state(ws:WorldState)

func _init() -> void:
	text = "File"

func _ready() -> void:
	custom_minimum_size = Vector2(25,25)
	flat = false
	self.get_popup().add_item("New World")
	self.get_popup().add_item("Save As")
	self.get_popup().add_item("Load")
	
	self.get_popup().id_pressed.connect(_on_item_pressed)
	
func _on_item_pressed(id):
	var item_name := get_popup().get_item_text(id)
	print(item_name)
	match item_name:
		"New World":
			_on_new_world()
		"Save As":
			_on_save_as()
		"Load":
			_on_load()
		_:
			pass

func _on_new_world():
	var we :WorldEditor = get_tree().root.get_node("WorldEditor")
	var fileDia := FileDialog.new()
	add_child(fileDia)
	fileDia.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	fileDia.file_filter_toggle_enabled = false
	fileDia.add_filter("*.tres")
	fileDia.add_filter("*.res")
	fileDia.folder_creation_enabled = false
	fileDia.file_selected.connect(func(path):
		var res :WorldState = WorldState.new()
		res.take_over_path(path)
		res.name = "New World"
		we.ws = res
		ResourceSaver.save(res,res.resource_path,ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
	)
	fileDia.popup_centered(Vector2i(500,500))

func _on_save_as():
	var we :WorldEditor = get_tree().root.get_node("WorldEditor")
	var fileDia := FileDialog.new()
	add_child(fileDia)
	fileDia.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	fileDia.file_filter_toggle_enabled = false
	fileDia.add_filter("*.tres")
	fileDia.add_filter("*.res")
	fileDia.folder_creation_enabled = false
	fileDia.file_selected.connect(func(path):
		we.ws.take_over_path(path)
		ResourceSaver.save(we.ws,we.ws.resource_path,ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
	)
	fileDia.popup_centered(Vector2i(500,500))
	
func _on_load():
	var fileDia := FileDialog.new()
	add_child(fileDia)
	fileDia.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fileDia.file_filter_toggle_enabled = false
	fileDia.add_filter("*.tres")
	fileDia.add_filter("*.res")
	fileDia.folder_creation_enabled = false
	fileDia.file_selected.connect(func(path):
		var res := ResourceLoader.load(path)
		if res is WorldState:
			loaded_world_state.emit(res)
	)
	fileDia.popup_centered(Vector2i(500,500))
