class_name WorldEditor
extends Node

@onready var file_menu_button: FileMenuButton = %FileMenuButton
@onready var world_name_line_edit: LineEdit = %WorldNameLineEdit
@onready var canon_proposition_container: VBoxContainer = %CanonPropositionContainer
@onready var character_proposition_container: VBoxContainer = %CharacterPropositionContainer
@onready var details_panel_container: ScrollContainer = $VBoxContainer/MarginContainer/HSplitContainer/RightPanel/DetailsPanelContainer

@onready var left_tab_container: TabContainer = %LeftTabContainer

@onready var create_proposition_h_box_container: HBoxContainer = %CreatePropositionHBoxContainer
@onready var new_proposition_line_edit: LineEdit = %NewPropositionLineEdit
@onready var confirm_proposition_button: Button = %ConfirmPropositionButton

@onready var create_character_h_box_container: HBoxContainer = %CreateCharacterHBoxContainer
@onready var new_character_line_edit: LineEdit = %NewCharacterLineEdit
@onready var confirm_character_button: Button = %ConfirmCharacterButton


@export var ws:WorldState:set = _on_world_state_set
var character:Character

func _ready() -> void:
	world_name_line_edit.text_submitted.connect(func(text):
		ws.name = text
	)
	file_menu_button.loaded_world_state.connect(func(res:WorldState):
		ws = res
	)
	left_tab_container.tab_changed.connect(func(i):
		create_proposition_h_box_container.visible = false
		match i:
			0: # Proposition Tab
				create_character_h_box_container.visible = false
				create_proposition_h_box_container.visible = true
			1: # Character Tab
				create_proposition_h_box_container.visible = false
				create_character_h_box_container.visible = true
			_:
				pass
	)
	new_proposition_line_edit.text_submitted.connect(func(text):
		ws.canonWorld.setTruth(text,World.TriBool.UNKNOWN)
		new_proposition_line_edit.clear()
	)
	confirm_proposition_button.pressed.connect(func():
		ws.canonWorld.setTruth(new_proposition_line_edit.text,World.TriBool.UNKNOWN)
		new_proposition_line_edit.clear()
	)
	
	new_character_line_edit.text_submitted.connect(func(text):
		var c := Character.new()
		c.name = text
		ws.add_character(c)
		new_character_line_edit.clear()
	)
	confirm_character_button.pressed.connect(func():
		var c := Character.new()
		c.name = new_character_line_edit.text
		ws.add_character(c)
		new_character_line_edit.clear()
	)
func _on_world_state_set(value):
	if ws != null && ws.changed.is_connected(_on_world_state_changed):
		ws.changed.disconnect(_on_world_state_changed)
	ws = value
	ws._reconnect_signals()
	ws.changed.connect(_on_world_state_changed)
	for n in details_panel_container.get_children():
		n.queue_free()
	_update_gui()

func _on_world_state_changed():
	print("Changes made to World State. Saving...")
	ResourceSaver.save(ws,ws.resource_path,ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
	_update_gui()
	
func _update_gui():
	if ws != null:
		world_name_line_edit.text = ws.name
		for n in canon_proposition_container.get_children():
			n.queue_free()
		canon_proposition_container.get_parent().name = "Canon Propositions (%s)"%ws.canonWorld.propositions.size()
		for id in ws.canonWorld.propositions.keys():
			var entry = PropositionEntry.create_entry(ws.canonWorld,id)
			canon_proposition_container.add_child(entry)
		for c in character_proposition_container.get_children():
			c.queue_free()
		character_proposition_container.get_parent().name = "Characters (%s)"%ws.characters.size()
		for c in ws.characters:
			var entry :CharacterEntry = CharacterEntry.create_entry(ws,c)
			entry.character_selected.connect(_on_character_selected)
			character_proposition_container.add_child(entry)
	else:
		world_name_line_edit.text = "<No WorldState Loaded>"

func _on_character_selected(c:Character):
	for n in details_panel_container.get_children():
		n.queue_free()
	var entry :CharacterDetailedEntry= CharacterDetailedEntry.create_entry(ws,c)
	details_panel_container.add_child(entry)
	character = c
