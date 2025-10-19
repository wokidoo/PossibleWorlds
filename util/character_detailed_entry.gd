class_name CharacterDetailedEntry
extends Control

const SCENE = preload("uid://cwdwqqw1spy0y")

@onready var name_line_edit: LineEdit = %NameLineEdit
@onready var instance_id_label: RichTextLabel = %InstanceIDLabel
@onready var perceived_proposition_v_box_container: VBoxContainer = %PerceivedPropositionVBoxContainer
@onready var ideal_proposition_v_box_container: VBoxContainer = %IdealPropositionVBoxContainer
@onready var perceived_foldable_container: FoldableContainer = %PerceivedFoldableContainer
@onready var ideal_foldable_container: FoldableContainer = %IdealFoldableContainer
@onready var tension_tree: Tree = %TensionTree
@onready var add_proposition_button: Button = %AddPropositionButton
@onready var add_proposition_line_edit: LineEdit = %AddPropositionLineEdit

# Reuse one popup for all rows/columns
var _tri_popup: PopupMenu
var _popup_item: TreeItem
var _popup_column: int

@export var ws:WorldState
var character: Character

static func create_entry(world_state:WorldState, c:Character) -> CharacterDetailedEntry:
	var e :CharacterDetailedEntry = SCENE.instantiate()
	e.ws = world_state
	e.set_character.call_deferred(c)
	return e

func _ready() -> void:
	name_line_edit.text_submitted.connect(func(text):
		character.name = text
	)
	_setup_tri_popup()
	# Show popup when a custom-cell arrow is clicked
	tension_tree.custom_popup_edited.connect(_on_tree_custom_popup_edited)
	# Also handle double-activate (Enter/Double click) as a fallback
	tension_tree.item_activated.connect(_on_tree_item_activated)
	add_proposition_button.pressed.connect(func():
		if not character.perceivedWorld.hasProposition(add_proposition_line_edit.text):
			character.setPerceived(add_proposition_line_edit.text,PW.TriBool.UNKNOWN)
			add_proposition_line_edit.clear()
	)
	add_proposition_line_edit.text_submitted.connect(func(text):
		if not character.perceivedWorld.hasProposition(text):
			character.setPerceived(text,PW.TriBool.UNKNOWN)
			add_proposition_line_edit.clear()
			
	)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("proposition") and data.has("world")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	character.setPerceived(data["proposition"],data["world"].getTruth(data["proposition"]))
	character.setIdeal(data["proposition"],data["world"].getTruth(data["proposition"]))

func set_character(c:Character):
	if ws != null && ws.characters.has(c):
		if character != null and character.changed.is_connected(_update_gui):
			character.changed.disconnect(_update_gui)
		character = c
		character.changed.connect(_update_gui)
		_update_gui()

func _setup_tri_popup() -> void:
	_tri_popup = PopupMenu.new()
	add_child(_tri_popup)
	for i in PW.TriBoolString.size():
		_tri_popup.add_item(PW.TriBoolString[i], i)
	_tri_popup.id_pressed.connect(_on_tri_popup_id_pressed)

# Show popup when the user clicks the custom cell’s arrow
func _on_tree_custom_popup_edited(arrow_clicked: bool) -> void:
	if not arrow_clicked:
		return
	var item := tension_tree.get_edited()
	var col  := tension_tree.get_edited_column()
	if item == null or (col != 1 and col != 2):
		return
	_show_tri_popup_for(item, col)

# Fallback: double-click / Enter on the cell
func _on_tree_item_activated() -> void:
	var item := tension_tree.get_selected()
	var col := tension_tree.get_selected_column()
	if item and (col == 1 or col == 2):
		_show_tri_popup_for(item, col)

