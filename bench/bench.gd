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
var character_list:Control
var themes_list:Control

#region buttons
var save_button:Button
var load_button:Button

func _ready() -> void:
	add_child(top_bar_container)
	save_button = UiButton.create_top_bar_button("Save",func():pass)
	load_button = UiButton.create_top_bar_button("load",func():pass)
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
	character_list = UiContainer.create_item_list("Characters")
	left_tab_container.add_child(proposition_list)
	left_tab_container.add_child(themes_list)
	left_tab_container.add_child(character_list)

	populate_propositions_list()

func populate_propositions_list():
	# Clear current rows
	for c in proposition_list.get_children():
		c.queue_free()

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
	for i in themes_list.get_children():
		i.free()

func populate_characters_list():
	for i in character_list.get_children():
		i.free()

func populate_detail_container(control:Control):
	for i in detail_container.get_children():
		i.free()
	detail_container.add_child(control)

func _on_proposition_item_selected(index:int):
	populate_detail_container(make_canonical_proposition_details(index))

static func make_canonical_proposition_details(id:int):
	if id == 0:
		return null
	var prop := WorldServer.get_canonical_proposition(id)
	var container:= VBoxContainer.new()
	var title_label:= Label.new()
	title_label.text = "Proposition"
	var description_label := Label.new()
	description_label.text = "Description: '%s' [%s]" % [prop.description,prop.value]
	container.add_child(title_label)
	container.add_child(description_label)
	return container
