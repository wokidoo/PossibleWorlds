class_name  CharacterTree
extends Tree

@export var ws: WorldState:
	set(value):
		ws = value
		if ws != null:
			_rebuild_tree()

signal character_selected(c:Character)

var root:TreeItem

var sorted_by_tension:bool = false
var sorted_by_name:bool = false

func _ready():
	columns = 3
	select_mode = Tree.SELECT_ROW
	root = create_item()
	hide_root = true
	column_titles_visible = true
	set_column_title(0,"Name")
	set_column_title_alignment(0,HORIZONTAL_ALIGNMENT_RIGHT)
	set_column_title(1,"Internal Tension")
	set_column_title(2,"Instance ID")
	set_column_expand(0,true)
	set_column_expand(1,false)
	set_column_expand(2,true)
	set_column_expand_ratio(0,2)
	set_column_expand_ratio(1,1)
	set_column_expand_ratio(2,1)
	self.item_selected.connect(func():
		character_selected.emit(get_selected().get_metadata(0))
	)
	self.column_title_clicked.connect(func(col:int,_button:int):
		match col:
			0:
				sort_by_name()
			1:
				sort_by_tension()
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

func sort_by_tension():
	var items:Array[TreeItem] = get_root().get_children()
	if sorted_by_tension:
		items.sort_custom(func(a,b):
			return float(a.get_text(1)) < float(b.get_text(1))
		)
		sorted_by_tension = false
	else:
		items.sort_custom(func(a,b):
			return float(a.get_text(1)) > float(b.get_text(1))
		)
		sorted_by_tension = true
	for item in get_root().get_children():
		get_root().remove_child(item)
	for item in items:
		get_root().add_child(item)

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
					ws.remove_character(item.get_metadata(0))
					call_deferred("_rebuild_tree")
				_:
					pass
		)

func _rebuild_tree():
	self.clear()
	if ws == null:
		return
	root = create_item()
	for c in ws.characters:
		var col:= create_item(get_root())
		col.set_metadata(0,c)
		col.set_text_alignment(0,HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT)
		col.set_cell_mode(0,TreeItem.CELL_MODE_STRING)
		col.set_text(0,c.name)
		col.set_cell_mode(1,TreeItem.CELL_MODE_STRING)
		col.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
		col.set_text(1,"%.2f" % c.total_internal_tension())
		col.set_cell_mode(2,TreeItem.CELL_MODE_STRING)
		col.set_text(2,str(c.get_instance_id()))
		col.set_text_alignment(2,HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT)
