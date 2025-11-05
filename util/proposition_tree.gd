class_name  PropositionTree
extends Tree

@export var world: World:
	set(value):
		if world and world.proposition_added.is_connected(_rebuild_tree):
			world.proposition_added.disconnect(_rebuild_tree)
		if world and world.proposition_removed.is_connected(_rebuild_tree):
			world.proposition_removed.disconnect(_rebuild_tree)
		world = value
		if world != null:
			world.proposition_added.connect(_rebuild_tree)
			world.proposition_removed.connect(_rebuild_tree)
			_rebuild_tree()

var sorted_by_name:bool = false
var sorted_by_value:bool = false
var sorted_by_confidence:bool = false

func _ready():
	columns = 3
	hide_root = true
	column_titles_visible = true
	set_column_title(0,"Proposition")
	set_column_title_alignment(0,HORIZONTAL_ALIGNMENT_LEFT)
	set_column_title(1,"Value")
	set_column_title_alignment(1,HORIZONTAL_ALIGNMENT_LEFT)
	set_column_title(2,"Confidence")
	set_column_expand(0,true)
	set_column_expand(1,true)
	set_column_expand(2,false)
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
				match world.get_truth(id):
					PW.TriBool.UNKNOWN:
						item.set_custom_color(1,Color.GOLDENROD)
					PW.TriBool.FALSE:
						item.set_custom_color(1,Color.FIREBRICK)
					PW.TriBool.TRUE:
						item.set_custom_color(1,Color.WEB_GREEN)
					_:
						pass
				item.set_range(2,world.get_confidence(id))
			"Confidence":
				var conf:float = item.get_range(2)
				world.set_confidence(id,conf)
			_:
				pass
	)
	
	self.column_title_clicked.connect(func(col:int,_button:int):
		match col:
			0:
				sort_by_name()
			1:
				sort_by_value()
			2:
				sort_by_confidence()
			_:
				pass
	)

func sort_by_name():
	var items:Array[TreeItem] = get_root().get_children()
	if sorted_by_name:
		items.sort_custom(func(a,b):
			return a.get_text(0) > b.get_text(0)
		)
		sorted_by_name = false
	else:
		items.sort_custom(func(a,b):
			return a.get_text(0) < b.get_text(0)
		)
		sorted_by_name = true
	for item in get_root().get_children():
		get_root().remove_child(item)
	for item in items:
		get_root().add_child(item)

func sort_by_value():
	var items:Array[TreeItem] = get_root().get_children()
	if sorted_by_value:
		items.sort_custom(func(a,b):
			return int(a.get_range(1)) < int(b.get_range(1))
		)
		sorted_by_value = false
	else:
		items.sort_custom(func(a,b):
			return int(a.get_range(1)) > int(b.get_range(1))
		)
		sorted_by_value = true
	for item in get_root().get_children():
		get_root().remove_child(item)
	for item in items:
		get_root().add_child(item)

func sort_by_confidence():
	var items:Array[TreeItem] = get_root().get_children()
	if sorted_by_confidence:
		items.sort_custom(func(a,b):
			return float(a.get_range(2)) < float(b.get_range(2))
		)
		sorted_by_confidence = false
	else:
		items.sort_custom(func(a,b):
			return float(a.get_range(2)) > float(b.get_range(2))
		)
		sorted_by_confidence = true
	for item in get_root().get_children():
		get_root().remove_child(item)
	for item in items:
		get_root().add_child(item)

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
	self.create_item()
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
