class_name PossibleMindTreeList
extends VBoxContainer

@export var minds:Dictionary[StringName,PossibleWorldMind]:
	set(val):
		minds = val.duplicate_deep()
		_update_ui.call_deferred()

signal mind_selected(key:StringName,mind:PossibleWorldMind)
signal mind_added(key:StringName,mind:PossibleWorldMind)
signal mind_removed(key:StringName,mind:PossibleWorldMind)

var _tree:Tree
var _filter_line_edit:LineEdit
var _filter_terms: Array[Dictionary] = []
var _add_mind_button:Button
var _add_mind_line_edit:LineEdit

func _ready() -> void:
	var filter_container := HBoxContainer.new()
	var filter_label:= Label.new()
	filter_label.text = "Filter: "
	_filter_line_edit = LineEdit.new()
	
	_filter_line_edit.text_submitted.connect(_on_filter_line_edit_submitted)
	_filter_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_container.add_child(filter_label)
	filter_container.add_child(_filter_line_edit)
	filter_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(filter_container)
	_tree = Tree.new()
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.hide_root = true
	_tree.column_titles_visible = true
	_tree.item_selected.connect(_on_mind_tree_list_item_selected)
	_tree.set_column_expand_ratio(0,4)
	_tree.set_column_title(0,"Minds")
	_tree.columns = 2
	add_child(_tree)
	var h_box:HBoxContainer = HBoxContainer.new()
	h_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label:= Label.new()
	label.text = "New Mind: "
	_add_mind_line_edit = LineEdit.new()
	_add_mind_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_mind_line_edit.text_submitted.connect(_on_add_mind_line_edit_submitted)
	_add_mind_button = Button.new()
	_add_mind_button.pressed.connect(_on_add_mind_button_pressed)
	_add_mind_button.text = "Add +"
	h_box.add_child(label)
	h_box.add_child(_add_mind_line_edit)
	h_box.add_child(_add_mind_button)
	add_child(h_box)

func update_ui():
	_update_ui.call_deferred()

func _update_ui():
	_tree.clear()
	_tree.create_item()
	if not minds:
		return
	for mind_name in minds:
		var mind: PossibleWorldMind = minds.get(mind_name)
		if not _matches_filter(mind_name, mind):
			continue
		var item: TreeItem = _tree.create_item()
		item.set_meta('mind', mind)
		item.set_text(0, mind_name)
		item.set_text(1, "Delete")

func _on_mind_tree_list_item_selected():
	var column := _tree.get_selected_column()
	var item := _tree.get_selected()
	if column == 0:
		mind_selected.emit(item.get_text(0),item.get_meta('mind'))
	elif column == 1:
		minds.erase(item.get_text(0))
		mind_removed.emit(item.get_text(0),item.get_meta('mind'))
		update_ui()

func _on_add_mind_button_pressed():
	if _add_mind_line_edit.text.is_empty() or minds.has(_add_mind_line_edit.text):
		return
	var mind := PossibleWorldMind.new()
	minds.set(_add_mind_line_edit.text,mind)
	mind_added.emit(_add_mind_line_edit.text,mind)
	_add_mind_line_edit.clear()
	update_ui()

func _on_add_mind_line_edit_submitted(text:String):
	if _add_mind_line_edit.text.is_empty() or minds.has(_add_mind_line_edit.text):
		return
	var mind := PossibleWorldMind.new()
	minds.set(_add_mind_line_edit.text,mind)
	mind_added.emit(_add_mind_line_edit.text,mind)
	_add_mind_line_edit.clear()
	update_ui()


func _on_filter_line_edit_submitted(text: String):
	_filter_terms = _parse_filter(text)
	update_ui()

# Optional: live filtering as the user types.
# In _ready(): _filter_line_edit.text_changed.connect(_on_filter_text_changed)
func _on_filter_text_changed(text: String):
	_filter_terms = _parse_filter(text)
	update_ui()

func _parse_filter(text: String) -> Array[Dictionary]:
	var terms: Array[Dictionary] = []
	for raw in text.strip_edges().split(" ", false):
		var term := _parse_term(raw)
		if not term.is_empty():
			terms.append(term)
	return terms

func _parse_term(token: String) -> Dictionary:
	var negate := false
	if token.begins_with("!"):
		negate = true
		token = token.substr(1)

	# Find comparison operator (check longest first so >= isn't eaten by >).
	var op := ""
	var op_pos := -1
	for candidate in [">=", "<=", "!=", ">", "<", "="]:
		var p := token.find(candidate)
		if p != -1:
			op = candidate
			op_pos = p
			break

	if op_pos == -1:
		# No comparison operator: it's a presence check or name match.
		if token.begins_with("has:"):
			return {"type": "has", "prop": StringName(token.substr(4).to_snake_case()), "negate": negate}
		return {"type": "name", "value": token, "negate": negate}

	var key := token.substr(0, op_pos)
	var value := token.substr(op_pos + op.length()).to_float()

	if key == "total_tension":
		return {"type": "total_tension", "op": op, "value": value, "negate": negate}

	var colon := key.find(":")
	if colon == -1:
		return {}  # malformed; skip
	var kind := key.substr(0, colon)
	var prop := StringName(key.substr(colon + 1).to_snake_case())
	if not kind in ["ideal", "perceived", "tension"]:
		return {}
	return {"type": kind, "prop": prop, "op": op, "value": value, "negate": negate}

func _matches_filter(name: StringName, mind: PossibleWorldMind) -> bool:
	for term in _filter_terms:
		var result := _evaluate_term(name, mind, term)
		if term.get("negate", false):
			result = not result
		if not result:
			return false
	return true

func _evaluate_term(name: StringName, mind: PossibleWorldMind, term: Dictionary) -> bool:
	match term.type:
		"name":
			return String(name).to_lower().contains(String(term.value).to_lower())
		"has":
			return mind.has_proposition(term.prop)
		"ideal":
			return mind.has_proposition(term.prop) and _compare(mind.get_ideal_proposition(term.prop), term.op, term.value)
		"perceived":
			return mind.has_proposition(term.prop) and _compare(mind.get_perceived_proposition(term.prop), term.op, term.value)
		"tension":
			return mind.has_proposition(term.prop) and _compare(mind.get_internal_tension(term.prop), term.op, term.value)
		"total_tension":
			return _compare(mind.get_total_internal_tension(), term.op, term.value)
	return true

func _compare(a: float, op: String, b: float) -> bool:
	match op:
		">":  return a > b
		"<":  return a < b
		">=": return a >= b
		"<=": return a <= b
		"=":  return is_equal_approx(a, b)
		"!=": return not is_equal_approx(a, b)
	return false
