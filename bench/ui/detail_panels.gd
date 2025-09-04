extends RefCounted
class_name UiDetails

class PropositionDetailPanel extends MarginContainer:

	@export var proposition:Proposition:
		set(val):
			proposition = val
			_update_data()

	var vbox_container:VBoxContainer
	var title_label: Label
	var desc_label :LineEdit
	var value_check_box: CheckBox
	var id_label: Label

	func _init():
		set_anchors_preset(LayoutPreset.PRESET_FULL_RECT)
		add_theme_constant_override("margin_top", 7)
		add_theme_constant_override("margin_bottom", 7)
		add_theme_constant_override("margin_left", 7)
		add_theme_constant_override("margin_right", 7)
		vbox_container = VBoxContainer.new()
		add_child(vbox_container)
		
		title_label = Label.new()
		title_label.add_theme_font_size_override("font_size",24)
		title_label.text = "Proposition"
		vbox_container.add_child(title_label)

		vbox_container.add_child(HSeparator.new())

		id_label = Label.new()
		id_label.autowrap_mode = TextServer.AUTOWRAP_OFF

		desc_label = LineEdit.new()
		desc_label.text_submitted.connect(_on_description_line_submitted)
		desc_label.expand_to_text_length = true

		value_check_box = CheckBox.new()
		value_check_box.focus_mode = Control.FOCUS_NONE
		value_check_box.button_up.connect(_on_value_button_pressed)
		value_check_box.button_up.connect(_update_data)

		var hbox_container_id := HBoxContainer.new()
		vbox_container.add_child(hbox_container_id)
		var hbox_container_desc := HBoxContainer.new()
		vbox_container.add_child(hbox_container_desc)
		var hbox_container_val := HBoxContainer.new()
		vbox_container.add_child(hbox_container_val)

		var id := Label.new()
		id.text = "ID: "
		hbox_container_id.add_child(id)
		hbox_container_id.add_child(id_label)

		var description := Label.new()
		description.text = "Description: "
		hbox_container_desc.add_child(description)
		hbox_container_desc.add_child(desc_label)

		var value := Label.new()
		value.text = "Value: "
		hbox_container_val.add_child(value)
		hbox_container_val.add_child(value_check_box)

	func _ready():
		value_check_box.button_pressed = proposition.value

	func _update_data():
		if proposition != null:
			id_label.text = str(proposition._prop_id)
			desc_label.text = proposition.description
			value_check_box.button_pressed = proposition.value

	func _on_value_button_pressed():
		if proposition != null:
			proposition.value = value_check_box.button_pressed


	func _on_description_line_submitted(text:String):
		if proposition != null:
			proposition.description = text

	static func create(id:int) -> PropositionDetailPanel:
		var prop :Proposition = WorldServer.get_canonical_proposition(id)
		
		var panel := PropositionDetailPanel.new()

		panel.proposition = prop
		return panel

class ThemesDetailPanel extends MarginContainer:
	
	var vbox_container:VBoxContainer
	var title_label: Label
	var theme_line_edit:LineEdit
	var theme_index: int:
		set(val):
			var themes :Array= WorldServer.get_themes()
			if val < themes.size() and val >= 0:
				theme_index = val
				_update_data()

	func _init():
		set_anchors_preset(LayoutPreset.PRESET_FULL_RECT)
		add_theme_constant_override("margin_top", 7)
		add_theme_constant_override("margin_bottom", 7)
		add_theme_constant_override("margin_left", 7)
		add_theme_constant_override("margin_right", 7)
		vbox_container = VBoxContainer.new()
		add_child(vbox_container)
		
		title_label = Label.new()
		title_label.add_theme_font_size_override("font_size",24)
		title_label.text = "Theme"
		vbox_container.add_child(title_label)

		vbox_container.add_child(HSeparator.new())

		theme_line_edit = LineEdit.new()
		theme_line_edit.expand_to_text_length = true
		theme_line_edit.text_submitted.connect(_on_text_submitted)

		var hbox_container := HBoxContainer.new()
		var name_label:=Label.new()
		name_label.text = "Name: "
		hbox_container.add_child(name_label)
		hbox_container.add_child(theme_line_edit)
		vbox_container.add_child(hbox_container)

	func _update_data():
		var theme_string :String = WorldServer.get_themes()[theme_index]
		theme_line_edit.text = theme_string

	func _on_text_submitted(text:String):
		WorldServer.rename_theme(theme_index,text)

	static func create(index:int) -> ThemesDetailPanel:
		var panel := ThemesDetailPanel.new()
		panel.theme_index = index
		return panel
	
