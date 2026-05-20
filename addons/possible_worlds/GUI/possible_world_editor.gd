extends Tree
class_name PossibleWorldEditor

@export var possible_world:PossibleWorld:
	set(val):
		if possible_world and possible_world.changed.is_connected(_on_resource_changed):
			possible_world.changed.disconnect(_on_resource_changed)
		possible_world = val
		possible_world.changed.connect(_on_resource_changed)
		_update_tree.call_deferred()

var root:TreeItem
var last_row:TreeItem

func _ready() -> void:
	visibility_changed.connect(_update_tree.call_deferred)
	column_titles_visible = true
	hide_root = true
	columns = 3
	set_column_title(0,"Proposition")
	set_column_title(1,"Value")
	cell_selected.connect(_on_cell_selected)
	item_edited.connect(_on_item_edited)
	_update_tree()

func _update_tree():
	clear()
	root = create_item()
	if not possible_world:
		return
	for prop in possible_world.get_all_propositions().keys():
		_create_row(prop,possible_world)
	last_row = create_item()
	last_row.set_cell_mode(0,TreeItem.CELL_MODE_STRING)
	last_row.set_editable(0,true)
	last_row.set_cell_mode(1,TreeItem.CELL_MODE_CUSTOM)
	last_row.set_text(1,"Create Proposition...")

func _create_row(prop:StringName,pw:PossibleWorld)->TreeItem:
	var item :TreeItem = create_item(root)
	item.set_meta('prop',prop)
	item.set_text(0,prop)
	item.set_editable(1,true)
	item.set_cell_mode(1,TreeItem.CELL_MODE_RANGE)
	item.set_range_config(1,-1,1,0.001)
	item.set_range(1,pw.get_proposition(prop))
	item.set_cell_mode(2,TreeItem.CELL_MODE_CUSTOM)
	item.set_text(2,'Delete')
	return item

func _on_item_edited():
	var item:TreeItem = get_edited()
	var column:int = get_edited_column()
	match column:
		0:
			pass
		1:
			possible_world.set_proposition(item.get_meta('prop'),item.get_range(1))
			_update_tree.call_deferred()
		2:
			pass
		3:
			pass

func _on_cell_selected():
	var item := get_selected()
	if item == last_row and get_selected_column() == 1:
		if item.get_text(0).is_empty():
			return
		possible_world.set_proposition(item.get_text(0),0.0)
		_update_tree.call_deferred()
	elif item != last_row and get_selected_column() == 2:
		possible_world.remove_proposition(item.get_meta('prop'))
		_update_tree.call_deferred()

func _on_resource_changed():
	if possible_world.is_built_in():
		return
	ResourceSaver.save(possible_world,possible_world.resource_path,ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
