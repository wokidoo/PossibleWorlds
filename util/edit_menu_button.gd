extends MenuButton
class_name EditMenuButton

const GENERATOR_SCENE:= preload("uid://jnnwhyqkgqr1")

func _init() -> void:
	text = "Edit"

func _ready() -> void:
	self.get_popup().add_item("Generate World")
	
	self.get_popup().id_pressed.connect(_on_item_pressed)
	
func _on_item_pressed(id):
	var item_name := get_popup().get_item_text(id)
	match item_name:
		"Generate World":
			_on_generate_world()
		_:
			pass

func _on_generate_world():
	var window := Window.new()
	window.add_child(GENERATOR_SCENE.instantiate())
	add_child(window)
	window.close_requested.connect(window.queue_free)
	window.popup_centered(Vector2i(300,300))
	
func _on_new_world():
	var we :WorldEditor = get_tree().root.get_node("WorldEditor")
	var fileDia := FileDialog.new()
	add_child(fileDia)
	fileDia.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	fileDia.file_filter_toggle_enabled = false
	fileDia.access = FileDialog.ACCESS_USERDATA
	
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

#func _on_save_as():
	#var we :WorldEditor = get_tree().root.get_node("WorldEditor")
	#var fileDia := FileDialog.new()
	#fileDia.access = FileDialog.ACCESS_USERDATA
	#add_child(fileDia)
	#fileDia.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	#fileDia.file_filter_toggle_enabled = false
	#fileDia.add_filter("*.tres")
	#fileDia.add_filter("*.res")
	#fileDia.folder_creation_enabled = false
	#fileDia.file_selected.connect(func(path):
		#we.ws.take_over_path(path)
		#ResourceSaver.save(we.ws,we.ws.resource_path,ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
	#)
	#fileDia.popup_centered(Vector2i(500,500))
	#
#func _on_load():
	#var fileDia := FileDialog.new()
	#add_child(fileDia)
	#fileDia.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	#fileDia.file_filter_toggle_enabled = false
	#fileDia.access = FileDialog.ACCESS_USERDATA
	#fileDia.add_filter("*.tres")
	#fileDia.add_filter("*.res")
	#fileDia.folder_creation_enabled = false
	#fileDia.file_selected.connect(func(path):
		#var res := ResourceLoader.load(path)
		#if res is WorldState:
			#loaded_world_state.emit(res)
	#)
	#fileDia.popup_centered(Vector2i(500,500))