class CharacterDetailPanel extends MarginContainer:
	
	@export var character:Character:
		set(val):
			character = val
			_update_data()

	var vbox_container:VBoxContainer
	var title_label: Label
	var name_line_edit:LineEdit

	var pvc_table:Tree

	func _init():
		set_anchors_preset(LayoutPreset.PRESET_FULL_RECT)
		add_theme_constant_override("margin_top", 7)
		add_theme_constant_override("margin_bottom", 7)
		add_theme_constant_override("margin_left", 7)
		add_theme_constant_override("margin_right", 7)
		vbox_container = VBoxContainer.new()
		add_child(vbox_container)
		
		title_label = Label.new()
		title_label.add_theme_font_size_override("font_size",24)
		title_label.text = "Character"
		vbox_container.add_child(title_label)

		vbox_container.add_child(HSeparator.new())

		name_line_edit = LineEdit.new()
		name_line_edit.expand_to_text_length = true
		name_line_edit.text_submitted.connect(_on_name_line_edit_submitted)

		var hbox_container_name := HBoxContainer.new()
		var name_label:=Label.new()
		name_label.text = "Name: "
		hbox_container_name.add_child(name_label)
		hbox_container_name.add_child(name_line_edit)

		vbox_container.add_child(hbox_container_name)
		vbox_container.add_child(HSeparator.new())

		pvc_table = Tree.new()
		pvc_table.add_theme_color_override("bg_color",Color(45,45,45))
		pvc_table.columns = 4
		pvc_table.set_column_expand(0,true)
		pvc_table.set_column_expand(1,true)
		pvc_table.set_column_expand(2,true)
		pvc_table.set_column_expand(3,true)
		pvc_table.set_column_expand_ratio(0,2)
		pvc_table.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pvc_table.hide_root = false
		vbox_container.add_child(pvc_table)

		pvc_table.item_edited.connect(_on_pvc_item_edited)

	func _update_data():
		if character != null:
			name_line_edit.text = character.name
			populate_perceived_vs_canonical_table()


	func _on_name_line_edit_submitted(text:String):
		character.name = text


	func _on_pvc_item_edited() -> void:
		var item := pvc_table.get_edited()
		var col := pvc_table.get_edited_column()

		# Which proposition is this row?
		var id := int(item.get_metadata(col))
		var new_val := item.is_checked(col)
		
		# Write back into the character’s perceived world
		character.believe(id, new_val)

		# update table
		var tension:int = character.get_perceived_proposition_with_id(id).diff(WorldServer.get_canonical_proposition(id))
		var tension_string:String = str(tension)
		if tension >0:
			item.set_custom_color(3,Color.RED)
		else:
			item.clear_custom_color(3)
		item.set_text(3,tension_string)

		pvc_table.get_root().set_text(1,str(character.get_perceived_vs_canonical_tension()))


	func populate_perceived_vs_canonical_table():
		pvc_table.clear()
		var root := pvc_table.create_item()
		root.set_text(0,"Tension: Perceived ↔ Canonical")
		root.set_text(1,str(character.get_perceived_vs_canonical_tension()))
		root.set_custom_font_size(0,18)

		var header:= root.create_child()
		header.set_text(0, "Proposition")
		header.set_text(1, "Perveived")
		header.set_text(2, "Canonical")
		header.set_text(3, "Tension")
		var props := character.get_perceived_propositions() 
		for id in props:
			var p_prop:Proposition = character.get_perceived_proposition_with_id(id)
			var c_prop:Proposition = WorldServer.get_canonical_proposition(id)
			var entry = pvc_table.create_item(root)
			var tension = p_prop.diff(c_prop)

			entry.set_text(0,p_prop.description)
			entry.set_metadata(0,p_prop._prop_id)

			# perceived column
			entry.set_cell_mode(1,TreeItem.CELL_MODE_CHECK)
			entry.set_checked(1,p_prop.value)
			entry.set_editable(1,true)
			entry.set_metadata(1,p_prop._prop_id)

			# canonical column
			entry.set_text(2,str(c_prop.value))
			entry.set_text(3,str(tension))

			if p_prop.value:
				entry.set_custom_color(1,Color.GREEN)
			else:
				entry.set_custom_color(1,Color.RED)
			
			if c_prop.value:
				entry.set_custom_color(2,Color.GREEN)
			else:
				entry.set_custom_color(2,Color.RED)

			if tension > 0:
				entry.set_custom_color(3,Color.RED)



	static func create(c:Character) -> CharacterDetailPanel:
		var panel := CharacterDetailPanel.new()
		panel.character = c
		return panel