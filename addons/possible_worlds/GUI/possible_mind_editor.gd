extends Tree
class_name PossibleMindEditor

@export var possible_world_mind:PossibleWorldMind:
	set(val):
		if possible_world_mind and possible_world_mind.changed.is_connected(_on_resource_changed):
			possible_world_mind.changed.disconnect(_on_resource_changed)
		possible_world_mind = val
		if possible_world_mind:
			possible_world_mind.changed.connect(_on_resource_changed)
		_update_tree.call_deferred()

var _totals_row:TreeItem
var root:TreeItem

func _ready() -> void:
	visibility_changed.connect(_update_tree.call_deferred)
	columns = 5
	column_titles_visible = true
	hide_root = true
	root = create_item()
	item_edited.connect(_on_item_edited)
	self.cell_selected.connect(_on_cell_selected)
	set_column_title(0,"Proposition")
	set_column_title(1,"Ideal")
	set_column_title(2,"Perceived")
	set_column_title(3,"Tension")
	set_column_expand_ratio(0,3)
	set_column_expand_ratio(1,1)
	set_column_expand_ratio(2,1)
	set_column_expand_ratio(3,1)
	set_column_expand_ratio(4,1)
	_update_tree()

func _update_tree():
	self.clear()
	root = create_item()
	if not possible_world_mind:
		return
	for prop in possible_world_mind.ideal_world.get_all_propositions().keys():
		_create_row(prop,possible_world_mind)
	_totals_row = create_item(get_root())
	_totals_row.set_cell_mode(0,TreeItem.CELL_MODE_STRING)
	_totals_row.set_editable(0,true)
	_totals_row.set_cell_mode(1,TreeItem.CELL_MODE_CUSTOM)
	_totals_row.set_text(1,"Create Proposition...")
	_totals_row.set_cell_mode(2,TreeItem.CELL_MODE_STRING)
	_totals_row.set_text_alignment(2,HORIZONTAL_ALIGNMENT_RIGHT)
	_totals_row.set_text(2,"Total Internal Tension")
	_totals_row.set_cell_mode(3,TreeItem.CELL_MODE_STRING)
	_totals_row.set_text(3,str(possible_world_mind.get_total_internal_tension()))
	_totals_row.set_text_alignment(3,HORIZONTAL_ALIGNMENT_CENTER)
	_totals_row.set_selectable(2,false)
	_totals_row.set_selectable(3,false)
	_totals_row.set_selectable(4,false)

func _create_row(prop:StringName,pwm:PossibleWorldMind)->TreeItem:
	var item :TreeItem = create_item(root)
	item.set_meta('prop',prop)
	item.set_text(0,prop)
	item.set_editable(1,true)
	item.set_cell_mode(1,TreeItem.CELL_MODE_RANGE)
	item.set_range_config(1,-1,1,0.001)
	item.set_range(1,pwm.get_ideal_proposition(prop))
	item.set_editable(2,true)
	item.set_cell_mode(2,TreeItem.CELL_MODE_RANGE)
	item.set_range_config(2,-1,1,0.001)
	item.set_range(2,pwm.get_perceived_proposition(prop))
	var tension := pwm.get_internal_tension(prop)
	item.set_text(3,str(tension))
	if tension <= 1.0:
		item.set_custom_color(3,Color.GREEN)
	elif tension <= 1.5:
		item.set_custom_color(3,Color.GOLD)
	else:
		item.set_custom_color(3,Color.ORANGE_RED)
	item.set_cell_mode(4,TreeItem.CELL_MODE_CUSTOM)
	item.set_text(4,'Delete')
	return item

func _on_resource_changed():
	if possible_world_mind.is_built_in():
		return
	ResourceSaver.save(possible_world_mind,possible_world_mind.resource_path,ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)

func _on_item_edited():
	var item:TreeItem = get_edited()
	var column:int = get_edited_column()
	match column:
		0:
			pass
		1:
			possible_world_mind.set_ideal_proposition(item.get_meta('prop'),item.get_range(1))
			var new_tension = possible_world_mind.get_internal_tension(item.get_meta('prop'))
			item.set_text(3,str(new_tension))
			if new_tension <= 1.0:
				item.set_custom_color(3,Color.GREEN)
			elif new_tension <= 1.5:
				item.set_custom_color(3,Color.GOLD)
			else:
				item.set_custom_color(3,Color.ORANGE_RED)
			_totals_row.set_text(3,str(possible_world_mind.get_total_internal_tension()))
		2:
			possible_world_mind.set_perceived_proposition(item.get_meta('prop'),item.get_range(2))
			var new_tension = possible_world_mind.get_internal_tension(item.get_meta('prop'))
			item.set_text(3,str(new_tension))
			if new_tension <= 1.0:
				item.set_custom_color(3,Color.GREEN)
			elif new_tension <= 1.5:
				item.set_custom_color(3,Color.GOLD)
			else:
				item.set_custom_color(3,Color.ORANGE_RED)
			_totals_row.set_text(3,str(possible_world_mind.get_total_internal_tension()))
		3:
			pass

func _on_cell_selected():
	if get_selected() == _totals_row and get_selected_column() == 1:
		_create_new_prop()
	elif get_selected() != _totals_row and get_selected_column() == 4:
		_delete_row(get_selected())

func _delete_row(item:TreeItem):
	possible_world_mind.remove_proposition(item.get_meta('prop'))
	_update_tree.call_deferred()

func _create_new_prop():
	var prop :StringName = _totals_row.get_text(0)
	possible_world_mind.set_proposition(prop,0.0,0.0)
	_update_tree.call_deferred()
