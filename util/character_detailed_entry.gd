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
	add_proposition_button.pressed.connect(func():
		if not character.perceivedWorld.has_proposition(add_proposition_line_edit.text):
			character.set_perceived(add_proposition_line_edit.text,PW.TriBool.UNKNOWN)
			add_proposition_line_edit.clear()
			_build_tension_tree()
	)
	add_proposition_line_edit.text_submitted.connect(func(text):
		if not character.perceivedWorld.has_proposition(text):
			character.set_perceived(text,PW.TriBool.UNKNOWN)
			add_proposition_line_edit.clear()
			_build_tension_tree()
	)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("proposition") and data.has("world")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	character.set_perceived(data["proposition"],data["world"].get_truth(data["proposition"]))
	character.set_ideal(data["proposition"],data["world"].get_truth(data["proposition"]))

func set_character(c:Character):
	if ws != null && ws.characters.has(c):
		if character != null and character.changed.is_connected(_populate_proposition_containers):
			character.changed.disconnect(_populate_proposition_containers)
		if character != null and character.changed.is_connected(_build_tension_tree):
			character.changed.disconnect(_build_tension_tree)
		character = c
		character.changed.connect(_populate_proposition_containers)
		character.changed.connect(_build_tension_tree)
		_populate_proposition_containers()
		_build_tension_tree()

func _tension_text(perceived:int, ideal:int) -> String:
	if perceived == PW.TriBool.UNKNOWN or ideal == PW.TriBool.UNKNOWN:
		return "UNKNOWN"
	elif perceived == ideal:
		return "AGREE"
	return "DISAGREE"

func _set_tension_color(item:TreeItem,column:int):
	var v :int= item.get_range(column) as int -1
	match v:
		PW.TriBool.FALSE:
			item.set_custom_color(column,Color.FIREBRICK)
		PW.TriBool.UNKNOWN:
			item.set_custom_color(column,Color.GOLDENROD)
		PW.TriBool.TRUE:
			item.set_custom_color(column,Color.WEB_GREEN)
		_:
			item.set_custom_color(column,Color.GOLDENROD)
			
func _on_tension_item_edited() -> void:
	var item := tension_tree.get_edited()
	if item == null:
		return
	var col := tension_tree.get_edited_column()
	var prop := item.get_text(0)

	# Clamp/round defensively, though step=1 makes it integer.
	var v := item.get_range(col) as int  -1# -1, 0, or 1

	match col:
		1:
			character.set_perceived(prop, v)
		2:
			character.set_ideal(prop, v)
		_:
			return

func _populate_proposition_containers():
	for n in perceived_proposition_v_box_container.get_children():
		n.queue_free()
	for n in ideal_proposition_v_box_container.get_children():
		n.queue_free()
	for p in character.perceivedWorld.propositions:
		var entry:PropositionEntry= PropositionEntry.create_entry(character.perceivedWorld,p)
		perceived_proposition_v_box_container.add_child(entry)
	for p in character.idealWorld.propositions:
		var entry:PropositionEntry= PropositionEntry.create_entry(character.idealWorld,p)
		ideal_proposition_v_box_container.add_child(entry)

func _refresh_proposition_tree_cells():
	for child in tension_tree.get_root().get_children():
		if child == tension_tree.get_root():
			continue
		var p:String = child.get_text(0)
		child.set_range(1, character.get_perceived(p)+1)
		_set_tension_color(child,1)
		child.set_range(2, character.get_ideal(p)+1)
		_set_tension_color(child,2)
		_refresh_tension_cell(child)

func _refresh_tension_cell(item:TreeItem) -> void:
	var p := item.get_text(0)
	var perceived := character.get_perceived(p)
	var ideal := character.get_ideal(p)
	item.set_text(3, _tension_text(perceived, ideal))
	match item.get_text(3):
		"AGREE":
			item.set_custom_color(3, Color.WEB_GREEN)
		"DISAGREE":
			item.set_custom_color(3, Color.FIREBRICK)
		"UNKNOWN":
			item.set_custom_color(3, Color.GOLDENROD)
		_:
			item.set_custom_color(3, Color.PURPLE)
	
	item.set_text_alignment(3, HORIZONTAL_ALIGNMENT_CENTER)
	tension_tree.set_column_title(3, "Tension Perceived vs Ideal (%.2f)" % character.ideal_perceived_tension())

func _build_tension_tree():
	name_line_edit.text = character.name
	instance_id_label.text = "[b]Instance ID:[/b] %s" % character.get_instance_id()

	tension_tree.clear()
	tension_tree.item_edited.connect(_on_tension_item_edited)
	var root = tension_tree.create_item()
	tension_tree.set_column_title(0, "Proposition")
	tension_tree.set_column_title(1, "Perceived")
	tension_tree.set_column_title(2, "Ideal")
	tension_tree.set_column_title(3, "Tension Perceived vs Ideal (%.2f)" % character.ideal_perceived_tension())

	for p in character.perceivedWorld.propositions.keys():
		var child := tension_tree.create_item(root)
		child.set_text(0, p)

		child.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
		child.set_range_config(1, -1, 1, 1)
		child.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
		child.set_editable(1, true)
		child.set_text(1,"%s,%s,%s" % [PW.TriBoolString[-1],PW.TriBoolString[0],PW.TriBoolString[1]])
		
		child.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
		child.set_range_config(2, -1, 1, 1)
		child.set_text_alignment(2,HORIZONTAL_ALIGNMENT_CENTER)
		child.set_editable(2, true)
		child.set_text(2,"%s,%s,%s" % [PW.TriBoolString[-1],PW.TriBoolString[0],PW.TriBoolString[1]])

		_refresh_tension_cell(child)
	_refresh_proposition_tree_cells()
