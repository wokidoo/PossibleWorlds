class_name PropositionEntry
extends HBoxContainer

@export var world:World

var prop_label:Label
var option_button: OptionButton
var confidence_spinbox: SpinBox
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
	prop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prop_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prop_label.autowrap_mode =TextServer.AUTOWRAP_WORD
	add_child(prop_label)
	
	option_button = OptionButton.new()
	option_button.add_item("FALSE",0)
	option_button.add_item("UNKOWN",1)
	option_button.add_item("TRUE",2)
	add_child(option_button)
	
	option_button.item_selected.connect(func(v):
		world.set_truth(prop_label.text,v-1)
	)
	
	confidence_spinbox = SpinBox.new()
	confidence_spinbox.step = 0.01
	confidence_spinbox.max_value = 1
	confidence_spinbox.min_value = 0
	confidence_spinbox.value_changed.connect(func(v):
		world.set_confidence(prop_label.text,v)
	)
	add_child(VSeparator.new())
	var conf_l: Label = Label.new()
	conf_l.text = "Confidence:"
	add_child(conf_l)
	add_child(confidence_spinbox)
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
			we.character.set_perceived(prop_label.text,world.get_truth(prop_label.text))
		"Delete":
			world.erase_truth(prop_label.text)
		_:
			pass

func set_proposition(id:StringName):
	if world != null && world.has_proposition(id):
		prop_label.text = id
		option_button.select(world.get_truth(id)+1)
		confidence_spinbox.value = world.get_confidence(id)

func _get_drag_data(at_position: Vector2) -> Variant:
	var data:Dictionary
	data.set("world",world)
	data.set("proposition",prop_label.text)
	return data
