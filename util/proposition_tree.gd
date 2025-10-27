class_name  PropositionTree
extends Tree

@export var world: World:
	set(value):
		if world != null and world.changed.is_connected(_on_world_changed):
			world.changed.disconnect(_on_world_changed)
		world = value
		if world != null:
			world.changed.connect(_on_world_changed)
			_rebuild_tree()

var root:TreeItem

func _ready():
	columns = 3
	root = create_item()
	hide_root = true
	column_titles_visible = true
	set_column_title(0,"Proposition")
	set_column_title_alignment(0,HORIZONTAL_ALIGNMENT_LEFT)
	set_column_title(1,"Value")
	set_column_title_alignment(1,HORIZONTAL_ALIGNMENT_LEFT)
	set_column_title(2,"Confidence")
	set_column_expand(0,true)
	set_column_expand(1,true)
	set_column_expand(2,true)
	set_column_expand_ratio(0,6)
	set_column_expand_ratio(1,2)
	set_column_expand_ratio(2,1)
	
	self.item_edited.connect(func():
		var item := get_edited()
		var id:String = item.get_text(0)
		var col:String = get_column_title(get_edited_column())
		match col:
			"Value":
				var truth:int = item.get_range(1) as int
				world.set_truth(id,truth-1)
				call_deferred("_rebuild_tree")
			"Confidence":
				var conf:float = item.get_range(2)
				world.set_confidence(id,conf)
				call_deferred("_rebuild_tree")
			_:
				pass
	)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("proposition") and data.has("world")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	world.set_truth(data["proposition"],data["world"].get_truth(data["proposition"]))
	world.set_confidence(data["proposition"],data["world"].get_truth(data["proposition"]))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		var item := get_item_at_position(event.position)
		if item == null:
			return
		var popup_menu:= PopupMenu.new()
		add_child(popup_menu)
		popup_menu.popup_on_parent(Rect2i(event.global_position,Vector2.ZERO)) 
		popup_menu.add_item("Delete",0)
		popup_menu.id_pressed.connect(func(id):
			match  id:
				0:
					world.erase_truth(item.get_text(0))
					call_deferred("_rebuild_tree")
				_:
					pass
		)

func _get_drag_data(at_position: Vector2) -> Variant:
	var item:= get_item_at_position(at_position)
	if item:
		var data:Dictionary
		data.set("world",world)
		data.set("proposition",item.get_text(0))
		return data
	return null

func _rebuild_tree():
	self.clear()
	if world == null:
		return
	root = create_item()
	for id in world.propositions:
		var col:= create_item(get_root())
		col.set_cell_mode(0,TreeItem.CELL_MODE_STRING)
		col.set_cell_mode(1,TreeItem.CELL_MODE_RANGE)
		col.set_cell_mode(2,TreeItem.CELL_MODE_RANGE)
		col.set_editable(1,true)
		col.set_editable(2,true)
		col.set_range_config(1,-1,1,1)
		col.set_range_config(2,0.0,1,0.01)
		col.set_text(0,id)
		col.set_text(1,"%s,%s,%s" % [PW.TriBoolString[-1],PW.TriBoolString[0],PW.TriBoolString[1]])
		col.set_range(1,world.get_truth(id)+1)
		col.set_range(2,world.get_confidence(id))
		match world.get_truth(id):
			PW.TriBool.UNKNOWN:
				col.set_custom_color(1,Color.GOLDENROD)
			PW.TriBool.FALSE:
				col.set_custom_color(1,Color.FIREBRICK)
			PW.TriBool.TRUE:
				col.set_custom_color(1,Color.WEB_GREEN)
			_:
				pass

func _on_world_changed():
	call_deferred("_rebuild_tree")
