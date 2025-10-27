class_name  CharacterTree
extends Tree

@export var ws: WorldState:
	set(value):
		ws = value
		if ws != null:
			_rebuild_tree()

signal character_selected(c:Character)

var root:TreeItem

func _ready():
	columns = 2
	select_mode = Tree.SELECT_ROW
	root = create_item()
	hide_root = true
	column_titles_visible = true
	set_column_title(0,"Name")
	set_column_title_alignment(0,HORIZONTAL_ALIGNMENT_RIGHT)
	set_column_title(1,"Instance ID")
	set_column_expand(0,true)
	set_column_expand(1,true)
	set_column_expand_ratio(0,2)
	self.item_selected.connect(func():
		character_selected.emit(get_selected().get_metadata(0))
	)

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
	for c in ws.characters:
		var col:= create_item(get_root())
		col.set_metadata(0,c)
		col.set_text_alignment(0,HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT)
		col.set_cell_mode(0,TreeItem.CELL_MODE_STRING)
		col.set_text(0,c.name)
		col.set_cell_mode(1,TreeItem.CELL_MODE_STRING)
		col.set_text(1,str(c.get_instance_id()))
		col.set_text_alignment(1,HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT)
