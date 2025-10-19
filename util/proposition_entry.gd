class_name PropositionEntry
extends HBoxContainer

@export var world:World

var prop_label:Label
var option_button: OptionButton
var popup_menu: PopupMenu

static func create_entry(w:World,prop_id:StringName):
	var e := PropositionEntry.new()
	e.world = w
	e.set_proposition(prop_id)
	return e

func _init() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	prop_label = Label.new()
	prop_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prop_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prop_label.autowrap_mode =TextServer.AUTOWRAP_WORD_SMART
	add_child(prop_label)
	
	option_button = OptionButton.new()
	option_button.add_item("FALSE",0)
	option_button.add_item("TRUE",1)
	option_button.add_item("UNKOWN",1)
	add_child(option_button)
	
	option_button.item_selected.connect(func(v):
		world.setTruth(prop_label.text,v)
	)
	
	popup_menu = PopupMenu.new()
	add_child(popup_menu)
	popup_menu.id_pressed.connect(_on_popup_menu)
	popup_menu.add_item("Add Proposition")
	popup_menu.add_item("Delete")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		popup_menu.popup_on_parent(Rect2(event.global_position,Vector2.ZERO))

func _on_popup_menu(id):
	var item_name = popup_menu.get_item_text(id)
	print(item_name)
	match item_name:
		"Add Proposition":
			var we :WorldEditor = get_tree().root.get_node("WorldEditor")
			we.character.setPerceived(prop_label.text,world.getTruth(prop_label.text))
		"Delete":
			world.eraseTruth(prop_label.text)
		_:
			pass

func set_proposition(id:StringName):
	if world != null && world.hasProposition(id):
		prop_label.text = id
		option_button.select(world.getTruth(id) as int)

func _get_drag_data(at_position: Vector2) -> Variant:
	var data:Dictionary
	data.set("world",world)
	data.set("proposition",prop_label.text)
	return data
