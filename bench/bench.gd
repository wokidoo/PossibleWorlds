@tool
extends VBoxContainer
class_name Bench

const LAMBDA_MISSING := 0  # tune if you want missing props to count in tensions

#region containers
@onready var top_bar_container:HBoxContainer = HBoxContainer.new()
@onready var split_container:SplitContainer = SplitContainer.new()
@onready var left_container:PanelContainer = PanelContainer.new()
@onready var detail_container:PanelContainer = PanelContainer.new()
@onready var left_tab_container:TabContainer = TabContainer.new()

var proposition_list:ItemList
var character_list:ItemList
var themes_list:ItemList

#region buttons

var new_button:Button
var save_button:Button
var load_button:Button

#region init

func _ready() -> void:
	add_child(top_bar_container)
	new_button = UiButton.create_top_bar_button("New", _on_new_button_pressed)
	save_button = UiButton.create_top_bar_button("Save",WorldServer.save_state)
	load_button = UiButton.create_top_bar_button("load",WorldServer.load_state)
	top_bar_container.add_child(new_button)
	top_bar_container.add_child(save_button)
	top_bar_container.add_child(load_button)
	
	left_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
	split_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split_container)
	split_container.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
	split_container.add_child(left_container)
	split_container.add_child(detail_container)

	left_container.add_child(left_tab_container)
	proposition_list = UiContainer.create_item_list("Propositions")
	proposition_list.item_selected.connect(_on_proposition_item_selected)
	themes_list = UiContainer.create_item_list("Themes")
	themes_list.item_selected.connect(_on_theme_item_selected)
	character_list = UiContainer.create_item_list("Characters")
	character_list.item_selected.connect(_on_character_item_selected)
	left_tab_container.add_child(proposition_list)
	left_tab_container.add_child(themes_list)
	left_tab_container.add_child(character_list)

	WorldServer.changed.connect(populate_propositions_list)
	WorldServer.changed.connect(populate_themes_list)
	WorldServer.changed.connect(populate_characters_list)

	populate_propositions_list()
	populate_themes_list()
	populate_characters_list()

#region populate panels

func populate_propositions_list():
	# Clear current rows
	proposition_list.clear()

	# Collect and sort by id for stable ordering
	var ids: Array = WorldServer.get_canonical_proposition_ids()
	ids.sort()

	proposition_list.add_item("")
	for id in ids:
		var p: Proposition = WorldServer.get_canonical_proposition(id)
		if p == null:
			continue
		var label := "%d: %s  [%s]" % [id, String(p.description), p.value]
		proposition_list.add_item(label)

func populate_themes_list():
	themes_list.clear()
	var themes:Array = WorldServer.get_themes()
	for t in themes:
		var label :String = t
		themes_list.add_item(label)

func populate_characters_list():
	character_list.clear()
	var characters:Array = WorldServer.get_characters()
	for c in characters:
		var label:String = c.name
		character_list.add_item(label)

func populate_detail_container(control:Control):
	for i in detail_container.get_children():
		i.free()
	detail_container.add_child(control)

#region on signals

func _on_proposition_item_selected(index:int):
	if index > 0:
		populate_detail_container(UiDetails.PropositionDetailPanel.create(index))

func _on_theme_item_selected(index:int):
	populate_detail_container(UiDetails.ThemesDetailPanel.create(index))

func _on_character_item_selected(index:int):
	var c := WorldServer.get_characters()[index]
	populate_detail_container(UiDetails.CharacterDetailPanel.create(c))

func _on_new_button_pressed():
	WorldServer._reset_for_tests()
	populate_characters_list()
	populate_propositions_list()
	populate_themes_list()