func _show_tri_popup_for(item: TreeItem, col: int) -> void:
	_popup_item = item
	_popup_column = col
	# Pre-select current value
	var current_text := item.get_text(col)
	var initial_index := 0
	for i in PW.TriBoolString.size():
		if PW.TriBoolString[i] == current_text:
			initial_index = i
			break
	_tri_popup.toggle_item_checked(initial_index)

	# Position the popup to the edited cell
	var r: Rect2 = tension_tree.get_custom_popup_rect()
	_tri_popup.position = (tension_tree.get_global_rect().position + r.position).floor()
	_tri_popup.reset_size()
	_tri_popup.popup_on_parent(Rect2(get_viewport().get_mouse_position(),Vector2.ZERO))
	
func _on_tri_popup_id_pressed(id: int) -> void:
	if _popup_item == null:
		return
	var label :String= PW.TriBoolString[id]
	var value :PW.TriBool = id as PW.TriBool
	_popup_item.set_text(_popup_column, label)

	var prop_name := _popup_item.get_text(0)

	if _popup_column == 1:
		character.perceivedWorld.setTruth(prop_name, value)  # value is 0/1/2 per your enum
	elif _popup_column == 2:
		character.idealWorld.setTruth(prop_name, value)
	_update_gui()

func _tension_text(perceived:int, ideal:int) -> String:
	var result :String
	if perceived == PW.TriBool.UNKNOWN or ideal == PW.TriBool.UNKNOWN:
		return "Unknown"
	elif perceived == ideal:
		return "Agree"
	return "Disagree"

func _update_gui():
	name_line_edit.text = character.name
	instance_id_label.text = "[b]Instance ID:[/b] %s" % character.get_instance_id()
	for n in perceived_proposition_v_box_container.get_children():
		n.queue_free()
	for n in ideal_proposition_v_box_container.get_children():
		n.queue_free()
	perceived_foldable_container.title = "Perceived World (%s)" %character.perceivedWorld.propositions.size()
	for p in character.perceivedWorld.propositions.keys():
		var e :PropositionEntry = PropositionEntry.create_entry(character.perceivedWorld,p)
		perceived_proposition_v_box_container.add_child(e)
	ideal_foldable_container.title = "Ideal World (%s)" % character.idealWorld.propositions.size()
	for i in character.idealWorld.propositions.keys():
		var e:PropositionEntry = PropositionEntry.create_entry(character.idealWorld,i)
		ideal_proposition_v_box_container.add_child(e)
	
	tension_tree.clear()
	_setup_tri_popup()
	var root = tension_tree.create_item()
	tension_tree.set_column_title(0,"Proposition")
	tension_tree.set_column_title(1,"Perceived")
	tension_tree.set_column_title(2,"Ideal")
	tension_tree.set_column_title(3,"Tension Perceived vs Ideal (%s)" % character.idealPerceivedDiff().size())
	for p in character.perceivedWorld.propositions.keys():
		var child := tension_tree.create_item(root)
		child.set_text(0, p)

		# ----- Column 1 as "OptionButton" style -----
		child.set_cell_mode(1, TreeItem.CELL_MODE_CUSTOM)
		child.set_editable(1, true)
		child.set_custom_as_button(1, true) # draws a dropdown-like arrow
		child.set_text(1, PW.TriBoolString[character.getPerceived(p)])

		# ----- Column 2 as "OptionButton" style -----
		child.set_cell_mode(2, TreeItem.CELL_MODE_CUSTOM)
		child.set_editable(2, true)
		child.set_custom_as_button(2, true)
		child.set_text(2, PW.TriBoolString[character.getIdeal(p)])

		# Column 3: just text (your tension metric)
		var perceived := character.getPerceived(p)
		var ideal := character.getIdeal(p)
		child.set_text(3, _tension_text(perceived, ideal))
		if child.get_text(3) == "Agree":
			child.set_custom_color(3,Color.WEB_GREEN)
		elif child.get_text(3) == "Disagree":
			child.set_custom_color(3,Color.FIREBRICK)
		else:
			child.set_custom_color(3,Color.YELLOW)
		child.set_text_alignment(3,HORIZONTAL_ALIGNMENT_CENTER)
