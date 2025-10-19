class_name CharacterEntry
extends Button

@export var ws:WorldState
var character:Character
var popup_menu: PopupMenu

signal character_selected(c:Character)

static func create_entry(world_state:WorldState,c:Character) -> CharacterEntry:
	var e := CharacterEntry.new()
	e.ws = world_state
	e.set_character(c)
	return e

func _init() -> void:
	popup_menu = PopupMenu.new()
	add_child(popup_menu)
	popup_menu.id_pressed.connect(_on_popup_menu)
	popup_menu.add_item("Delete")
	
	pressed.connect(func():
		character_selected.emit(character)
	)
	self.alignment = HORIZONTAL_ALIGNMENT_RIGHT

func set_character(c:Character):
	if ws != null && ws.characters.has(c):
		character = c
		text = character.name
		text +=" (%s)"%character.get_instance_id()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		popup_menu.popup_on_parent(Rect2(event.global_position,Vector2.ZERO))

func _on_popup_menu(id):
	var item_name = popup_menu.get_item_text(id)
	print(item_name)
	match item_name:
		"Delete":
			ws.remove_character(character)
		_:
			pass
